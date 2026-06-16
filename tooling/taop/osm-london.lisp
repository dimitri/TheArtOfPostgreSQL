;;;
;;; London OSM Dataset Loader
;;;
;;; Loads an OpenStreetMap extract of the Holborn area of London (major streets
;;; and parks), converted from the committed holborn.osm to PostGIS-loadable SQL
;;; dumps at image build time (see docker/taop.Dockerfile, the osmlondon-build
;;; stage). Provides the street-map backdrop for the nearest-pub kNN figure.
;;; Schemas: osm_london.roads (lines, highway/name) and osm_london.parks.
;;;
;;; Usage:
;;;   taop osm-london [directory]
;;;
;;; Environment Variables:
;;;   OSM_LONDON_DIR - directory containing the generated SQL dumps
;;;

(in-package #:taop)

(defun osm-london-default-directory ()
  "Return the default directory for the London OSM dumps from OSM_LONDON_DIR,
   or the current directory if not set."
  (or (uiop:getenv "OSM_LONDON_DIR")
      (uiop:getcwd)))

(define-command (("osm-london") (&optional directory))
    "Load the Holborn-area OpenStreetMap streets and parks.

     Requires the PostGIS extension (created here if missing). Creates the
     osm_london schema with the roads and parks tables, the street-map backdrop
     for the nearest-pub kNN figure.

     Arguments (optional):
       - DIRECTORY  directory containing osm_roads.sql / osm_parks.sql
                    (default: OSM_LONDON_DIR)

     Environment Variables:
       OSM_LONDON_DIR  default directory for the London OSM SQL dumps"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (osm-london-default-directory))))
         (scripts '("osm_roads.sql" "osm_parks.sql")))
    (format t ";;; London OSM Dataset Loader~%")
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
