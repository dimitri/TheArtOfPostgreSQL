;;;; appdev.asd

(asdf:defsystem #:taop
  :serial t
  :description "The Art of PostgreSQL - data tool"
  :author "Dimitri Fontaine <dim@tapoueh.org>"
  :license "The PostgreSQL Licence"
  :depends-on (#:uiop			; host system integration
               #:cl-log                 ; logging
               #:postmodern		; PostgreSQL protocol implementation
               #:cl-postgres		; low level bits for COPY streaming
               #:simple-date		; date:{decode|encode}-inderval
               #:local-time             ; generate "now" with some precision
               #:split-sequence         ; some parsing is made easy
               #:lparallel		; threads, workers, queues
               #:alexandria		; utils
               #:drakma                 ; http client, download archives
               #:command-line-arguments ; for the main function
               #:cl-ppcre              ; Perl Compatible Regular Expressions
               #:cxml                  ; parsing XML
               #:esrap                  ; parser generator
               #:zip                    ; read zip files
               #:yason                  ; parse JSON
               #:pubnames               ; parse pub names from OSM XML files
               )
  :components
  ((:module "taop"
            :components

            ((:module "utils"
              :components ((:file "package")
                           (:file "strings")
                           (:file "timing")
                           (:file "pgpass")
                           (:file "pguri")
                           (:file "cli-parser")))

             ;; scan34
             (:file "access")

             ;; shakespeare
             (:module "shakes"
              :components ((:file "shakes")
                           (:file "concurrency")
                           (:file "visits")
                           (:file "commands")))

             ;; rates
             (:file "rates")

             ;; commitlog
             (:file "gitlog")

             ;; pubnames, depends on another git project, see Makefile
             ;; git clone https://github.com/dimitri/pubnames.git
             (:file "pubnames")

             ;; magic
             (:file "magic")

             ;; f1db
             (:file "f1db")

             ;; moma
             (:file "moma")

             ;; opendata
             (:file "opendata")

             ;; eav
             (:file "eav")

             ;; sandbox
             (:file "sandbox")

             ;; counter
             (:file "counter")

             ;; lastfm (10k-track subset; full tags DB is phase 2)
             (:file "lastfm_load_json")

             ;; geonames (1% sample, 115k rows; reference data + normalization)
             (:file "geonames")

             ;; naturalearth (countries, French départements, rivers; PostGIS)
             (:file "naturalearth")

             ;; hydrorivers (French river network with NEXT_DOWN topology; PostGIS)
             (:file "hydrorivers")

             ;; osm-london (Holborn-area streets + parks from OSM; PostGIS)
             (:file "osm-london")

             ;; natural earth 50m countries (242 country polygons, PostGIS)
             (:file "natural_earth")

             ;; chinook
             (:file "chinook")

             ;; hashtag (200k USA tweets; CSV fetched at image build time)
             (:file "hashtag")

             ;; castles (European medieval castle ruins from OSM; CSV fetched at build time)
             (:file "castles")

             ;; load all datasets
             (:file "load-data")

             ;; taop main command
             (:file "main")))))

