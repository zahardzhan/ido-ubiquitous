;;; ido-ubiquitous.el --- Use ido (nearly) everywhere.

;; Author: Ryan C. Thompson
;; URL: http://www.emacswiki.org/emacs/InteractivelyDoThings#toc13
;; Version: 0.2
;; Created: 2011-09-01
;; Keywords: convenience
;; EmacsWiki: InteractivelyDoThings

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; You may have seen the `ido-everywhere' variable in ido.el and got
;; excited that you could use ido completion for everything. Then you
;; were probably disappointed when you realized that it only applied
;; to *file names* and nothing else. Well, ido-ubiquitous is here to
;; fulfill the original promise and let you use ido completion for
;; (almost) any command that uses `completing-read' to offer you a
;; choice of several alternatives.

;; One place where this package *doesn't* work is the completion
;; offered by "M-x" (that is, the `execute-extended-command'
;; function). If you want ido-style completion for "M-x", you should
;; install the "smex" package.

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

;;; Code:

(require 'ido)

;;;###autoload
(defgroup ido-ubiquitous nil
  "Use ido for (almost) all completion."
  :group 'ido)

;;;###autoload
(define-minor-mode ido-ubiquitous
  "Use `ido-completing-read' instead of `completing-read' almost everywhere.

  This mode has no effect unles `ido-mode' is also enabled.

  If this mode causes problems for a function, you can force the
  function to use the original completing read by using the macro
  `disable-ido-ubiquitous-in'. For example, if a
  function `foo' cannot work with ido-style completion, evaluate
  the following (for example by putting it in your .emacs file):

    (disable-ido-ubiquitous-in foo)"

  nil
  :global t
  :group 'ido-ubiquitous)

;;;###autoload
(defcustom ido-ubiquitous-exceptions '(grep-read-files)
  "List of commands that should not be affected by `ido-ubiquitous'.

Even when `ido-ubiquitous' mode is enabled, these commands will
continue to use `completing-read' instead of
`ido-completing-read'."
  :type '(repeat symbol)
  :group 'ido-ubiquitous)

(defadvice completing-read (around ido-ubiquitous activate)
  (if (or (not ido-mode)
          (not ido-ubiquitous)
          (memq this-command ido-ubiquitous-exceptions)
          ;; Avoid infinite recursion from ido calling completing-read
          (boundp 'ido-cur-item))
      ad-do-it
    (let ((allcomp (all-completions "" collection predicate)))
      ;; Only use ido completion if there are actually any completions to offer.
      (if allcomp
          (setq ad-return-value
                (ido-completing-read prompt allcomp
                                     nil require-match initial-input hist def))
        ad-do-it))))

(defmacro disable-ido-ubiquitous-in (func)
  "Disable ido-ubiquitous in FUNC."
  `(defadvice ,func (around disable-ido-ubiquitous activate)
     (let (ido-ubiquitous) ad-do-it)))

(defmacro enable-ido-ubiquitous-in (func)
  "Re-enable ido-ubiquitous in FUNC.

  This reverses the effect of `disable-ido-ubiquitous-in'."
  ;; In my experience, simply using `ad-remove-advice' or
  ;; `ad-disable-advice' doesn't work correctly (in Emacs 23).
  ;; Instead, I've found that one must redefine the advice under the
  ;; same name ("disable-ido-ubiquitous") to simply call the original
  ;; function with no modifications. This has the same effect
  ;; (disables the advice), but is presumably less efficient.
  `(defadvice ,func (around disable-ido-ubiquitous activate)
     ad-do-it))

;; Disable ido-ubiquitous in `find-file' and similar functions,
;; because they are not supposed to use ido.
(disable-ido-ubiquitous-in read-file-name)

(provide 'ido-ubiquitous) ;;; ido-ubiquitous.el ends here
