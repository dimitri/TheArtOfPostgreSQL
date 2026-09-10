;;;
;;; dbipcity Dataset Loader
;;;
;;; Loads DB-IP City Lite IP geolocation data (GB/FR/whole-US slice,
;;; committed to git as dbipcity.csv.xz -- see data/dbipcity/README.md for
;;; provenance, license attribution, and how to regenerate it). Replaces
;;; the old MaxMind GeoLite2 "geolite" dataset.
;;;
;;; Usage:
;;;   taop dbipcity [directory]
;;;
;;; Arguments:
;;;   directory  - Directory containing dbipcity.sql and dbipcity.csv.xz
;;;                (default: DBIPCITY_DIR)
;;;
;;; Environment Variables:
;;;   DBIPCITY_DIR - Default directory containing dbipcity.sql/.csv.xz
;;;

(in-package #:taop)

(defun ensure-decompressed (xz-path csv-path)
  "Decompress XZ-PATH to CSV-PATH (xz -k keeps the .xz, -f overwrites a
   stale .csv from a previous run)."
  (format t ";;; Decompressing ~a...~%" xz-path)
  (uiop:run-program (list "xz" "--decompress" "--keep" "--force"
                          (namestring xz-path))
                    :output t :error-output t))

(define-command (("dbipcity") (&optional directory))
    "Load DB-IP City Lite geolocation data (GB, FR, whole US) with a GiST index.

     Decompresses dbipcity.csv.xz, creates the dbipcity table from it, then
     indexes the iprange (ip4r) column with GiST for kNN and containment
     queries.

     Arguments (optional):
       - DIRECTORY  directory holding dbipcity.sql + dbipcity.csv.xz (default: DBIPCITY_DIR)

     Environment Variables:
       DBIPCITY_DIR  default directory for data files"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory
                    (uiop:getenv "DBIPCITY_DIR")
                    (uiop:getcwd))))
         (sql (merge-pathnames "dbipcity.sql" dir))
         (xz  (merge-pathnames "dbipcity.csv.xz" dir))
         (csv (merge-pathnames "dbipcity.csv" dir)))
    (format t ";;; dbipcity Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)
    (ensure-decompressed xz csv)
    (format t "~%;;; Creating dbipcity table and loading CSV...~%")
    (run-psql-file dir sql)
    (format t "~%;;; Done!~%")))
