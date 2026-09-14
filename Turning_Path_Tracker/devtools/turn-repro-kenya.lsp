;;; turn-repro-kenya.lsp - Run TURN 1.1.17 against Kenya's exact vehicle and her
;;; exact course, and record what it actually draws.
;;;
;;; Her drawing shows one computed path where there should be seven, with no
;;; lateral offset, on a layer its geometry does not match. Rather than guess a
;;; third time, rebuild the inputs here and watch.
;;;
;;; NO PROMPTS. The course geometry and the vehicle attributes are lifted from
;;; her DWG through ObjectDBX, and every input function TURN would ask through
;;; is stubbed to answer from a queue. That is the same technique as overriding
;;; alert: it lets an unattended script drive prompt-driven code exactly.
(vl-load-com)

(setq
  *turn-tool-repro-src* (turn-test-src "user_help/Kenya_Caldwell/Kenya-Caldwell-test-2.dwg")
  *turn-tool-repro-log* (turn-test-src "user_help/Kenya_Caldwell/reproduction-2.md")
  ;; She used a 2.0 calculation step: her path vertices are 2.0 apart.
  *turn-tool-repro-step* 2.0
  *turn-tool-repro-plotfreq* 10
)

(defun turn-tool-repro-note (s / f)
  (setq f (open *turn-tool-repro-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

(defun turn-tool-repro-dbx (/ doc v)
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

;;; ---------------------------------------------------------------------------
;;; Lift the real inputs out of her drawing
;;; ---------------------------------------------------------------------------
;; Returns (points bulges attributes)
(defun turn-tool-repro-harvest (/ atts bulges dbx err flat i n out pts)
  (setq dbx (turn-tool-repro-dbx))
  (setq err (vl-catch-all-apply 'vla-open (list dbx *turn-tool-repro-src*)))
  (cond
    ((vl-catch-all-error-p err)
     (turn-tool-repro-note (strcat "OPEN FAILED: " (vl-catch-all-error-message err)))
     nil
    )
    (t
     (vlax-for o (vla-get-modelspace dbx)
       (cond
         ;; The course: the short hand-drawn polyline.
         ((and (= "AcDbPolyline" (vla-get-objectname o)) (not pts))
          (setq flat (vlax-safearray->list (vlax-variant-value (vla-get-coordinates o))))
          (if (<= (/ (length flat) 2) 20)
            (progn
              (while flat
                (setq pts (cons (list (car flat) (cadr flat)) pts) flat (cddr flat))
              )
              (setq pts (reverse pts) n (length pts) i -1)
              (repeat n
                (setq i (1+ i) bulges (cons (vla-getbulge o i) bulges))
              )
              (setq bulges (reverse bulges))
            )
            (setq flat nil)
          )
         )
         ;; The vehicle: the insert carrying VEHWHEELBASE.
         ((and (= "AcDbBlockReference" (vla-get-objectname o))
               (= :vlax-true (vla-get-hasattributes o))
               (not atts)
          )
          (setq
            out
             (mapcar
               '(lambda (a) (cons (strcase (vla-get-tagstring a)) (vla-get-textstring a)))
               (vlax-safearray->list (vlax-variant-value (vla-getattributes o)))
             )
          )
          (if (assoc "VEHWHEELBASE" out) (setq atts out))
         )
       )
     )
     (list pts bulges atts)
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; Rebuild them here
;;; ---------------------------------------------------------------------------
(defun turn-tool-repro-make-course (pts bulges / i lst)
  (setq
    lst
     (list
       '(0 . "LWPOLYLINE")
       '(100 . "AcDbEntity")
       (cons 8 "KENYA-COURSE")
       '(100 . "AcDbPolyline")
       (cons 90 (length pts))
       '(70 . 0)
       '(43 . 0.0)
     )
    i -1
  )
  (foreach p pts
    (setq
      i (1+ i)
      lst (append lst (list (cons 10 p) (cons 42 (nth i bulges))))
    )
  )
  (entmake lst)
  (entlast)
)

(defun turn-tool-repro-attdef (pt tag val height)
  (entmake
    (list
      '(0 . "ATTDEF")
      (cons 8 "KENYA-VEHICLE")
      (cons 10 pt)
      (cons 40 height)
      (cons 1 val)
      (cons 3 tag)
      (cons 2 tag)
      '(70 . 0)
      '(50 . 0.0)
    )
  )
  (entlast)
)

;; A block carrying her exact attribute values, at `base`, rotation 0 - which is
;; what her drawing has, and which makes TURN read the heading as pi (due west,
;; the direction her course runs).
(defun turn-tool-repro-make-vehicle (atts base / a ss y)
  (setq ss (ssadd) y (cadr base))
  ;; a body rectangle, so the block has visible geometry
  (entmake
    (list
      '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 "KENYA-VEHICLE")
      '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1) '(43 . 0.0)
      (cons 10 (list (car base) (- y 4.25)))
      (cons 10 (list (+ (car base) 27.9) (- y 4.25)))
      (cons 10 (list (+ (car base) 27.9) (+ y 4.25)))
      (cons 10 (list (car base) (+ y 4.25)))
    )
  )
  (ssadd (entlast) ss)
  (foreach a atts
    (setq y (- y 1.2))
    (ssadd (turn-tool-repro-attdef (list (car base) y) (car a) (cdr a) 0.5) ss)
  )
  (setvar "attreq" 0)
  (setvar "attdia" 0)
  (setvar "expert" 5)
  (command "._-block" "KENYAVEH" base ss "")
  (command "._-insert" "KENYAVEH" base "" "" "")
  (entlast)
)

;;; ---------------------------------------------------------------------------
;;; Answer TURN's prompts from a queue instead of a keyboard
;;; ---------------------------------------------------------------------------
(setq *turn-tool-repro-entsel-queue* nil)

(defun turn-tool-repro-install-stubs ()
  ;; Arity matters: AutoLISP has no optional arguments, so a stub must take
  ;; exactly as many as the call site passes. entsel is called with a prompt,
  ;; and turn-getdistx calls getdist with a base point AND a prompt.
  (eval
    '(defun entsel (msg / v)
       (setq v (car *turn-tool-repro-entsel-queue*) *turn-tool-repro-entsel-queue* (cdr *turn-tool-repro-entsel-queue*))
       v
     )
  )
  (eval '(defun getkword (msg) "Generated"))
  (eval '(defun getstring (msg) ""))
  ;; nil makes turn-getdistx / -getintx fall through to their default,
  ;; which we have pre-loaded with her values.
  (eval '(defun getdist (basept msg) nil))
  (eval '(defun getint (msg) nil))
  (eval '(defun alert (msg) (turn-tool-repro-note (strcat "- ALERT: " (vl-princ-to-string msg))) (princ)))
  (princ)
)

;;; ---------------------------------------------------------------------------
;;; Look at what came out
;;; ---------------------------------------------------------------------------
(defun turn-tool-repro-points (en / flat out)
  (setq flat (cdr (assoc -1 (entget en))))
  (setq out nil)
  (foreach g (entget en) (if (= 10 (car g)) (setq out (cons (cdr g) out))))
  (reverse out)
)

(defun turn-tool-repro-report (course-start / el en i n pts ss)
  (turn-tool-repro-note "")
  (turn-tool-repro-note "## What TURN drew")
  (turn-tool-repro-note "")
  (turn-tool-repro-note "| layer | vertices | first vertex | offset from course start |")
  (turn-tool-repro-note "|---|---|---|---|")
  (setq ss (ssget "_X" '((0 . "LWPOLYLINE"))) i -1)
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (setq pts (turn-tool-repro-points en) el (entget en))
      (turn-tool-repro-note
        (strcat "| " (cdr (assoc 8 el))
                " | " (itoa (length pts))
                " | " (rtos (car (car pts)) 2 3) ", " (rtos (cadr (car pts)) 2 3)
                " | " (rtos (distance (car pts) course-start) 2 4)
                " |")
      )
    )
  )
  (turn-tool-repro-note "")
)

;;; ---------------------------------------------------------------------------
(defun turn-tool-repro-run (/ atts bulges en-course en-veh err harvest pts start)
  (setq f (open *turn-tool-repro-log* "w"))
  (close f)
  (turn-tool-repro-note "# Reproduction of Kenya's run, TURN 1.1.17")
  (turn-tool-repro-note "")
  (setq harvest (turn-tool-repro-harvest))
  (cond
    ((not harvest) (turn-tool-repro-note "could not read the source drawing"))
    (t
     (setq
       pts (car harvest)
       bulges (cadr harvest)
       atts (caddr harvest)
     )
     (turn-tool-repro-note (strcat "course vertices lifted: " (itoa (length pts))))
     (turn-tool-repro-note (strcat "bulges: " (vl-princ-to-string bulges)))
     (turn-tool-repro-note (strcat "attributes lifted: " (itoa (length atts))))
     (turn-tool-repro-note (strcat "VEHWHEELWIDTH = " (cdr (assoc "VEHWHEELWIDTH" atts))))
     (turn-tool-repro-note "")
     (setq
       en-course (turn-tool-repro-make-course pts bulges)
       start (car pts)
       en-veh (turn-tool-repro-make-vehicle atts (list (+ (car start) 200.0) (cadr start)))
     )
     (turn-tool-repro-note (strcat "course start: " (rtos (car start) 2 3) ", " (rtos (cadr start) 2 3)))
     (turn-tool-repro-note "")
     ;; Queue the two picks TURN will make: the vehicle, then the course.
     ;; The course pick point IS its start vertex, so the osnap "_end" inside
     ;; TURN cannot miss regardless of zoom.
     (setq *turn-tool-repro-entsel-queue* (list (list en-veh (list 0.0 0.0)) (list en-course start)))
     (setq
       *turn-calculationstep* *turn-tool-repro-step*
       *turn-plotfrequency* *turn-tool-repro-plotfreq*
     )
     (turn-tool-repro-install-stubs)
     ;; TURN finds the start of the course with (osnap pick "_end"), and osnap
     ;; measures its aperture in SCREEN pixels. Her geometry sits near
     ;; 2562, 7450 while a fresh drawing is looking at the origin, so without
     ;; this the snap has nothing on screen and quietly returns nil.
     (command "._zoom" "_extents")
     (turn-tool-repro-note (strcat "osnap _end at course start -> "
                      (vl-princ-to-string (osnap start "_end"))))
     (turn-tool-repro-note "")
     (turn-tool-repro-note "running c:turn ...")
     (setq err (vl-catch-all-apply 'c:turn nil))
     (if (vl-catch-all-error-p err)
       (turn-tool-repro-note (strcat "!! c:turn raised: " (vl-catch-all-error-message err)))
       (turn-tool-repro-note "c:turn returned normally")
     )
     (turn-tool-repro-note "")
     (turn-tool-repro-note "## What TURN read out of the block")
     (turn-tool-repro-note "")
     (foreach v (list "VEHWHEELBASE" "VEHWHEELWIDTH" "VEHBODYLENGTH" "VEHFRONTHANG"
                      "VEHREARHITCH" "TRAILHAVE" "TRAILERHITCHTOWHEEL" "TRAILERWHEELWIDTH")
       (turn-tool-repro-note (strcat "- " v " = "
                        (vl-princ-to-string (eval (read v)))
                        "   [type " (vl-princ-to-string (type (eval (read v)))) "]"))
     )
     (turn-tool-repro-report start)
    )
  )
  (turn-tool-repro-note "REPRODUCTION COMPLETE")
  (princ)
)
(princ "\nturn-repro-kenya.lsp loaded.")
(princ)
