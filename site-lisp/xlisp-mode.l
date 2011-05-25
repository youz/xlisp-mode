;;; -*- mode:Lisp; package:editor -*-

(provide "xlisp-mode")
(defun xlisp-mode-version ()
  (interactive)
  (if (interactive-p)
      (message "xlisp-mode ~A on 2011-05-24" (xlisp-mode-version))
    "mod-004"))

;; ritual
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "lispmode"))
(in-package "editor")

(export
 '(*xlisp-profiles*
   *xlisp-mode-map*
   *xlisp-mode-hook*
   *xlisp-popup-vertical*
   xlisp-mode
   xlisp-profile
   xlisp-send-last-sexp
   xlisp-send-current-form
   xlisp-send-line
   xlisp-send-buffer
   xlisp-send-region
   xlisp-send-string
   xlisp-macroexpand
   xlisp-macroexpand-1
   xlisp-set-mode
   xlisp-set-header
   ))


(defvar *xlisp-profiles* nil)
(defvar *xlisp-mode-hook* nil)
(defvar *xlisp-popup-vertical* nil)

#|
(define-key ctl-x-map #\LFD 'xlisp-send-last-sexp)
(define-key ctl-x-map #\F5 'xlisp-send-buffer)
(define-key ctl-x-map #\C-- 'xlisp-send-line)
|#

;; keymap
(defvar *xlisp-mode-map* (copy-keymap *lisp-mode-map*))
(define-key *xlisp-mode-map* #\C-j 'xlisp-send-last-sexp)
(define-key *xlisp-mode-map* '(#\C-c #\C-e) 'xlisp-send-last-sexp)
(define-key *xlisp-mode-map* '(#\C-c #\C-c) 'xlisp-send-current-form)
(define-key *xlisp-mode-map* '(#\C-c #\C-j) 'xlisp-send-line)
(define-key *xlisp-mode-map* '(#\C-c #\C-r) 'xlisp-send-region)
(define-key *xlisp-mode-map* '(#\C-c #\C-z) 'xlisp-send-buffer)
(define-key *xlisp-mode-map* '(#\C-c #\C-l) 'xlisp-load-file)
(define-key *xlisp-mode-map* '(#\C-c #\M-m) 'xlisp-macroexpand)
(define-key *xlisp-mode-map* '(#\C-c #\C-m) 'xlisp-macroexpand-1)
(define-key *xlisp-mode-map* '(#\C-c #\C-x) 'xlisp-run-repl)

(defvar *xlisp-repl-map* (copy-keymap ed::*command-output-mode-map*))
(define-key *xlisp-repl-map* #\RET 'xlisp-repl-send-input)

;; profile
(defun xlisp-profile (&key name exe cmd dir env encoding
			   run-char auto-mode macex loadfile hook)
  (when (and (stringp name) (string/= name ""))
    (setq *xlisp-profiles* (delete name *xlisp-profiles* :test 'equal :key 'cadr))
    (let* ((mode-sym (intern (format nil "xlisp-~(~A~)-mode" name)))
	   (pkgname (format nil "xlisp-~(~A~)" name))
	   (pkg (or (find-package pkgname)
		    (make-package pkgname)))
	   (prf (list :name name :exe exe :cmd cmd :dir dir
		      :env env :encoding (or encoding *encoding-sjis*)
		      :hook hook :auto-mode auto-mode
		      :macex macex
		      :loadfile loadfile
		      :mode mode-sym
		      :package pkg
		      :run-char (or run-char #\LFD))))
      (push prf *xlisp-profiles*)
      (si:*fset mode-sym
		`(lambda ()
		   (interactive)
		   (let ((*lisp-mode-hook* nil)) (lisp-mode))
		   (xlisp-setup ',prf)))
      (when auto-mode
	(push (cons auto-mode mode-sym) *auto-mode-alist*))
      ;(export (list mode-sym))
      )))


;;; repl buffer
(defun xlisp-run-repl ()
  (interactive)
  (xlisp-bind-proc))

(defun xlisp-bind-proc ()
  (let ((sbuff (selected-buffer))
	proc)
    (when (and (boundp 'xlisp-buff-profile)
	       (boundp 'xlisp-bound-proc))
      (setq proc (apply 'xlisp-call-new-proc xlisp-buff-profile))
      (pop-to-buffer sbuff t)
      (setq xlisp-bound-proc proc))))

(defun xlisp-repl-send-input ()
  (interactive)
  (ed:shell-send-input))

(defun xlisp-call-new-proc (&key name exe cmd dir env run-char encoding)
  (let* ((d (or dir (directory-namestring (get-buffer-file-name))))
	 (cmd (format nil "\"~a\" ~a" exe (or cmd "")))
	 (pbuff (execute-subprocess cmd t (format nil "*~A*" name) env d))
	 (bproc (buffer-process pbuff)))
    (set-buffer pbuff)
    (use-keymap *xlisp-repl-map*)
    (change-fileio-encoding encoding)
    (set-process-incode bproc encoding)
    (set-process-outcode bproc encoding)
    (pop-to-buffer pbuff t *xlisp-popup-vertical*)
    (make-local-variable 'keyword-hash-table)
    (setf keyword-hash-table (load-keyword-file name t))
    bproc))


;; get positions
(defun xlisp-point-last-sexp (buff)
  (save-excursion
    (let* ((start (and (backward-sexp) (point)))
	   (end (and (forward-sexp) (point))))
      (if (and start end)
	  (values start end)
	(error "parse error")))))

(defun xlisp-point-current-form (buff)
  (save-excursion
    (set-buffer buff)
    (while (not (or (string= "(" (buffer-substring (1- (point)) (point)))
		    (= (point) (point-min))))
      (backward-sexp))
    (if (= (point) (point-min))
	(xlisp-send-region (point-min) (point-max))
      (let* ((start (and (backward-char) (point)))
	     (end (and (forward-sexp) (point))))
	(if (and start end)
	    (values start end)
	  (error "parse error"))))))


;;; commands
(defun xlisp-send-last-sexp ()
  (interactive)
  (let ((buff (selected-buffer)))
    (multiple-value-call #'xlisp-send-region (xlisp-point-last-sexp buff))
    (pop-to-buffer buff)))


(defun xlisp-send-current-form ()
  (interactive)
  (let ((buff  (selected-buffer)))
    (multiple-value-call #'xlisp-send-region (xlisp-point-current-form buff))
    (pop-to-buffer buff)))


(defun xlisp-send-buffer ()
  (interactive)
  (xlisp-send-region (point-min) (point-max)))


(defun xlisp-send-line ()
  (interactive)
  (let ((buff (selected-buffer)))
    (xlisp-send-region
     (progn (goto-bol) (point))
     (progn (goto-eol) (point)))
    (pop-to-buffer buff)
    (forward-char)))


(defun xlisp-send-region (from to)
  (interactive "r")
  (if (> from to) (rotatef from to))
  (let ((buff (selected-buffer)))
    (xlisp-send-string
     (substitute-string
      (format nil "~A~A"
	      (buffer-substring from to)
	      (getf xlisp-buff-profile :run-char))
      ";[^\"]*\n" ""))
    (when (interactive-p)
      (pop-to-buffer buff))))


(defun xlisp-macroexpand (&optional expand-1)
  (interactive)
  (when (and (boundp 'xlisp-buff-profile)
	     #1=(getf xlisp-buff-profile :macex))
    (let ((buff (selected-buffer)))
      (multiple-value-bind (from to) (xlisp-point-current-form buff)
	(xlisp-send-string
	 (format nil "~@?~%" #1# expand-1 (buffer-substring from to))))
      (pop-to-buffer buff))))


(defun xlisp-macroexpand-1 ()
  (interactive)
  (xlisp-macroexpand t))

(defun xlisp-load-file ()
  (interactive)
  (when (and (boundp 'xlisp-buff-profile)
	     #1=(getf xlisp-buff-profile :loadfile))
    (let ((file (get-buffer-file-name)))
      (xlisp-send-string
       (format nil "~@?~%" #1# file)))))


(defun xlisp-send-string (str)
  (interactive "sExpression: ")
  (let ((buff (selected-buffer)))
    (when (and (boundp 'xlisp-buff-profile)
	       (boundp 'xlisp-bound-proc))
      (process-send-string
       (if (and (processp xlisp-bound-proc)
		(eq (process-status xlisp-bound-proc) :run))
	   xlisp-bound-proc
	 (xlisp-bind-proc))
       str)
      (let ((pbuff (process-buffer xlisp-bound-proc)))
	(when pbuff
	  (pop-to-buffer pbuff t *xlisp-popup-vertical*)
	  (set-buffer pbuff)
	  (sit-for 0.3)
	  (goto-char (point-max)))))
    (when (interactive-p)
      (pop-to-buffer buff))))


(defun xlisp-setup (profile)
  (make-local-variable 'xlisp-buff-profile)
  (make-local-variable 'xlisp-bound-proc)
 
  (setq mode-name (getf profile :name)
	buffer-mode (getf profile :mode)
	*buffer-package* (package-name (getf profile :package))
	xlisp-buff-profile profile)
  (make-local-variable '*delete-buffer-hook*)
  (add-hook '*delete-buffer-hook* 'xlisp-show-result)
  (make-local-variable 'keyword-hash-table)
  (setf keyword-hash-table (load-keyword-file mode-name t))
  (make-local-variable 'regexp-keyword-list)
  (setf regexp-keyword-list
	(compile-regexp-keyword-list
	 '(("(" t (:color 14))
	   (")" t (:color 14)))))

;  (make-local-variable 'xlisp-mode-map)
;  (setq xlisp-mode-map (copy-keymap *xlisp-mode-map*))
  (use-keymap *xlisp-mode-map*)
  (run-hooks '*xlisp-mode-hook*)
  (when #1=(getf profile :hook)
    (run-hooks #1#)))


(defun xlisp-mode ()
  (interactive)
  (let ((*lisp-mode-hook* nil))
    (lisp-mode))
  (save-excursion
    (goto-char 0)
    (when (scan-buffer "-\\*-.*xlisp[ \t]*;+[ \t]*\\(.*\\)-\\*-"
		       :case-fold t :regexp t)
      (let ((params (match-string 1)))
	(dolist (prf *xlisp-profiles*)
	  (when (string-matchp (getf prf :name) params)
	    (return (xlisp-setup prf)))))))
  (when (string-equal mode-name "lisp")
    (run-hooks '*lisp-mode-hook*)))


(defun xlisp-show-result (buff)
  (set-buffer buff)
  (when (and (boundp 'xlisp-bound-proc)
	     (processp xlisp-bound-proc) 
	     (eq (process-status xlisp-bound-proc) :run))
    (setq buff (file-namestring (get-buffer-file-name)))
    (delete-other-windows)
    (pop-to-buffer (process-buffer xlisp-bound-proc) nil)
    (kill-subprocess)
    (rename-buffer (format nil "result: ~A" buff)))
  t)

(defun xlisp-kill-subprocess ()
  (interactive)
  (when (and (boundp 'xlisp-bound-proc)
	     (processp xlisp-bound-proc) 
	     (eq (process-status xlisp-bound-proc) :run))
    (kill-subprocess)
    (delete-other-windows)
    t))


(defun xlisp-set-mode (name)
  (interactive (list (xlisp-mode-name-completion)))
  (let ((prf (find name *xlisp-profiles* :test #'string-equal :key #'cadr)))
    (funcall (getf prf :mode))))

(defun xlisp-set-header (name)
  (interactive (list (xlisp-mode-name-completion)))
  (save-excursion
    (goto-char (point-min))
    (insert (format nil ";;; -*- mode: xlisp; ~A -*-~%" name)))
  (xlisp-mode))


(defun xlisp-mode-name-completion (&optional (default "CommonLisp"))
  (completing-read "xlisp-mode: "
		   (mapcar #'cadr *xlisp-profiles*)
		   :default default
		   :case-fold t
		   :must-match t))
