;;;
;;; Chinook Dataset Loader
;;;
;;; Loads the Chinook music store database as a 'chinook' schema
;;; inside the taop PostgreSQL database.
;;;
;;; Usage:
;;;   taop chinook [sql-file]
;;;
;;; Arguments:
;;;   sql-file  - Path to Chinook_PostgreSql.sql (default: CHINOOK_SQL env var)
;;;
;;; Environment Variables:
;;;   CHINOOK_SQL  - Full path to Chinook_PostgreSql.sql
;;;

(in-package #:taop)

(defun chinook-default-sql-file ()
  "Return the path to the Chinook SQL file from env var or container default."
  (or (uiop:getenv "CHINOOK_SQL")
      "/usr/src/taop/cdstore/Chinook_PostgreSql.sql"))

(defun write-chinook-filtered-sql (input-path output-path)
  "Write a schema-scoped version of the Chinook SQL to output-path.
   Strips DROP/CREATE DATABASE and \\c commands; prepends SET search_path."
  (with-open-file (in input-path :direction :input)
    (with-open-file (out output-path :direction :output :if-exists :supersede)
      (write-line "SET search_path TO chinook;" out)
      (loop :for line := (read-line in nil nil)
            :while line
            :unless (cl-ppcre:scan
                     "^(DROP DATABASE|CREATE DATABASE|\\\\c )"
                     line)
              :do (write-line line out)))))

(define-command (("chinook") (&optional sql-file))
    "Load the Chinook music store data as a schema in the taop database.

     Creates a 'chinook' schema inside taop and loads all Chinook tables
     and data into it.

     Environment Variables:
       CHINOOK_SQL  path to Chinook_PostgreSql.sql
                    (default: /usr/src/taop/cdstore/Chinook_PostgreSql.sql)"
  (let* ((source-file (uiop:parse-native-namestring
                       (or sql-file (chinook-default-sql-file))))
         (tmp-file (uiop:parse-native-namestring
                    (format nil "/tmp/chinook-~a.sql" (get-universal-time)))))
    (format t ";;; Chinook Dataset Loader~%")
    (format t ";;; Source: ~a~%" source-file)

    (format t "~%;;; Step 1: Creating chinook schema...~%")
    (uiop:run-program
     (list "psql" "-v" "ON_ERROR_STOP=1"
           "-c" "DROP SCHEMA IF EXISTS chinook CASCADE; CREATE SCHEMA chinook;")
     :output t :error-output :output)

    (format t "~%;;; Step 2: Filtering SQL for schema context...~%")
    (write-chinook-filtered-sql source-file tmp-file)

    (format t "~%;;; Step 3: Loading chinook data...~%")
    (unwind-protect
         (uiop:run-program
          (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring tmp-file))
          :output t :error-output :output)
      (uiop:delete-file-if-exists tmp-file))

    (format t "~%;;; Done!~%")))
