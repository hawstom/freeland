;;; turn-inspect-dwg.lsp - Read a user's drawing with ObjectDBX and report
;;; everything that bears on a TURN support question. Opens nothing, changes
;;; nothing.
;;;
;;; Cheap facts are written first and the expensive full census last, so a slow
;;; or failed pass still leaves the answer on disk.
(vl-load-com)

(setq
  *ti-dwg* (tt-src "user_help/Kenya_Caldwell/Kenya-Caldwell-test-1.dwg")
  *ti-log* (tt-src "user_help/Kenya_Caldwell/dwg-analysis.md")
)

(defun ti-note (s / f)
  (setq f (open *ti-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun ti-dbx (/ doc v)
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
(defun ti-attributes (o)
  (if (= :vlax-true (vla-get-hasattributes o))
    (mapcar
      '(lambda (a) (cons (strcase (vla-get-tagstring a)) (vla-get-textstring a)))
      (vlax-safearray->list (vlax-variant-value (vla-getattributes o)))
    )
  )
)

;; The vehicle blocks, reported in full. This is the answer to the support
;; question, so it runs before anything expensive.
(defun ti-vehicles (dbx / atts n)
  (ti-note "## Vehicle blocks and their stored dimensions")
  (ti-note "")
  (setq n 0)
  (vlax-for o (vla-get-modelspace dbx)
    (if (= "AcDbBlockReference" (vla-get-objectname o))
      (progn
        (setq atts (ti-attributes o))
        (if (assoc "VEHWHEELBASE" atts)
          (progn
            (setq n (1+ n))
            (ti-note (strcat "### " (vla-get-name o)))
            (ti-note
              (strcat "rotation " (rtos (* 180.0 (/ (vla-get-rotation o) pi)) 2 4)
                      " deg, layer " (vla-get-layer o)
                      ", scale " (rtos (vla-get-xscalefactor o) 2 4))
            )
            (ti-note "")
            (ti-note "| tag | value |")
            (ti-note "|---|---|")
            (foreach a atts (ti-note (strcat "| " (car a) " | " (cdr a) " |")))
            (ti-note "")
          )
        )
      )
    )
  )
  (ti-note (strcat "vehicle blocks found: " (itoa n)))
  (ti-note "")
)

(defun ti-layers (dbx)
  (ti-note "## Layers whose name mentions TURN")
  (ti-note "")
  (ti-note "| layer | colour | on | frozen | locked |")
  (ti-note "|---|---|---|---|---|")
  (vlax-for lay (vla-get-layers dbx)
    (if (wcmatch (strcase (vla-get-name lay)) "*TURN*")
      (ti-note
        (strcat "| " (vla-get-name lay)
                " | " (itoa (vla-get-color lay))
                " | " (if (= :vlax-true (vla-get-layeron lay)) "on" "**OFF**")
                " | " (if (= :vlax-true (vla-get-freeze lay)) "**FROZEN**" "no")
                " | " (if (= :vlax-true (vla-get-lock lay)) "**LOCKED**" "no")
                " |")
      )
    )
  )
  (ti-note "")
)

;; Object counts on TURN layers only - cheaper and more relevant than a census
;; of a 7 MB civil drawing.
(defun ti-turn-counts (dbx / key out)
  (ti-note "## Objects on TURN layers")
  (ti-note "")
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
  (ti-note "| layer | type | count |")
  (ti-note "|---|---|---|")
  (foreach c (vl-sort out '(lambda (a b) (< (car a) (car b))))
    (ti-note (strcat "| " (car c) " | " (itoa (cdr c)) " |"))
  )
  (ti-note "")
)

(defun ti-step (label fn dbx / err)
  (setq err (vl-catch-all-apply fn (list dbx)))
  (if (vl-catch-all-error-p err)
    (ti-note (strcat "!! " label " failed: " (vl-catch-all-error-message err)))
  )
  (princ)
)

(defun ti-run (dwg log / dbx err f units)
  (setq *ti-dwg* dwg *ti-log* log)
  (setq f (open *ti-log* "w"))
  (close f)
  (ti-note (strcat "# Analysis of " dwg))
  (ti-note "")
  (ti-note "- about to create the ObjectDBX document")
  (setq dbx (ti-dbx))
  (ti-note (strcat "- dbx object: " (vl-princ-to-string (type dbx))))
  (ti-note "- about to vla-open the drawing")
  (setq err (vl-catch-all-apply 'vla-open (list dbx *ti-dwg*)))
  (ti-note "- vla-open returned")
  (cond
    ((vl-catch-all-error-p err)
     (ti-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
    )
    (t
     ;; AxDbDocument does not expose every AcadDocument property - insunits
     ;; among them - so ask for it inside a catch rather than assume.
     (setq units (vl-catch-all-apply (quote vla-get-insunits) (list dbx)))
     (ti-note
       (strcat "opened ok.  INSUNITS = "
               (if (vl-catch-all-error-p units) "not available on a DBX document" (vl-princ-to-string units)))
     )
     (ti-note "")
     (ti-step "vehicles" 'ti-vehicles dbx)
     (ti-step "layers" 'ti-layers dbx)
     (ti-step "counts" 'ti-turn-counts dbx)
    )
  )
  (ti-note "ANALYSIS COMPLETE")
  (princ)
)
(princ "\nturn-inspect-dwg.lsp loaded.")
(princ)
