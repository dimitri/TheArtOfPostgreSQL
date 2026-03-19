(defpackage #:shakes
  (:use #:cl #:taop)
  (:import-from #:cxml-xmls
                #:make-xmls-builder
                #:node-name
                #:node-ns
                #:node-attrs
                #:node-children)
  (:import-from #:cl-postgres
                #:open-db-writer
                #:close-db-writer
                #:db-write-row)
  (:export #:*connspec*
           #:parse-document))

(in-package #:shakes)

(defparameter *connspec* '("taop" "dim" nil "localhost"))

(defstruct tweet speaker text lines)

(defun parse-document (filename)
  (let* ((document (cxml:parse-file filename (make-xmls-builder)))
         (tweets
          (remove-if #'null
                     (loop :for node :in (node-children document)
                        :when (and (listp node)
                                   (string= "ACT" (node-name node)))
                        :append (parse-act node)))))
    (format t "~&Tweeted ~d messages in ~s~%" (length tweets) "tweet.message")))

(defun parse-act (act)
  (loop :for node :in (node-children act)
     :when (and (listp node)
                (string= "SCENE" (node-name node)))
     :append (parse-scene node)))

(defun parse-scene (scene)
  (format t ".")                        ; el-cheap'o progress bar
  (force-output)
  (loop :for node :in (node-children scene)
     :when (and (listp node)
                (string= "SPEECH" (node-name node)))
     :collect (parse-speech node)))

(defun parse-speech (speech)
  (let ((tw (make-tweet)))
    (loop :for node :in (node-children speech)
       :do (when (listp node)
             (let ((type (intern (node-name node) "KEYWORD")))
               (case type
                 (:stagedir nil)
                 (:speaker  (setf (tweet-speaker tw)
                                  (normalize-speaker-name
                                   (first (node-children node)))))
                 (:line     (loop :for l :in (parse-line node)
                               :do (push l (tweet-lines tw))))))))
    (setf (tweet-text tw)
          (reverse-list-of-string-to-string (tweet-lines tw)))
    (when (tweet-speaker tw)
      (tweet tw)
      tw)))

(defun parse-line (line)
  (loop :for c :in (node-children line)
     :unless (listp c)
     :collect c))


;;;
;;; Inser the message into our tweet table. It's not very wise to reconnect
;;; at each message, but it might provide *some* delay in between
;;; character's lines…
;;;
(defun tweet (tw &optional (connspec *connspec*))
  "Tweet by inserting the content into our tweet.message table."
  (multiple-value-bind (res affected)
      (pomo:with-connection connspec
        (pomo:query "
insert into tweet.message(userid, message)
     select userid, $2
       from tweet.users
      where users.uname = $1 or users.nickname = $1"
                    (tweet-speaker tw)
                    (tweet-text tw)))
    (declare (ignore res))
    (unless (= 1 affected)
      (error "Failed to tweet ~s" tw))))


;;;
;;; Normalize speaker names to tweet user names.
;;;
;;; Return NIL in some cases where we don't handle the speakers, such as ALL
;;; or Fairy.
;;;
(defun normalize-speaker-name (name)
  (string-capitalize
   (cond ((string= name "HERNIA") "HERMIA")
         (t name))))
