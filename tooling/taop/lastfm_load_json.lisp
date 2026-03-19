(defpackage #:lastfm
  (:use #:cl #:zip)
  (:import-from #:cl-postgres
                #:open-db-writer
                #:close-db-writer
                #:db-write-row))

(in-package #:lastfm)

(defvar *db* '("taop" "taop" nil "localhost" :port 5432))
(defvar *tablename* "lastfm.track")
(defvar *colnames*  '("tid" "artist" "title"))

(defun process-zipfile (filename)
  "Process a zipfile by sending its content down to a PostgreSQL table."

  (pomo:with-connection *db*

    (let ((count 0)
          (copier (open-db-writer pomo:*database* *tablename* *colnames*)))

      (unwind-protect
           (with-zipfile (zip filename)
             (do-zipfile-entries (name entry zip)
               (let ((pathname (uiop:parse-native-namestring name)))
                 (when (string= (pathname-type pathname) "json")
                   (let* ((bytes   (zipfile-entry-contents entry))
                          (content
                           (babel:octets-to-string bytes :encoding :utf-8)))
                     (db-write-row copier (parse-json-entry content))
                     (incf count))))))
        (close-db-writer copier))

      ;; Return how many rows we did COPY in PostgreSQL
      count)))

(defun parse-json-entry (json-data)
  (let ((json (yason:parse json-data :object-as :alist)))
    (list (cdr (assoc "track_id" json :test #'string=))
          (cdr (assoc "artist"   json :test #'string=))
          (cdr (assoc "title"    json :test #'string=)))))
