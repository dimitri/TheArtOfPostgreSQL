;;;
;;; Sandbox Dataset Loader
;;;
;;; Loads the sandbox test data into PostgreSQL.
;;;
;;; Usage:
;;;   taop sandbox [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing sandbox SQL files (default: SANDBOX_DIR)
;;;
;;; Environment Variables:
;;;   SANDBOX_DIR  - Default directory containing sandbox data and SQL files
;;;

(in-package #:taop)

(defun sandbox-default-directory ()
  "Return the default directory for sandbox files from SANDBOX_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "SANDBOX_DIR")
      (uiop:getcwd)))

(define-command (("sandbox") ())
    "Load the sandbox test data into PostgreSQL.

     Environment Variables:
       SANDBOX_DIR  directory containing sandbox data and SQL files (default: .)

     Loads the sandbox schema with test data and utilities.

     Uses external psql command to support \\ir meta-commands.

     After loading, the sandbox tables are available for testing and experiments."
  (let* ((sandbox-dir (uiop:ensure-directory-pathname (sandbox-default-directory)))
         (sandbox-file (merge-pathnames "sandbox.sql" sandbox-dir))
         (args (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring sandbox-file)))
         (cwd (uiop:getcwd)))
    (format t ";;; Sandbox Loader~%")
    (format t ";;; Directory: ~a~%" sandbox-dir)
    (format t ";;; File: ~a~%" sandbox-file)

    (format t "~%;;; Loading sandbox data...~%")
    (uiop:chdir sandbox-dir)
    (unwind-protect
         (uiop:run-program args :output t :error-output :output)
      (uiop:chdir cwd))

    (format t "~%;;; Done!~%")))
