;;;
;;; Magic: The Gathering data loader command.
;;;
;;; Loads the Magic: The Gathering card data from a JSON file into PostgreSQL.
;;; The data is loaded in three steps:
;;;   1. Create the magic schema and allsets table
;;;   2. Load the JSON data from MagicAllSets.json
;;;   3. Flatten the data into sets and cards tables
;;;
;;; Environment Variables:
;;;   MAGIC_DIR  - Default directory containing Magic: The Gathering data files
;;;

(in-package #:taop)

(defun run-sql-file (connspec filepath)
  "Execute SQL from FILENAME using a PostgreSQL connection."
  (format t "~%;;; Running SQL file: ~a~%" filepath)
  (pomo:with-connection connspec
    (pomo:execute-file filepath)))

(defun run-magic-py (magic-dir)
  "Run the magic.py Python script to load JSON data."
  (let ((script (merge-pathnames "magic.py" magic-dir)))
    (format t "~%;;; Running ~a~%" script)
    (uiop:run-program (list "python3" (namestring script))
                       :output t :error-output t)))

(defun magic-default-directory ()
  "Return the default directory for Magic files from MAGIC_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "MAGIC_DIR")
      (uiop:getcwd)))

(define-command (("magic") (directory))
    "load the Magic: The Gathering card data from DIRECTORY.

     This command expects DIRECTORY to contain:
       - MagicAllSets.json  the JSON data file
       - magic.py           Python script to load the JSON
       - magic.sql          SQL script to create schema
       - magic.cards.sql    SQL script to flatten cards

      Environment Variables:
        MAGIC_DIR  default directory when DIRECTORY is not provided

     If DIRECTORY is not given, uses the MAGIC_DIR env variable or current directory."
  (let* ((magic-dir (if directory
                         (uiop:ensure-directory-pathname directory)
                         (uiop:ensure-directory-pathname (magic-default-directory))))
         (connspec (get-connspec *dbname*)))
    (format t ";;; Magic: The Gathering data loader~%")
    (format t ";;; Data directory: ~a~%" magic-dir)

    (format t "~%;;; Step 1: Creating schema and allsets table...")
    (run-sql-file connspec (merge-pathnames "magic.sql" magic-dir))

    (format t "~%;;; Step 2: Loading JSON data with magic.py...")
    (run-magic-py magic-dir)

    (format t "~%;;; Step 3: Flattening cards and sets...")
    (run-sql-file connspec (merge-pathnames "magic.cards.sql" magic-dir))

    (format t "~%;;; Done! Magic: The Gathering data loaded successfully.~%")))
