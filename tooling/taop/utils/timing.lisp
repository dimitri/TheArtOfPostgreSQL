(in-package #:taop)

;;;
;;; Timing utilities
;;;
(defun elapsed-time-since (start &optional (end (get-internal-real-time)))
  "Return how many seconds ticked between START and now"
  (let ((end (or end (get-internal-real-time))))
    (coerce (/ (- end start) internal-time-units-per-second) 'double-float)))

(defmacro with-timing ((var-result var-seconds) form &body body)
  "return both how much real time was spend in body and its result"
  (let ((start (gensym))
	(end (gensym))
	(result (gensym)))
    `(let* ((,start (get-internal-real-time))
	    (,result ,form)
	    (,end (get-internal-real-time)))
       (multiple-value-bind (,var-result ,var-seconds)
           (values ,result (elapsed-time-since ,start ,end))
         ,@body))))
