;;; turn-inspect-plines.lsp - Census every polyline in a drawing by vertex count.
;;;
;;; A course a person drew has a handful of vertices. A path TURN computed has
;;; one per calculation step, typically hundreds. That difference tells us
;;; whether TURN drew anything in a drawing, and on which layer it landed.
(vl-load-com)

(defun turn-tool-plines-note (s / f)
  (setq f (open *turn-tool-plines-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun turn-tool-plines-dbx (/ doc v)
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

(defun turn-tool-plines-vertices (o / n)
  (setq n (vl-catch-all-apply 'vlax-safearray->list
                              (list (vlax-variant-value (vla-get-coordinates o)))))
  (if (vl-catch-all-error-p n) 0 (/ (length n) 2))
)

(defun turn-tool-plines-len (o / v)
  (setq v (vl-catch-all-apply 'vla-get-length (list o)))
  (if (vl-catch-all-error-p v) 0.0 v)
)

(defun turn-tool-plines-run (dwg log / dbx err n)
  (setq *turn-tool-plines-log* log)
  (setq f (open *turn-tool-plines-log* "w"))
  (close f)
  (turn-tool-plines-note (strcat "# Polyline census: " dwg))
  (turn-tool-plines-note "")
  (setq dbx (turn-tool-plines-dbx))
  (setq err (vl-catch-all-apply 'vla-open (list dbx dwg)))
  (cond
    ((vl-catch-all-error-p err)
     (turn-tool-plines-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
    )
    (t
     (turn-tool-plines-note "Every LWPOLYLINE in model space. Hundreds of vertices means TURN")
     (turn-tool-plines-note "computed it; a handful means a person drew it.")
     (turn-tool-plines-note "")
     (turn-tool-plines-note "| layer | vertices | length | closed |")
     (turn-tool-plines-note "|---|---|---|---|")
     (setq n 0)
     (vlax-for o (vla-get-modelspace dbx)
       (if (= "AcDbPolyline" (vla-get-objectname o))
         (progn
           (setq n (1+ n))
           (turn-tool-plines-note
             (strcat "| " (vla-get-layer o)
                     " | " (itoa (turn-tool-plines-vertices o))
                     " | " (rtos (turn-tool-plines-len o) 2 2)
                     " | " (if (= :vlax-true (vla-get-closed o)) "yes" "no")
                     " |")
           )
         )
       )
     )
     (turn-tool-plines-note "")
     (turn-tool-plines-note (strcat "polylines found: " (itoa n)))
    )
  )
  (turn-tool-plines-note "")
  (turn-tool-plines-note "CENSUS COMPLETE")
  (princ)
)
(princ "\nturn-inspect-plines.lsp loaded.")
(princ)
