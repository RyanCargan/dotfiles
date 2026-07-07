;;; ai.el --- gptel and Pi coding-agent integration -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; AI/agent layer.
;;
;; gptel:
;;   General LLM chat/composition client.
;;
;; Pi:
;;   Project-oriented coding agent.
;;
;; Clean split:
;;
;;   gptel = talk to a model from Emacs.
;;   Pi    = put a coding agent inside this project.

;;; Code:

(require 'pi-coding-agent)
(defalias 'pi #'pi-coding-agent)

(setq epg-pinentry-mode 'loopback)
(require 'auth-source)
(require 'use-package)

(use-package gptel
  :config
  (setq gptel-model 'gemini-3.1-flash-lite-preview
        gptel-backend
        (gptel-make-gemini "Gemini"
          :key (lambda ()
                 (auth-source-pick-first-password
                  :host "generativelanguage.googleapis.com"))
          :stream t)))

(defun my/pi-project ()
  "Start or focus Pi with the current project as its working directory.

Semantic role:
  Keep the coding agent inside the current project chart."
  (interactive)
  (let ((default-directory (my/project-root)))
    (pi-coding-agent)))

;; Preserve Pi's native chat keymap; prompts should be ready for composing.
(evil-set-initial-state 'pi-coding-agent-chat-mode 'emacs)
(evil-set-initial-state 'pi-coding-agent-input-mode 'insert)

;; Corfu is useful in code buffers but distracting in chat/input buffers.
(add-hook 'pi-coding-agent-chat-mode-hook
          (lambda ()
            (corfu-mode -1)))

(add-hook 'pi-coding-agent-input-mode-hook
          (lambda ()
            (corfu-mode -1)))

(global-set-key (kbd "C-c a") #'pi-coding-agent)

(provide 'ai)
;;; ai.el ends here
