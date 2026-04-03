;;;
;;; Currency Exchange Rates Loader
;;;
;;; Parses IMF currency exchange rates TSV files and loads them into PostgreSQL.
;;;
;;; Usage:
;;;   taop rates [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing TSV rate files (default: RATES_DIR)
;;;
;;; Environment Variables:
;;;   RATES_DIR  - Default directory containing TSV rate files
;;;
;;; Workflow:
;;;   1. Parse TSV files from directory
;;;   2. COPY directly to PostgreSQL using COPY protocol
;;;   3. Create typed rates table with exclusion constraint
;;;   4. Create typed table using rate_t.sql
;;;

(in-package #:taop)

(defun rates-default-directory ()
  "Return the default directory for rates files from RATES_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "RATES_DIR")
      (uiop:getcwd)))

(defstruct data dates values)

(defun copy-rates (connspec directory)
  "Parse TSV files from DIRECTORY and COPY them directly to PostgreSQL.
   Returns the total number of rate entries loaded."
  (let ((table-name "raw.rates")
        (colnames '("currency" "date" "rate"))
        (total-count 0))
    (pomo:with-connection connspec
      (pomo:execute "begin")
      (let ((copier
              (cl-postgres:open-db-writer pomo:*database* table-name colnames)))
        (handler-case
            (progn
              (loop
                :for filename :in (uiop:directory-files directory)
                :when (string= "tsv" (pathname-type filename))
                  :do
                     (let ((dataset (parse-currency-file filename)))
                       (loop :for (currency . values) :in (data-values dataset)
                             :for dates := (data-dates dataset)
                             :do
                                (loop
                                  :for i :from 0
                                  :for value :across values
                                  :when value
                                    :do (let ((row (list currency
                                                         (aref dates i)
                                                         value)))
                                          (cl-postgres:db-write-row copier row)
                                          (incf total-count))))))
              (cl-postgres:close-db-writer copier)
              (pomo:execute "commit")
              total-count)
          (condition (e)
            (format t "ERROR: ~a~%" e)
            (cl-postgres:close-db-writer copier)
            (ignore-errors (pomo:execute "rollback"))))))))

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

(define-command (("rates") (&optional directory))
    "Parse rates TSV files from DIRECTORY and load into PostgreSQL.

     Arguments (all optional):
       - DIRECTORY  directory containing TSV rate files (default: RATES_DIR)

     Environment Variables:
       RATES_DIR  default directory when DIRECTORY is not provided

     Workflow:
       1. Create raw.rates table in database
       2. Parse TSV files and COPY directly to PostgreSQL
       3. Create public.rates with daterange and exclusion constraint
       4. Create typed table using rate_t.sql

     After loading, query public.rates for currency exchange rates."
  (let* ((connspec (get-connspec *dbname*))
         (rates-dir (if directory
                        (uiop:ensure-directory-pathname directory)
                        (uiop:ensure-directory-pathname (rates-default-directory))))
         (schema-file (merge-pathnames "rates-schema.sql" rates-dir))
         (insert-file (merge-pathnames "rates-insert.sql" rates-dir))
         (typed-file (merge-pathnames "rate_t.sql" rates-dir)))
    (format t ";;; Currency Exchange Rates Loader~%")
    (format t ";;; Directory: ~a~%" rates-dir)

    (format t "~%;;; Step 1: Creating schema and raw.rates table...~%")
    (run-sql-file connspec schema-file)

    (format t "~%;;; Step 2: Parsing and loading rates...")
    (let ((count (copy-rates connspec rates-dir)))
      (format t "~%;;; Loaded ~d rate entries~%" count))

    (format t "~%;;; Step 3: Transform raw rates data to rates table...")
    (run-sql-file connspec insert-file)

    (format t "~%;;; Step 4: Creating typed rates table...")
    (run-sql-file connspec typed-file)

    (format t "~%;;; Done!~%")))
