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

(defun tt-split (s delim / c i out piece)
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

(defun tt-join (lst delim / out)
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
(defun tt-normalize (path / parts stack)
  (setq parts (tt-split (vl-string-translate "/" "\\" path) "\\") stack nil)
  (foreach p parts
    (cond
      ((or (= p "") (= p ".")) nil)
      ((= p "..") (setq stack (cdr stack)))
      (t (setq stack (cons p stack)))
    )
  )
  (tt-join (reverse stack) "\\")
)

(defun tt-trust (path / canon current found)
  (setq
    canon (tt-normalize path)
    current (getvar "TRUSTEDPATHS")
    found nil
  )
  (foreach one (tt-split current ";")
    (if (= (strcase (tt-normalize one)) (strcase canon)) (setq found T))
  )
  (if (not found)
    (setvar "TRUSTEDPATHS"
      (if (= "" current) canon (strcat current ";" canon))
    )
  )
)

(foreach p (list *tt-dir* *tt-root* *tt-gnu*) (tt-trust p))

;;; ---------------------------------------------------------------------------
;;; Quitting
;;;
;;; THE "SAVE CHANGES?" PROMPT ON QUIT IS A MODAL TASK DIALOG, not a command
;;; line prompt, and FILEDIA does not change that. No script line can answer it:
;;; a `quit` followed by `y` or by `n` both leave AutoCAD sitting there forever
;;; holding the process. Tom found a session parked exactly there.
;;;
;;; The only reliable exit is to leave the drawing SAVED, so QUIT has nothing to
;;; ask about. Every .scr ends with (tt-safe-quit).
;;; ---------------------------------------------------------------------------
(defun tt-safe-quit (/ scratch)
  (setq scratch (strcat *tt-dir* "turn-scratch.dwg"))
  (vl-file-delete scratch)
  ;; SAVEAS rather than QSAVE: it takes a name whether or not the drawing
  ;; already has one, so this behaves the same however the run got here.
  ;; "" accepts the default file format.
  (command "._saveas" "" scratch)
  (command "._quit")
  (princ)
)

(princ)
