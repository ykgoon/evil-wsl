;;; evil-wsl.el --- Copy/paste for Windows


;;; Adapted from https://github.com/alexnguyennn/evil-wsl

;; Version: 0.1.0

(require 'evil)

;;; Code:

(defgroup evil-wsl nil
  "wsl"
  :group 'evil
  :prefix "evil-wsl-")

(evil-define-operator evil-wsl-yank (beg end type register yank-handler)
  "save to win clipboard on object that {motion} moves over."
  :move-point nil
  :repeat nil
  (interactive "<R><x><y>")
  (shell-command-on-region beg end "clip.exe")
  (evil-yank beg end type register yank-handler))


(defun get-win-clipboard-text ()
  (string-trim
   (replace-regexp-in-string "" "" (shell-command-to-string "powershell.exe -c Get-Clipboard"))))

(evil-define-operator evil-wsl-paste-after (count register yank-handler)
  "save to win clipboard on object that {motion} moves over."
  :around-advice: ‘spacemacs//yank-indent-region’
  :move-point nil
  (insert (get-win-clipboard-text)))

(defcustom evil-replace-with-register-wsl-indent nil
  "If non-nil, the newly added text will be indented."
  :group 'evil-replace-with-register
  :type 'boolean)

;; depends on evil-replacewithregister
(evil-define-operator evil-replace-with-register-wsl (count beg end type register)
  "Replacing an existing text with the contents of win clipboard"
  :move-point nil
  (interactive "<vc><R><x>")
  (setq count (or count 1))
  (let ((text (if register
                  (evil-get-register register)
                (current-kill 0))))
    (goto-char beg)
    (if (eq type 'block)
        (evil-apply-on-block
         (lambda (begcol endcol)
           (let ((maxcol (evil-column (line-end-position))))
             (when (< begcol maxcol)
               (setq endcol (min endcol maxcol))
               (let ((beg (evil-move-to-column begcol nil t))
                     (end (evil-move-to-column endcol nil t)))
                 (delete-region beg end)
                 (dotimes (_ count)
                   ;; (insert text))))))
                   (insert (get-win-clipboard-text)))))))
         beg end t)
      (delete-region beg end)
      )
      (dotimes (_ count)
        (insert (get-win-clipboard-text)))
        ;; (insert text))
      (when (and evil-replace-with-register-indent (/= (line-number-at-pos beg) (line-number-at-pos)))
        ;; indent if more then one line was inserted
        (save-excursion
(evil-indent beg (point))))))

(define-minor-mode evil-wsl-mode
  "wsl mode."
  :global t
  :keymap (let ((map (make-sparse-keymap)))
            (evil-define-key 'normal map "gy" 'evil-wsl-yank)
            (evil-define-key 'normal map "gp" 'evil-wsl-paste-after)
            (evil-define-key 'normal map "gw" 'evil-replace-with-register-wsl)
            ;; (define-key map (kbd "s-/") 'evil-commentary-line)
            map))

(provide 'evil-wsl)

;;; evil-wsl.el ends here
