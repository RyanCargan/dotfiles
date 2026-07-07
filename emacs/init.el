;;; init.el --- Ryan's Emacs entrypoint -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Keep init.el boring.
;;
;; This file only:
;;   1. Adds ./lisp to `load-path`.
;;   2. Loads the sidecar modules in dependency order.
;;
;; The sidecars carry the actual explanations.

;;; Code:

(add-to-list 'load-path
             (expand-file-name "lisp" user-emacs-directory))

(require 'core)
(require 'completion)
(require 'place)
(require 'discovery)
(require 'terminal)
(require 'ai)
(require 'cockpit)

(provide 'init)
;;; init.el ends here
