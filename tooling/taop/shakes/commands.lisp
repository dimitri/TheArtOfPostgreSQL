;;;
;;; Shakespeare Tweet Commands
;;;
;;; Commands for parsing Shakespeare plays and loading them into the tweet schema.
;;;
;;; Environment Variables:
;;;   SHAKESPEARE_DIR  - Directory containing Shakespeare data and SQL files
;;;   SHAKESPEARE_PLAY_XML        - Path to the play XML file (default: dream.xml)
;;;

(in-package #:taop)

(defun run-psql-file (filepath)
  "Execute SQL from FILENAME using psql command line tool.
   This function is compatible with psql meta-commands like \\ir."
  (format t "~%;;; Running SQL file: ~a~%" filepath)
  (let* ((dir (uiop:directory-exists-p (uiop:pathname-directory-pathname filepath)))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring filepath))))
    (when dir
      (let ((cwd (uiop:getcwd)))
        (uiop:chdir dir)
        (unwind-protect
             (uiop:run-program args :output t :error-output :output)
          (uiop:chdir cwd))))))

(defun tweet-default-play ()
  "Return the default play file from SHAKESPEARE_PLAY_XML env variable,
   or 'dream.xml' if not set."
  (or (uiop:getenv "SHAKESPEARE_PLAY_XML")
      "dream.xml"))

(defun tweet-default-directory ()
  "Return the default Shakespeare directory from SHAKESPEARE_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "SHAKESPEARE_DIR")
      (uiop:getcwd)))

(define-command (("tweet") (&optional play))
    "Parse PLAY XML file and tweet its lines to the database.

     Arguments:
       - PLAY  path to Shakespeare play XML file (default: SHAKESPEARE_PLAY_XML or dream.xml)

     Environment Variables:
       SHAKESPEARE_DIR  directory containing Shakespeare data and SQL files
       SHAKESPEARE_PLAY_XML         path to the play XML file (default: dream.xml)

     Workflow:
       1. Load the tweet schema using dream.sql
       2. Parse the play XML file and tweet its lines

     Note: The tweet schema is automatically created from dream.sql."
  (let* ((shakes-dir (uiop:ensure-directory-pathname (tweet-default-directory)))
         (play-file (or play (tweet-default-play)))
         (play-path (if (uiop:absolute-pathname-p play-file)
                       play-file
                       (merge-pathnames play-file shakes-dir)))
         (schema-file (merge-pathnames "dream.sql" shakes-dir))
         (shakes:*connspec* (get-connspec *dbname*)))
    (format t ";;; Shakespeare Tweet Loader~%")
    (format t ";;; Directory: ~a~%" shakes-dir)
    (format t ";;; Play: ~a~%" play-path)

    (format t "~%;;; Step 1: Loading tweet schema...")
    (run-psql-file schema-file)

    (format t "~%;;; Step 2: Parsing and loading play...")
    (handler-case
        (shakes:parse-document (namestring play-path))
      (condition (c)
        (error 'cli-error
               :mesg (format nil "Failed to tweet Shakespeare play ~s" play-path)
               :detail (format nil "~a" c)
               :hint "Check that the play XML file exists.")))

    (format t "~%;;; Done!~%")))

(define-command (("retweet") (messageid workers times))
    "Retweet MESSAGEID TIMES times using WORKERS concurrent threads.

     Requires three arguments:
       - MESSAGEID  the message ID to retweet
       - WORKERS    number of concurrent worker threads
       - TIMES      number of times to retweet

     Note: The tweet schema must be created before running this command."
  (let ((concurrency:*connspec* (get-connspec *dbname*))
        (messageid (parse-integer messageid))
        (workers   (parse-integer workers))
        (times     (parse-integer times)))
    (handler-case
        (concurrency:concurrency-test workers times messageid)
      (condition (c)
        (error 'cli-error
               :mesg "Failed to test tweeting concurrently"
               :detail (format nil "~a" c)
               :hint "The tweet schema should be created first.")))))
