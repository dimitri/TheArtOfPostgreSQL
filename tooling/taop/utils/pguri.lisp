;;;
;;; Build a Postmortem connection spec from pieces.
;;;

(in-package #:taop)

(defun get-connspec (dbname)
  (let* ((user (or (uiop:getenv "PGUSER")
                   (uiop:getenv "USER")))

         (host (or (uiop:getenv "PGHOST")
                   "localhost"))

         (port (parse-integer (or (uiop:getenv "PGPORT")
                                  "5432")))

         (pass (or (uiop:getenv "PGPASSWORD")
                   (pgpass:match-pgpass-file host port dbname user))))

    (list dbname user pass host :port port)))
