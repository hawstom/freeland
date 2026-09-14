;;; turn-inspect-plines.lsp - Census every polyline in a drawing by vertex count.
;;;
;;; A course a person drew has a handful of vertices. A path TURN computed has
;;; one per calculation step, typically hundreds. That difference tells us
;;; whether TURN drew anything in a drawing, and on which layer it landed.
(vl-load-com)

(defun tp-note (s / f)
  (setq f (open *tp-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun tp-dbx (/ doc v)
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

(defun tp-vertices (o / n)
  (setq n (vl-catch-all-apply 'vlax-safearray->list
                              (list (vlax-variant-value (vla-get-coordinates o)))))
  (if (vl-catch-all-error-p n) 0 (/ (length n) 2))
)

(defun tp-len (o / v)
  (setq v (vl-catch-all-apply 'vla-get-length (list o)))
  (if (vl-catch-all-error-p v) 0.0 v)
)

(defun tp-run (dwg log / dbx err n)
  (setq *tp-log* log)
  (setq f (open *tp-log* "w"))
  (close f)
  (tp-note (strcat "# Polyline census: " dwg))
  (tp-note "")
  (setq dbx (tp-dbx))
  (setq err (vl-catch-all-apply 'vla-open (list dbx dwg)))
  (cond
    ((vl-catch-all-error-p err)
     (tp-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
    )
    (t
     (tp-note "Every LWPOLYLINE in model space. Hundreds of vertices means TURN")
     (tp-note "computed it; a handful means a person drew it.")
     (tp-note "")
     (tp-note "| layer | vertices | length | closed |")
     (tp-note "|---|---|---|---|")
     (setq n 0)
     (vlax-for o (vla-get-modelspace dbx)
       (if (= "AcDbPolyline" (vla-get-objectname o))
         (progn
           (setq n (1+ n))
           (tp-note
             (strcat "| " (vla-get-layer o)
                     " | " (itoa (tp-vertices o))
                     " | " (rtos (tp-len o) 2 2)
                     " | " (if (= :vlax-true (vla-get-closed o)) "yes" "no")
                     " |")
           )
         )
       )
     )
     (tp-note "")
     (tp-note (strcat "polylines found: " (itoa n)))
    )
  )
  (tp-note "")
  (tp-note "CENSUS COMPLETE")
  (princ)
)
(princ "\nturn-inspect-plines.lsp loaded.")
(princ)
