# xlisp-mode mod version 003


## Author
2009-2010
  Yousuke Ushiki <citrus.yubeshi@gmail.com>
2008
  knenet <kneneglect_std@yahoo.co.jp>


## Copyright
�I���W�i���łɏ�����B(README.txt�Q��)


## History

### mod-003  2010-10-13
* (new) xlisp-load-file
* repl����send-input��ύX


### mod-002  2009-06-09
* xlisp-profile
** mac�p�����[�^�ǉ� (macroexpand�p�t�H�[�}�b�g)
  ��:
  `:macex "(macroexpand~:[-1~;~] '~A)"  ;; cl�p`

* (new) xlisp-send-current-form
* (new) xlisp-macroexpand
* (new) xlisp-macroexpand-1

  �L�[�o�C���h��
  [C-c C-c] xlisp-send-current-form
  [C-c M-m] xlisp-macroexpand
  [C-c C-m] xlisp-macroexpand-1


## mod-001  2009-06-05
* �v���t�@�C����plist��
* (new) *xlisp-mode-hook*
* �e�R�}���h��export
* �L�[�}�b�v *xlisp-mode-map* �쐬 & �o�C���h�ύX
   C-j      xlisp-send-last-sexp
  [C-c C-e] xlisp-send-last-sexp
  [C-c C-j] xlisp-send-line
  [C-c C-r] xlisp-send-region
  [C-c C-z] xlisp-send-buffer

* xlisp-profile
** (new) auto-mode�p�����[�^
** �v���t�@�C�����ƂɃ��W���[���[�h�R�}���h�𐶐�
  ��:

    (xlisp-profile :name "Scheme"
                   :exe "gosh.exe"
                   :cmd "-i -u pp"
                   :auto-mode "\\.scm$")

  ��]������ƃR�}���h xlisp-scheme-mode ���`���A������
  *auto-mode-alist*�� '("\\.scm$" . xlisp-scheme-mode) ��ǉ�����

* buffer-mode��xlisp-mode����xlisp-profile�Ő��������V���{��(xlisp-hoge-mode)�ɕύX

* (new) xlisp-send-string (xlisp-send-region���番��)
* (new) xlisp-set-mode   �w�b�_�Ɋ֌W�Ȃ����[�h�������ύX
* (new) xlisp-set-header �w�b�_��}������xlisp-mode��K�p

