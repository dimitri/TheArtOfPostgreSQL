;;;
;;; Load All Data Command
;;;
;;; Runs all data loading subcommands in sequence using *commands*.
;;;

(in-package #:taop)

(define-command (("load-data") ())
                "Load all datasets into PostgreSQL.
Note: Commands are run with default values using environment variables."
  (format t ";;; Loading all datasets~%~%")
  (let ((step 0))
    (loop :for command :across *commands*
          :for cname := (first (command-verbs command))
          :unless (member cname '("load-data" "retweet") :test #'string=)
            :do
               (progn
                 (incf step)
                 (format t ";;; Step ~d: Running ~a...~%~%" step cname)
                 (handler-case
                     ;;
                     ;; Rely on default values for arguments, that is,
                     ;; environment variables.
                     ;;
                     (apply (command-lambda command) nil)
                   (condition (c)
                     (format t ";;; WARNING: ~{~a~^ ~} failed: ~a~%" cname c))))))
  (format t "~%;;; All datasets loaded successfully!~%"))
