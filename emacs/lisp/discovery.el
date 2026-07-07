;;; discovery.el --- Key discovery, act-on-target, richer help -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Discovery/action layer.
;;
;; This answers:
;;
;;   "What can I press here?"
;;   "What can I do to this thing?"
;;   "What is this command/key/variable?"
;;
;; Components:
;;
;;   which-key = key continuation map.
;;   Embark    = act on target/candidate.
;;   Helpful   = richer C-h introspection.

;;; Code:

(require 'which-key)
(setq which-key-idle-delay 0.35)
(which-key-mode 1)

(global-set-key (kbd "<f1>") #'which-key-show-major-mode)

(require 'embark)
(require 'embark-consult)

(global-set-key (kbd "C-.") #'embark-act)
(global-set-key (kbd "C-;") #'embark-dwim)
(global-set-key (kbd "C-h B") #'embark-bindings)

(require 'helpful)

(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)

;; Preserve classic help commands nearby.
(global-set-key (kbd "C-h F") #'describe-function)
(global-set-key (kbd "C-h V") #'describe-variable)

(defun my/help-lossage ()
  "Show recent keystrokes and commands.

Semantic role:
  Answer: WTF did I just press?"
  (interactive)
  (view-lossage))

(defun my/help-key ()
  "Describe what a key would do.

Semantic role:
  Block the keypress and explain it instead of executing it."
  (interactive)
  (call-interactively #'helpful-key))

(defun my/help-mode ()
  "Describe the current major/minor mode and its keymaps.

Semantic role:
  Answer: what can this buffer do?"
  (interactive)
  (describe-mode))

(provide 'discovery)
;;; discovery.el ends here
