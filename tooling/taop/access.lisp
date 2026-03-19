;;;
;;; Scan34 Access Log Parser and Loader
;;;
;;; Parses scan34 access.log files and loads them into PostgreSQL.
;;;
;;; Usage:
;;;   taop scan34 [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing access.log files (default: SCAN34_DIR)
;;;
;;; Environment Variables:
;;;   SCAN34_DIR  - Default directory containing scan34 access.log files
;;;
;;; Workflow:
;;;   1. Create the access_log schema
;;;   2. Parse access.log files and COPY directly to PostgreSQL
;;;   3. Commit transaction
;;;

(in-package #:taop)

(defun run-sql-file (connspec filepath)
  "Execute SQL from FILENAME using a PostgreSQL connection."
  (format t "~%;;; Running SQL file: ~a~%" filepath)
  (pomo:with-connection connspec
    (pomo:execute-file filepath)))

(defun parse-access-log-date (date-string)
  "Parse date strings such as 17/Mar/2005:08:26:36 -0500"
  (let* ((items (cl-ppcre:split "[/: ]" date-string))
         (d     (first items))
         (m     (cdr (assoc (second items) *months* :test #'string=)))
         (y     (third items))
         (h     (fourth items))
         (mi    (fifth items))
         (ss    (sixth items))
         (tz    (seventh items)))
    (assert (not (null m)))
    (format nil "~a-~a-~a ~a:~a:~a ~a" y m d h mi ss tz)))

(defun parse-access-file (filename)
  (with-open-file (s filename
                     :direction :input
                     :element-type 'character
                     :external-format :utf-8)
    (loop :for line := (read-line s nil nil)
       :while line
       :collect (cl-ppcre:register-groups-bind (ip timestamp request status)
                    ("^([^ ]+) - - [[]([^]]+)[]] \"([^\"]+)\" ([0-9]{3})" line)
                  (list ip (parse-access-log-date timestamp) request status)))))

(defun access-default-directory ()
  "Return the default directory for scan34 files from SCAN34_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "SCAN34_DIR")
      (uiop:getcwd)))

(defun copy-access-logs (connspec directory)
  "Parse access.log files from DIRECTORY and COPY them to PostgreSQL.
   Returns the total number of entries loaded."
  (let ((table-name "access_log")
        (colnames '("ip" "ts" "request" "status"))
        (total-count 0))
    (pomo:with-connection connspec
      (pomo:execute "begin")
      (let ((copier
              (cl-postgres:open-db-writer pomo:*database* table-name colnames)))
        ;; use the PostgreSQL COPY protocol to load the parsed data as we go
        (handler-case
            (progn
              (loop :for filename :in (uiop:directory-files directory)
                    :when (string= "access_log" (pathname-name filename))
                      :do (progn
                            (format t "Parsing ~s..." filename)
                            (let ((entries (parse-access-file filename)))
                              (loop :for entry :in entries :do
                                (cl-postgres:db-write-row copier entry)
                                (incf total-count))
                              (format t "  ~d entries~%" (length entries)))))
              (format t "Closing writer~%")
              (cl-postgres:close-db-writer copier)
              (format t "COMMIT ~d~%" total-count)
              (pomo:execute "commit")
              (format t "Returns ~d~%" total-count)
              total-count)
          (condition (e)
            ;; in case of errors, close the copier and ROLLBACK
            (format t "ERROR: ~a~%" e)
            (cl-postgres:close-db-writer copier)
            (ignore-errors (pomo:execute "rollback"))))))))

(define-command (("scan34") (&optional directory))
    "Parse scan34 access.log files from DIRECTORY and load into PostgreSQL.

     Arguments (all optional):
       - DIRECTORY  directory containing scan34 access.log files (default: SCAN34_DIR)

     Environment Variables:
       SCAN34_DIR  default directory for data files

     Workflow:
       1. Create access_log schema in database
       2. Parse access.log files and COPY directly to PostgreSQL
       3. Commit transaction

     After running, query the access_log table in PostgreSQL."
  (let* ((connspec (get-connspec *dbname*))
         (scan-dir (if directory
                      (uiop:ensure-directory-pathname directory)
                      (uiop:ensure-directory-pathname (access-default-directory))))
         (schema-file (merge-pathnames "access.sql" scan-dir)))
    (format t ";;; Scan34 Access Log Loader~%")
    (format t ";;; Directory: ~a~%" scan-dir)

    (format t "~%;;; Step 1: Creating schema...")
    (run-sql-file connspec schema-file)

    (format t "~%;;; Step 2: Parsing and loading access.log files...")
    (let ((count (copy-access-logs connspec scan-dir)))
      (format t "~%;;; Loaded ~d total entries~%" count))

    (format t "~%;;; Done!~%")))
