;;; turn-tool-trust-prune.lsp - remove dead FreeLand entries from TRUSTEDPATHS.
;;;
;;; TRUSTEDPATHS is saved in the AutoCAD profile, so folders the harness once
;;; trusted outlive the folders themselves: Turning_Path_Tracker/src (removed
;;; 2026-09-13) and Turning_Path_Tracker/hawsedc.com/gnu (moved to the freeland
;;; root 2026-09-27). This removes every entry that lies inside the freeland
;;; tree and no longer exists on disk. Entries outside the tree are never
;;; touched, whatever state they are in.
;;;
;;; Run once per product:  devtools\turn-tests.bat turn-tool-trust-prune [c3d|acad|2024]
;;; Writes turn-tool-trust-prune.md with the list before and after.
;;;
;;; A tool. Never ships.

;; T if PATH is the freeland root or lies below it. A sibling such as
;; freeland2 shares the prefix and is not inside.
(defun turn-tool-trust-inside-p (path freeland / canon)
  (setq canon (strcase (turn-test-normalize path)))
  (and (= freeland (substr canon 1 (strlen freeland)))
       (member (substr canon (1+ (strlen freeland)) 1) '("" "\\")))
)

(defun turn-tool-trust-prune-run (log / f freeland keep removed)
  (setq freeland (strcase (turn-test-normalize (strcat *turn-test-root* ".."))))
  (foreach one (turn-test-split (getvar "TRUSTEDPATHS") ";")
    ;; "\..." is AutoCAD's "and every folder below", not a folder name, so
    ;; such an entry cannot be tested for existence and is always kept.
    (if (and (not (vl-string-search "..." one))
             (turn-tool-trust-inside-p one freeland)
             (not (vl-file-directory-p (turn-test-normalize one))))
      (setq removed (cons one removed))
      (setq keep (cons one keep))
    )
  )
  (setq f (open log "w"))
  (write-line (strcat "# TRUSTEDPATHS prune, AutoCAD " (getvar "acadver") " profile " (getvar "cprofile")) f)
  (write-line "" f)
  (write-line (strcat "freeland root: `" freeland "`") f)
  (write-line "" f)
  (write-line "## Removed (inside freeland, no longer on disk)" f)
  (foreach r (reverse removed) (write-line (strcat "- `" r "`") f))
  (if (null removed) (write-line "- none" f))
  (write-line "" f)
  (write-line "## Kept" f)
  (foreach k (reverse keep) (write-line (strcat "- `" k "`") f))
  (close f)
  (if removed (setvar "TRUSTEDPATHS" (turn-test-join (reverse keep) ";")))
  (princ)
)
