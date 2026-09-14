;;; turn-release-smoke.lsp - Prove the SHIPPED file works, not just the source.
;;;
;;; turn-2.0.0.lsp in the website folder is a copy. A copy is where a stale or
;;; truncated release comes from, so load that exact file and check it reports
;;; the right version, defines both commands, and still tracks.

(setq *rs-log* (tt-dev "turn-release-smoke.md"))

(defun rs-say (s / f)
  (setq f (open *rs-log* "a"))
  (write-line s f)
  (close f)
  (princ (strcat "\n" s))
  (princ)
)

(defun rs-check (label ok)
  (rs-say (strcat (if ok "- PASS " "- **FAIL** ") label))
  (if ok 1 0)
)

;; A circle course, defined here rather than borrowed from turn-core-tests.lsp:
;; this test must load nothing but the shipped file.
(defun rs-circle (r n sweep / i out)
  (setq i -1)
  (repeat (1+ n)
    (setq i (1+ i) out (cons (polar '(0.0 0.0) (* sweep (/ (float i) n)) r) out))
  )
  (reverse out)
)

(defun rs-run (/ f n paths released vehicle)
  (setq f (open *rs-log* "w"))
  (close f)
  (rs-say "# Release smoke test: gnu/turn-2.0.0.lsp")
  (rs-say "")
  (setq
    released
     (tt-gnu "turn-2.0.0.lsp")
    n 0
  )
  (setq n (+ n (rs-check "the shipped file exists" (and (findfile released) t))))
  (load released)
  (setq n (+ n (rs-check "reports version 2.0.0"
                         (= "2.0.0" (wiki-turn-getvar "general.version")))))
  (setq n (+ n (rs-check "defines TURN" (and c:turn t))))
  (setq n (+ n (rs-check "defines BUILDVEHICLE" (and c:buildvehicle t))))
  (setq n (+ n (rs-check "defines the BV alias" (and c:bv t))))
  ;; A three segment rig still tracks, straight out of the shipped file.
  ;; Rig wheelbase = 19.5 + 0.0 hitch + 45.5 + 2.0 hitch + 30.0 = 97.0.
  (setq
    vehicle
     (list
       (wiki-turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0 0.0 0.0)
       (wiki-turn-segment "Trailer1" 45.5 8.5 53.0 8.5 3.0 2.0 0.0 0.0)
       (wiki-turn-segment "Trailer2" 30.0 8.5 40.0 8.5 3.0 nil 0.0 0.0)
     )
    paths (wiki-turn-path vehicle (rs-circle 120.0 400 (* 2 pi)) (/ pi 2))
  )
  (setq n (+ n (rs-check "a three segment rig yields three paths" (= 3 (length paths)))))
  (setq n (+ n (rs-check "course length and rig wheelbase are computable"
                         (and (< 0 (wiki-turn-course-length (car paths)))
                              (equal 97.0 (wiki-turn-rig-wheelbase vehicle) 0.001)))))
  (rs-say "")
  (rs-say (strcat "passed " (itoa n) " of 7"))
  (rs-say (if (= n 7) "" "**SOMETHING FAILED**"))
  (princ)
)

(princ "\nturn-release-smoke.lsp loaded. Run (rs-run).")
(princ)
