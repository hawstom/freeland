;;; turn-probe-sci.lsp - how does AutoLISP read scientific notation?
;;;
;;; turn-drive-tests.lsp failed with "bad function: 5.0" on a line whose only
;;; unusual token was the tolerance 1e-9. Parens checked out, so the reader is
;;; the suspect. Reason about it and you get a plausible story; probe it and you
;;; get the answer.

(setq *sci-log* (strcat *tt-dir* "turn-probe-sci.md"))

(defun sci-say (s / f)
  (setq f (open *sci-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun sci-show (label form / r)
  (setq r (vl-catch-all-apply '(lambda () (eval form))))
  (sci-say
    (strcat "- `" label "` -> "
      (if (vl-catch-all-error-p r)
        (strcat "ERROR: " (vl-catch-all-error-message r))
        (strcat "type " (vl-princ-to-string (type r))
                ", value " (vl-princ-to-string r))
      )
    )
  )
)

(defun sci-run ()
  (vl-file-delete *sci-log*)
  (sci-say "# How AutoLISP reads scientific notation")
  (sci-say "")
  (sci-show "1e-9" (read "1e-9"))
  (sci-show "1.0e-9" (read "1.0e-9"))
  (sci-show "1E-9" (read "1E-9"))
  (sci-show "1e9" (read "1e9"))
  (sci-show "0.000000001" (read "0.000000001"))
  (sci-say "")
  (sci-say "How a whole call reads, which is what actually broke:")
  (sci-show "(list 5.0 1e-9) read as a list" (read "(list 5.0 1e-9)"))
  (sci-say (strcat "- `(list 5.0 1e-9)` reads to: "
                   (vl-princ-to-string (read "(list 5.0 1e-9)"))))
  (sci-say (strcat "- `(f \"a\" 5.0 x 1e-9)` reads to: "
                   (vl-princ-to-string (read "(f \"a\" 5.0 x 1e-9)"))))
  (sci-say (strcat "- `(f \"a\" 5.0 x 1.0e-9)` reads to: "
                   (vl-princ-to-string (read "(f \"a\" 5.0 x 1.0e-9)"))))
  (princ)
)
