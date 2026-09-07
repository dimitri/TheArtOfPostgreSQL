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

(defun run-psql-append (sql-file)
  "Load the 2018-2024 append file with psql.

   Separate from the dump on purpose: data/f1db/f1db.dump is the last
   Ergast release and stops at the 2017 season, and every query, plan and
   row count the book and courses captured was captured against it.
   Replacing the dump would invalidate all of that; appending the later
   seasons on top leaves 1950-2017 byte-identical. The file is idempotent
   (every insert is ON CONFLICT DO NOTHING), so re-running this command
   is safe."
  (let ((args (list "psql" "-v" "ON_ERROR_STOP=1" "-q" "-f"
                    (namestring sql-file))))
    (format t "~%;;; Appending 2018-2024 seasons: ~{~a ~}~%" args)
    (uiop:run-program args :output t :error-output t)))

(defun run-pg-restore (dump-file)
  "Restore PostgreSQL dump file using pg_restore.
   Connection details come from the standard PG* environment variables
   (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE) via pg_restore's own
   libpq handling, same as every other loader in this codebase — a previous
   version hardcoded \"-d postgres://taop@postgres/taop\", which only worked
   by coincidence in the docker-compose flow where the postgres service
   really is reachable at the hostname \"postgres\"; it broke anywhere else
   (e.g. a single all-in-one seed container talking to itself over
   PGHOST=localhost)."
  (let ((args (list "pg_restore"
                    "-Fc"
                    "--no-owner"
                    "--no-acl"
                    "--clean"
                    "--if-exists"
                    "-d" (or (uiop:getenv "PGDATABASE") "taop")
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
         (dump-file (merge-pathnames "f1db.dump" f1db-dir))
         (append-file (merge-pathnames "f1db.2018-2024.sql" f1db-dir)))
    (format t ";;; F1 Database Loader~%")
    (format t ";;; Directory: ~a~%" f1db-dir)
    (format t ";;; Dump file: ~a~%" dump-file)

    (format t "~%;;; Restoring F1 database...~%")
    (run-pg-restore dump-file)

    ;; The dump ends at 2017; the append file carries 2018-2024. Missing
    ;; is not an error -- an older checkout has the dump and not the
    ;; append, and should still load.
    (if (probe-file append-file)
        (run-psql-append append-file)
        (format t "~%;;; No f1db.2018-2024.sql beside the dump - skipping.~%"))

    (format t "~%;;; Done!~%")))
