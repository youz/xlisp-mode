(provide "xlisp-mode")
(defun xlisp-mode-version ()
  (interactive)
  (if (interactive-p)
      (message "xlisp-mode ~A on 2009-11-25" (xlisp-mode-version))
    "mod-003"))

#| xlisp-mode modver. by Y.Ushiki

History
== mod-003  2009-11-25
=== 変更点
* xlisp-profile
  * encodingパラメータ追加

* toplevelでsend-current-formやmacroexpandを実行すると
  無限ループに陥いるバグを修正


== mod-002  2009-06-09
=== 変更点
* xlisp-profile
  * macパラメータ追加 (macroexpand用フォーマット)
例:
  :mac "(macroexpand~:[-1~;~] '~A)"  ;; cl用

+ xlisp-send-current-form
+ xlisp-macroexpand
+ xlisp-macroexpand-1

デフォルトキーバインドは
  [C-c C-c] xlisp-send-current-form
  [C-c M-m] xlisp-macroexpand
  [C-c C-m] xlisp-macroexpand-1


== mod-001  2009-06-05
=== 変更点
* プロファイルをplistに
* *xlisp-mode-hook*を追加
* 各コマンドをexport
* キーマップ *xlisp-mode-map* 作成 & バインド変更
   C-j      xlisp-send-last-sexp
  [C-c C-e] xlisp-send-last-sexp
  [C-c C-j] xlisp-send-line
  [C-c C-r] xlisp-send-region
  [C-c C-l] xlisp-send-buffer

* xlisp-profile
  * auto-modeパラメータ追加
  * プロファイルごとにメジャーモードコマンドを生成
例:
(xlisp-profile :name "Scheme"
	       :exe "gosh.exe"
	       :cmd "-i -u pp"
	       :auto-mode "\\.scm$")
  を実行すると xlisp-scheme-mode が使用可能になり、
  *auto-mode-alist*に '("\\.scm$" . xlisp-scheme-mode) を追加する

* buffer-modeをxlisp-modeからxlisp-profileで生成したシンボル(xlisp-hoge-mode)に変更

+ xlisp-send-string (xlisp-send-regionから分離)
+ xlisp-set-mode   ヘッダに関係なくモードを強制変更
+ xlisp-set-header ヘッダを挿入してxlisp-modeを適用

|#


#| xlisp-mode lapse001 for xyzzy-0.2.2.235 or over version

 Copyright (C) 2008 knenet
 All rights reserved.
 <kneneglect_std@yahoo.co.jp>

他のlispの評価器と連携してみる。
別バッファのサブプロセスとして走らせる。

使い方 -*- mode:lisp -*-

このファイルをsite-lispにでも置いておく。

.xyzzyとかに以下を書く。

(require "xlisp-mode") ; 準備する。
(xlisp-profile "Arc" ; モード名。
	       :exe "c:/MzScheme/MzScheme.exe" ; 評価器位置。
	       :cmd "-m -f as.scm" ; パラメータ。
	       :dir "c:/MzScheme/" ; 実行ディレクトリ（デフォルトはファイル位置）
	       :env nil ; 環境変数。
	       :run-char #\LFD) ; 改行文字（デフォルトは#\LFD）
;プロファイルはいくつでもＯＫ。ただし、モード名が同じものは上書きされる。

モード名と同じ名前のキーワードリストをetc-pathに置く。
モード変更したいバッファに以下を書いておく（Arcの場合）。

;; -*- mOdE:xLiSp;ArC -*-

モード名が変わっていたら成功。
lispmodeを直接読み込んでいるので、プロファイルがなければlisp-modeになる。

追加機能は次のコマンド。

C-x LFD S式を評価器に送る。
C-x F5 バッファを評価器に送る。
C-x C-- 1行を評価器に送る。

コマンドを使って、評価器が呼び出されているのに反応がない場合は、改行文字を変えてみると良い。
例えば、GNU CLISPは#\RETで評価を始めるようだ。

ファイルを閉じるときに評価器が残っていれば、そのバッファを表示してプロセスを終了する。

履歴

lapse001 2008-03-27 00:45 とりあえず動くよ。

権利・責任関係

日本国の著作権法が適用される範囲でknenetが著作権を持つ。
細かく見ると、どこにも主張するべき点がなさそうだけれども。
ライセンスは以下の通り。MIT Licenseと同等であると考えて良い。

配布、改造、編纂等の再利用を許可する。二次創作物の権利は一切主張しない（し得ない）。
ただし、ファイルのバージョンや作成・配布元が区別できるように名前や表示を考慮すること。
後に情報元がたどれるように、著作権表示を明記すること。
何人も、このプログラムによって生じた損益について責任を持たない。
このプログラムを使用する者は、同時にこのライセンスを許諾しているものとみなす。

|#

;; ritual
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "lispmode"))
(in-package "editor")

(export
 '(*xlisp-profile*
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

;; macros
(eval-when (:compile-toplevel :execute)
;macro-function
;macro
(defmacro or1 (exist otherwise)
  `(if ,exist ,exist ,otherwise))
)

(defvar *xlisp-profile* nil)
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
(define-key *xlisp-mode-map* '(#\C-c #\C-l) 'xlisp-send-buffer)
(define-key *xlisp-mode-map* '(#\C-c #\M-m) 'xlisp-macroexpand)
(define-key *xlisp-mode-map* '(#\C-c #\C-m) 'xlisp-macroexpand-1)


;; functions
(defun xlisp-profile (&key name exe cmd dir env encoding run-char auto-mode mac hook)
  (when (and (stringp name) (string/= name ""))
    (setq *xlisp-profile* (delete name *xlisp-profile* :test 'equal :key 'cadr))
    (let* ((mode-sym (intern (format nil "xlisp-~(~A~)-mode" name)))
	   (prf (list :name name :exe exe :cmd cmd :dir dir
		      :env env :encoding (or encoding *encoding-sjis*)
		      :hook hook :auto-mode auto-mode
		      :mac mac
		      :mode mode-sym
		      :run-char (or run-char #\LFD))))
      (push prf *xlisp-profile*)
      (si:*fset mode-sym
		`(lambda ()
		   (interactive)
		   (let ((*lisp-mode-hook* nil)) (lisp-mode))
		   (xlisp-setup ',prf)))
      (when auto-mode
	(push (cons auto-mode mode-sym) *auto-mode-alist*))
      ;(export (list mode-sym))
      )))


(defun xlisp-bind-proc ()
  (let ((sbuff (selected-buffer))
	proc)
    (when (and (boundp 'xlisp-buff-profile)
	       (boundp 'xlisp-bound-proc))
      (setq proc (apply 'xlisp-call-new-proc xlisp-buff-profile))
      (pop-to-buffer sbuff t)
      (setq xlisp-bound-proc proc))))

(defun xlisp-call-new-proc (&key name exe cmd dir env run-char encoding)
  (let* ((d (or1 dir (directory-namestring (get-buffer-file-name))))
	 (cmd (format nil "\"~a\" ~a" exe (or cmd "")))
	 pbuff bproc)
    (setq pbuff (execute-subprocess cmd t (format nil "*~A*" name) env d)
	  bproc (buffer-process pbuff))
    (set-process-incode bproc encoding)
    (set-process-outcode bproc encoding)
    (pop-to-buffer pbuff t *xlisp-popup-vertical*)
    (set-buffer pbuff)
    (change-fileio-encoding encoding)
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
    (while (and (not (bobp))
		(string/= "(" (buffer-substring (1- (point)) (point))))
      (backward-sexp))
    (if (bobp)
	(values (point-min) (point-max))
      (let* ((start (and (backward-char) (point)))
	     (end (and (forward-sexp) (point))))
	(if (and start end)
	    (values start end)
	  (error "parse error"))))))


;; commands
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
      ";.*\n" ""))
    (when (interactive-p)
      (pop-to-buffer buff))))

(defun xlisp-macroexpand (&optional (expand-all t))
  (interactive)
  (when (and (boundp 'xlisp-buff-profile)
	     #1=(getf xlisp-buff-profile :mac))
    (let ((buff (selected-buffer)))
      (multiple-value-bind (from to) (xlisp-point-current-form buff)
	(xlisp-send-string
	 (format nil "~@?~%" #1# expand-all (buffer-substring from to))))
      (pop-to-buffer buff))))

(defun xlisp-macroexpand-1 ()
  (interactive)
  (xlisp-macroexpand nil))

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
	(dolist (prf *xlisp-profile*)
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
  (let ((prf (find name *xlisp-profile* :test #'string-equal :key #'cadr)))
    (funcall (getf prf :mode))))

(defun xlisp-set-header (name)
  (interactive (list (xlisp-mode-name-completion)))
  (save-excursion
    (goto-char (point-min))
    (insert (format nil ";;; -*- mode: xlisp; ~A -*-~%" name)))
  (xlisp-mode))


(defun xlisp-mode-name-completion (&optional (default "CommonLisp"))
  (completing-read "xlisp-mode: "
		   (mapcar #'cadr *xlisp-profile*)
		   :default default
		   :case-fold t
		   :must-match t))
