;;;
;;; Open Data Loader
;;;
;;; Loads open data files into PostgreSQL using external psql command.
;;;
;;; Usage:
;;;   taop opendata [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing opendata SQL files (default: OPENDATA_DIR)
;;;
;;; Environment Variables:
;;;   OPENDATA_DIR  - Default directory containing opendata data and SQL files
;;;

(in-package #:taop)

(defun opendata-default-directory ()
  "Return the default directory for opendata files from OPENDATA_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "OPENDATA_DIR")
      (uiop:getcwd)))

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

(define-command (("opendata") ())
    "Load open data files into PostgreSQL.

     Loads the following datasets:
       - hello.sql        - Hello world translations
       - archives-de-la-planete.sql  - Archives of the planet photo collection
       - factbook.sql     - CIA World Factbook data

     Environment Variables:
       OPENDATA_DIR  directory containing opendata data and SQL files (default: .)

     Uses external psql command to support \\copy meta-commands.

     After loading, query the hello, opendata.archives_planete, and factbook tables."
  (let* ((opendata-dir (uiop:ensure-directory-pathname (opendata-default-directory)))
         (hello-file (merge-pathnames "hello.sql" opendata-dir))
         (archives-file (merge-pathnames "archives-de-la-planete.sql" opendata-dir))
         (factbook-file (merge-pathnames "factbook.sql" opendata-dir)))
    (format t ";;; Open Data Loader~%")
    (format t ";;; Directory: ~a~%" opendata-dir)

    (format t "~%;;; Step 1: Loading hello data...~%")
    (run-psql-file hello-file)

    (format t "~%;;; Step 2: Loading Archives de la Planete data...~%")
    (run-psql-file archives-file)

    (format t "~%;;; Step 3: Loading CIA World Factbook data...~%")
    (run-psql-file factbook-file)

    (format t "~%;;; Done!~%")))
