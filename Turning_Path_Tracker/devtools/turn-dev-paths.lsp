;;; turn-dev-paths.lsp - where everything is, derived, never typed.
;;;
;;; Loaded as the first line of every .scr in this folder. It is the ONE place
;;; that knows the layout, and it does not know where the project lives: the
;;; TURNDEV environment variable is set by turn-tests.bat from %~dp0, so the
;;; whole tree can be cloned anywhere by anyone and the tests still run.
;;;
;;; The .scr line that loads this file is therefore the only one that mentions
;;; getenv. Everything after it says (turn-test-dev "x.lsp") or (turn-test-src "turn.lsp").
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
  *turn-test-dir*  (strcat (getenv "TURNDEV") "/")
  ;; Turning_Path_Tracker/ - the trunk: turn.lsp and its two .dat files
  *turn-test-root* (strcat (getenv "TURNDEV") "/../")
  ;; hawsedc.com/gnu/ - what users actually download
  *turn-test-gnu*  (strcat (getenv "TURNDEV") "/../hawsedc.com/gnu/")
)

(defun turn-test-dev (f) (strcat *turn-test-dir* f))
(defun turn-test-src (f) (strcat *turn-test-root* f))
(defun turn-test-gnu (f) (strcat *turn-test-gnu* f))

;;; ---------------------------------------------------------------------------
;;; TRUSTEDPATHS
;;;
;;; AutoCAD refuses to load LISP from an untrusted folder with a modal dialog,
;;; which hangs a /b script forever. So the tree has to be trusted. Two traps,
;;; both of which have already bitten:
;;;
;;; 1. TRUSTEDPATHS IS SAVED IN THE PROFILE, NOT THE SESSION. Appending to it
;;;    unconditionally adds three entries on EVERY run. That is how Tom's Civil
;;;    3D trusted locations became a mess he had to clean out by hand.
;;; 2. Deduplicating on the raw string is not enough. "…\devtools" and
;;;    "…\devtools/../devtools/" are the same folder and compare unequal, so an
;;;    entry that is already there gets added again in a different spelling.
;;;
;;; Hence: normalise to a canonical form - backslashes, ".." resolved, no
;;; trailing slash - then add only what is genuinely absent.
;;; ---------------------------------------------------------------------------

(defun turn-test-split (s delim / c i out piece)
  (setq i 1 piece "" out nil)
  (while (<= i (strlen s))
    (setq c (substr s i 1))
    (if (= c delim)
      (setq out (cons piece out) piece "")
      (setq piece (strcat piece c))
    )
    (setq i (1+ i))
  )
  (reverse (cons piece out))
)

(defun turn-test-join (lst delim / out)
  (if lst
    (progn
      (setq out (car lst))
      (foreach s (cdr lst) (setq out (strcat out delim s)))
      out
    )
    ""
  )
)

;; "C:/a/b/../c/" -> "C:\a\c"
(defun turn-test-normalize (path / parts stack)
  (setq parts (turn-test-split (vl-string-translate "/" "\\" path) "\\") stack nil)
  (foreach p parts
    (cond
      ((or (= p "") (= p ".")) nil)
      ((= p "..") (setq stack (cdr stack)))
      (t (setq stack (cons p stack)))
    )
  )
  (turn-test-join (reverse stack) "\\")
)

(defun turn-test-trust (path / canon current found)
  (setq
    canon (turn-test-normalize path)
    current (getvar "TRUSTEDPATHS")
    found nil
  )
  (foreach one (turn-test-split current ";")
    (if (= (strcase (turn-test-normalize one)) (strcase canon)) (setq found T))
  )
  (if (not found)
    (setvar "TRUSTEDPATHS"
      (if (= "" current) canon (strcat current ";" canon))
    )
  )
)

(foreach p (list *turn-test-dir* *turn-test-root* *turn-test-gnu*) (turn-test-trust p))

;;; ---------------------------------------------------------------------------
;;; Quitting
;;;
;;; THE "SAVE CHANGES?" PROMPT ON QUIT IS A MODAL TASK DIALOG, not a command
;;; line prompt, and FILEDIA does not change that. No script line can answer it:
;;; a `quit` followed by `y` or by `n` both leave AutoCAD sitting there forever
;;; holding the process. Tom found a session parked exactly there.
;;;
;;; The only reliable exit is to leave the drawing SAVED, so QUIT has nothing to
;;; ask about. Every .scr therefore ends with two lines:
;;;
;;;     (turn-test-safe-quit)
;;;     quit
;;;
;;; THE QUIT IS A SCRIPT LINE, NOT PART OF THE LISP. Calling (command "._quit")
;;; from inside a function tears the interpreter down mid-call and logs a
;;; spurious "Function cancelled" every run - noise that would hide a real
;;; error. So the LISP only makes quitting safe; the script does the quitting.
;;; ---------------------------------------------------------------------------
(defun turn-test-safe-quit (/ scratch)
  ;; Only save if there is something to save. A suite that ended in turn-test-finish
  ;; has already written its drawing, leaving DBMOD 0; saving again over the
  ;; file that IS the current drawing fails and logs a spurious "Function
  ;; cancelled", which is exactly the kind of noise that hides a real error.
  (if (/= 0 (getvar "DBMOD"))
    (progn
      (setq scratch (strcat *turn-test-dir* "turn-scratch.dwg"))
      (vl-file-delete scratch)
      ;; SAVEAS rather than QSAVE: it takes a name whether or not the drawing
      ;; already has one. "" accepts the default file format.
      (command "._saveas" "" scratch)
    )
  )
  (princ)
)

(princ)
