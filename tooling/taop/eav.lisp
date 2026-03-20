;;;
;;; EAV Dataset Loader
;;;
;;; Loads the Entity-Attribute-Value pattern examples into PostgreSQL.
;;;
;;; Usage:
;;;   taop eav [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing eav SQL files (default: EAV_DIR)
;;;
;;; Environment Variables:
;;;   EAV_DIR  - Default directory containing eav data and SQL files
;;;

(in-package #:taop)

(defun eav-default-directory ()
  "Return the default directory for eav files from EAV_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "EAV_DIR")
      (uiop:getcwd)))

(define-command (("eav") ())
    "Load the Entity-Attribute-Value pattern examples into PostgreSQL.

     Environment Variables:
       EAV_DIR  directory containing eav data and SQL files (default: .)

     Loads the eav schema with create, insert, and support scripts.

     Uses external psql command to support \\ir meta-commands.

     After loading, the eav schema tables are available for querying."
  (let* ((eav-dir (uiop:ensure-directory-pathname (eav-default-directory)))
         (eav-file (merge-pathnames "eav.sql" eav-dir))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring eav-file)))
         (cwd (uiop:getcwd)))
    (format t ";;; EAV Dataset Loader~%")
    (format t ";;; Directory: ~a~%" eav-dir)
    (format t ";;; File: ~a~%" eav-file)

    (format t "~%;;; Loading EAV data...~%")
    (uiop:chdir eav-dir)
    (unwind-protect
         (uiop:run-program args :output t :error-output :output)
      (uiop:chdir cwd))

    (format t "~%;;; Done!~%")))
