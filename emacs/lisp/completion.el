;;; completion.el --- Completion, search, and edit-time popup completion -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Completion/search layer.
;;
;; This answers:
;;
;;   "I do not remember the exact command/file/buffer/symbol name."
;;
;; Stack:
;;
;;   Vertico    = vertical minibuffer UI.
;;   Orderless  = unordered fragment matching.
;;   Marginalia = candidate annotations.
;;   Consult    = useful navigation/search commands.
;;   Corfu      = completion popup at point while editing.

;;; Code:

(require 'vertico)
(vertico-mode 1)

(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion)))))

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

(provide 'completion)
;;; completion.el ends here
