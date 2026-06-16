;;;
;;; HydroRIVERS Dataset Loader
;;;
;;; Loads the HydroSHEDS HydroRIVERS river network, fetched from OVH Cloud and
;;; clipped to France at image build time (see docker/taop.Dockerfile, the
;;; hydrorivers-build stage). Each reach carries its downstream neighbour in
;;; NEXT_DOWN, which makes the table a tree — the dataset behind the book's
;;; WITH RECURSIVE example. Schema: hydrorivers.rivers(hyriv_id, next_down,
;;; main_riv, ord_stra, dis_av_cms, length_km, geom).
;;;
;;; Usage:
;;;   taop hydrorivers [directory]
;;;
;;; Environment Variables:
;;;   HYDRORIVERS_DIR - directory containing the generated SQL dump
;;;   (the data is fetched at build time from HYDRORIVERS_URL — see .env.example)
;;;

(in-package #:taop)

(defun hydrorivers-default-directory ()
  "Return the default directory for HydroRIVERS files from HYDRORIVERS_DIR,
   or the current directory if not set."
  (or (uiop:getenv "HYDRORIVERS_DIR")
      (uiop:getcwd)))

(define-command (("hydrorivers") (&optional directory))
    "Load the HydroRIVERS French river network (with NEXT_DOWN topology).

     Requires the PostGIS extension (created here if missing). Creates the
     hydrorivers schema and the rivers table. The data is fetched from OVH Cloud
     and clipped to France at image build time; if HYDRORIVERS_URL was unset
     during the build, the dump is an empty placeholder and nothing is loaded.

     Arguments (optional):
       - DIRECTORY  directory containing hydrorivers.sql (default: HYDRORIVERS_DIR)

     Environment Variables:
       HYDRORIVERS_DIR  default directory for the HydroRIVERS SQL dump"
  (let* ((dir (uiop:ensure-directory-pathname
                (or directory (hydrorivers-default-directory))))
         (sql (merge-pathnames "hydrorivers.sql" dir)))
    (format t ";;; HydroRIVERS Dataset Loader~%")
    (format t ";;; Directory: ~a~%" dir)

    ;; PostGIS must exist before loading: the dump calls AddGeometryColumn().
    (format t "~%;;; Ensuring the PostGIS extension is available...~%")
    (uiop:run-program '("psql" "-v" "ON_ERROR_STOP=1"
                        "-c" "create extension if not exists postgis")
                      :output t :error-output t)

    (format t "~%;;; Loading hydrorivers.sql...~%")
    (uiop:run-program (list "psql" "-v" "ON_ERROR_STOP=1"
                            "-f" (namestring sql))
                      :directory dir :output t :error-output t)

    (format t "~%;;; Done!~%")))
