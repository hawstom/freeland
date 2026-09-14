;;; turn-getdist-probe.lsp - Does BUILDVEHICLE's getdist prompt accept a
;;; negative number? TRAILERFRONTHANG and VEHREARHITCH are both documented as
;;; "forward is NEGATIVE", so the answer decides what we can tell a user to type.
(setq *turn-probe-getdist-log* (turn-test-dev "getdist-probe.md"))
(defun turn-probe-getdist-note (s / f)
  (setq f (open *turn-probe-getdist-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)
(defun turn-probe-getdist-start (/ f)
  (setq f (open *turn-probe-getdist-log* "w"))
  (close f)
  (turn-probe-getdist-note "# Does getdist accept a negative?")
  (turn-probe-getdist-note "")
  (princ)
)
;; Called from the script right after a value has been typed at the prompt.
(defun turn-probe-getdist-report (label v)
  (turn-probe-getdist-note
    (strcat "- " label ": returned " (vl-princ-to-string v)
            "  [type " (vl-princ-to-string (type v)) "]")
  )
)
(defun turn-probe-getdist-done () (turn-probe-getdist-note "") (turn-probe-getdist-note "PROBE COMPLETE") (princ))
(princ "\nturn-getdist-probe.lsp loaded.")
(princ)
