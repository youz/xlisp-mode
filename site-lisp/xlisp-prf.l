;;; -*- mode:Lisp; package:editor -*-

(require "xlisp-mode")

(in-package "editor")
(setq *xlisp-popup-vertical* t)

(defun xlisp-cl-mode-setup ()
  )

(defvar *xlisp-cl-mode-hook* nil)
(add-hook '*xlisp-cl-mode-hook* 'xlisp-cl-mode-setup)


(defun xlisp-scheme-mode-setup ()
  (let ((syn (copy-syntax-table *lisp-mode-syntax-table* (make-syntax-table))))
    (set-syntax-match syn #\[ #\])
    (use-syntax-table syn)))

(defvar *xlisp-scheme-mode-hook* nil)
(add-hook '*xlisp-scheme-mode-hook* 'xlisp-scheme-mode-setup)


(defun xlisp-clojure-mode-setup ()
  (let ((syn (copy-syntax-table *lisp-mode-syntax-table* (make-syntax-table))))
    (set-syntax-match syn #\[ #\])
    (set-syntax-match syn #\{ #\})
    (use-syntax-table syn)))


(defvar *xlisp-clojure-mode-hook* nil)
(add-hook '*xlisp-clojure-mode-hook* 'xlisp-clojure-mode-setup)

(xlisp-profile :name "CommonLisp"
	       :exe "sbcl.bat"
	       :macex "(macroexpand~:[-1~;~] '~A)"
	       :loadfile "(load ~S)"
	       :auto-mode "\\.lisp$"
	       :hook '*xlisp-cl-mode-hook*)

(xlisp-profile :name "Scheme"
	       :exe "gosh.exe"
	       :cmd "-i -u gauche.pp"
	       :encoding *encoding-utf8n*
	       :loadfile "(load ~S)"
	       :macex "(pretty-print (macroexpand~:[-1~;~] '~A))"
	       :auto-mode "\\.scm$"
	       :hook '*xlisp-scheme-mode-hook*)

(xlisp-profile :name "Clojure"
	       :exe "c:/usr/bin/clj.bat"
	       :cmd ""
	       :loadfile "(load-file ~S)"
	       :macex "(do (println) (clojure.contrib.pprint/pprint (macroexpand~:[-1~;~] '~A)))"
	       :auto-mode "\\.clj$"
	       :hook '*xlisp-clojure-mode-hook*)

(xlisp-profile :name "Arc"
	       :exe "arc.bat"
	       :loadfile "(load ~S)"
	       :macex "(do (prn) (ppr (macex~:[1~;~] '~A)) (prn))"
	       :auto-mode "\\.arc$"
	       :hook '*xlisp-scheme-mode-hook*)

(add-hook '*xlisp-mode-hook*
	  #'(lambda ()
	      (ac-mode-on)
	      (toggle-paren t)))

(in-package "user")
(global-set-key '(#\C-x #\C-l) 'xlisp-set-mode)
