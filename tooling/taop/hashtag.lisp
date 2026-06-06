;;;
;;; Hashtag Dataset Loader
;;;
;;; Loads the 200k USA tweets dataset (Follow the Hashtag).
;;; Creates tweet table with CSV data and hashtag table with extracted tags.
;;;
;;; Usage:
;;;   taop hashtag [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing tweets.sql and hashtag.sql
;;;                 (default: HASHTAG_DIR)
;;;
;;; Environment Variables:
;;;   HASHTAG_DIR - Default directory containing tweets.csv and *.sql files
;;;

(in-package #:taop)

(defun hashtag-default-directory ()
  "Return the default directory for hashtag files from HASHTAG_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "HASHTAG_DIR")
      (uiop:getcwd)))

(defun run-psql-file (dir filepath)
  "Execute a SQL file using psql with client-side features (e.g., \\copy).
   Requires PG* environment variables to be set (via compose)."
  (uiop:run-program (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring filepath))
                    :directory dir :output t :error-output t))

(define-command (("hashtag") (&optional directory))
    "Load the 200k USA tweets dataset (tweet + hashtag tables).

     Creates public.tweet table by copying the CSV, then creates public.hashtag
     table with extracted hashtags indexed via GIN.

     Arguments (optional):
       - DIRECTORY  directory holding tweets.csv + *.sql (default: HASHTAG_DIR)

     Environment Variables:
       HASHTAG_DIR  default directory for data files

     Workflow:
       1. Create public.tweet and \\copy the CSV (via psql)
       2. Create public.hashtag + GIN index (via psql)"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (hashtag-default-directory))))
         (tweets (merge-pathnames "tweets.sql"  dir))
         (htag   (merge-pathnames "hashtag.sql" dir)))
    (format t ";;; Hashtag Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)

    (format t "~%;;; Step 1: Creating tweet table and loading CSV...~%")
    (run-psql-file dir tweets)

    (format t "~%;;; Step 2: Creating hashtag table with extracted tags...~%")
    (run-psql-file dir htag)

    (format t "~%;;; Done!~%")))
