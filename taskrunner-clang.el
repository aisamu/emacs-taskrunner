;; Functions, variables and messages used in the process of retrieving tasks
;; for any build/task system typically used for C/C++/C# languages.
(require 'projectile)

(defconst taskrunner--make-phony-regexp "\.PHONY[[:space:]]+:[[:space:]]+"
  "Regular expression used to locate all PHONY targets in makefile.")

(defconst taskrunner--cmake-warning
  "Taskrunner: Detected CMake build system but no build folder or Makefile were found! Please setup
CMake for either insource or outsource build and then call emacs-taskrunner again!"
  "A warning string used to indicate that a CMake project was detected but no
build folder or makefile was found.")

(defun taskrunner--make-get-phony-tasks (dir)
  "Retrieve all 'PHONY' tasks from the makefile located in the directory DIR."
  (interactive)
  (let ((make-path (concat dir "Makefile"))
        (buff (get-buffer-create "*taskrunner-makefile*"))
        (tasks '())
        )
    (with-temp-buffer
      (set-buffer buff)
      (goto-line 1)
      (insert-file-contents make-path)
      (while (re-search-forward taskrunner--make-phony-regexp nil t)
        (setq tasks (push (symbol-name (symbol-at-point)) phony-tasks)))
      (kill-current-buffer))
    ;; Return tasks
    tasks
    )
  )

(defun taskrunner--cmake-tasks (dir)
  "Retrieve tasks for the CMake build system from the project in directory DIR.
Since the Makefile generated by CMake can be in several different places, first
the directory provided is checked.  If it is not present there, then attempt to
check for a directory called 'build' or 'Build'.  If those are not present then
the fallback behaviour is to ask the user to specify the directory."
  (let ((dir-files (directory-files dir))
        )
    (cond
     ((member "build" dir-files)
      (taskrunner--make-get-phony-tasks (concat dir "build")))
     ((member "Build" dir-files)
      (taskrunner--make-get-phony-tasks (concat dir "Build")))
     )
    )
  )

(provide 'taskrunner-clang)
