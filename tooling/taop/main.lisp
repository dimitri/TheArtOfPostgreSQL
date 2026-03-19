;;;
;;; Build a main function entry point for end users.
;;;

(in-package #:taop)

(defparameter *dbname* "taop")

(defparameter *top-dir* (asdf:system-relative-pathname :taop "./"))

(defparameter *version-string* "0.1")

(defvar *options*
  (list (make-option :help    "-h" "--help")
        (make-option :version "-V" "--version")))

(defun main ()
  (let ((argv (uiop:raw-command-line-arguments)))
    (multiple-value-bind (args opts)
        (process-argv-options argv)

      (when (member :help opts)
        (usage args :help t)
        (uiop:quit 0))

      (when (member :version opts)
        (format t "taop version ~s~%" *version-string*)
        (format t "compiled with ~a ~a~%"
                (lisp-implementation-type)
                (lisp-implementation-version))
        (uiop:quit 0))

      (unless args
        (usage args :help t)
        (uiop:quit 0))

      ;; don't do anything when --help or --version were given
      (let ((match (find-command-function args)))
        (if match
            (destructuring-bind (fun args) match
              (handler-case
                  (handler-bind ((warning
                                   #'(lambda (c)
                                       (format t "WARNING: ~a~%" c)
                                       (muffle-warning))))
                    (apply fun args))
                (cli-error (e)
                  (format t
                          "ERROR: ~a~%~@[DETAIL: ~a~%~]~@[HINT: ~a~%~]"
                          (cli-error-message e)
                          (cli-error-detail e)
                          (cli-error-hint e)))
                (condition (c)
                  (if (member :debug opts)
                      (invoke-debugger c)
                      (format t "ERROR: ~a~%" c)))))
            (usage argv))))))


;;;
;;; Commands
;;;
(define-command (("scan34") (csv directory))
    "parse scan34 access.log file, outputs a CSV file."
  (let ((directory (uiop:ensure-directory-pathname directory)))
    (access-to-csv csv directory)))

(define-command (("tweet") (play))
    "Parse the XML file PLAY and tweet its lines."
  (let* ((shakes:*connspec* (get-connspec *dbname*)))
    (handler-case
        (shakes:parse-document play)
      (condition (c)
        (error 'cli-error
               :mesg (format nil "Failed to tweet Shakespeare play ~s" play)
               :detail (format nil "~a" c)
               :hint "Tweet users should be created first.")))))

(define-command (("retweet") (messageid workers times))
    "retweet MessageID given TIMES in concurrent WORKERS threads."
  (let ((concurrency:*connspec* (get-connspec *dbname*))
        (messageid (parse-integer messageid))
        (workers   (parse-integer workers))
        (times     (parse-integer times)))
    (handler-case
        (concurrency:concurrency-test workers times messageid)
      (condition (c)
        (error 'cli-error
               :mesg "Failed to test tweeting concurrently"
               :detail (format nil "~a" c)
               :hint "The tweet schema should be created first.")))))

(define-command (("rates") (csv directory))
    "parse rates TSV files in DIRECTORY, outputs a CSV file."
  (let ((directory (uiop:ensure-directory-pathname directory)))
    (load-currency-files csv directory)))

(define-command (("gitlog") (csv project-directory))
    "parse a git project's log and output a csv file."
  (let* ((project-directory (uiop:ensure-directory-pathname project-directory))
         (project-directory (uiop:native-namestring project-directory)))
    (multiple-value-bind (abs-rel directories last flag)
        (uiop:split-unix-namestring-directory-components project-directory)
      (declare (ignore abs-rel last flag))
      (let ((project-name (first (reverse directories))))
        (git-logs-to-csv csv project-name project-directory)))))

(define-command (("lastfm") (zipfilename))
    "load the lastfm subset zip of JSON files."
  (let ((lastfm::*db* (get-connspec *dbname*)))
    (lastfm::process-zipfile zipfilename)))

(define-command (("pubnames") ())
    "load the pubnames from OSM export"
  (let ((pubnames::*pgconn* (get-connspec *dbname*)))
    (pubnames::import-pub-names-and-cities :drop t)))


;;;
;;; Some other things...
;;;
(define-condition cli-error ()
  ((mesg   :initarg :mesg   :initform nil :reader cli-error-message)
   (detail :initarg :detail :initform nil :reader cli-error-detail)
   (hint   :initarg :hint   :initform nil :reader cli-error-hint)))


