;;; turn-inspect-envl.lsp - Measure every C-TURN-ENVL polyline in a drawing.
;;;
;;; The envelope is built by laying the body outline down at every step, handing
;;; the pile to REGION/UNION, then exploding and rejoining. That can come back as
;;; more than one loop, and the pieces mean different things:
;;;
;;;   - a genuine interior HOLE, where the rig's own bodies never covered a spot
;;;     because the calculation step was coarser than the body is long;
;;;   - a numerical SLIVER, a near-zero-area artifact of the union.
;;;
;;; Length alone cannot tell them apart. Area can. Also reports the vehicle
;;; block's dimensions and the step actually used, because the ratio of step to
;;; body length is the thing that decides whether holes appear at all.

(vl-load-com)

(defun turn-tool-envl-say (s / f)
  (setq f (open *turn-tool-envl-log* "a"))
  (write-line s f)
  (close f)
  (princ (strcat "\n" s))
  (princ)
)

(defun turn-tool-envl-num (x) (rtos x 2 3))

;; Distance from a polyline's first vertex to its last.
(defun turn-tool-envl-end-gap (obj / co n pts)
  (setq co (vlax-safearray->list (vlax-variant-value (vla-get-coordinates obj)))
        n (length co))
  (if (< n 4)
    0.0
    (distance (list (nth 0 co) (nth 1 co))
              (list (nth (- n 2) co) (nth (- n 1) co)))
  )
)

(defun turn-tool-envl-dbx (/ doc v)
  (setq v 16)
  (while (and (not doc) (< v 30))
    (setq doc (vl-catch-all-apply 'vla-getinterfaceobject
                (list (vlax-get-acad-object)
                      (strcat "ObjectDBX.AxDbDocument." (itoa v)))))
    (if (vl-catch-all-error-p doc) (setq doc nil))
    (setq v (1+ v))
  )
  doc
)

(defun turn-tool-envl-run (dwg log / a big dbx err n obj small total)
  (setq *turn-tool-envl-log* log)
  (setq n (open log "w"))
  (close n)
  (turn-tool-envl-say (strcat "# Envelope census: " dwg))
  (turn-tool-envl-say "")
  (setq dbx (turn-tool-envl-dbx))
  (cond
    ((not dbx) (turn-tool-envl-say "!! no ObjectDBX document"))
    ((vl-catch-all-error-p (setq err (vl-catch-all-apply 'vla-open (list dbx dwg))))
     (turn-tool-envl-say (strcat "!! vla-open failed: " (vl-catch-all-error-message err)))
    )
    (t
     ;; Vehicle blocks, for the body dimensions that set the scale of "small".
     (turn-tool-envl-say "## Vehicle blocks")
     (turn-tool-envl-say "")
     (vlax-for obj (vla-get-modelspace dbx)
       (if (and (= "AcDbBlockReference" (vla-get-objectname obj))
                (= :vlax-true (vla-get-hasattributes obj)))
         (progn
           (turn-tool-envl-say (strcat "### " (vla-get-name obj)))
           (foreach att (vlax-safearray->list
                          (vlax-variant-value (vla-getattributes obj)))
             (if (wcmatch (strcase (vla-get-tagstring att))
                          "*BODYLENGTH,*WHEELBASE,*WIDTH,*HITCH*,*FRONTHANG")
               (turn-tool-envl-say (strcat "- " (vla-get-tagstring att) " = "
                               (vla-get-textstring att)))
             )
           )
           (turn-tool-envl-say "")
         )
       )
     )
     ;; Every envelope loop, with area.
     (turn-tool-envl-say "## C-TURN-ENVL loops")
     (turn-tool-envl-say "")
     (turn-tool-envl-say "| # | vertices | length | area | closed | end gap |")
     (turn-tool-envl-say "|---|---|---|---|---|---|")
     (setq n 0 total 0.0 small 0 big 0)
     (vlax-for obj (vla-get-modelspace dbx)
       (if (and (= "AcDbPolyline" (vla-get-objectname obj))
                (= "C-TURN-ENVL" (vla-get-layer obj)))
         (progn
           (setq
             n (1+ n)
             a (vl-catch-all-apply 'vla-get-area (list obj))
             a (if (vl-catch-all-error-p a) 0.0 a)
             total (+ total a)
           )
           (if (< a 1.0) (setq small (1+ small)) (setq big (1+ big)))
           ;; AcDbPolyline has no Count property through ActiveX - asking for it
           ;; aborts the whole census. Vertices come off the coordinate array,
           ;; which is flat pairs.
           (turn-tool-envl-say
             (strcat "| " (itoa n)
                     " | " (itoa (/ (length (vlax-safearray->list
                                              (vlax-variant-value
                                                (vla-get-coordinates obj))))
                                    2))
                     " | " (turn-tool-envl-num (vla-get-length obj))
                     " | " (turn-tool-envl-num a)
                     " | " (if (= :vlax-true (vla-get-closed obj)) "yes" "no")
                     ;; An unclosed loop whose ends coincide is only missing the
                     ;; Closed flag. One with a real gap is missing geometry.
                     ;; Those need opposite fixes, so measure the gap.
                     " | " (turn-tool-envl-num (turn-tool-envl-end-gap obj))
                     " |")
           )
         )
       )
     )
     (turn-tool-envl-say "")
     (turn-tool-envl-say (strcat "loops: " (itoa n) "   total area: " (turn-tool-envl-num total)))
     (turn-tool-envl-say (strcat "loops with area < 1.0 (candidate slivers): " (itoa small)))
     (turn-tool-envl-say (strcat "loops with area >= 1.0: " (itoa big)))
     (vlax-release-object dbx)
    )
  )
  (turn-tool-envl-say "")
  (turn-tool-envl-say "END")
  (princ)
)

(princ "\nturn-inspect-envl.lsp loaded. Run (turn-tool-envl-run dwg log).")
(princ)
