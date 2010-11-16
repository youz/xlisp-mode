# xlisp-mode mod version 003


## Author
2009-2010  
Yousuke Ushiki <citrus.yubeshi@gmail.com>

2008  
knenet <kneneglect_std@yahoo.co.jp>  


## Copyright
オリジナル版に準ずる。(README.txt参照)


## History

### mod-003  2010-10-13
* (new) xlisp-load-file
* repl側のsend-inputを変更


### mod-002  2009-06-09
* xlisp-profile
** macパラメータ追加 (macroexpand用フォーマット)
  例:
  `:macex "(macroexpand~:[-1~;~] '~A)"  ;; cl用`

* (new) xlisp-send-current-form
* (new) xlisp-macroexpand
* (new) xlisp-macroexpand-1  
    キーバインドは  
    [C-c C-c] xlisp-send-current-form  
    [C-c M-m] xlisp-macroexpand  
    [C-c C-m] xlisp-macroexpand-1


### mod-001  2009-06-05
* プロファイルをplistに
* (new) `*xlisp-mode-hook*`
* 各コマンドをexport
* キーマップ `*xlisp-mode-map*` 作成 & バインド変更  
    C-j      xlisp-send-last-sexp  
    [C-c C-e] xlisp-send-last-sexp  
    [C-c C-j] xlisp-send-line  
    [C-c C-r] xlisp-send-region  
    [C-c C-z] xlisp-send-buffer

* xlisp-profile
** (new) auto-modeパラメータ
** プロファイルごとにメジャーモードコマンドを生成  
    例:

        (xlisp-profile :name "Scheme"
                       :exe "gosh.exe"
                       :cmd "-i -u pp"
                       :auto-mode "\\.scm$")

    を評価するとコマンド xlisp-scheme-mode を定義し、同時に
    `*auto-mode-alist*に` `'("\\.scm$" . xlisp-scheme-mode)` を追加する

* buffer-modeを `xlisp-mode` からxlisp-profileで生成したシンボル (ex.`xlisp-scheme-mode`) に変更
* (new) xlisp-send-string (xlisp-send-regionから分離)
* (new) xlisp-set-mode   ヘッダに関係なくモードを強制変更
* (new) xlisp-set-header ヘッダを挿入してxlisp-modeを適用

