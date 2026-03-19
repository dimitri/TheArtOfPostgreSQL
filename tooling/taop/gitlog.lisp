(in-package #:taop)

(defparameter *git-log-split-re* "[¦]"
  "Regex to split the log format after the fact.")

(defparameter *git-log-format* "--format=~a¦%H¦%an¦%aI¦%cn¦%cI¦%s"
  "Format argument to `git log`, with a dynamic project name.")

(defun git-logs-to-csv (csv project path)
  "Outputs the git logs found at PATH for PROJECT into the CSV file."
  (setf (uiop:getenv "LC_ALL") "en_US.UTF-8")
  (let* ((path    (uiop:ensure-directory-pathname path))
         (format  (format nil *git-log-format* project))
         (git-log (uiop:with-current-directory (path)
                    (uiop:run-program (list "git"
                                            "log"
                                            "--encoding=utf8"
                                            "--no-merges"
                                            "--branches=*"
                                            format)
                                      :element-type '(unsigned-byte 8)
                                      :output #'read-log-from-stream))))
    (format t
            "Wrote ~d git log lines in CSV format for project ~s to ~s~%"
            (write-git-log-as-csv csv git-log)
            project
            csv)))

(defun write-git-log-as-csv (output git-log)
  (with-open-file (o output
                     :direction :output
                     :element-type 'character
                     :external-format :utf-8
                     :if-does-not-exist :create
                     :if-exists :supersede)
    (with-input-from-string (s git-log)
      (loop :for line := (read-line s nil nil)
         :while line
         :count line
         :do (let ((fields (cl-ppcre:split *git-log-split-re* line)))
               (format o "~{\"~a\"~^;~}~%" (mapcar #'quote-field fields)))))))

(defun quote-field (field)
  (cl-ppcre:regex-replace-all "[\"]" field "\"\""))


(defun read-log-from-stream (stream)
  (let ((bytes (alexandria:read-stream-content-into-byte-vector stream)))
    (babel:octets-to-string bytes :errorp nil :encoding :utf-8)))
