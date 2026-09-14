;;; turn-dev-paths.lsp - where everything is, derived, never typed.
;;;
;;; Loaded as the first line of every .scr in this folder. It is the ONE place
;;; that knows the layout, and it does not know where the project lives: the
;;; TURNDEV environment variable is set by turn-tests.bat from %~dp0, so the
;;; whole tree can be cloned anywhere by anyone and the tests still run.
;;;
;;; The .scr line that loads this file is therefore the only one that mentions
;;; getenv. Everything after it says (tt-dev "x.lsp") or (tt-src "turn.lsp").
;;;
;;; Test scaffolding. None of it ships to users.

(if (not (getenv "TURNDEV"))
  (progn
    (princ "\nFATAL: TURNDEV is not set. Run these scripts through turn-tests.bat.")
    (exit)
  )
)

(setq
  ;; devtools/ - the harness, the probes, the logs
  *tt-dir*  (strcat (getenv "TURNDEV") "/")
  ;; Turning_Path_Tracker/ - the trunk: turn.lsp and its two .dat files
  *tt-root* (strcat (getenv "TURNDEV") "/../")
  ;; hawsedc.com/gnu/ - what users actually download
  *tt-gnu*  (strcat (getenv "TURNDEV") "/../hawsedc.com/gnu/")
)

(defun tt-dev (f) (strcat *tt-dir* f))
(defun tt-src (f) (strcat *tt-root* f))
(defun tt-gnu (f) (strcat *tt-gnu* f))

;;; AutoCAD refuses to load LISP from an untrusted folder with a modal dialog,
;;; which hangs a /b script forever. Trust our own tree, once, here.
(setvar "TRUSTEDPATHS"
  (strcat (getvar "TRUSTEDPATHS") ";" *tt-dir* ";" *tt-root* ";" *tt-gnu*)
)
(princ)
