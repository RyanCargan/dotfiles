;;; init.el --- Ryan's Emacs configuration -*- lexical-binding: t; -*-

(setq inhibit-startup-screen t
      ring-bell-function #'ignore
      use-short-answers t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)

(setq evil-want-keybinding nil)
(require 'evil)
(evil-mode 1)

(require 'pi-coding-agent)
(defalias 'pi #'pi-coding-agent)

;; Preserve Pi's native chat keymap; prompts should be ready for composing.
(evil-set-initial-state 'pi-coding-agent-chat-mode 'emacs)
(evil-set-initial-state 'pi-coding-agent-input-mode 'insert)

(global-set-key (kbd "C-c a") #'pi-coding-agent)
(evil-define-key 'normal 'global (kbd "SPC a p") #'pi-coding-agent)

(provide 'init)
;;; init.el ends here
