;;; terminal.el --- Eat terminal integration -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Terminal layer.
;;
;; This answers:
;;
;;   "I need a real terminal, but I want it inside Emacs."
;;
;; Eat should inherit project context when used through `my/eat-project`.

;;; Code:

(require 'eat)

(defun my/eat-project ()
  "Open Eat terminal at the current project root.

Semantic role:
  Terminal context should inherit project context.

This prevents the common mistake of opening a shell in the wrong directory."
  (interactive)
  (let ((default-directory (my/project-root)))
    (eat)))

;; Terminal buffers should usually own their own keys.
(evil-set-initial-state 'eat-mode 'emacs)

;; Completion popups are usually noise inside terminals.
(add-hook 'eat-mode-hook
          (lambda ()
            (corfu-mode -1)))

(provide 'terminal)
;;; terminal.el ends here
