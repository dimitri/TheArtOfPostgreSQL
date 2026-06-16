;;;
;;; Natural Earth Dataset Loader
;;;
;;; Loads the Natural Earth 1:50m Admin-0 country polygons into the
;;; naturalearth.countries table (PostGIS MULTIPOLYGON, SRID 4326, GiST index).
;;; The SQL dump is generated from the committed shapefile at image build time
;;; (see docker/taop.Dockerfile, the naturalearth-build stage), so loading only
;;; needs psql against a PostGIS-enabled server.
;;;
;;; Usage:
;;;   taop naturalearth [directory]
;;;
;;; Arguments:
;;;   directory   - Directory containing ne_50m_admin_0_countries.sql
;;;                 (default: NATURALEARTH_DIR)
;;;
;;; Environment Variables:
;;;   NATURALEARTH_DIR - Default directory containing the Natural Earth SQL dump
;;;

(in-package #:taop)

(defun naturalearth-default-directory ()
  "Return the default directory for Natural Earth files from NATURALEARTH_DIR,
   or the current directory if not set."
  (or (uiop:getenv "NATURALEARTH_DIR")
      (uiop:getcwd)))

(define-command (("naturalearth") (&optional directory))
    "Load Natural Earth 1:50m country polygons into naturalearth.countries.

     Requires the PostGIS extension (created here if missing).  Creates the
     naturalearth schema, the countries table (MULTIPOLYGON, SRID 4326) and a
     GiST index on the geometry column.  The data is the public-domain Natural
     Earth 1:50m Admin-0 Countries layer, ~240 features.

     Arguments (optional):
       - DIRECTORY  directory containing ne_50m_admin_0_countries.sql
                    (default: NATURALEARTH_DIR)

     Environment Variables:
       NATURALEARTH_DIR  default directory for the Natural Earth SQL dump"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (naturalearth-default-directory))))
         (scripts '("ne_50m_admin_0_countries.sql"   ; world country polygons
                    "ne_10m_admin_1.sql"             ; French départements (clipped)
                    "ne_10m_rivers.sql")))           ; major rivers (clipped)
    (format t ";;; Natural Earth Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)

    ;; PostGIS must exist before loading: the dumps call AddGeometryColumn().
    (format t "~%;;; Ensuring the PostGIS extension is available...~%")
    (uiop:run-program '("psql" "-v" "ON_ERROR_STOP=1"
                        "-c" "create extension if not exists postgis")
                      :output t :error-output t)

    (dolist (script scripts)
      (format t "~%;;; Loading ~a...~%" script)
      (uiop:run-program (list "psql" "-v" "ON_ERROR_STOP=1"
                              "-f" (namestring (merge-pathnames script dir)))
                        :directory dir :output t :error-output t))

    (format t "~%;;; Done!~%")))
