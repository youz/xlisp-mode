(require "xlisp-mode")

(in-package "editor")

(setq *xlisp-popup-vertical* t)

(xlisp-profile :name "CommonLisp"
	       :exe "sbcl.bat"
	       :mac "(macroexpand~:[-1~;~] '~A)"
	       :auto-mode "\\.lisp$")

(xlisp-profile :name "Scheme"
	       :exe "gosh.exe"
	       :cmd "-i -u pp"
	       :mac "(pretty-print (macroexpand~:[-1~;~] '~A))"
	       :auto-mode "\\.scm$")

(xlisp-profile :name "Clojure"
	       :exe "clj.bat"
	       :cmd "--nojline"
	       :mac "(do (println) (clojure.contrib.pprint/pprint (macroexpand~:[-1~;~] '~A)))"
	       :auto-mode "\\.clj$")

(xlisp-profile :name "Arc"
	       :exe "arc.bat"
	       :mac "(do (prn) (ppr (macex~:[1~;~] '~A)) (prn))"
	       :auto-mode "\\.arc$")

(add-hook '*xlisp-mode-hook*
	  #'(lambda ()
	      (ac-mode-on)
	      (toggle-paren t)))

(in-package "user")
(global-set-key '(#\C-x #\C-l) 'xlisp-set-mode)
