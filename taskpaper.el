;;; taskpaper.el --- Taskpaper implementation for Emacs

;; Copyright (C) 2008 Kentaro Kuribayashi (original)
;; Copyright (c) 2010 Jonas Oberschweiber <jonas@oberschweiber.com> (updates)
;; Copyright (C) 2010 Ted Roden (updates)


;; Author: kentaro <kentarok@gmail.com>
;; Author: Jonas Oberschweiber <jonas@oberschweiber.com>
;; Author: Ted Roden <tedroden@gmail.com>

;; Keywords: tools, task


;; Changed handling of "done" tasks: uses TaskPaper's @done notation
;; instead of +/- at the beginning of the line
;; Changed the indentation function to automatically indent tasks that
;; appear below projects (only one level supported).
;; I don't know if the other functions work (didn't test them as I
;; don't use them (yet)).

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; * Install
;;
;; After download this file, just put the code below into your .emacs
;;
;;   (require 'taskpaper)
;;
;; * Usage
;;
;; (1) Create a Taskpaper file
;;
;;   M-x find-file RET 2008-02-18.taskpaper
;;
;; (2) Create a new project
;;
;;   `C-c C-p' or just write as follows:
;;
;;   Project 1:
;;
;; (2) List tasks as follows:
;;
;;   `C-c C-t' or just write as follows:
;;
;;   Project 1:
;;
;;   + task 1
;;   + task 2
;;
;;   Project 2:
;;
;;   + task 3
;;   + task 4
;;
;; (3) Mark task as done
;;
;;   `C-c C-d' on the task you have done.
;;
;; (4) Misc:
;;
;;   `M-<up>' increase the priority of a task
;;   `M-<down>' decrease the priority of a task
;;   `M-RET' create a new task from anywhere on the line
;;   `C-M-T' View a list of tasks tagged with "@today" in a new buffer `taskpaper-list-today`

;;; Code:

;; Hook
(defvar taskpaper-mode-hook nil
  "*Hooks for Taskpaper major mode")

;; Keymap
(defvar taskpaper-mode-map (make-keymap)
  "*Keymap for Taskpaper major mode")

(defvar taskpaper-indent-amount 4)

(define-key taskpaper-mode-map "\C-c\C-p" 'taskpaper-create-new-project)
(define-key taskpaper-mode-map "\C-c\C-t" 'taskpaper-create-new-task)
(define-key taskpaper-mode-map "\C-c\C-d" 'taskpaper-toggle-task)
(define-key taskpaper-mode-map "-"        'taskpaper-electric-mark)
(define-key taskpaper-mode-map (kbd "M-RET") 'taskpaper-newline-and-electric-mark)
(define-key taskpaper-mode-map (kbd "M-<up>") 'taskpaper-priority-increase)
(define-key taskpaper-mode-map (kbd "M-<down>") 'taskpaper-priority-decrease)


(define-key taskpaper-mode-map "\C-c\C-f" 'taskpaper-focus-on-current-project)
(define-key taskpaper-mode-map "\C-c\C-t" 'taskpaper-focus-on-today)

;; Face
(defface taskpaper-project-face
  '((((class color) (background light))
     (:foreground "white" :underline "darkred" :weight bold :family "8x13" :height 2.0))
    (((class color) (background dark))
     (:foreground "white" :underline "darkred" :weight bold :family "8x13" :height 2.0)))
  "Face definition for project name")

(defface taskpaper-task-face
  '((((class color) (background light))
     (:foreground "wheat1"))
    (((class color) (background dark))
     (:foreground "wheat1")))
  "Face definition for task")

(defface taskpaper-task-marked-as-done-face
  '((((class color) (background light))
     (:foreground "grey20" :weight light :strike-through t))
    (((class color) (background dark))
     (:foreground "grey20" :weight light :strike-through t)))
  "Face definition for task marked as done")

(defface taskpaper-done-mark-face
  '((((class color) (background light))
     (:foreground "grey20"))
    (((class color) (background dark))
     (:foreground "grey20")))
  "Face definition for done mark")

(defface taskpaper-undone-mark-face
  '((((class color) (background light))
     (:foreground "yellow"))
    (((class color) (background dark))
     (:foreground "yelow")))
  "Face definition for undone mark")

(defface taskpaper-task-priority-3-face
  '((((class color) (background light))
     (:foreground "red1"))
    (((class color) (background dark))
     (:foreground "red1")))
  "Priority 3 Face")

(defface taskpaper-task-priority-2-face
  '((((class color) (background light))
     (:foreground "OrangeRed1"))
    (((class color) (background dark))
     (:foreground "OrangeRed1")))
  "Priority 2 Face")

(defface taskpaper-task-priority-1-face
  '((((class color) (background light))
     (:foreground "orange1"))
    (((class color) (background dark))
     (:foreground "orange1")))
  "Priority 1 Face")

(defface taskpaper-task-today-face
  '((((class color) (background light))
     (:foreground "LimeGreen"))
    (((class color) (background dark))
     (:foreground "LimeGreen")))
  "today's tasks Face")


(defvar taskpaper-project-face 'taskpaper-project-face)
(defvar taskpaper-task-face 'taskpaper-task-face)
(defvar taskpaper-task-marked-as-done-face 'taskpaper-task-marked-as-done-face)
(defvar taskpaper-done-mark-face 'taskpaper-done-mark-face)
(defvar taskpaper-undone-mark-face 'taskpaper-undone-mark-face)
(defvar taskpaper-task-today-face 'taskpaper-task-today-face)
(defvar taskpaper-task-priority-1-face 'taskpaper-task-priority-1-face)
(defvar taskpaper-task-priority-2-face 'taskpaper-task-priority-2-face)
(defvar taskpaper-task-priority-3-face 'taskpaper-task-priority-3-face)

(defvar taskpaper-font-lock-keywords
  '(
	("^.+:[ \t]*$" 0 taskpaper-project-face)
    ("^[ \t]*\\(-\\)\\(.*\\).*$"
     (1 taskpaper-undone-mark-face t)
     (2 taskpaper-task-face t))

	(".+@today.*" 0 taskpaper-task-today-face t)

	("^.+@priority\(1\)$" 0 taskpaper-task-priority-1-face t)
	("^.+@priority\(2\)$" 0 taskpaper-task-priority-2-face t)
	("^.+@priority\(3\)$" 0 taskpaper-task-priority-3-face t)

	;; if it's done, it's done... make sure we display it as done
    ("^[ \t]*\\(-\\)\\(.+\\)@done.*$"
     (0 taskpaper-done-mark-face t)
     (2 taskpaper-task-marked-as-done-face t))))

;; Taskpaper major mode
(define-derived-mode taskpaper-mode fundamental-mode "Taskpaper"
  "Major mode to manage tasks easily"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'taskpaper-mode)
  (setq mode-name "Taskpaper")
  (use-local-map taskpaper-mode-map)
  (set (make-local-variable 'font-lock-defaults) '(taskpaper-font-lock-keywords))
  (set (make-local-variable 'font-lock-string-face) nil)
  (set (make-local-variable 'indent-line-function) 'taskpaper-indent-line)
  (run-hooks 'taskpaper-mode-hook))

;; start up when we see these files
(add-to-list 'auto-mode-alist (cons "\\.taskpaper$" 'taskpaper-mode))

;; Commands
(defun taskpaper-create-new-project (name)
  "Creates new project"
  (interactive "sProject Name: ")
  (insert (concat name ":\n\n")))

(defun taskpaper-create-new-task (task)
  "Creates new task"
  (interactive "sNew Task: ")
  (insert (concat "- " task)))

(defun taskpaper-toggle-task ()
  "Marks task as done"
  (interactive)
  (save-excursion
    (beginning-of-line)
    (when (looking-at "[- ]")
      (let ((mark (if (equal (match-string 0) " ") "-" " ")))
        (delete-char 1)
        (insert mark)))))

(defun taskpaper-indent-line ()
  "Detects if list mark is needed when indented"
  (interactive)
  (let ((mark-flag nil)
        (in-project nil)
        (old-tabs indent-tabs-mode))
    ;; TaskPaper won't recognize the indents otherwise.
    (setq indent-tabs-mode t)
    (save-excursion
      (while (and (not in-project) (not (bobp)))
        (forward-line -1)
        (when (looking-at "^.+:[ \t]*$") (setq in-project t))
        (when (looking-at "-") (setq mark-flag t))))
    (when mark-flag (insert "- "))    
    (when in-project (indent-line-to taskpaper-indent-amount))
    (setq indent-tabs-mode old-tabs)))

(defun taskpaper-electric-mark (arg)
  "Inserts a list mark"
  (interactive "*p")
  (if (zerop (current-column))
      (progn
        (taskpaper-indent-line)
        (self-insert-command arg)      
        (insert " "))
    (self-insert-command arg)))

(defun tedroden/trim-line ()
  (interactive)
  (save-excursion 
	(end-of-line)
	(setq eol (point))
	(while (= ?  (char-before ))
	  (backward-char))
	(delete-region eol (point))))


(defun taskpaper-newline-and-electric-mark ()
  "Newline and new task"
  (interactive)
  (progn
	(end-of-line) 
	(insert "\n")
	(taskpaper-indent-line)
	(insert "- ")))

(defun taskpaper-focus-on-today ()
  "List all tasks tagged with @today in a new (read-only) buffer."
  (interactive)
  (taskpaper-focus-on-tag "@today"))

(defun taskpaper-focus-on-tag (tag)
  "List all tasks tagged with tag in a new (read-only) buffer."
  (interactive)
  (message (format "Focusing on %s" tag))

  (setq taskpaper-list-today (format "* Taskpaper Focus: %s *" tag))
  
  (save-excursion
	;; go to the beginning of the buffer
	(goto-char 0)

	;; FIXME: probably a rough way to get a blank buffer
	;; if we already have this buffer, kill it and try again
	(if (get-buffer taskpaper-list-today)
		(kill-buffer taskpaper-list-today))
	(get-buffer-create taskpaper-list-today)
	
	;; set up some basic variables
	(setq current-project "")
	(setq current-project-has-tasks nil)
	(setq this-buffer (current-buffer))

	;; probably not the best way to loop through the contents of a buffer...
	(setq moving t)

	(setq tag-regexp (format "^.*%s.*" tag))

	(while moving 

	  (when (looking-at "^\\(.+\\):[ \t]+*$") 
		(setq current-project (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
		(setq current-project-has-tasks nil))
	  
	  (when (looking-at tag-regexp) 
		;; set the current task
		(setq current-task (thing-at-point 'line))

		;; write the task/project into the new buffer
		(set-buffer taskpaper-list-today)

		;; if it's the first task for this project... add the project name
		(when (not current-project-has-tasks)
		  (setq current-project-has-tasks t)
		  (insert (format "\n%s:\n" current-project)))

		;; inser the final task
		(insert current-task))

	  ;; ensure that we go forward in the proper buffer
	  (set-buffer this-buffer)
	  (when (< 0 (forward-line))
		(setq moving nil)))

	;; switch to the new buffer
	(switch-to-buffer taskpaper-list-today)
	;; mark it as read only... we don't save from here
	(setq buffer-read-only t)
	;; use this mode
	(taskpaper-mode)))


(defun taskpaper-focus-on-current-project ()
  "Limit the view to only the current project."
  (interactive)

  (save-excursion

	(setq this-buffer (current-buffer))

	(setq current-project nil)
	(setq moving t)

	;; crawl back to project line
	(while moving 
	  
	  (when (looking-at "^\\(.+\\):[ \t]+*$") 
		(setq current-project (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
		(message (format "Found project %s" current-project))
		(setq moving nil))

	  ;; if we should still be moving
	  (when moving
		;; go back one line
		(when (< 0 (forward-line -1))
		  (setq moving nil))))


	;; if we have a current project...
	(when current-project

	  ;; setup the new buffer
	  (message (format "Focusing on %s" current-project))
	  (setq taskpaper-focus-buffer (format "* Taskpaper Project Focus: %s *" current-project))
	  
	  (if (get-buffer taskpaper-focus-buffer)
		  (kill-buffer taskpaper-focus-buffer))
	  (get-buffer-create taskpaper-focus-buffer)

	  (forward-line) ;; move one step (we're on the project line aleady)
	  (set-buffer taskpaper-focus-buffer)
	  (insert (format "%s:\n" current-project))
	  (set-buffer this-buffer)
	  ;; loop through the thing

	  (setq moving t)

	  (while moving
		
		;; unless we're looking at another project, add it to the buffer
		(if (looking-at "^\\(.+\\):[ \t]+*$")
			(setq moving nil)
		  (setq line (thing-at-point 'line))
		  (set-buffer taskpaper-focus-buffer)
		  (insert line))
		
		;; keep going?
		(set-buffer this-buffer)
		(when moving
		  (when (< 0 (forward-line))
			(setq moving nil))))

	  ;; switch to the new buffer
	  (switch-to-buffer taskpaper-focus-buffer)
	  ;; mark it as read only... we don't save from here
	  (setq buffer-read-only t)
	  (goto-char 0)
	  (forward-line)
	  ;; use this mode
	  (taskpaper-mode))))


(defun taskpaper-priority-increase ()
  "increase the priority by one"
  (interactive)
  (taskpaper-priority-adjust 1))

(defun taskpaper-priority-decrease ()
  "increase the priority by one"
  (interactive)
  (taskpaper-priority-adjust -1))

(defun taskpaper-priority-adjust (number)
  "Adjust the priority by x"
  (interactive)
  (save-excursion
	(progn
	  ;; get to the start of the line
	  (beginning-of-line)

	  ;; is there a priority already defined
	  (if (looking-at ".*\\( ?@priority(\\([0-9]\\))\\).*")

		  ;; cache the current-priority
		  (let ((current-priority (string-to-number 
								   (buffer-substring-no-properties 
									(match-beginning 2) 
									(match-end 2)))))

			(setq new-priority (+ number current-priority))

			;; if the priority goes to zero, remove it all together
			(if (> 1 new-priority)
				(delete-region (match-beginning 1) (match-end 1))

			  ;; otherwise, delete the current-priority
			  (delete-region (match-beginning 2) (match-end 2))

			  ;; go to the inside of the priority() parens
			  (goto-char (match-beginning 2))

			  ;; insert the updated priority
			  (insert (number-to-string new-priority))))

		;; otherwise, if we're increasing append a basic priority
		(message (number-to-string number))
		(if (< number 0)
			;; nothing to see here.
			(message "No priority to decrease")

		  ;; create a default priority
		  (tedroden/trim-line)
		  (end-of-line) 
		  (insert " @priority(1)"))))))


(defun taskpaper-toggle-today ()
  "Tag this task with @today"
  (interactive)
  (save-excursion
	;; get to the start of the line
	(beginning-of-line)

	;; already tagged?
	(if (looking-at ".*\\( ?@today\\).*")
		;; delete the @today tag
		(delete-region (match-beginning 1) (match-end 1))

	  (tedroden/trim-line)
	  (end-of-line)
	  
	  (insert " @today"))))
		  
(provide 'taskpaper)
;;; taskpaper.el ends here
