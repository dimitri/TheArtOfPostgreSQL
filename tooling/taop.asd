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

             ;; lastfm
             ;; The Last.fm dataset is too large (~1GB) to include in the repository.
             ;; Uncomment when you have the data available.
             ;; (:file "lastfm_load_json")

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

             ;; load all datasets
             (:file "load-data")

             ;; taop main command
             (:file "main")))))

