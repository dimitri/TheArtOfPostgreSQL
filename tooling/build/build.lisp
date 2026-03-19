;;;
;;; Build a executable image from the appdev.asd system
;;;

#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(defparameter *bin* (or (uiop:getenv "TAOP") "/tmp/taop"))

(ql:quickload "taop")

(setf uiop::*image-entry-point* #'taop::main)
(uiop:dump-image *bin*
                 :executable t
                 #+sbcl :compression #+sbcl t)

