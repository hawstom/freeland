;;; turn-kenya.lsp - Reproduce the spiral in Kenya Caldwell's 2026-09-08 screenshot.
;;;
;;; Observed: a single cyan curve (trailer layers, colour 4) that spirals
;;; inward to a tight curl instead of following the course. The truck's own
;;; tire paths (colours 1 and 2) are not visible at all.
;;;
;;; Hypothesis: the hitch was placed well BEHIND the drive axle. A trailer
;;; hitched behind the tow vehicle's rear axle is genuinely unstable - that is
;;; why real rigs put the fifth wheel at or ahead of the drive axle - so the
;;; tracking equation would faithfully produce a diverging, curling path.
;;; If so, TURN is not miscomputing. It is drawing an unusable answer without
;;; ever saying the manoeuvre is impossible.

(setq *ky-log* (tt-src "user_help/Kenya_Caldwell/reproduction.md"))

(defun ky-note (s / f)
  (setq f (open *ky-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

;; A course shaped like the screenshot: run in straight, then a long sweeping
;; loop back on itself.
(defun ky-course (/ i out r)
  (setq i -1 r 60.0)
  ;; straight approach
  (repeat 40 (setq i (1+ i) out (cons (list (- (* i 3.0) 200.0) 0.0) out)))
  ;; then most of a circle
  (setq i -1)
  (repeat 400
    (setq i (1+ i))
    (setq
      out
       (cons
         (polar (list -80.0 (- r)) (+ (/ pi 2) (* 2 pi (/ (float i) 400.0))) r)
         out
       )
    )
  )
  (reverse out)
)

;; Largest articulation angle anywhere along the run, in degrees.
(defun ky-max-articulation (vehicle course / a paths worst)
  (setq
    paths (wiki-turn-path vehicle course 0.0)
    worst 0.0
  )
  (foreach a (wiki-turn-articulation (car paths) (cadr paths))
    (if (> (abs a) worst) (setq worst (abs a)))
  )
  (* 180.0 (/ worst pi))
)

;; How far the trailer's last position is from the course - a path that curls
;; up in the middle ends nowhere near where it should.
(defun ky-final-error (vehicle course / paths)
  (setq paths (wiki-turn-path vehicle course 0.0))
  (distance
    (wiki-turn-trail (last (cadr paths)))
    (last course)
  )
)

(defun ky-case (label hitch / course tractor trailer vehicle)
  (setq
    course (ky-course)
    tractor (wiki-turn-segment "Truck" 20.0 8.0 30.0 8.5 4.0 hitch (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    trailer (wiki-turn-segment "Trailer" 45.5 8.5 53.0 8.5 3.0 nil 0.0 0.0)
    vehicle (list tractor trailer)
  )
  (ky-note
    (strcat "| " label
            " | " (rtos hitch 2 1)
            " | " (rtos (ky-max-articulation vehicle course) 2 1)
            " | " (rtos (ky-final-error vehicle course) 2 1)
            " | " (if (wiki-turn-findings vehicle (wiki-turn-path vehicle course 0.0))
                    "REPORTED"
                    "silent"
                  )
            " |")
  )
)

(defun ky-run (/ f)
  (setq f (open *ky-log* "w"))
  (close f)
  (ky-note "# Reproduction: Kenya Caldwell, 2026-09-08")
  (ky-note "")
  (ky-note "Same WB-67-ish tractor and semitrailer, same course. The only thing")
  (ky-note "that changes is where the hitch sits relative to the drive axle.")
  (ky-note "Positive = behind the axle.")
  (ky-note "")
  (ky-note "| case | hitch | max articulation (deg) | trailer end error | TURN 2.0 verdict |")
  (ky-note "|---|---|---|---|---|")
  (ky-case "fifth wheel ahead of axle" -2.0)
  (ky-case "fifth wheel on the axle" 0.0)
  (ky-case "hitch 5 behind axle" 5.0)
  (ky-case "hitch 12 behind axle" 12.0)
  (ky-case "hitch 23 behind axle" 23.0)
  (ky-note "")
  (ky-note "RUN COMPLETE")
  (princ)
)
(princ "\nturn-kenya.lsp loaded.")
(princ)
