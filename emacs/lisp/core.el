;;; core.el --- Core UI, persistence, Evil, leader key -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Core layer.
;;
;; This answers:
;;
;;   "What is the default shape of Emacs?"
;;
;; It sets startup behavior, persistence, basic UI, Evil, and the SPC leader.
;;
;; Other modules assume `my/leader` exists.

;;; Code:

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t
      visible-bell nil)

(menu-bar-mode -1)
(tool-bar-mode -1)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(column-number-mode 1)

;; Place/session memory.
;;
;; save-place:
;;   Reopen files where you left off.
;;
;; savehist:
;;   Keep minibuffer history across sessions.
;;
;; recentf:
;;   Remember recently opened files.
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)

;; Refresh buffers when files change on disk.
;; Useful when Git, agents, build tools, or other editors touch files.
(global-auto-revert-mode 1)

;; Built-in tab workspaces.
(tab-bar-mode 1)

;; Built-in repeated-action compression.
;;
;; Role:
;;   After certain commands, repeat related commands without retyping the
;;   entire prefix.
;;
;; Semantic role:
;;   Lowers friction inside local action loops.
(repeat-mode 1)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(load-theme 'modus-vivendi-tinted t)

(require 'doom-modeline)
(setq doom-modeline-icon nil)
(doom-modeline-mode 1)

;; Evil / Vim-style modal editing.
(setq evil-want-keybinding nil)
(require 'evil)
(evil-mode 1)

(require 'evil-collection)
(evil-collection-init)

;; general.el provides the SPC leader key DSL.
(require 'general)

(general-create-definer my/leader
  :states '(normal visual motion)
  :keymaps 'override
  :prefix "SPC")

(provide 'core)
;;; core.el ends here
