;;; cockpit.el --- Transient cockpit and leader bindings -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Cockpit layer.
;;
;; This answers:
;;
;;   "I forgot everything. Show me the local command map."
;;
;; Transient is used for a broad recovery menu.
;; The SPC leader is used for fast muscle-memory access.

;;; Code:

(require 'transient)

(transient-define-prefix my/starter-cockpit ()
  "Personal command cockpit for zero-XP recovery.

This is the 'I forgot everything' menu.

It intentionally duplicates some leader bindings because its job is not
minimalism. Its job is to make the local command map visible."
  [["Project"
    ("pf" "find project file" project-find-file)
    ("ps" "search project" consult-ripgrep)
    ("pb" "project buffer" consult-project-buffer)
    ("pp" "open/switch project tab" my/project-open)
    ("pd" "project Dired" project-dired)
    ("pc" "project compile" project-compile)
    ("pt" "project terminal" my/eat-project)
    ("pa" "Pi in project" my/pi-project)]

   ["Places"
    ("bb" "switch buffer" consult-buffer)
    ("rf" "recent file" consult-recent-file)
    ("bj" "jump bookmark" my/bookmark-jump)
    ("bs" "set bookmark here" my/bookmark-set-here)
    ("dd" "Dired here" dired-jump)
    ("ff" "find file" find-file)
    ("tr" "Treemacs" treemacs)]

   ["Search"
    ("sl" "line in buffer" consult-line)
    ("sg" "ripgrep project" consult-ripgrep)
    ("si" "imenu symbols" consult-imenu)
    ("so" "outline" consult-outline)]

   ["Help / WTF"
    ("hk" "describe key" my/help-key)
    ("hm" "describe mode" my/help-mode)
    ("ha" "apropos command" apropos-command)
    ("hl" "recent keys / lossage" my/help-lossage)
    ("hb" "Embark bindings" embark-bindings)
    ("hw" "where is command bound?" where-is)]

   ["Act"
    ("aa" "Embark act" embark-act)
    ("ad" "Embark dwim" embark-dwim)
    ("ae" "Embark export" embark-export)]

   ["Git / Agent / LLM"
    ("gg" "Magit status" magit-status)
    ("ap" "Pi coding agent in project" my/pi-project)
    ("gc" "gptel chat" gptel)]

   ["Terminal"
    ("tt" "Eat terminal here" eat)
    ("tp" "Eat terminal in project" my/eat-project)]])

(global-set-key (kbd "C-c SPC") #'my/starter-cockpit)

(my/leader
  "?" '(which-key-show-major-mode :which-key "mode key guide")
  "SPC" '(execute-extended-command :which-key "M-x")

  ;; Recovery cockpit
  "RET" '(my/starter-cockpit :which-key "starter cockpit")
  "C"   '(my/starter-cockpit :which-key "starter cockpit")

  ;; Agent / LLM
  "a"   '(:ignore t :which-key "agent")
  "a p" '(my/pi-project :which-key "Pi in project")
  "a g" '(gptel :which-key "gptel chat")

  ;; Embark / act-on-target
  "e"   '(:ignore t :which-key "embark/act")
  "e a" '(embark-act :which-key "act on thing")
  "e d" '(embark-dwim :which-key "dwim on thing")
  "e b" '(embark-bindings :which-key "action bindings")
  "e e" '(embark-export :which-key "export candidates")

  ;; Buffer
  "b"   '(:ignore t :which-key "buffer")
  "b b" '(consult-buffer :which-key "switch buffer")
  "b k" '(kill-current-buffer :which-key "kill buffer")

  ;; File / place memory
  "f"   '(:ignore t :which-key "file/place")
  "f f" '(find-file :which-key "find file")
  "f r" '(consult-recent-file :which-key "recent file")
  "f s" '(save-buffer :which-key "save")
  "f t" '(treemacs :which-key "file tree")
  "f b" '(my/bookmark-jump :which-key "jump bookmark")
  "f B" '(my/bookmark-set-here :which-key "set bookmark")
  "f d" '(dired-jump :which-key "Dired here")

  ;; Git
  "g"   '(:ignore t :which-key "git")
  "g g" '(magit-status :which-key "Magit status")

  ;; Help / WTF layer
  "h"   '(:ignore t :which-key "help/WTF")
  "h k" '(my/help-key :which-key "describe key")
  "h m" '(my/help-mode :which-key "describe mode")
  "h a" '(apropos-command :which-key "apropos command")
  "h l" '(my/help-lossage :which-key "recent keys")
  "h w" '(where-is :which-key "where is command")
  "h f" '(helpful-callable :which-key "describe callable")
  "h v" '(helpful-variable :which-key "describe variable")
  "h x" '(helpful-command :which-key "describe command")

  ;; Open
  "o"   '(:ignore t :which-key "open")
  "o a" '(org-agenda :which-key "Org agenda")
  "o c" '(calc :which-key "calculator")
  "o d" '(dired-jump :which-key "Dired here")
  "o e" '(eat :which-key "Eat terminal here")
  "o r" '(find-file :which-key "open local/TRAMP path")

  ;; Project
  "p"   '(:ignore t :which-key "project")
  "p a" '(my/pi-project :which-key "Pi in project")
  "p b" '(consult-project-buffer :which-key "project buffer")
  "p f" '(project-find-file :which-key "project file")
  "p p" '(my/project-open :which-key "switch project")
  "p s" '(consult-ripgrep :which-key "search project")
  "p d" '(project-dired :which-key "project Dired")
  "p c" '(project-compile :which-key "project compile")
  "p t" '(my/eat-project :which-key "project terminal")

  ;; Search
  "s"   '(:ignore t :which-key "search")
  "s l" '(consult-line :which-key "line in buffer")
  "s p" '(consult-ripgrep :which-key "search project")
  "s i" '(consult-imenu :which-key "symbols/imenu")
  "s o" '(consult-outline :which-key "outline")

  ;; Tabs
  "t"   '(:ignore t :which-key "tabs")
  "t n" '(tab-next :which-key "next tab")
  "t p" '(tab-previous :which-key "previous tab")
  "t r" '(tab-rename :which-key "rename tab"))

(provide 'cockpit)
;;; cockpit.el ends here
