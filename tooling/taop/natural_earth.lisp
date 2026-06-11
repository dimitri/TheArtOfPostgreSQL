;;;
;;; Natural Earth 50m Countries Dataset Loader
;;;
;;; Loads Natural Earth 50m country polygons into natural_earth.ne_countries
;;; using PostGIS GEOMETRY(MULTIPOLYGON, 4326).  Requires PostGIS to be
;;; installed in the postgres Docker image (postgres.Dockerfile).
;;;
;;; Usage:
;;;   taop natural-earth [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing natural earth SQL files
;;;                 (default: NATURAL_EARTH_DIR)
;;;
;;; Environment Variables:
;;;   NATURAL_EARTH_DIR - Default directory containing natural earth SQL files
;;;

(in-package #:taop)

(defun natural-earth-default-directory ()
  "Return the default directory for natural earth files from NATURAL_EARTH_DIR
   env variable, or the bundled data/natural_earth/ directory if running inside
   the taop container."
  (or (uiop:getenv "NATURAL_EARTH_DIR")
      (uiop:getcwd)))

(define-command (("natural-earth") (&optional directory))
    "Load Natural Earth 50m country polygons into natural_earth.ne_countries.

     Requires PostGIS extension (installed in postgres.Dockerfile).
     Creates schema natural_earth, table ne_countries with a GiST spatial
     index, and inserts 242 country MultiPolygon features (~2.2 MB).

     Arguments (optional):
       - DIRECTORY  directory containing natural earth SQL files
                    (default: NATURAL_EARTH_DIR)

     Environment Variables:
       NATURAL_EARTH_DIR  default directory for natural earth data files

     Workflow:
       0. CREATE EXTENSION postgis (if not exists), CREATE SCHEMA + TABLE + INDEX
       1. INSERT 242 country rows using ST_GeomFromGeoJSON"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (natural-earth-default-directory))))
         (scripts '("ne_50m_countries_schema.sql"  ; extension, schema, table, index
                    "ne_50m_countries.sql")))       ; 242 INSERT rows
    (format t ";;; Natural Earth 50m Countries Loader~%")
    (format t ";;; Directory: ~a~%" dir)

    (dolist (script scripts)
      (format t "~%;;; Loading ~a...~%" script)
      (run-psql-file-in-dir dir (merge-pathnames script dir)))

    (format t "~%;;; Done!~%")))
