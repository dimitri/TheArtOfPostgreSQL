;;;
;;; MoMA Dataset Loader
;;;
;;; Loads the Museum of Modern Art artist data into PostgreSQL.
;;;
;;; Usage:
;;;   taop moma [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing moma SQL files (default: MOMA_DIR)
;;;
;;; Environment Variables:
;;;   MOMA_DIR  - Default directory containing moma data and SQL files
;;;

(in-package #:taop)

(defun moma-default-directory ()
  "Return the default directory for moma files from MOMA_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "MOMA_DIR")
      (uiop:getcwd)))

(define-command (("moma") ())
    "Load the MoMA artist data into PostgreSQL.

     Environment Variables:
       MOMA_DIR  directory containing moma data and SQL files (default: .)

     Loads the moma schema and artist data using artists.sql.

     After loading, the moma.artist table is available for querying."
  (let* ((moma-dir (uiop:ensure-directory-pathname (moma-default-directory)))
         (schema-file (merge-pathnames "artists.sql" moma-dir))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring schema-file)))
         (cwd (uiop:getcwd)))
    (format t ";;; MoMA Dataset Loader~%")
    (format t ";;; Directory: ~a~%" moma-dir)
    (format t ";;; Schema file: ~a~%" schema-file)

    (format t "~%;;; Loading MoMA data...~%")
    (uiop:chdir moma-dir)
    (unwind-protect
         (uiop:run-program args :output t :error-output :output)
      (uiop:chdir cwd))

    (format t "~%;;; Done!~%")))
