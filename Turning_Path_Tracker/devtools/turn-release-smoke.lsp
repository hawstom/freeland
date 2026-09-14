;;; turn-release-smoke.lsp - Prove the SHIPPED file works, not just the source.
;;;
;;; The file in the website folder is a copy. A copy is where a stale or
;;; truncated release comes from, so load that exact file and check it reports
;;; the right version, defines the commands, and still tracks.
;;;
;;; IT MUST SPEAK WHATEVER PREFIX THE PUBLISHED FILE USES, which is not always
;;; the one the trunk uses. The published 2.0.0 is `wiki-turn-*`; the trunk was
;;; consolidated to `turn-*` on 2026-09-14. A blind rename broke this test so
;;; that it stopped silently after its first check -- it still said PASS, just
;;; only once, and the summary line vanished. Resolving the name at run time is
;;; what makes the test survive its own project's renames, which is the whole
;;; job of a test that guards releases.

(setq *turn-test-smoke-log* (turn-test-dev "turn-release-smoke.md"))

(defun turn-test-smoke-say (s / f)
  (setq f (open *turn-test-smoke-log* "a"))
  (write-line s f)
  (close f)
  (princ (strcat "\n" s))
  (princ)
)

(defun turn-test-smoke-check (label ok)
  (turn-test-smoke-say (strcat (if ok "- PASS " "- **FAIL** ") label))
  (if ok 1 0)
)

;; Whichever of these the loaded file actually defines. Returns a symbol ready
;; for (apply), or nil with a FAIL logged, so a missing function is reported as
;; a failing check rather than aborting the run.
(defun turn-test-smoke-fn (base / bare prefixed)
  (setq
    bare (read (strcat "turn-" base))
    prefixed (read (strcat "wiki-turn-" base))
  )
  (cond
    ((eval bare) bare)
    ((eval prefixed) prefixed)
    (t (turn-test-smoke-check (strcat "the shipped file defines " base) nil) nil)
  )
)

(defun turn-test-smoke-call (base args / f)
  (if (setq f (turn-test-smoke-fn base)) (apply f args))
)

;; A circle course, defined here rather than borrowed from turn-core-tests.lsp:
;; this test must load nothing but the shipped file.
(defun turn-test-smoke-circle (r n sweep / i out)
  (setq i -1)
  (repeat (1+ n)
    (setq i (1+ i) out (cons (polar '(0.0 0.0) (* sweep (/ (float i) n)) r) out))
  )
  (reverse out)
)

(defun turn-test-smoke-run (/ f n paths released version vehicle)
  (setq f (open *turn-test-smoke-log* "w"))
  (close f)
  (setq n 0)

  ;; Whatever is published, found by name rather than assumed. A release that
  ;; renamed the file and forgot to say so should fail here, loudly.
  (setq released (turn-test-smoke-published))
  (turn-test-smoke-say
    (strcat "# Release smoke test: "
            (if released (turn-test-smoke-basename released) "**nothing published**")))
  (turn-test-smoke-say "")
  (setq n (+ n (turn-test-smoke-check "a shipped file exists" (and released t))))

  (if (not released)
    (progn (turn-test-smoke-say "") (turn-test-smoke-say "**NOTHING TO TEST**") (princ))
    (progn
      (load released)
      (setq version (turn-test-smoke-call "getvar" '("general.version")))
      (turn-test-smoke-say (strcat "- loaded version `" (vl-princ-to-string version) "`"))
      (setq n (+ n (turn-test-smoke-check "the version is in the file name"
                     (and version (vl-string-search version released)))))
      (setq n (+ n (turn-test-smoke-check "defines TURN" (and c:turn t))))
      (setq n (+ n (turn-test-smoke-check "defines BUILDVEHICLE" (and c:buildvehicle t))))
      (setq n (+ n (turn-test-smoke-check "defines the BV alias" (and c:bv t))))

      ;; A three segment rig still tracks, straight out of the shipped file.
      ;; Rig wheelbase = 19.5 + 0.0 hitch + 45.5 + 2.0 hitch + 30.0 = 97.0.
      (setq
        vehicle
         (list
           (turn-test-smoke-call "segment" '("Tractor" 19.5 8.0 27.92 8.0 4.0 0.0 0.0 0.0))
           (turn-test-smoke-call "segment" '("Trailer1" 45.5 8.5 53.0 8.5 3.0 2.0 0.0 0.0))
           (turn-test-smoke-call "segment" '("Trailer2" 30.0 8.5 40.0 8.5 3.0 nil 0.0 0.0))
         )
        paths (turn-test-smoke-call
                "path"
                (list vehicle (turn-test-smoke-circle 120.0 400 (* 2 pi)) (/ pi 2)))
      )
      (setq n (+ n (turn-test-smoke-check "a three segment rig yields three paths"
                     (= 3 (length paths)))))
      (setq n (+ n (turn-test-smoke-check "course length and rig wheelbase are computable"
                     (and (< 0 (turn-test-smoke-call "course-length" (list (car paths))))
                          (equal 97.0 (turn-test-smoke-call "rig-wheelbase" (list vehicle))
                                 0.001)))))
      (turn-test-smoke-say "")
      (turn-test-smoke-say (strcat "passed " (itoa n) " of 7"))
      (turn-test-smoke-say (if (= n 7) "" "**SOMETHING FAILED**"))
    )
  )
  (princ)
)

;; The newest turn-<version>.lsp in the website folder, by version number.
;; Asked for rather than hardcoded, so the test follows the release instead of
;; having to be edited alongside it.
(defun turn-test-smoke-published (/ best files)
  (setq files (vl-directory-files (turn-test-gnu "") "turn-*.lsp" 1))
  (foreach f files
    (if (or (null best) (> (turn-test-smoke-version-key f)
                           (turn-test-smoke-version-key best)))
      (setq best f)
    )
  )
  (if best (turn-test-gnu best))
)

;; "turn-2.0.0.lsp" -> 2000000, so a plain numeric comparison orders releases.
(defun turn-test-smoke-version-key (name / bits n total)
  (setq
    bits (turn-test-smoke-split (vl-string-subst "" ".lsp" (substr name 6)) ".")
    total 0
  )
  (foreach b bits
    (setq
      n (atoi b)
      total (+ (* total 1000) n)
    )
  )
  total
)

(defun turn-test-smoke-split (s delim / c i out piece)
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

(defun turn-test-smoke-basename (path / i out)
  (setq i (strlen path) out path)
  (while (and (> i 0) (/= "\\" (substr path i 1)) (/= "/" (substr path i 1)))
    (setq i (1- i))
  )
  (if (> i 0) (substr path (1+ i)) path)
)

(princ "\nturn-release-smoke.lsp loaded. Run (turn-test-smoke-run).")
(princ)
