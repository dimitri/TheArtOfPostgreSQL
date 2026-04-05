;;;
;;; Counter Dataset Loader
;;;
;;; Loads the counter schema into PostgreSQL using psql.
;;;
;;; Usage:
;;;   taop counter [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing counter SQL files (default: COUNTER_DIR)
;;;
;;; Environment Variables:
;;;   COUNTER_DIR  - Default directory containing counter data and SQL files
;;;

(in-package #:taop)

(defun counter-default-directory ()
  "Return the default directory for counter files from COUNTER_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "COUNTER_DIR")
      (uiop:getcwd)))

(define-command (("counter") ())
    "Load the counter schema into PostgreSQL.

     Environment Variables:
       COUNTER_DIR  directory containing counter SQL files (default: .)

     Loads the counter schema using schema.sql.

     After loading, the counter.measures table is available for querying."
  (let* ((counter-dir (uiop:ensure-directory-pathname (counter-default-directory)))
         (schema-file (merge-pathnames "schema.sql" counter-dir))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring schema-file)))
         (cwd (uiop:getcwd)))
    (format t ";;; Counter Dataset Loader~%")
    (format t ";;; Directory: ~a~%" counter-dir)
    (format t ";;; Schema file: ~a~%" schema-file)

    (format t "~%;;; Loading counter data...~%")
    (uiop:chdir counter-dir)
    (unwind-protect
         (uiop:run-program args :output t :error-output :output)
      (uiop:chdir cwd))

    (format t "~%;;; Done!~%")))
