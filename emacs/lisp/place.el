;;; place.el --- Projects, files, Dired, bookmarks, Git -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Place/context layer.
;;
;; This answers:
;;
;;   "Where is my stuff?"
;;   "What project am I in?"
;;   "How do I return to known places?"
;;   "How do I act on files as a set?"
;;
;; Dired is treated as a visible file-set table:
;;
;;   rows    = files
;;   marks   = selected files
;;   actions = operations on marked files

;;; Code:

(require 'subr-x)
(require 'project)
(require 'dired-x)
(require 'treemacs)
(require 'magit)

(setq dired-dwim-target t
      dired-recursive-copies 'always
      dired-recursive-deletes 'top)

(defun my/project-root ()
  "Return the current project root, or `default-directory`.

Semantic role:
  Normalize project context into one reusable answer.

Many commands need a working directory. This prevents each command from
rediscovering project context differently."
  (if-let ((project (project-current)))
      (project-root project)
    default-directory))

(defun my/project-open ()
  "Select a project and open it in a named tab.

Workflow:
  project root
  -> new tab
  -> tab named after project
  -> Dired at project root

Semantic role:
  Project = named workspace plus visible file table."
  (interactive)
  (let* ((directory (project-prompt-project-dir))
         (name (file-name-nondirectory
                (directory-file-name directory))))
    (tab-new)
    (tab-rename name)
    (dired directory)))

(defun my/bookmark-set-here ()
  "Set a bookmark at the current location.

Semantic role:
  Convert a useful place into a named place."
  (interactive)
  (call-interactively #'bookmark-set))

(defun my/bookmark-jump ()
  "Jump to a saved bookmark.

Semantic role:
  Return to a known place without remembering the path."
  (interactive)
  (call-interactively #'bookmark-jump))

(provide 'place)
;;; place.el ends here
