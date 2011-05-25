;;; -*- mode:Lisp; package:editor -*-

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "xlisp-mode"))

(in-package "editor")

(global-set-key '(#\C-x #\C-l) 'xlisp-set-mode)

(setq *xlisp-popup-vertical* t)

(defvar *xlisp-cl-mode-hook* nil)

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
	       :exe "clojure.bat"
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


(defmacro xlisp-define-indent (modename &rest clauses)
  (macrolet ((w/uniq (names &body body)
	       `(let ,(mapcar (lambda (n) `(,n (gensym))) names)
		  ,@body)))
    (w/uniq (gpkgname gpkg gclause gi gsym)
	    `(let* ((,gpkgname (format nil "xlisp-~(~A~)" ,modename))
		    (,gpkg (or (find-package ,gpkgname)
			       (make-package ,gpkgname))))
	       (unuse-package "lisp" ,gpkgname)
	       (dolist (,gclause ',clauses)
		 (let ((,gi (car ,gclause)))
		   (dolist (,gsym (cdr ,gclause))
		     (setf (get (intern (symbol-name ,gsym) ,gpkg) 'ed:lisp-indent-hook)
			   ,gi))))))))

(xlisp-define-indent
 "Arc"
 (0 #:do #:defs #:w/bars #:thread)
 (1 #:with #:withs #:fn #:afn #:when #:unless #:while #:until
    #:atwith #:atwiths #:repeat #:do1 #:case #:aif #:awhen
    #:accum #:n-of #:summing
    #:w/uniq #:w/outstring #:w/stdout #:w/stdin #:w/table
    #:point #:catch)
 (2 #:let #:def #:mac #:atlet #:defset #:each #:whilet #:caselet #:iflet #:whenlet
    #:w/infile #:w/outfile #:w/instring #:w/socket #:w/appendfile
    #:forlen #:on #:defmemo #:trav #:defcall)
 (3 #:loop #:for #:down #:whiler #:noisy-each))

(xlisp-define-indent
 "Clojure"
 (0 #:comment #:do)
 (1 #:defn #:defn- #:fn #:when #:while  #:when-not #:when-let #:when-first
    #:with-precision #:with-open #:with-local-vars
    #:sync #:locking #:if-let #:when-let #:let #:implement #:doto #:dotimes
    #:doseq #:defstruct #:binding #:ns #:assoc #:struct-map #:loop
    #:letfn #:let #:if-not #:if #:for #:defmuti #:defmacro #:case)
 (2 #:proxy #:condp #:catch))

(xlisp-define-indent
 "Scheme"
 (0 #:sequence #:delay #:begin)
 (1 #:define #:call-with-values #:with-output-to-port #:with-output-to-file
    #:call-with-output-file #:with-input-from-port #:with-input-from-file
    #:call-with-input-file #:syntax-rules #:letrec-syntax #:let-syntax
    #:let*-values #:let-values #:letrec #:let* #:let #:lambda #:case)
 (2 #:syntax-case #:do)
 (3 #:dynamic-wind)
 (0 #:identifier-syntax #:dynamic-wind #:call/cc #:call-with-string-output-port
    #:call-with-current-continuation #:call-with-bytevector-output-port
    #:rxmatch-cond #:call-with-output-string #:begin0 #:case-lambda)
 (1 #:with-syntax #:letrec* #:library #:define-record-type #:define-enumeration
    #:rec #:datum->syntax #:call-with-port #:with-time-counter #:with-string-io
    #:with-signal-handlers #:with-port-locking #:with-output-to-process
    #:with-output-to-port #:with-output-to-file #:with-output-conversion
    #:with-module #:with-locking-mutex #:with-iterator #:with-input-from-string
    #:with-input-from-process #:with-input-from-file #:with-input-from-port
    #:with-input-conversion #:with-error-to-port #:with-exception-handler
    #:with-error-handler #:with-builder #:while #:when #:unwind-protect
    #:until #:unless #:syntax-rules #:rxmatch-case #:pre-pose-order #:parse-options
    #:parameterize #:match #:make-parameter #:make #:let/cc #:let-values
    #:let*-values #:hash-table-for-each #:guard #:dotimes #:dolist
    #:call-with-values #:call-with-temporary-file #:call-with-string-io
    #:call-with-process-io #:call-with-output-process #:call-with-output-file
    #:call-with-output-conversion #:call-with-iterators #:call-with-iterator
    #:call-with-input-string #:call-with-input-process #:call-with-input-file
    #:call-with-input-conversion #:call-with-ftp-connection
    #:call-with-client-socket #:call-with-cgi-script #:call-with-builder
    #:and-let*)
 (2 #:define-condition-type #:rxmatch-let #:receive #:rlet1 #:let1
    #:let-optionals* #:let-match #:let-keywords* #:let-keywords #:let-args
    #:if-match #:if-let1)
 (3 #:with-ports)
 (4 #:rxmatch-if))

