;;;
;;; Currency Exchange Rates Loader
;;;
;;; Parses IMF currency exchange rates TSV files and loads them into PostgreSQL.
;;;
;;; Usage:
;;;   taop rates [output.csv [directory]]
;;;
;;; Arguments:
;;;   output.csv  - Path to output CSV file (default: RATES_DIR/rates.csv)
;;;   directory   - Directory containing TSV rate files (default: RATES_DIR)
;;;
;;; Environment Variables:
;;;   RATES_DIR  - Default directory containing TSV rate files
;;;
;;; Workflow:
;;;   1. Parse TSV files from directory
;;;   2. Output CSV file with parsed rates
;;;   3. Load CSV into PostgreSQL using rates.sql
;;;   4. Create typed table using rate_t.sql
;;;

(in-package #:taop)

(defun run-psql-file (filepath)
  "Execute SQL from FILENAME using psql command line tool.
   This function is compatible with psql meta-commands like \\copy."
  (format t "~%;;; Running SQL file: ~a~%" filepath)
  (let* ((dir (uiop:directory-exists-p (uiop:pathname-directory-pathname filepath)))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring filepath))))
    (when dir
      (let ((cwd (uiop:getcwd)))
        (uiop:chdir dir)
        (unwind-protect
             (uiop:run-program args :output t :error-output :output)
          (uiop:chdir cwd))))))

(defun rates-default-directory ()
  "Return the default directory for rates files from RATES_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "RATES_DIR")
      (uiop:getcwd)))

(define-command (("rates") (&optional csv directory))
    "Parse rates TSV files from DIRECTORY and load into PostgreSQL.

     Arguments (all optional):
       - CSV        output CSV file path (default: RATES_DIR/rates.csv)
       - DIRECTORY  directory containing TSV rate files (default: RATES_DIR)

     Environment Variables:
       RATES_DIR  default directory when DIRECTORY is not provided

     Workflow:
       1. Parse TSV files from directory
       2. Output CSV file with parsed rates
       3. Load CSV into PostgreSQL using rates.sql
       4. Create typed table using rate_t.sql

     The rates.sql script creates the rates table with exclusion constraint.
     The rate_t.sql script creates a typed table using PostgreSQL custom type."
  (let* ((rates-dir (if directory
                         (uiop:ensure-directory-pathname directory)
                         (uiop:ensure-directory-pathname (rates-default-directory))))
         (csv-file (or csv (merge-pathnames "rates.csv" rates-dir)))
         (schema-file (merge-pathnames "data/rates/rates.sql" *top-dir*))
         (typed-file (merge-pathnames "data/rates/rate_t.sql" *top-dir*)))
    (format t ";;; Currency Exchange Rates Loader~%")
    (format t ";;; Directory: ~a~%" rates-dir)
    (format t ";;; Output: ~a~%" csv-file)

    (format t "~%;;; Step 1: Parsing TSV files...")
    (load-currency-files csv-file rates-dir)

    (format t "~%;;; Step 2: Creating schema and loading rates...")
    (run-psql-file schema-file)

    (format t "~%;;; Step 3: Creating typed table...")
    (run-psql-file typed-file)

    (format t "~%;;; Done!~%")))

(defstruct data dates values)

(defun load-currency-files (output directory)
  (format t "Loading rates currency files from ~s~%"
          (uiop:native-namestring directory))
  (let ((datasets
         (loop :for filename :in (uiop:directory-files directory)
            :when (string= (pathname-type filename) "tsv")
            :collect (parse-currency-file filename))))
    (with-open-file (o output
                       :direction :output
                       :element-type 'character
                       :external-format :utf-8
                       :if-does-not-exist :create
                       :if-exists :supersede)
      (let ((currencies (make-hash-table :test 'equal))
            (line-count 0))
        (loop :for dataset :in datasets
           :for dates := (data-dates dataset)
           :do (loop :for (currency . values) :in (data-values dataset)
                  :do (loop :for i :from 0
                         :for value :across values
                         :do (when value
                               (incf line-count)
                               (incf (gethash currency currencies 0))
                               (format o
                                       "~a;~a;~a~%"
                                       currency
                                       (aref dates i)
                                       value)))))
        (format t "Wrote ~d currency rate values for ~d currencies to ~s~%"
                line-count
                (hash-table-count currencies)
                (uiop:native-namestring output))))))

(defun parse-currency-file (filename)
  (format t "Parsing rates from ~s~%" (uiop:native-namestring filename))
  (with-open-file (s filename
                     :direction :input
                     :element-type 'character
                     :external-format :ascii)
    (read-line s)

    (let* ((line  (read-line s))
           (dates (parse-header-dates
                   (string-right-trim '(#\Return #\Newline) line)))
           (currs (loop :for line := (read-line s nil nil)
                     :while line
                     :collect (parse-currencies
                               (string-right-trim '(#\Return #\Newline) line)))))
      (make-data :dates dates :values currs))))

(defun parse-header-dates (line)
  (let* ((dates (rest (split-sequence #\Tab line)))
         (arr   (make-array (length dates) :element-type 'string)))
    (loop :for i :from 0
       :for date-string :in dates
       :do (let ((date (parse-imf-date date-string)))
             (setf (aref arr i) date)))
    arr))

(defun parse-imf-date (date-string)
  "Given May 01, 2017, return 2017-05-01."
  (let* ((items (split-sequence #\Space date-string))
         (m     (cdr (assoc (first items) *months* :test #'string=)))
         (d     (subseq (second items) 0 (+ -1 (length (second items)))))
         (y     (third items)))
    (format nil "~a-~a-~a" y m d)))

(defun parse-currencies (line)
  (let* ((fields (split-sequence #\Tab line))
         (values (mapcar (lambda (value)
                           (if (string= "NA" value) nil
                               (cl-ppcre:regex-replace "," value "")))
                         (rest fields))))
    (cons (first fields) (coerce values 'vector))))
