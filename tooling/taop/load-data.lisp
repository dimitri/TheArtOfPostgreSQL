;;;
;;; Load All Data Command
;;;
;;; Runs all data loading subcommands in sequence using *commands*.
;;;

(in-package #:taop)

(defvar *commands-to-skip* '("load-data" "retweet" "gitlog" "commitlog"))

;; PostGIS-dependent datasets (skip when SKIP_POSTGIS_DATASETS=true)
;; These require PostGIS extension and functions.
(defvar *postgis-datasets* '("naturalearth" "hydrorivers" "osm-london"))

(defun skip-postgis-datasets-p ()
  "Return true if SKIP_POSTGIS_DATASETS environment variable is set to 'true'."
  (string= (uiop:getenv "SKIP_POSTGIS_DATASETS") "true"))

(define-command (("load-data") ())
    "Load all datasets into PostgreSQL.

     Environment Variables:
       SKIP_POSTGIS_DATASETS - Set to 'true' to skip PostGIS-dependent datasets
                              (naturalearth, hydrorivers, osm-london).
                              Use for PostgreSQL 18+ before PostGIS releases support.

     Note: Commands are run with default values using environment variables."
  (reset-command-timings)
  (let ((skip-postgis (skip-postgis-datasets-p)))
    (when skip-postgis
      (format t ";;; Skipping PostGIS-dependent datasets~%"))
    (format t ";;; Loading all datasets~%~%")
    (let ((step 0))
      (loop :for command :across *commands*
            :for verbs := (command-verbs command)
            :for cname := (first verbs)
            :unless (or (member cname *commands-to-skip* :test #'equal)
                        (and skip-postgis
                             (member cname *postgis-datasets* :test #'equal)))
              :do
                 (progn
                   (incf step)
                   (format t ";;; Step ~d: Loading ~{~a~^ ~}~%~%" step verbs)
                   (with-command-timing cname
                     ;;
                     ;; Rely on default values for arguments, that is,
                     ;; environment variables.
                     ;;
                     (apply (command-lambda command) nil))))
      (print-timing-summary))))
