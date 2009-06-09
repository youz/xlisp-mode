;; -*- mode:lisp-interaction; -*-

;; make Arc keyword file for xyzzy
(defparameter *arc-home* "c:/usr/lisp/arc")

(save-excursion
  (with-open-file (os "~/etc/Arc"
			:direction :output
			:if-exists :overwrite :if-does-not-exist :create)
    (format os ";; Arc keyword file~% ~{~A~%~}~%"
	    '(quote quasiquote if fn assign))

    (format os ";; xdef~%")
    (find-file (merge-pathnames "ac.scm" *arc-home*))
    (goto-char (point-min))
    (while (scan-buffer "^(xdef \\([^ \t\n]+\\) " :tail t :no-dup t :regexp t)
      (format os "~a~%" (match-string 1)))

    (find-file (merge-pathnames "arc.arc" *arc-home*))
    (goto-char (point-min))
    (let ((defs (make-hash-table :test #'equal)))
      (while (scan-buffer "^.\\(def\\|mac\\|set\\|assign\\) \\([^ \t\n]+\\) " :tail t :no-dup t :regexp t)
	(push (match-string 2) (gethash (match-string 1) defs)))
      (maphash (lambda (k v)
		 (format os "~%;; ~A~%~{~A~%~}" k (nreverse v)))
	       defs))
    ))
