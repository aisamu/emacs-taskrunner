;;; taskrunner-clang.el --- Provide functions to retrieve c/c++ build system targets -*- lexical-binding: t; -*-
;; Copyright (C) 2019 Yavor Konstantinov

(require 'projectile)

;;;; Constants
(defconst taskrunner--make-phony-target-regexp "^\.[[:space:]]*PHONY[[:space:]]*:[[:space:]]*"
  "Regular expression used to locate all PHONY targets in makefile.")

(defconst taskrunner--make-non-phony-target-regexp "^[1-9a-zA-Z_/\\-]+[[:space:]]*:"
  "Regular expression used to locate all Makefile targets which are not PHONY.")

(defconst taskrunner--cmake-warning
  "Taskrunner: Detected CMake build system but no build folder or Makefile were found! Please setup
CMake for either insource or outsource build and then call emacs-taskrunner again!"
  "A warning string used to indicate that a CMake project was detected but no
build folder or makefile was found.")

;;;; Functions
(defun taskrunner--make-get-non-phony-targets ()
  "Retrieve all non-phony Makefile targets from the current buffer.
That is, retrieve all targets which do not start with PHONY."
  (interactive)
  (fundamental-mode)
  (goto-line 1)
  (let ((target-list '()))
    (while (search-forward-regexp taskrunner--make-non-phony-target-regexp nil t)
      (taskrunner--narrow-to-line)
      (push (concat "MAKE" " " (car (split-string (buffer-string) ":"))) target-list)
      (widen)
      )
    target-list
    )
  )

(defun taskrunner--make-get-phony-targets ()
"Retrieve all PHONY Makefile targets from the current buffer.
The targets retrieved are every line of the form `.PHONY'."
(interactive)
(fundamental-mode)
(let ((target-list '()))
  (goto-line 1)
  (text-mode)
  (while (search-forward-regexp taskrunner--make-phony-target-regexp nil t)
    (taskrunner--narrow-to-line)
    (push
     (concat "MAKE" " " (string-trim (cadr (split-string (buffer-string) ":")))) target-list)
    (widen)
    )
  target-list
  )
)

(provide 'taskrunner-clang)
;;; taskrunner-clang.el ends here
