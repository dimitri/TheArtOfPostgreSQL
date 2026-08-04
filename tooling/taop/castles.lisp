;;;
;;; Castle Ruins Dataset Loader
;;;
;;; Loads European medieval castle locations sourced from OpenStreetMap.
;;; The CSV (id, name, lon, lat) is produced from the Overpass API at
;;; image build time.  Creates castle_ruins with a SP-GiST index on the
;;; pos (point) column — used to illustrate kNN and quadtree behaviour in
;;; The Art of PostgreSQL, chapter 2 (SP-GiST index access method).
;;;
;;; Usage:
;;;   taop castles [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing castles.csv and castles.sql
;;;                 (default: CASTLES_DIR)
;;;
;;; Environment Variables:
;;;   CASTLES_DIR - Default directory containing castles.csv and castles.sql
;;;

(in-package #:taop)

(define-command (("castles") (&optional directory))
    "Load European medieval castle ruins with SP-GiST index.

     Creates the castle_ruins table from a CSV of OSM castle locations
     (fetched from the Overpass API at image build time), then indexes
     the pos (point) column with SP-GiST for kNN and containment queries.

     Arguments (optional):
       - DIRECTORY  directory holding castles.csv + castles.sql (default: CASTLES_DIR)

     Environment Variables:
       CASTLES_DIR  default directory for data files"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory
                    (uiop:getenv "CASTLES_DIR")
                    (uiop:getcwd))))
         (sql (merge-pathnames "castles.sql" dir)))
    (format t ";;; Castle Ruins Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)
    (format t "~%;;; Creating castle_ruins table and loading CSV...~%")
    (run-psql-file dir sql)
    (format t "~%;;; Done!~%")))
