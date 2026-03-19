(in-package #:taop)

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
    ;; skip first line
    (read-line s)

    ;; second line is the list of dates for currencies in the file
    (let* ((line  (read-line s))
           (dates (parse-header-dates
                   (string-right-trim '(#\Return #\Newline) line)))

           ;; then we have a line per currency with values for the dates
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
                               ;; drop the thousands separator
                               (cl-ppcre:regex-replace "," value "")))
                         (rest fields))))
    (cons (first fields) (coerce values 'vector))))

