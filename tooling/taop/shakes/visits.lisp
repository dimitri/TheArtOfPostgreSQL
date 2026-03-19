(in-package #:shakes)

(defparameter *connspec* '("taop" "dim" nil "localhost"))
(defparameter *visitor-table*   "tweet.visitor")
(defparameter *visitor-columns* '("messageid" "ipaddr" "datetime"))

;;;
;;; select '192.168.0.0'::ip4::bigint; == 3232235520
;;;
(defparameter *ip-range-start* 3232235520)
(defparameter *ip-range-size* (expt 2 16))

(defun insert-visistors (messageid n &optional (connspec *connspec*))
  (pomo:with-connection connspec
    (let ((count 0)
          (copier (open-db-writer connspec *visitor-table* *visitor-columns*)))
      (unwind-protect
           (loop :for i :below n
              :do (let ((ipaddr   (generate-ipaddress))
                        (datetime (format nil "~a" (generate-timestamp))))
                    (db-write-row copier (list messageid ipaddr datetime))
                    (incf count)))
        (close-db-writer copier))

      ;; and return the number of rows copied
      count)))

;;;
;;; Generate values to insert into our tweet.visitor tables: ip addresses
;;; within a given range, and timestamps. We want the ip address generated
;;; such that we have "collisions", because we then want to show how to
;;; count disctinct visitors per period thanks to the PostgreSQL HLL data
;;; type.
;;;
(defun generate-ipaddress (&optional
                             (range-size *ip-range-size*)
                             (range-start *ip-range-start*))
  "Generate N random IP addresses, as strings."
  (int-to-ip (+ range-start (random range-size))))

(defun generate-timestamp ()
  "Generate a random timestamp between now and a month ago."
  (local-time:timestamp- (local-time:now) (random #. (* 24 60 31)) :minute))

;;;
;;; Utility function to transform an integer into a string representation of
;;; the integer number as an IPv4 address:
;;;
;;; (shakes::int-to-ip 3232235520)
;;; "192.168.0.0"
;;;
(defun int-to-ip (int)
  "Transform an IP as integer into its dotted notation, optimised code from
   stassats."
  (declare (optimize speed)
           (type (unsigned-byte 32) int))
  (let ((table (load-time-value
                (let ((vec (make-array (+ 1 #xFFFF))))
                  (loop for i to #xFFFF
		     do (setf (aref vec i)
			      (coerce (format nil "~a.~a"
					      (ldb (byte 8 8) i)
					      (ldb (byte 8 0) i))
				      'simple-base-string)))
                  vec)
                t)))
    (declare (type (simple-array simple-base-string (*)) table))
    (concatenate 'simple-base-string
		 (aref table (ldb (byte 16 16) int))
		 "."
		 (aref table (ldb (byte 16 0) int)))))
