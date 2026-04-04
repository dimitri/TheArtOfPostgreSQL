(in-package #:taop)

;;;
;;; Timing utilities
;;;
(defun format-interval (seconds &optional (stream t))
  "Output the number of seconds in a human friendly way"
  (multiple-value-bind (years months days hours mins secs millisecs)
      (simple-date:decode-interval (simple-date:encode-interval :second seconds))
    (declare (ignore millisecs))
    (format
     stream
     "~:[~*~;~d years ~]~:[~*~;~d months ~]~:[~*~;~d days ~]~:[~*~;~dh~]~:[~*~;~dm~]~5,3fs"
     (< 0 years)  years
     (< 0 months) months
     (< 0 days)   days
     (< 0 hours)  hours
     (< 0 mins)   mins
     (+ secs (- (multiple-value-bind (r q)
		    (truncate seconds 60)
		  (declare (ignore r))
		  q)
		secs)))))

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

;;;
;;; Command Timing System
;;;
(defvar *command-timings* nil
  "List to store command timing data: (list (list name seconds success))")

(defun reset-command-timings ()
  "Reset the command timings list"
  (setf *command-timings* nil))

(defun record-command-timing (name seconds success)
  "Record timing for a command"
  (push (list name seconds success) *command-timings*))

(defmacro with-command-timing (command-name &body body)
  "Execute body and record its timing under command-name"
  (let ((start (gensym))
        (end (gensym))
        (success (gensym)))
    `(let* ((,start (get-internal-real-time))
            (,success t)
            (,end (let ((ok t))
                    (handler-case (progn ,@body)
                      (condition (c)
                        (format *error-output* ";;; ERROR: ~a~%" c)
                        (setf ok nil)))
                    (setf ,success ok)
                    (get-internal-real-time)))
            (seconds (elapsed-time-since ,start ,end)))
       (record-command-timing ,command-name seconds ,success)
       (format t "~%")
       seconds)))

(defun print-timing-summary ()
  "Print a summary table of all command timings"
  (when *command-timings*
    (let* ((timings (nreverse *command-timings*))
           (max-name-len (loop :for (name . _) :in timings
                               :maximizing (length name)))
           (col-name (max 20 max-name-len))
           (total-time (loop :for (nil seconds nil) :in timings
                             :sum seconds)))
      (format t "~%;;; SUMMARY~%")
      (format t "~&~20@a  ~9@a  ~9@a~%" "dataset" "timing" "status")
      (format t "--------------------  ---------  ---------~%")

      (loop :for (name seconds success) :in timings
            :for status := (if success "ok" "FAIL")
            :do (format t "~&~20@a  ~9@a  ~9@a~%"
                        name
                        (format-interval seconds nil)
                        status))

      (format t "--------------------  ---------~%")
      (format t "~&~20@a  ~9@a~%~%" "TOTAL" (round total-time)))))
