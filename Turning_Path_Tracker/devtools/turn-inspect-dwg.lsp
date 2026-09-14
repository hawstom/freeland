;;; turn-inspect-dwg.lsp - Read a user's drawing with ObjectDBX and report
;;; everything that bears on a TURN support question. Opens nothing, changes
;;; nothing.
;;;
;;; Cheap facts are written first and the expensive full census last, so a slow
;;; or failed pass still leaves the answer on disk.
(vl-load-com)

(setq
  *turn-tool-inspect-dwg* (turn-test-src "user_help/Kenya_Caldwell/Kenya-Caldwell-test-1.dwg")
  *turn-tool-inspect-log* (turn-test-src "user_help/Kenya_Caldwell/dwg-analysis.md")
)

(defun turn-tool-inspect-note (s / f)
  (setq f (open *turn-tool-inspect-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun turn-tool-inspect-dbx (/ doc v)
  (setq v 16)
  (while (and (not doc) (< v 30))
    (setq
      doc
       (vl-catch-all-apply
         'vla-getinterfaceobject
         (list (vlax-get-acad-object) (strcat "ObjectDBX.AxDbDocument." (itoa v)))
       )
    )
    (if (vl-catch-all-error-p doc) (setq doc nil))
    (setq v (1+ v))
  )
  doc
)

;; Attributes of one insert as ("TAG" . "value"), or nil.
(defun turn-tool-inspect-attributes (o)
  (if (= :vlax-true (vla-get-hasattributes o))
    (mapcar
      '(lambda (a) (cons (strcase (vla-get-tagstring a)) (vla-get-textstring a)))
      (vlax-safearray->list (vlax-variant-value (vla-getattributes o)))
    )
  )
)

;; The vehicle blocks, reported in full. This is the answer to the support
;; question, so it runs before anything expensive.
(defun turn-tool-inspect-vehicles (dbx / atts n)
  (turn-tool-inspect-note "## Vehicle blocks and their stored dimensions")
  (turn-tool-inspect-note "")
  (setq n 0)
  (vlax-for o (vla-get-modelspace dbx)
    (if (= "AcDbBlockReference" (vla-get-objectname o))
      (progn
        (setq atts (turn-tool-inspect-attributes o))
        (if (assoc "VEHWHEELBASE" atts)
          (progn
            (setq n (1+ n))
            (turn-tool-inspect-note (strcat "### " (vla-get-name o)))
            (turn-tool-inspect-note
              (strcat "rotation " (rtos (* 180.0 (/ (vla-get-rotation o) pi)) 2 4)
                      " deg, layer " (vla-get-layer o)
                      ", scale " (rtos (vla-get-xscalefactor o) 2 4))
            )
            (turn-tool-inspect-note "")
            (turn-tool-inspect-note "| tag | value |")
            (turn-tool-inspect-note "|---|---|")
            (foreach a atts (turn-tool-inspect-note (strcat "| " (car a) " | " (cdr a) " |")))
            (turn-tool-inspect-note "")
          )
        )
      )
    )
  )
  (turn-tool-inspect-note (strcat "vehicle blocks found: " (itoa n)))
  (turn-tool-inspect-note "")
)

(defun turn-tool-inspect-layers (dbx)
  (turn-tool-inspect-note "## Layers whose name mentions TURN")
  (turn-tool-inspect-note "")
  (turn-tool-inspect-note "| layer | colour | on | frozen | locked |")
  (turn-tool-inspect-note "|---|---|---|---|---|")
  (vlax-for lay (vla-get-layers dbx)
    (if (wcmatch (strcase (vla-get-name lay)) "*TURN*")
      (turn-tool-inspect-note
        (strcat "| " (vla-get-name lay)
                " | " (itoa (vla-get-color lay))
                " | " (if (= :vlax-true (vla-get-layeron lay)) "on" "**OFF**")
                " | " (if (= :vlax-true (vla-get-freeze lay)) "**FROZEN**" "no")
                " | " (if (= :vlax-true (vla-get-lock lay)) "**LOCKED**" "no")
                " |")
      )
    )
  )
  (turn-tool-inspect-note "")
)

;; Object counts on TURN layers only - cheaper and more relevant than a census
;; of a 7 MB civil drawing.
(defun turn-tool-inspect-turn-counts (dbx / key out)
  (turn-tool-inspect-note "## Objects on TURN layers")
  (turn-tool-inspect-note "")
  (vlax-for o (vla-get-modelspace dbx)
    (if (wcmatch (strcase (vla-get-layer o)) "*TURN*")
      (progn
        (setq key (strcat (vla-get-layer o) " | " (vla-get-objectname o)))
        (if (assoc key out)
          (setq out (subst (cons key (1+ (cdr (assoc key out)))) (assoc key out) out))
          (setq out (cons (cons key 1) out))
        )
      )
    )
  )
  (turn-tool-inspect-note "| layer | type | count |")
  (turn-tool-inspect-note "|---|---|---|")
  (foreach c (vl-sort out '(lambda (a b) (< (car a) (car b))))
    (turn-tool-inspect-note (strcat "| " (car c) " | " (itoa (cdr c)) " |"))
  )
  (turn-tool-inspect-note "")
)

(defun turn-tool-inspect-step (label fn dbx / err)
  (setq err (vl-catch-all-apply fn (list dbx)))
  (if (vl-catch-all-error-p err)
    (turn-tool-inspect-note (strcat "!! " label " failed: " (vl-catch-all-error-message err)))
  )
  (princ)
)

(defun turn-tool-inspect-run (dwg log / dbx err f units)
  (setq *turn-tool-inspect-dwg* dwg *turn-tool-inspect-log* log)
  (setq f (open *turn-tool-inspect-log* "w"))
  (close f)
  (turn-tool-inspect-note (strcat "# Analysis of " dwg))
  (turn-tool-inspect-note "")
  (turn-tool-inspect-note "- about to create the ObjectDBX document")
  (setq dbx (turn-tool-inspect-dbx))
  (turn-tool-inspect-note (strcat "- dbx object: " (vl-princ-to-string (type dbx))))
  (turn-tool-inspect-note "- about to vla-open the drawing")
  (setq err (vl-catch-all-apply 'vla-open (list dbx *turn-tool-inspect-dwg*)))
  (turn-tool-inspect-note "- vla-open returned")
  (cond
    ((vl-catch-all-error-p err)
     (turn-tool-inspect-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
    )
    (t
     ;; AxDbDocument does not expose every AcadDocument property - insunits
     ;; among them - so ask for it inside a catch rather than assume.
     (setq units (vl-catch-all-apply (quote vla-get-insunits) (list dbx)))
     (turn-tool-inspect-note
       (strcat "opened ok.  INSUNITS = "
               (if (vl-catch-all-error-p units) "not available on a DBX document" (vl-princ-to-string units)))
     )
     (turn-tool-inspect-note "")
     (turn-tool-inspect-step "vehicles" 'turn-tool-inspect-vehicles dbx)
     (turn-tool-inspect-step "layers" 'turn-tool-inspect-layers dbx)
     (turn-tool-inspect-step "counts" 'turn-tool-inspect-turn-counts dbx)
    )
  )
  (turn-tool-inspect-note "ANALYSIS COMPLETE")
  (princ)
)
(princ "\nturn-inspect-dwg.lsp loaded.")
(princ)
