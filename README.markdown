taskpaper.el
============

This is a simple emacs mode to allow for editing of [Taskpaper](http://www.hogbaysoftware.com/products/taskpaper/) files.

The URL for this (fork of this) project: [http://github.com/tedroden/taskpaper-el](http://github.com/tedroden/taskpaper-el)

# Things you can do 

 - Open, create, and edit taskpaper files.
 - Increase/decrease priority with a keystroke
 - Focus on a single project or tag
 - List of key commands:

<pre>
(define-key taskpaper-mode-map "\C-c\C-p" 'taskpaper-create-new-project)
(define-key taskpaper-mode-map "\C-c\C-t" 'taskpaper-create-new-task)
(define-key taskpaper-mode-map "\C-c\C-d" 'taskpaper-toggle-task)
(define-key taskpaper-mode-map "-"        'taskpaper-electric-mark)
(define-key taskpaper-mode-map (kbd "M-RET") 'taskpaper-newline-and-electric-mark)
(define-key taskpaper-mode-map (kbd "M-<up>") 'taskpaper-priority-increase)
(define-key taskpaper-mode-map (kbd "M-<down>") 'taskpaper-priority-decrease)

(define-key taskpaper-mode-map "\C-c\C-f" 'taskpaper-focus-on-current-project)
(define-key taskpaper-mode-map "\C-c\C-t" 'taskpaper-focus-on-today)
</pre>

# Authors

This was originally written by [Kentaro Kuribayashi](http://coderepos.org/share/browser/lang/elisp/taskpaper/trunk/taskpaper.el) in 2008.

Modified in 2010 by [Jonas Oberschweiber](http://github.com/jonasoberschweiber/taskpaper-el) and then me, [Ted Roden](https://twitter.com/tedroden).
