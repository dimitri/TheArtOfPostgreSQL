;;;
;;; Last.fm Data Loader
;;;
;;; Loads Last.fm subset data from a ZIP file of JSON data into PostgreSQL.
;;;
;;; Usage:
;;;   taop lastfm <zipfilename>
;;;
;;; Arguments:
;;;   zipfilename  - Path to Last.fm subset ZIP file
;;;
;;; Note:
;;;   The Last.fm dataset is too large (~1GB compressed) to include in the
;;;   git repository. Download it separately from:
;;;   https://www.bicicletorama.com/work/data/lastfm_subset.zip
;;;

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

;;;
;;; Command definition
;;;
;;; Note: The Last.fm dataset is too large to include in the repository.
;;; See data/lastfm/README.md for download instructions.
;;;

(in-package #:taop)

(define-command (("lastfm") (zipfilename))
    "Load Last.fm subset ZIP file of JSON data into the database.

     Requires one argument:
       - ZIPFILENAME  path to Last.fm subset zip file

     The ZIP file should contain JSON files with track data.

     Note: The Last.fm dataset is too large (~1GB) to include in the
     repository. Download from:
     https://www.bicicletorama.com/work/data/lastfm_subset.zip"
  (let ((lastfm::*db* (get-connspec *dbname*)))
    (lastfm::process-zipfile zipfilename)))
