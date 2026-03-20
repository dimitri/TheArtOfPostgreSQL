;;;
;;; F1 Database Loader
;;;
;;; Loads the Ergast F1 database from a pg_restore dump file.
;;;
;;; Usage:
;;;   taop f1db [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing f1db.dump (default: F1DB_DIR)
;;;
;;; Environment Variables:
;;;   F1DB_DIR  - Default directory containing f1db.dump
;;;
;;; Note:
;;;   The f1db.dump file is created with: pg_dump -Fc -n f1db -f f1db.dump f1db
;;;

(in-package #:taop)

(defun f1db-default-directory ()
  "Return the default directory for f1db files from F1DB_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "F1DB_DIR")
      (uiop:getcwd)))

(defun run-pg-restore (dump-file)
  "Restore PostgreSQL dump file using pg_restore."
  (let ((args (list "pg_restore"
                    "-Fc"
                    "--no-owner"
                    "--no-acl"
                    ;; use environment for connection details
                    "-d" "postgres://taop@postgres/taop"
                    (namestring dump-file))))
    (format t "~%;;; Running pg_restore: ~{~a ~}~%" args)
    (uiop:run-program args :output t :error-output t)))

(define-command (("f1db") (&optional directory))
    "Load the Ergast F1 database from f1db.dump.

     Arguments (all optional):
       - DIRECTORY  directory containing f1db.dump (default: F1DB_DIR)

     Environment Variables:
       F1DB_DIR   default directory for f1db.dump
       PGUSER     PostgreSQL username (default: taop)
       PGPASSWORD PostgreSQL password
       PGDATABASE PostgreSQL database (default: taop)
       PGHOST     PostgreSQL host (default: localhost)
       PGPORT     PostgreSQL port (default: 5432)

     The f1db.dump file is created with:
       pg_dump -Fc -n f1db -f f1db.dump f1db

     Note: Requires the f1db database to exist in the PostgreSQL instance."
  (let* ((f1db-dir (if directory
                       (uiop:ensure-directory-pathname directory)
                       (uiop:ensure-directory-pathname (f1db-default-directory))))
         (dump-file (merge-pathnames "f1db.dump" f1db-dir)))
    (format t ";;; F1 Database Loader~%")
    (format t ";;; Directory: ~a~%" f1db-dir)
    (format t ";;; Dump file: ~a~%" dump-file)

    (format t "~%;;; Restoring F1 database...~%")
    (run-pg-restore dump-file)

    (format t "~%;;; Done!~%")))
