;;; turn-inspect-offset.lsp - Is the computed path actually offset from the
;;; course the user drew, and by how much?
;;;
;;; If the separation is half the axle width, the offsets are working and the
;;; complaint is about something else. If it is zero, they are not.
(vl-load-com)

(defun to-note (s / f)
  (setq f (open *to-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun to-dbx (/ doc v)
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

;; Flat coordinate list -> list of 2D points.
(defun to-points (o / flat out)
  (setq flat (vlax-safearray->list (vlax-variant-value (vla-get-coordinates o))))
  (while flat
    (setq out (cons (list (car flat) (cadr flat)) out) flat (cddr flat))
  )
  (reverse out)
)

(defun to-run (dwg log / course dbx err path pts)
  (setq *to-log* log)
  (setq f (open *to-log* "w"))
  (close f)
  (to-note (strcat "# Offset check: " dwg))
  (to-note "")
  (setq dbx (to-dbx))
  (setq err (vl-catch-all-apply 'vla-open (list dbx dwg)))
  (cond
    ((vl-catch-all-error-p err)
     (to-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
    )
    (t
     ;; Collect the hand-drawn course and the computed path.
     (vlax-for o (vla-get-modelspace dbx)
       (if (= "AcDbPolyline" (vla-get-objectname o))
         (progn
           (setq pts (to-points o))
           (if (< (length pts) 20)
             (setq course (cons (cons (vla-get-layer o) pts) course))
             (setq path (cons (cons (vla-get-layer o) pts) path))
           )
         )
       )
     )
     (foreach c course
       (to-note (strcat "## Hand-drawn, layer " (car c)
                        " (" (itoa (length (cdr c))) " vertices)"))
       (to-note "")
       (foreach p (cdr c)
         (to-note (strcat "- " (rtos (car p) 2 3) ", " (rtos (cadr p) 2 3)))
       )
       (to-note "")
     )
     (foreach c path
       (to-note (strcat "## Computed, layer " (car c)
                        " (" (itoa (length (cdr c))) " vertices)"))
       (to-note "")
       (to-note (strcat "- first vertex: " (rtos (car (nth 0 (cdr c))) 2 3)
                        ", " (rtos (cadr (nth 0 (cdr c))) 2 3)))
       (to-note (strcat "- second      : " (rtos (car (nth 1 (cdr c))) 2 3)
                        ", " (rtos (cadr (nth 1 (cdr c))) 2 3)))
       (to-note (strcat "- last vertex : "
                        (rtos (car (nth (1- (length (cdr c))) (cdr c))) 2 3) ", "
                        (rtos (cadr (nth (1- (length (cdr c))) (cdr c))) 2 3)))
       (to-note "")
     )
     ;; How far is the computed path's start from the nearest end of the course?
     (if (and course path)
       (progn
         (to-note "## Separation")
         (to-note "")
         (foreach c course
           (foreach q path
             (to-note
               (strcat "- start of computed path to start of course: "
                       (rtos (distance (nth 0 (cdr q)) (nth 0 (cdr c))) 2 4))
             )
             (to-note
               (strcat "- start of computed path to end of course:   "
                       (rtos (distance (nth 0 (cdr q))
                                       (nth (1- (length (cdr c))) (cdr c))) 2 4))
             )
           )
         )
       )
     )
    )
  )
  (to-note "")
  (to-note "OFFSET CHECK COMPLETE")
  (princ)
)
(princ "\nturn-inspect-offset.lsp loaded.")
(princ)
