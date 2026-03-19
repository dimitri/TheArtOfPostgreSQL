(in-package #:taop)

(defun access-to-csv (output directory)
  (format t "Loading access.log files from ~s~%"
          (uiop:native-namestring directory))
  (let ((data
         (loop :for filename :in (uiop:directory-files directory)
            :append (when (string= "access_log" (pathname-name filename))
                      (format t "Parsing ~s~%" filename)
                      (parse-access-file filename)))))
    (with-open-file (o output
                       :direction :output
                       :element-type 'character
                       :external-format :utf-8
                       :if-does-not-exist :create
                       :if-exists :supersede)
      (loop :for entry :in data
         :do (format o "~{~s~^;~}~%" entry)))

    (format t "Wrote ~d access log entries to ~s~%" (length data) output)))

(defun parse-access-file (filename)
  (with-open-file (s filename
                     :direction :input
                     :element-type 'character
                     :external-format :utf-8)
    (loop :for line := (read-line s nil nil)
       :while line
       :collect (cl-ppcre:register-groups-bind (ip timestamp request status)
                    ("^([^ ]+) - - [[]([^]]+)[]] \"([^\"]+)\" ([0-9]{3})" line)
                  (list ip (parse-access-log-date timestamp) request status)))))

(defun parse-access-log-date (date-string)
  "Parse date strings such as 17/Mar/2005:08:26:36 -0500"
  (let* ((items (cl-ppcre:split "[/: ]" date-string))
         (d     (first items))
         (m     (cdr (assoc (second items) *months* :test #'string=)))
         (y     (third items))
         (h     (fourth items))
         (mi    (fifth items))
         (ss    (sixth items))
         (tz    (seventh items)))
    (assert (not (null m)))
    (format nil "~a-~a-~a ~a:~a:~a ~a" y m d h mi ss tz)))


