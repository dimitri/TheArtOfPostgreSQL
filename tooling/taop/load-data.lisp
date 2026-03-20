;;;
;;; Load All Data Command
;;;
;;; Runs all data loading subcommands in sequence using *commands*.
;;;

(in-package #:taop)

(defvar *commands-to-skip* '("load-data" "retweet" "gitlog" "commitlog"))

(define-command (("load-data") ())
    "Load all datasets into PostgreSQL.

     Note: Commands are run with default values using environment variables."
  (format t ";;; Loading all datasets~%~%")
  (let ((step 0))
    (loop :for command :across *commands*
          :for verbs := (command-verbs command)
          :for cname := (first verbs)
          :unless (member cname *commands-to-skip* :test #'equal)
            :do
               (progn
                 (incf step)
                 (format t ";;; Step ~d: Loading ~{~a~^ ~}~%~%" step verbs)
                 (handler-case
                     ;;
                     ;; Rely on default values for arguments, that is,
                     ;; environment variables.
                     ;;
                     (apply (command-lambda command) nil)
                   (condition (c)
                     (format t ";;; WARNING: ~a failed: ~a~%" cname c)))))))
