;;; turn-probe-sci.lsp - how does AutoLISP read scientific notation?
;;;
;;; turn-drive-tests.lsp failed with "bad function: 5.0" on a line whose only
;;; unusual token was the tolerance 1e-9. Parens checked out, so the reader is
;;; the suspect. Reason about it and you get a plausible story; probe it and you
;;; get the answer.

(setq *turn-probe-sci-log* (strcat *turn-test-dir* "turn-probe-sci.md"))

(defun turn-probe-sci-say (s / f)
  (setq f (open *turn-probe-sci-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun turn-probe-sci-show (label form / r)
  (setq r (vl-catch-all-apply '(lambda () (eval form))))
  (turn-probe-sci-say
    (strcat "- `" label "` -> "
      (if (vl-catch-all-error-p r)
        (strcat "ERROR: " (vl-catch-all-error-message r))
        (strcat "type " (vl-princ-to-string (type r))
                ", value " (vl-princ-to-string r))
      )
    )
  )
)

(defun turn-probe-sci-run ()
  (vl-file-delete *turn-probe-sci-log*)
  (turn-probe-sci-say "# How AutoLISP reads scientific notation")
  (turn-probe-sci-say "")
  (turn-probe-sci-show "1e-9" (read "1e-9"))
  (turn-probe-sci-show "1.0e-9" (read "1.0e-9"))
  (turn-probe-sci-show "1E-9" (read "1E-9"))
  (turn-probe-sci-show "1e9" (read "1e9"))
  (turn-probe-sci-show "0.000000001" (read "0.000000001"))
  (turn-probe-sci-say "")
  (turn-probe-sci-say "How a whole call reads, which is what actually broke:")
  (turn-probe-sci-show "(list 5.0 1e-9) read as a list" (read "(list 5.0 1e-9)"))
  (turn-probe-sci-say (strcat "- `(list 5.0 1e-9)` reads to: "
                   (vl-princ-to-string (read "(list 5.0 1e-9)"))))
  (turn-probe-sci-say (strcat "- `(f \"a\" 5.0 x 1e-9)` reads to: "
                   (vl-princ-to-string (read "(f \"a\" 5.0 x 1e-9)"))))
  (turn-probe-sci-say (strcat "- `(f \"a\" 5.0 x 1.0e-9)` reads to: "
                   (vl-princ-to-string (read "(f \"a\" 5.0 x 1.0e-9)"))))
  (princ)
)
