;;; init.el --- Ryan's Emacs configuration -*- lexical-binding: t; -*-

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t
      visible-bell nil)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(column-number-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(tab-bar-mode 1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(load-theme 'modus-vivendi-tinted t)

(require 'doom-modeline)
(setq doom-modeline-icon nil)
(doom-modeline-mode 1)

;; Minibuffer completion and contextual annotations.
(require 'vertico)
(vertico-mode 1)

(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion))))

(require 'marginalia)
(marginalia-mode 1)

(require 'consult)
(global-set-key (kbd "C-s") #'consult-line)
(global-set-key (kbd "C-x b") #'consult-buffer)

(require 'corfu)
(setq corfu-auto t
      corfu-cycle t
      corfu-preselect 'prompt)
(global-corfu-mode 1)

(setq evil-want-keybinding nil)
(require 'evil)
(evil-mode 1)

(require 'evil-collection)
(evil-collection-init)

(require 'which-key)
(setq which-key-idle-delay 0.35)
(which-key-mode 1)

(require 'general)
(general-create-definer my/leader
  :states '(normal visual motion)
  :keymaps 'override
  :prefix "SPC")

(require 'subr-x)
(require 'project)
(require 'dired-x)
(require 'treemacs)
(require 'magit)

(require 'pi-coding-agent)
(defalias 'pi #'pi-coding-agent)

(require 'auth-source)
(require 'use-package)

(use-package gptel
  :config
  (setq gptel-model 'gemini-3.1-flash-lite
        gptel-backend
        (gptel-make-gemini "Gemini"
          :key (lambda ()
                 (auth-source-pick-first-password
                  :host "generativelanguage.googleapis.com"))
          :stream t)))

;; Preserve Pi's native chat keymap; prompts should be ready for composing.
(evil-set-initial-state 'pi-coding-agent-chat-mode 'emacs)
(evil-set-initial-state 'pi-coding-agent-input-mode 'insert)
(add-hook 'pi-coding-agent-chat-mode-hook (lambda () (corfu-mode -1)))
(add-hook 'pi-coding-agent-input-mode-hook (lambda () (corfu-mode -1)))

(defun my/project-root ()
  "Return the current project root, or `default-directory'."
  (if-let ((project (project-current)))
      (project-root project)
    default-directory))

(defun my/pi-project ()
  "Start or focus Pi with the current project as its working directory."
  (interactive)
  (let ((default-directory (my/project-root)))
    (pi-coding-agent)))

(defun my/project-open ()
  "Select a project and open it in a named tab."
  (interactive)
  (let* ((directory (project-prompt-project-dir))
         (name (file-name-nondirectory (directory-file-name directory))))
    (tab-new)
    (tab-rename name)
    (dired directory)))

(global-set-key (kbd "C-c a") #'pi-coding-agent)
(global-set-key (kbd "<f1>") #'which-key-show-major-mode)

(my/leader
  "?" '(which-key-show-major-mode :which-key "mode key guide")
  "SPC" '(execute-extended-command :which-key "M-x")
  "a" '(:ignore t :which-key "agent")
  "a p" '(my/pi-project :which-key "Pi in project")
  "b" '(:ignore t :which-key "buffer")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b k" '(kill-current-buffer :which-key "kill buffer")
  "f" '(:ignore t :which-key "file")
  "f f" '(find-file :which-key "find file")
  "f r" '(consult-recent-file :which-key "recent file")
  "f s" '(save-buffer :which-key "save")
  "f t" '(treemacs :which-key "file tree")
  "g" '(:ignore t :which-key "git")
  "g g" '(magit-status :which-key "Magit status")
  "o" '(:ignore t :which-key "open")
  "o a" '(org-agenda :which-key "Org agenda")
  "o c" '(calc :which-key "calculator")
  "o d" '(dired-jump :which-key "Dired here")
  "o r" '(find-file :which-key "open local/TRAMP path")
  "p" '(:ignore t :which-key "project")
  "p a" '(my/pi-project :which-key "Pi in project")
  "p b" '(consult-project-buffer :which-key "project buffer")
  "p f" '(project-find-file :which-key "project file")
  "p p" '(my/project-open :which-key "switch project")
  "p s" '(consult-ripgrep :which-key "search project")
  "t" '(:ignore t :which-key "tabs")
  "t n" '(tab-next :which-key "next tab")
  "t p" '(tab-previous :which-key "previous tab")
  "t r" '(tab-rename :which-key "rename tab"))

(provide 'init)
;;; init.el ends here
