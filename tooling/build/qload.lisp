;;;
;;; Load the taop command dependencies with Quicklisp
;;;
;;; This allows to better use the docker build cache.

#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(defparameter *depends-on* '(#:uiop
                             #:cl-log
                             #:postmodern
                             #:cl-postgres
                             #:local-time
                             #:split-sequence
                             #:lparallel
                             #:alexandria
                             #:drakma
                             #:command-line-arguments
                             #:cl-ppcre
                             #:cxml
                             #:esrap
                             #:zip
                             #:yason
                             #:pubnames
                             ))

(ql:quickload *depends-on*)

