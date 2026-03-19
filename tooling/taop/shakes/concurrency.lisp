(defpackage #:concurrency
  (:use #:cl #:taop)
  (:import-from #:lparallel
                #:*kernel*
                #:make-kernel #:make-channel
                #:submit-task #:receive-result
                #:kernel-worker-index)
  (:import-from #:cl-postgres-error
                #:database-error)
  (:export      #:*connspec*
                #:concurrency-test))

(in-package #:concurrency)

(defparameter *connspec* '("taop" "dim" nil "localhost"))

(defparameter *insert-rt*
  "insert into tweet.activity(messageid, action) values($1, 'rt')")

(defparameter *update-rt*
  "update tweet.message set rts = coalesce(rts, 0) + 1 where messageid = $1")

(defun concurrency-test (workers retweets messageid
                         &optional (connspec *connspec*))
  (format t "Starting benchmark for updates~%")
  (with-timing (rts seconds)
      (run-workers workers retweets messageid *update-rt* connspec)
    (format t "Updating took ~f seconds, did ~d rts~%" seconds rts))

  (format t "~%")

  (format t "Starting benchmark for inserts~%")
  (with-timing (rts seconds)
      (run-workers workers retweets messageid *insert-rt* connspec)
    (format t "Inserting took ~f seconds, did ~d rts~%" seconds rts)))

(defun run-workers (workers retweets messageid sql
                    &optional (connspec *connspec*))
  (let* ((*kernel* (lparallel:make-kernel workers))
         (channel  (lparallel:make-channel)))
    (loop repeat workers
       do (lparallel:submit-task channel #'retweet-many-times
                                 retweets messageid sql connspec))

    (loop repeat workers sum (lparallel:receive-result channel))))

(defun retweet-many-times (times messageid sql
                           &optional (connspec *connspec*))
  (pomo:with-connection connspec
    (pomo:query
     (format nil "set application_name to 'worker ~a'"
             (lparallel:kernel-worker-index)))
    (loop repeat times sum (retweet messageid sql))))

(defun retweet (messageid sql)
  (handler-case
      (progn
        (pomo:query sql messageid)
        1)
    (database-error (c)
      (format t "Error: ~a~%" c)
      0)))
