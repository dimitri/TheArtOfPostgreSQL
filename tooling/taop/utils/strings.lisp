(in-package #:taop)

(defvar *months* '(("Jan"  . "01")
                   ("Feb"  . "02")
                   ("Mar"  . "05")
                   ("May"  . "05")
                   ("June" . "06")
                   ("July" . "07"))
  "Alist from month names to month number, for months seen in the files.")


;;;
;;; Utility function: we collect lines in reverse order, and we want a
;;; single string with all the text in the right order now, and with
;;; Newlines in between lines of text.
;;;
(defun reverse-list-of-string-to-string (list-of-strings)
  (when list-of-strings
    (let* ((len    (+ (length list-of-strings)
                      -1
                      (loop :for l :in list-of-strings :sum (length l))))
           (string (make-array len :element-type 'character)))
      ;; now insert each string in list-of-string to its place in string
      (loop :for i := 0 :then (+ i (length s))
         :for s :in (reverse list-of-strings)
         :do (if (< 0 i)
                 (progn
                   (setf (aref string i) #\Newline)
                   (incf i)))
         :do (replace string s :start1 i))

      ;; and return the new string
      string)))
