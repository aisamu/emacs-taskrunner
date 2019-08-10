;; Emacs taskrunner

(require 'projectile)
(require 'taskrunner-clang)
(require 'taskrunner-web)

(defgroup emacs-taskrunner nil
  "A taskrunner for emacs which covers several build systems and lets the user select and runtargets interactively.")

(defconst taskrunner--rake-tasks-command '("rake" "-AT")
  "Command used to retrieve the tasks from rake.")

(defvar taskrunner-tasks-cache '()
  "A cache used to store the tasks retrieved.
It is an alist of the form (project-root . list-of-tasks)")

(defun taskrunner--gradle-get-heading-tasks (heading)
  "Retrieve the gradle tasks below the heading HEADING and return as list."
  (goto-line 1)
  (narrow-to-region (re-search-forward heading nil t)
                    (progn 
                      (re-search-forward "^$" nil t)
                      (previous-line 1)
                      (line-end-position)))

  (map 'list (lambda (elem)
               (message (concat "GRADLE" " " (car (split-string elem " ")))))
       ;; (message "%s" (split-string elem " ")))
       (split-string (buffer-string) "\n"))
  (widen))

(defun taskrunner--gradle-tasks (dir)
  "Retrieve the gradle tasks in for the project in directory DIR."
  (let ((default-directory dir)
        (buff (get-buffer-create "*taskrunner-gradle-tasks*"))
        )
    (call-process "gradle"  nil "*taskrunner-gradle-tasks*"  nil "tasks" "--all")
    (with-temp-buffer
      (set-buffer buff)
      (message "Get build")
      (taskrunner--gradle-get-heading-tasks "Build tasks\n-+\n")
      (taskrunner--gradle-get-heading-tasks "Help tasks\n-+\n")
      (taskrunner--gradle-get-heading-tasks "Verification tasks\n-+\n")
      (taskrunner--gradle-get-heading-tasks "Build Setup tasks\n-+\n")
      (taskrunner--gradle-get-heading-tasks "Documentation tasks\n-+\n")
      (taskrunner--gradle-get-heading-tasks "Other tasks\n-+\n")
      (kill-buffer buff)
      )
    )
  )

(defun taskrunner--rake-tasks (dir)
  "Retrieve tasks from the rake build system for the project in directory DIR."
  (let ((default-directory dir)
        (task-list '()))
    (map 'list (lambda (elem)
                 (concat "RAKE" " " (cadr (split-string elem " "))))
         (split-string (shell-command-to-string taskrunner--rake-tasks-command) "\n"))
    )
  )

(defun taskrunner--get-tasks (dir)
  "Locate and extract all tasks for the project in directory DIR.
Returns a list containing all possible tasks.  Each element is of the form
'TASK-RUNNER-PROGRAM TASK-NAME'.  This is done for the purpose of working with
projects which might use multiple task runners."
  (let ((work-dir-files (directory-files dir))
        (tasks '()))
    (if (member "package.json" work-dir-files)
        (append tasks (taskrunner--js-get-package-tasks dir))
      )
    (if (or (member "gulpfile.js" work-dir-files)
            (member "Gulpfile.js" work-dir-files))
        (append tasks (taskrunner--js-get-gulp-tasks dir))
      )
    (if (or (member "rakefile" work-dir-files)
            (member "Rakefile" work-dir-files)
            (member "rakefile.rb" work-dir-files)
            (member "Rakefile.rb" work-dir-files))
        (append tasks (taskrunner--ruby-get-rake-tasks dir))
      )

    tasks
    )
  )

(defun taskrunner-refresh-cache ()
  "Retrieve all tasks for the current project and load them in the cache.
If there were tasks previously loaded then remove them and retrieve all tasks
again."
  (interactive)
  )


(defun taskrunner--create-process (dir commands run-in-compile &optional
                                       buff-name sentinel process-name)
  "Run the command COMMAND in the directory DIR. If RUN-IN-COMPILE is t
then run the command in compilation mode, otherwise run an async process."
  (let ((default-directory dir))
    (if (not run-in-compile)
        (progn
          (make-process
           :name process-name
           :buffer buff-name
           :command commands
           :sentinel sentinel))
      )
    )
  )

(provide 'emacs-taskrunner)
;;; emacs-taskrunner.el ends here
