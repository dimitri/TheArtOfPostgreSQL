;;;
;;; Build a main function entry point for end users.
;;;

(in-package #:taop)

(defparameter *dbname* "taop")

(defparameter *top-dir* (asdf:system-relative-pathname :taop "./"))

(defparameter *version-string* "0.1")

(defvar *options*
  (list (make-option :help    "-h" "--help")
        (make-option :version "-V" "--version")))

(defun main ()
  (let ((argv (uiop:raw-command-line-arguments)))
    (multiple-value-bind (args opts)
        (process-argv-options argv)

      (when (member :help opts)
        (usage args :help t)
        (uiop:quit 0))

      (when (member :version opts)
        (format t "taop version ~s~%" *version-string*)
        (format t "compiled with ~a ~a~%"
                (lisp-implementation-type)
                (lisp-implementation-version))
        (uiop:quit 0))

      (unless args
        (usage args :help t)
        (uiop:quit 0))

      ;; don't do anything when --help or --version were given
      (let ((match (find-command-function args)))
        (if match
            (destructuring-bind (command fun args) match
              (handler-case
                  (handler-bind ((warning
                                   #'(lambda (c)
                                       (format t "WARNING: ~a~%" c)
                                       (muffle-warning))))
                    (apply fun args))
                (cli-error (e)
                  (format t "ERROR running command: ~{a~~^ ~}%"
                          (command-verbs command))
                  (format t
                          "ERROR: ~a~%~@[DETAIL: ~a~%~]~@[HINT: ~a~%~]"
                          (cli-error-message e)
                          (cli-error-detail e)
                          (cli-error-hint e)))
                (condition (c)
                  (if (member :debug opts)
                      (invoke-debugger c)
                      (format t "ERROR: ~a~%" c)))))
            (usage argv))))))


(define-condition cli-error ()
  ((mesg   :initarg :mesg   :initform nil :reader cli-error-message)
   (detail :initarg :detail :initform nil :reader cli-error-detail)
   (hint   :initarg :hint   :initform nil :reader cli-error-hint)))


