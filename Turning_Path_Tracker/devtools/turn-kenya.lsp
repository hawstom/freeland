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

(setq *turn-tool-kenya-log* (turn-test-src "user_help/Kenya_Caldwell/reproduction.md"))

(defun turn-tool-kenya-note (s / f)
  (setq f (open *turn-tool-kenya-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)

;; A course shaped like the screenshot: run in straight, then a long sweeping
;; loop back on itself.
(defun turn-tool-kenya-course (/ i out r)
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
(defun turn-tool-kenya-max-articulation (vehicle course / a paths worst)
  (setq
    paths (turn-path vehicle course 0.0)
    worst 0.0
  )
  (foreach a (turn-articulation (car paths) (cadr paths))
    (if (> (abs a) worst) (setq worst (abs a)))
  )
  (* 180.0 (/ worst pi))
)

;; How far the trailer's last position is from the course - a path that curls
;; up in the middle ends nowhere near where it should.
(defun turn-tool-kenya-final-error (vehicle course / paths)
  (setq paths (turn-path vehicle course 0.0))
  (distance
    (turn-trail (last (cadr paths)))
    (last course)
  )
)

(defun turn-tool-kenya-case (label hitch / course tractor trailer vehicle)
  (setq
    course (turn-tool-kenya-course)
    tractor (turn-segment "Truck" 20.0 8.0 30.0 8.5 4.0 hitch (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    trailer (turn-segment "Trailer" 45.5 8.5 53.0 8.5 3.0 nil 0.0 0.0)
    vehicle (list tractor trailer)
  )
  (turn-tool-kenya-note
    (strcat "| " label
            " | " (rtos hitch 2 1)
            " | " (rtos (turn-tool-kenya-max-articulation vehicle course) 2 1)
            " | " (rtos (turn-tool-kenya-final-error vehicle course) 2 1)
            " | " (if (turn-findings vehicle (turn-path vehicle course 0.0))
                    "REPORTED"
                    "silent"
                  )
            " |")
  )
)

(defun turn-tool-kenya-run (/ f)
  (setq f (open *turn-tool-kenya-log* "w"))
  (close f)
  (turn-tool-kenya-note "# Reproduction: Kenya Caldwell, 2026-09-08")
  (turn-tool-kenya-note "")
  (turn-tool-kenya-note "Same WB-67-ish tractor and semitrailer, same course. The only thing")
  (turn-tool-kenya-note "that changes is where the hitch sits relative to the drive axle.")
  (turn-tool-kenya-note "Positive = behind the axle.")
  (turn-tool-kenya-note "")
  (turn-tool-kenya-note "| case | hitch | max articulation (deg) | trailer end error | TURN 2.0 verdict |")
  (turn-tool-kenya-note "|---|---|---|---|---|")
  (turn-tool-kenya-case "fifth wheel ahead of axle" -2.0)
  (turn-tool-kenya-case "fifth wheel on the axle" 0.0)
  (turn-tool-kenya-case "hitch 5 behind axle" 5.0)
  (turn-tool-kenya-case "hitch 12 behind axle" 12.0)
  (turn-tool-kenya-case "hitch 23 behind axle" 23.0)
  (turn-tool-kenya-note "")
  (turn-tool-kenya-note "RUN COMPLETE")
  (princ)
)
(princ "\nturn-kenya.lsp loaded.")
(princ)
