;;;
;;; GeoNames Dataset Loader
;;;
;;; Loads the GeoNames 1% sample (115k rows) with reference data,
;;; normalized into the geoname.* schema.
;;;
;;; Usage:
;;;   taop geonames [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing geonames SQL files
;;;                 (default: GEONAMES_DIR)
;;;
;;; Environment Variables:
;;;   GEONAMES_DIR - Default directory containing geonames SQL files
;;;

(in-package #:taop)

(defun geonames-default-directory ()
  "Return the default directory for geonames files from GEONAMES_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "GEONAMES_DIR")
      (uiop:getcwd)))

(defun run-psql-file-in-dir (dir filepath)
  "Execute a SQL file using psql with client-side features (e.g., \\copy).
   Requires PG* environment variables to be set (via compose)."
  (uiop:run-program (list "psql" "-v" "ON_ERROR_STOP=1" "-f" (namestring filepath))
                    :directory dir :output t :error-output t))

(define-command (("geonames") (&optional directory))
    "Load the GeoNames 1% sample + reference data, normalized into geoname.*

     Creates geoname.class, geoname.feature, geoname.country, geoname.region,
     geoname.district, sample.geonames, and geoname.geoname (~115k rows) with
     GiST spatial index.

     Arguments (optional):
       - DIRECTORY  directory containing geonames SQL files (default: GEONAMES_DIR)

     Environment Variables:
       GEONAMES_DIR  default directory for geonames data files

     Workflow:
       0. Load reference data into raw.* schema (country, feature codes)
       1. Create geoname.class + geoname.feature (from raw.*)
       2. Create geoname.country + neighbor relations
       3. Create geoname.region + geoname.district
       4. Load sample.geonames from CSV, normalize to geoname.geoname, create GiST index"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (geonames-default-directory))))
         (scripts '("geonames.raw.sql"          ; raw.geonames, raw.country, raw.feature (reference tables)
                    "geonames.feature.sql"      ; geoname.class, geoname.feature (from raw.feature)
                    "geonames.country.sql"      ; geoname.country, geoname.continent, geoname.region (table), geoname.neighbour
                    "geonames.admin.sql"        ; geoname.region, geoname.district
                    "geonames.from.sample.sql"))); sample.geonames + geoname.geoname + GiST
    (format t ";;; GeoNames Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)

    (dolist (script scripts)
      (format t "~%;;; Loading ~a...~%" script)
      (run-psql-file-in-dir dir (merge-pathnames script dir)))

    (format t "~%;;; Done!~%")))
