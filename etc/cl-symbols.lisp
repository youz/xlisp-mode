;;; -*- mode: xlisp; CommonLisp -*-

(defun cl-symbols ()
  (let (spo mac fun spo var)
    (do-external-symbols (sym (find-package 'COMMON-LISP))
      (if (fboundp sym)
	  (cond ((special-operator-p sym)
		 (push sym spo))
		((macro-function sym)
		 (push sym mac))
		(t (push sym fun)))
	(push sym var)))
    (macrolet ((sort! (l) `(setq ,l (sort ,l #'string<= :key #'symbol-name))))
      (with-open-file (os "CommonLisp"
			  :direction :output
			  :if-exists :overwrite
			  :if-does-not-exist :create)
	(format os "~(~@{;;~A~%~{~A~%~}~%~}~)"
		'special-operators (sort! spo)
		'macros (sort! mac)
		'functions (sort! fun)
		'variables (sort! var))))))

(defun cl-keywords ()
  (let (kw)
    (do-symbols (sym (find-package "KEYWORD"))
      (push (symbol-name sym) kw))
    (with-open-file (os "kw.txt"
			:direction :output
			:if-does-not-exist :create
			:if-exists :overwrite)
      (format os "~{:~A~%~}" (sort kw #'string<=)))))
