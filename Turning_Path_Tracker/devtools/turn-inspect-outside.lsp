;;; turn-inspect-outside.lsp - which TURN polylines stray outside the envelope?
;;;
;;; The envelope is meant to enclose everything the rig touches, so every tire
;;; path, hitch path and corner locus should lie inside it. This reads a drawing
;;; with ObjectDBX and, for every polyline on a C-TURN-* layer, measures how far
;;; its vertices and segment midpoints lie OUTSIDE the C-TURN-ENVL loops.
;;;
;;; Run:  devtools\turn-tests.bat turn-inspect-outside   (edit the .scr for the drawing)
;;;
;;; A tool over a user's drawing. Never ships.

(vl-load-com)

(defun turn-tool-outside-say (s / f)
  (setq f (open *turn-tool-outside-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun turn-tool-outside-pts (obj / co out)
  (setq co (vlax-safearray->list (vlax-variant-value (vla-get-coordinates obj))))
  (while co (setq out (cons (list (car co) (cadr co)) out) co (cddr co)))
  (reverse out)
)

;; Even-odd over every loop, so holes count as outside.
(defun turn-tool-outside-inside-p (p loops / a b inside)
  (foreach pts loops
    (setq b (car (reverse pts)))
    (foreach a pts
      (if (and (/= (> (cadr a) (cadr p)) (> (cadr b) (cadr p)))
               (< (car p)
                  (+ (car a) (/ (* (- (car b) (car a)) (- (cadr p) (cadr a)))
                                (- (cadr b) (cadr a))))))
        (setq inside (not inside))
      )
      (setq b a)
    )
  )
  inside
)

(defun turn-tool-outside-seg-dist (p a b / dx dy len2 u)
  (setq dx (- (car b) (car a)) dy (- (cadr b) (cadr a)) len2 (+ (* dx dx) (* dy dy)))
  (if (zerop len2)
    (distance p a)
    (progn
      (setq u (max 0.0 (min 1.0 (/ (+ (* (- (car p) (car a)) dx) (* (- (cadr p) (cadr a)) dy)) len2))))
      (distance p (list (+ (car a) (* u dx)) (+ (cadr a) (* u dy))))
    )
  )
)

(defun turn-tool-outside-dist (p loops / a b best d)
  (foreach pts loops
    (setq b (car (reverse pts)))
    (foreach a pts
      (setq d (turn-tool-outside-seg-dist p a b))
      (if (or (null best) (< d best)) (setq best d))
      (setq b a)
    )
  )
  best
)

;; Points to test on an open polyline: every vertex and every segment midpoint.
(defun turn-tool-outside-samples (pts / a out)
  (setq a (car pts))
  (foreach b (cdr pts)
    (setq out (cons (list (/ (+ (car a) (car b)) 2.0) (/ (+ (cadr a) (cadr b)) 2.0)) (cons a out)) a b)
  )
  (reverse (cons a out))
)

(defun turn-tool-outside-dbx (/ doc v)
  (setq v 16)
  (while (and (not doc) (< v 30))
    (setq doc (vl-catch-all-apply 'vla-getinterfaceobject
                (list (vlax-get-acad-object) (strcat "ObjectDBX.AxDbDocument." (itoa v)))))
    (if (vl-catch-all-error-p doc) (setq doc nil))
    (setq v (1+ v))
  )
  doc
)

(defun turn-tool-outside-run (dwg log / count d dbx err loops lay n outs pts worst where)
  (setq *turn-tool-outside-log* log)
  (close (open log "w"))
  (turn-tool-outside-say (strcat "# Outside the envelope: " dwg))
  (turn-tool-outside-say "")
  (setq dbx (turn-tool-outside-dbx))
  (cond
    ((vl-catch-all-error-p (setq err (vl-catch-all-apply 'vla-open (list dbx dwg))))
     (turn-tool-outside-say (strcat "!! vla-open failed: " (vl-catch-all-error-message err))))
    (t
     (turn-tool-outside-say "## Vehicle blocks")
     (vlax-for obj (vla-get-modelspace dbx)
       (if (and (= "AcDbBlockReference" (vla-get-objectname obj))
                (= :vlax-true (vla-get-hasattributes obj)))
         (progn
           (turn-tool-outside-say (strcat "- " (vla-get-name obj) " at "
                                          (vl-princ-to-string (vlax-safearray->list (vlax-variant-value (vla-get-insertionpoint obj))))))
           (foreach att (vlax-safearray->list (vlax-variant-value (vla-getattributes obj)))
             (turn-tool-outside-say (strcat "  - " (vla-get-tagstring att) " = " (vla-get-textstring att))))
         )
       )
     )
     (vlax-for obj (vla-get-modelspace dbx)
       (if (and (= "AcDbPolyline" (vla-get-objectname obj)) (= "C-TURN-ENVL" (vla-get-layer obj)))
         (setq loops (cons (turn-tool-outside-pts obj) loops))
       )
     )
     (turn-tool-outside-say "")
     (turn-tool-outside-say (strcat "## " (itoa (length loops)) " envelope loop(s), vertex counts "
                                    (vl-princ-to-string (mapcar 'length loops))))
     (turn-tool-outside-say "")
     (turn-tool-outside-say "| layer | vertices | first vertex | last vertex | points outside | worst | at |")
     (turn-tool-outside-say "|---|---|---|---|---|---|---|")
     (vlax-for obj (vla-get-modelspace dbx)
       (setq lay (vla-get-layer obj))
       (if (and (= "AcDbPolyline" (vla-get-objectname obj))
                (wcmatch lay "C-TURN-*")
                (not (wcmatch lay "C-TURN-ENVL,*-BODY")))
         (progn
           (setq pts (turn-tool-outside-pts obj) outs 0 worst 0.0 where nil)
           (foreach p (turn-tool-outside-samples pts)
             (if (not (turn-tool-outside-inside-p p loops))
               (progn
                 (setq outs (1+ outs) d (turn-tool-outside-dist p loops))
                 (if (> d worst) (setq worst d where p))
               )
             )
           )
           (turn-tool-outside-say
             (strcat "| " lay " | " (itoa (length pts))
                     " | " (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) (car pts)))
                     " | " (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) (last pts)))
                     " | " (itoa outs) " | " (rtos worst 2 4)
                     " | " (if where (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) where)) "")
                     " |"))
         )
       )
     )
     (vlax-release-object dbx)
    )
  )
  (turn-tool-outside-say "")
  (turn-tool-outside-say "END")
  (princ)
)
