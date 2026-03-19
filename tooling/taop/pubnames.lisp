;;;
;;; Pubnames Data Loader
;;;
;;; Loads pubnames data from OpenStreetMap export into PostgreSQL.
;;;

(in-package #:taop)

(define-command (("pubnames") ())
    "Load pubnames data from OpenStreetMap export into the database.

     Downloads and parses OSM data to create the pubnames table with
     geographic positions and names of public houses.

     Note: Run with a healthy database connection."
  (let ((pubnames::*pgconn* (get-connspec *dbname*)))
    (pubnames::import-pub-names-and-cities :drop t)))
