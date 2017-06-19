;;; helm-librarian.el --- Helm UI for searching in library sources.  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Nikita <CryptoManiac> Sivakov

;; Author: Nikita <CryptoManiac> Sivakov <cryptomaniac.512@gmail.com>
;; URL: https://gitlab.com/cryptomaniac/helm-librarian
;; Created: 2017-06-09
;; Version: 0.0.1
;; Package-Requires: ((helm "1.7.7") (cl-lib "0.3"))


;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library provides easy library search operations (grep/find).
;;
;;; Code:

(require 'cl-lib)
(require 'find-lisp)
(require 'helm)

(defun helm-librarian-source-grep ()
  "Helm grep in library sources."
  (interactive)
  (let* ((helm-grep-default-command "grep -a -r %e -n%cH -e %p %f.")
         (default-directory venv-current-dir)
         (helm-ff-default-directory default-directory)
         (helm-grep-default-recurse-command helm-grep-default-command))

    (setq helm-librarian-source-grep
          (helm-build-async-source "Librarian Grep"
            :candidates-process 'helm-grep-collect-candidates
            :filter-one-by-one 'helm-grep-filter-one-by-one
            :candidate-number-limit 9999
            :nohighlight t
            :keymap helm-grep-map
            :history 'helm-grep-history
            :action (apply #'helm-make-actions
                           '("Find file" helm-grep-action
                             "Find file other frame" helm-grep-other-frame
                             (lambda () (and (locate-library "elscreen")
                                             "Find file in Elscreen"))
                             helm-grep-jump-elscreen
                             "Save results in grep buffer" helm-grep-save-results
                             "Find file other window" helm-grep-other-window))
            :persistent-action 'helm-grep-persistent-action
            :requires-pattern 2))

    (helm
     :sources 'helm-librarian-source-grep
     :input (if (region-active-p)
                (buffer-substring-no-properties (region-beginning) (region-end))
              (thing-at-point 'symbol))
     :buffer "helm librarian grep"
     :default-directory default-directory
     :keymap helm-grep-map
     :history 'helm-grep-history
     :truncate-lines helm-grep-truncate-lines)))

(defun helm-librarian-file-persistent (candidate)
  "Previews the contents of a CANDIDATE in a temporary buffer."
  (let ((buf (get-buffer-create " *helm librarian persistent*")))
    (cl-flet ((preview (candidate)
                (switch-to-buffer buf)
                (setq inhibit-read-only t)
                (erase-buffer)
                (insert-file-contents candidate)
                (let ((buffer-file-name candidate))
                  (set-auto-mode))
                (font-lock-ensure)
                (setq inhibit-read-only nil)))
      (if (and (helm-attr 'previewp)
               (string= candidate (helm-attr 'current-candidate)))
          (progn
            (kill-buffer buf)
            (helm-attrset 'previewp nil))
        (preview candidate)
        (helm-attrset 'previewp t)))
    (helm-attrset 'current-candidate candidate)))

(defun librarian-source-find-files ()
  "Find files in library sources.."
  (cl-loop with root = venv-current-dir
     for display in (find-lisp-find-files root "")
     collect (cons display display)))

(defun helm-librarian-source-find ()
  "Helm find files in library sources."
  (interactive)
  (let ((venv-source-files (librarian-source-find-files)))

    (setq helm-librarian-source-files
          (helm-build-sync-source "Librarian files"
            :candidates librarian-source-files
            :persistent-action 'helm-librarian-file-persistent
            :mode-line helm-read-file-name-mode-line-string
            :keymap helm-find-files-map
            :fuzzy-match helm-locate-fuzzy-match
            :action helm-find-files-actions))

          (helm
           :sources 'helm-librarian-source-files
           :buffer "helm librarian find"
           :keymap helm-find-files-map
           :truncate-lines helm-truncate-lines
           :history 'helm-find-files-history)))

(provide 'helm-librarian)

;;; helm-librarian.el ends here
