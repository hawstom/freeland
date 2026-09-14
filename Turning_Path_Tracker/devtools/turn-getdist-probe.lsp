;;; turn-getdist-probe.lsp - Does BUILDVEHICLE's getdist prompt accept a
;;; negative number? TRAILERFRONTHANG and VEHREARHITCH are both documented as
;;; "forward is NEGATIVE", so the answer decides what we can tell a user to type.
(setq *gp-log* (tt-dev "getdist-probe.md"))
(defun gp-note (s / f)
  (setq f (open *gp-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)
(defun gp-start (/ f)
  (setq f (open *gp-log* "w"))
  (close f)
  (gp-note "# Does getdist accept a negative?")
  (gp-note "")
  (princ)
)
;; Called from the script right after a value has been typed at the prompt.
(defun gp-report (label v)
  (gp-note
    (strcat "- " label ": returned " (vl-princ-to-string v)
            "  [type " (vl-princ-to-string (type v)) "]")
  )
)
(defun gp-done () (gp-note "") (gp-note "PROBE COMPLETE") (princ))
(princ "\nturn-getdist-probe.lsp loaded.")
(princ)
