;;; turn-probe-initget.lsp - Does initget tolerate hyphenated keywords?
;;;
;;; The library keys are WB-67, S-BUS-36, A-BUS and friends. Moving the library
;;; prompt from getstring to getkword is only worth doing if initget accepts
;;; those verbatim - AutoLISP keyword lists are space delimited and the docs are
;;; silent about hyphens. Assume nothing; ask AutoCAD.
;;;
;;; getkword cannot be answered by a /b script without queued input, so this
;;; probe feeds answers through the script itself and records what came back.

(setq *pi-log* (tt-dev "turn-probe-initget.md"))

(defun pi-say (s / f)
  (setq f (open *pi-log* "a"))
  (write-line s f)
  (close f)
  (princ (strcat "\n" s))
  (princ)
)

(setq *pi-keys*
  '("A-BUS" "BUS-40" "BUS-45" "CITY-BUS" "MH" "MHB" "P" "PB" "PT"
    "S-BUS-36" "S-BUS-40" "SU" "WB-40" "WB-50" "WB-62" "WB-65" "WB-67")
)

;; The keyword string initget would be given.
(defun pi-keyword-string (keys / out)
  (setq out "")
  (foreach k keys (setq out (strcat out k " ")))
  (vl-string-trim " " out)
)

(defun pi-begin (/ f)
  (setq f (open *pi-log* "w"))
  (close f)
  (pi-say "# initget with hyphenated keywords")
  (pi-say "")
  (pi-say (strcat "Keyword string: `" (pi-keyword-string *pi-keys*) "`"))
  (pi-say "")
)

;; Call initget and report whether it errored at all.
(defun pi-test-initget (/ err)
  (setq err (vl-catch-all-apply 'initget (list (pi-keyword-string *pi-keys*))))
  (pi-say
    (if (vl-catch-all-error-p err)
      (strcat "- **initget REJECTED the list**: " (vl-catch-all-error-message err))
      "- PASS initget accepted the hyphenated keyword list"
    )
  )
  (not (vl-catch-all-error-p err))
)

;; Ask once. The answer comes from the next line of the .scr.
(defun pi-ask (label / got)
  (initget (pi-keyword-string *pi-keys*))
  (setq got (getkword (strcat "\nVehicle key <" (car *pi-keys*) ">: ")))
  (pi-say (strcat "- " label ": returned " (if got (strcat "\"" got "\"") "nil")))
  got
)

(princ "\nturn-probe-initget.lsp loaded.")
(princ)
