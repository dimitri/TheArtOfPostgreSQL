;;;
;;; Git Log Parser and Repository Fetcher
;;;
;;; Parses git log from PostgreSQL and pgloader repositories and loads to PostgreSQL.
;;;
;;; Usage:
;;;   taop gitlog import <project>       Import git log to PostgreSQL
;;;   taop gitlog fetch <project>        Fetch repository (postgres or pgloader)
;;;
;;; Environment Variables:
;;;   COMMITLOG_DIR  - Default directory for commitlog data and Makefile
;;;

(in-package #:taop)

(defparameter *git-log-split-re* "[¦]"
  "Regex to split the git log format after the fact.")

(defparameter *git-log-format* "--format=%H¦%an¦%aI¦%cn¦%cI¦%s"
  "Format argument to `git log`, with a dynamic project name.")

(defparameter *commitlog-table* "commitlog.commits"
  "Table name for commit log data.")

(defparameter *commitlog-colnames* '("project" "sha" "author" "author_date"
                                     "committer" "commit_date" "subject")
  "Column names for commit log data.")

(defun commitlog-default-directory ()
  "Return the default directory for commitlog from COMMITLOG_DIR env variable,
   or current directory if not set."
  (or (uiop:getenv "COMMITLOG_DIR")
      (uiop:getcwd)))

(defun run-make (directory target)
  "Run make TARGET in DIRECTORY."
  (let ((dir (uiop:ensure-directory-pathname directory)))
    (format t "~%;;; Running make ~a in ~a~%" target dir)
    (uiop:with-current-directory (dir)
      (uiop:run-program (list "make" target)
                         :output t
                         :error-output :output))))

(defun run-sql-file (connspec filepath)
  "Execute SQL from FILENAME using a PostgreSQL connection."
  (format t "~%;;; Running SQL file: ~a~%" filepath)
  (pomo:with-connection connspec
    (pomo:execute-file filepath)))

(defun quote-field (field)
  "Escape a field value for CSV output."
  (cl-ppcre:regex-replace-all "[\"]" field "\"\""))

(defun create-commitlog-schema (connspec commitlog-dir)
  "Create the commitlog schema and table in PostgreSQL using commitlog.sql."
  (let ((schema-file (merge-pathnames "commitlog.sql" commitlog-dir)))
    (format t "~%;;; Creating schema from ~a~%" schema-file)
    (run-sql-file connspec schema-file)))

(defun init-commitlog (connspec)
  "Initialize the commitlog schema. Creates schema, table, and indexes."
  (format t ";;; Git Log Init~%")
  (let ((commitlog-dir
          (uiop:ensure-directory-pathname (commitlog-default-directory))))
    (format t ";;; Directory: ~a~%" commitlog-dir)
    (create-commitlog-schema connspec commitlog-dir)
    (format t "~%;;; Done!~%")))

(defun copy-git-log (connspec project path)
  "Parse git log from PATH and COPY directly to PostgreSQL.
   Returns the total number of commits loaded."
  (setf (uiop:getenv "LC_ALL") "en_US.UTF-8")
  (let* ((path (uiop:ensure-directory-pathname path))
         (total-count 0))
    (pomo:execute "begin")
    (let ((copier (cl-postgres:open-db-writer pomo:*database*
                                              *commitlog-table*
                                              *commitlog-colnames*)))
      (handler-case
          (progn
            (format t "Parsing git log from ~a~%" path)
            (let* ((cmdlist (list "git" "log"
                                  "--encoding=utf8"
                                  "--no-merges"
                                  "--branches=*"
                                  *git-log-format*))
                   (git-log
                     (uiop:with-current-directory (path)
                       (format t "~{~a~^ ~}~%" cmdlist)
                       (uiop:run-program cmdlist
                                         :element-type '(unsigned-byte 8)
                                         :output :string))))
              (with-input-from-string (s git-log)
                (loop :for line := (read-line s nil nil)
                      :while line
                      :do (let ((fields (cl-ppcre:split *git-log-split-re* line)))
                            (when (= (length fields) 6)
                              ;; prepend project name to the git log output
                              ;; to comply with the multi-project schema
                              ;; definition in Postgres
                              (cl-postgres:db-write-row copier
                                                        (cons project fields))
                              (incf total-count)))))
              (format t "Loaded ~d commits~%" total-count))
            (cl-postgres:close-db-writer copier)
            (pomo:execute "commit")
            total-count)
        (condition (e)
          ;; in case of errors, close the copier and ROLLBACK
          (format t "ERROR: ~a~%" e)
          (cl-postgres:close-db-writer copier)
          (ignore-errors (pomo:execute "rollback")))))))

;;;
;;; Command definitions
;;;
(define-command (("gitlog" "init") ())
    "Initialize the commitlog schema in PostgreSQL.

     Creates the commitlog schema, commits table, and indexes.

     This should be run once before importing any git logs.

     Environment Variables:
       COMMITLOG_DIR  directory containing commitlog.sql (default: .)

     After initialization, use 'taop gitlog import <project>' to load data."
  (let ((connspec (get-connspec *dbname*)))
    (init-commitlog connspec)))

(define-command (("gitlog" "import") (project))
    "Import git log from PROJECT to PostgreSQL.

     Arguments:
       - PROJECT  which project to import: postgres or pgloader

     Environment Variables:
       COMMITLOG_DIR  directory containing project directories (default: .)

     The project directory is expected at: COMMITLOG_DIR/PROJECT

     Note: Run 'taop gitlog init' first to create the schema.

     Workflow:
       1. Parse git log and COPY directly to PostgreSQL
       2. Commit transaction

     After running, query the commitlog.commits table in PostgreSQL."
  (let* ((connspec (get-connspec *dbname*))
         (commitlog-dir (uiop:ensure-directory-pathname (commitlog-default-directory)))
         (project-dir (merge-pathnames (string-downcase project) commitlog-dir))
         (project-name (string-downcase project)))
    (format t ";;; Git Log Loader~%")
    (format t ";;; Project: ~a~%" project-name)
    (format t ";;; Directory: ~a~%" project-dir)

    (format t "~%;;; Step 1: Parsing and loading git log...")
    (pomo:with-connection connspec
      (let ((count (copy-git-log connspec project-name project-dir)))
        (format t "~%;;; Loaded ~d commits~%" count)))

    (format t "~%;;; Done!~%")))

(define-command (("gitlog" "fetch") (repository))
    "Fetch git repositories for use with gitlog.

     Arguments:
       - REPOSITORY  which repository to fetch: postgres or pgloader

     Environment Variables:
       COMMITLOG_DIR  directory containing Makefile (default: .)

     This command runs 'make postgres' or 'make pgloader' to clone the
     PostgreSQL or pgloader git repositories."
  (let* ((commitlog-dir (uiop:ensure-directory-pathname (commitlog-default-directory)))
         (target (cond
                   ((string-equal repository "postgres") "postgres")
                   ((string-equal repository "pgloader") "pgloader")
                   (t (error 'cli-error
                             :mesg (format nil "Unknown repository: ~s" repository)
                             :detail "Valid repositories are: postgres, pgloader"
                             :hint "Use 'taop gitlog fetch postgres' or 'taop gitlog fetch pgloader'")))))
    (format t ";;; Git Log Repository Fetcher~%")
    (format t ";;; Directory: ~a~%" commitlog-dir)
    (format t ";;; Target: ~a~%" target)
    (run-make commitlog-dir target)
    (format t "~%;;; Done!~%")))

(define-command (("commitlog") ())
    "Load all commitlog data: init schema, fetch and import postgres and pgloader.

     This command runs the full workflow:
       1. gitlog init      - Create commitlog schema
       3. gitlog import postgres  - Import PostgreSQL commits
       5. gitlog import pgloader  - Import pgloader commits

     Environment Variables:
       COMMITLOG_DIR  directory containing Makefile and commitlog.sql (default: .)

     After running, query the commitlog.commits table in PostgreSQL."
  (let ((connspec (get-connspec *dbname*))
        (commitlog-dir
          (uiop:ensure-directory-pathname (commitlog-default-directory))))
    (format t ";;; Commitlog Loader~%~%")

    (format t ";;; Initializing schema...~%")
    (init-commitlog connspec)

    (format t "~%;;; Importing PostgreSQL commits...~%")
    (let* ((project-dir (merge-pathnames "postgresql" commitlog-dir)))
      (pomo:with-connection connspec
        (let ((count (copy-git-log connspec "postgres" project-dir)))
          (format t ";;; Loaded ~d commits~%" count))))

    (format t "~%;;; All commitlog data loaded successfully!~%")))
