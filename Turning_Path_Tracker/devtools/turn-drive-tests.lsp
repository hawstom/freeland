;;; turn-drive-tests.lsp - Phase 4, the drive kernel.
;;;
;;; Driving asks the question a user asks at the wheel -- "I am steering this
;;; hard and moving this far, where does the rig go?" -- instead of "here is a
;;; polyline I already drew". The kernel treats it as the same kinematics read
;;; the other way round, so the tests that matter most are the ones that prove
;;; it really is the same and not a second, drifting copy.
;;;
;;; Everything here is pure: no drawing, no prompts, no drawing database. It
;;; runs in the core suite for that reason.
;;;
;;; Test scaffolding. None of it ships to users.

(defun tdv-deg (r) (/ (* r 180.0) pi))
(defun tdv-rad (d) (/ (* d pi) 180.0))

(defun tdv-truck ()
  (wiki-turn-segment "Truck" 20.0 8.0 30.0 8.0 4.0 nil (tdv-rad 30.0) (tdv-rad 70.0))
)

(defun tdv-rig ()
  (list
    (wiki-turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0 (tdv-rad 30.0) (tdv-rad 70.0))
    (wiki-turn-segment "Trailer" 45.5 8.5 53.0 8.5 -3.0 nil 0.0 (tdv-rad 70.0))
  )
)

;; n steps of a constant input.
(defun tdv-inputs (n steer travel / out)
  (repeat n (setq out (cons (cons steer travel) out)))
  out
)

;; AutoLISP has atan but no tan.
(defun tdv-tan (a) (/ (sin a) (cos a)))

;; THE INSTANTANEOUS TURN CENTRE IS SQUARE TO THE TRAILING AXLE, not to the
;; guide axle. The rear wheels do not steer, so the centre must lie on the line
;; through them perpendicular to the body; the guide axle then rides a larger
;; radius, wheelbase/sin(steer), while the trailing axle rides
;; wheelbase/tan(steer). Putting the centre abeam the guide axle instead was
;; what made the first version of the circle test fail by 20 ft.
(defun tdv-turn-centre (state wheelbase steer)
  (polar
    (wiki-turn-trail state)
    (+ (wiki-turn-heading state) (if (minusp steer) (- (/ pi 2.0)) (/ pi 2.0)))
    (abs (/ wheelbase (tdv-tan steer)))
  )
)

;;; ---------------------------------------------------------------------------
(defun tdv-test-straight (/ after before wheelbase)
  (tt-section "Driving straight")
  (setq
    wheelbase 20.0
    before (wiki-turn-state '(0.0 0.0) '(-20.0 0.0) 0.0 0.0 0.0)
    after (wiki-turn-drive-step before wheelbase 0.0 5.0)
  )
  (tt-near "the guide axle advances by exactly the distance driven"
           5.0 (distance (wiki-turn-guide before) (wiki-turn-guide after)) 1e-9)
  (tt-near "it advances along the heading" 0.0
           (wiki-turn-normalize-angle
             (- (angle (wiki-turn-guide before) (wiki-turn-guide after)) 0.0)) 1e-9)
  (tt-near "heading does not change with no steer"
           0.0 (wiki-turn-heading after) 1e-9)
  (tt-near "nothing turned" 0.0 (wiki-turn-turned after) 1e-9)
  (tt-near "the trailing axle stays one wheelbase behind"
           wheelbase (distance (wiki-turn-guide after) (wiki-turn-trail after)) 1e-9)
)

;; Drive with steer d; wiki-turn-step recovers the steer that geometry implies.
;; If those disagree, drive mode and course mode are not the same model.
(defun tdv-test-steer-round-trip (/ after before steer wheelbase)
  (tt-section "Steer in, steer out")
  (setq wheelbase 20.0)
  (foreach deg '(5.0 15.0 30.0 -20.0)
    (setq
      steer (tdv-rad deg)
      before (wiki-turn-state '(0.0 0.0) '(-20.0 0.0) 0.0 0.0 0.0)
      ;; A short step: the recovered steer is the average over the step, so it
      ;; converges on the input as the step shrinks.
      after (wiki-turn-drive-step before wheelbase steer 0.01)
    )
    (tt-near (strcat "steering " (rtos deg 2 1) " degrees reads back as "
                     (rtos deg 2 1))
             (abs steer) (abs (wiki-turn-steer after)) 0.001)
  )
)

;; Constant steer must trace a circle. For a bicycle model the guide axle runs
;; on radius wheelbase / sin(steer). This is the check that would catch a sign
;; error or a wheelbase used where a half-wheelbase belongs.
(defun tdv-test-circle (/ centre first-guide last-guide radius states steer wheelbase)
  (tt-section "Constant steer traces a circle of the right radius")
  (setq
    wheelbase 20.0
    steer (tdv-rad 30.0)
    radius (/ wheelbase (sin steer))
    states (car (wiki-turn-drive-path (list (tdv-truck))
                                      (tdv-inputs 200 steer 0.25)
                                      '(0.0 0.0) 0.0))
  )
  (tt-equal "one state per step, plus the state it started in" 201 (length states))
  (setq centre (tdv-turn-centre (car states) wheelbase steer))
  (tt-write (strcat "- wheelbase 20.0, steer 30 degrees: guide radius "
                    (rtos radius 2 3) ", trailing radius "
                    (rtos (/ wheelbase (tdv-tan steer)) 2 3)))
  (tt-check "the guide axle holds that radius to within 1 percent"
            (< (tdv-max-radius-error states centre radius) (* 0.01 radius)))
  ;; And the trailing axle rides the smaller radius, which is what offtracking
  ;; IS. If these two came out equal the model would be a rigid body, not a
  ;; steered one.
  (tt-check "the trailing axle rides wheelbase/tan(steer), also within 1 percent"
            (< (tdv-max-trail-error states centre (/ wheelbase (tdv-tan steer)))
               (* 0.01 radius)))
  (tdv-test-convergence)
)

;; The residual is integration error, not a modelling error: each step moves the
;; guide along a straight chord in the direction the wheel points, so a coarser
;; step leaves the circle by more. Asserting a magic tolerance would just be
;; picking a number. Asserting that HALVING THE STEP HALVES THE ERROR is the
;; real claim about a first-order integrator, and it is what would catch the
;; error becoming systematic rather than numerical.
(defun tdv-test-convergence (/ coarse fine ratio)
  (setq
    coarse (tdv-circle-error 0.50)
    fine (tdv-circle-error 0.25)
    ratio (/ coarse fine)
  )
  (tt-write (strcat "- radius error at step 0.50: " (rtos coarse 2 6)))
  (tt-write (strcat "- radius error at step 0.25: " (rtos fine 2 6)))
  (tt-write (strcat "- ratio: " (rtos ratio 2 3) " (first order predicts ~2)"))
  (tt-check "halving the step at least halves the error" (< 1.8 ratio))
)

;; Radius error after driving a fixed DISTANCE at a given step size, so the two
;; runs cover the same arc and only the step differs.
(defun tdv-circle-error (step / centre radius states steer wheelbase)
  (setq
    wheelbase 20.0
    steer (tdv-rad 30.0)
    radius (/ wheelbase (sin steer))
    states (car (wiki-turn-drive-path
                  (list (tdv-truck))
                  (tdv-inputs (fix (/ 50.0 step)) steer step)
                  '(0.0 0.0) 0.0))
    centre (tdv-turn-centre (car states) wheelbase steer)
  )
  (tdv-max-radius-error states centre radius)
)

(defun tdv-max-radius-error (states centre radius / err worst)
  (setq worst 0.0)
  (foreach s states
    (setq err (abs (- (distance centre (wiki-turn-guide s)) radius)))
    (if (> err worst) (setq worst err))
  )
  worst
)

(defun tdv-max-trail-error (states centre radius / err worst)
  (setq worst 0.0)
  (foreach s states
    (setq err (abs (- (distance centre (wiki-turn-trail s)) radius)))
    (if (> err worst) (setq worst err))
  )
  worst
)

;;; ---------------------------------------------------------------------------
;;; THE EQUIVALENCE TEST
;;;
;;; Drive the rig, take the course its guide axle actually traced, and follow
;;; that course with wiki-turn-path. The two must agree at every step of every
;;; segment. This is what stops drive mode becoming a second implementation of
;;; the tracking model that slowly drifts away from the first.
;;; ---------------------------------------------------------------------------
(defun tdv-test-equivalence (/ course driven followed rig worst)
  (tt-section "Driving and following a course are the same kinematics")
  (setq
    rig (tdv-rig)
    driven (wiki-turn-drive-path rig (tdv-inputs 240 (tdv-rad 20.0) 0.5) '(0.0 0.0) 0.0)
    ;; The course the powered guide axle actually drove.
    course (mapcar 'wiki-turn-guide (car driven))
    followed (wiki-turn-path rig course 0.0)
  )
  (tt-equal "same number of segments" (length driven) (length followed))
  (tt-equal "same number of steps" (length (car driven)) (length (car followed)))

  (setq worst (tdv-worst-guide-gap driven followed))
  (tt-write (strcat "- worst guide-point disagreement over "
                    (itoa (* (length driven) (length (car driven))))
                    " states: " (rtos worst 2 12)))
  (tt-check "every segment's guide point agrees to within a millionth of a unit"
            (< worst 1e-6))

  (setq worst (tdv-worst-heading-gap driven followed))
  (tt-write (strcat "- worst heading disagreement: " (rtos (tdv-deg worst) 2 12)
                    " degrees"))
  (tt-check "every heading agrees too" (< worst 1e-9))
)

(defun tdv-worst-guide-gap (a b / gap worst)
  (setq worst 0.0)
  (mapcar
    '(lambda (sa sb)
       (mapcar
         '(lambda (x y)
            (setq gap (distance (wiki-turn-guide x) (wiki-turn-guide y)))
            (if (> gap worst) (setq worst gap))
          )
         sa sb
       )
     )
    a b
  )
  worst
)

(defun tdv-worst-heading-gap (a b / gap worst)
  (setq worst 0.0)
  (mapcar
    '(lambda (sa sb)
       (mapcar
         '(lambda (x y)
            (setq gap (abs (wiki-turn-normalize-angle
                             (- (wiki-turn-heading x) (wiki-turn-heading y)))))
            (if (> gap worst) (setq worst gap))
          )
         sa sb
       )
     )
    a b
  )
  worst
)

;;; ---------------------------------------------------------------------------
(defun tdv-test-rest-states (/ rig states)
  (tt-section "The rig at rest, before it is driven anywhere")
  (setq rig (tdv-rig) states (wiki-turn-rest-states rig '(0.0 0.0) 0.0))
  (tt-equal "one state per segment" 2 (length states))
  (tt-near "the tractor's guide axle is where we put it"
           0.0 (distance '(0.0 0.0) (wiki-turn-guide (car states))) 1e-9)
  (tt-near "the tractor's trailing axle is one wheelbase back"
           19.5 (distance (wiki-turn-guide (car states)) (wiki-turn-trail (car states))) 1e-9)
  ;; Hitch is 0 on this tractor, so the trailer's kingpin sits over the drive
  ;; axle and the trailer's guide axle starts there.
  (tt-near "the trailer is hitched at the tractor's drive axle"
           0.0 (distance (wiki-turn-trail (car states)) (wiki-turn-guide (cadr states))) 1e-9)
  (tt-near "and stretches its own wheelbase behind that"
           45.5 (distance (wiki-turn-guide (cadr states)) (wiki-turn-trail (cadr states))) 1e-9)
  (tt-near "everything starts straight, so no articulation"
           0.0 (car (wiki-turn-articulation (list (car states)) (list (cadr states)))) 1e-9)
)

;; A gentle enough turn that the rig CAN follow it. See the jackknife test for
;; what happens when it cannot: a WB-67's trailer is 45.5 long, so a tractor
;; whose own trailing axle rides a radius smaller than that has set the trailer
;; an impossible problem, and 25 degrees of steer does exactly that.
(defun tdv-test-trailer-tracks-inside (/ art driven rig steer)
  (tt-section "A driven trailer tracks inside the tractor")
  (setq
    rig (tdv-rig)
    steer (tdv-rad 10.0)
    driven (wiki-turn-drive-path rig (tdv-inputs 400 steer 1.0) '(0.0 0.0) 0.0)
    art (wiki-turn-articulation (car driven) (cadr driven))
  )
  (tt-write (strcat "- 10 degrees of steer: the tractor's trailing axle rides "
                    (rtos (/ 19.5 (tdv-tan steer)) 2 2)
                    ", comfortably outside the 45.5 trailer wheelbase"))
  (tt-check "articulation starts at zero" (< (abs (car art)) 1e-9))
  (tt-check "and grows as the turn is held" (< (abs (car art)) (abs (last art))))
  (tt-write (strcat "- articulation after 400 ft: "
                    (rtos (tdv-max-abs-list art) 2 2) " degrees max"))
  ;; A trailer swinging WIDER than the tractor would mean a sign error.
  (tt-check "the trailer's trailing axle stays inside the tractor's path"
            (tdv-tracks-inside-p driven (car rig) steer))
)

;; Drive a rig into a turn it cannot physically make and the articulation limit
;; must object. This is the analysis 1.1.x collected inputs for and never used,
;; now reachable from the wheel rather than only from a drawn course.
(defun tdv-test-jackknife (/ art driven findings rig steer)
  (tt-section "Driving into a turn the rig cannot make")
  (setq
    rig (tdv-rig)
    steer (tdv-rad 25.0)
    ;; Far enough for it to actually happen. There is no steady state to reach:
    ;; with no radius the trailer can settle on, the articulation just keeps
    ;; growing until the rig is folded.
    driven (wiki-turn-drive-path rig (tdv-inputs 800 steer 0.5) '(0.0 0.0) 0.0)
    art (wiki-turn-articulation (car driven) (cadr driven))
    findings (wiki-turn-findings rig driven)
  )
  (tt-write (strcat "- 25 degrees of steer puts the tractor's trailing axle on "
                    (rtos (/ 19.5 (tdv-tan steer)) 2 2)
                    ", INSIDE the 45.5 trailer wheelbase - the trailer cannot follow"))
  (tt-write (strcat "- articulation reaches " (rtos (tdv-max-abs-list art) 2 2)
                    " degrees against a 70.0 limit"))
  (tt-check "articulation passes the vehicle's articulation limit"
            (< 70.0 (tdv-max-abs-list art)))
  ;; 25 degrees is INSIDE the 30 degree steering lock, so the driver has done
  ;; nothing the tractor cannot do. The finding has to come from the hitch.
  (tt-check "and it is reported, even though the steering lock was never exceeded"
            (not (null findings)))
  (if findings (foreach f findings (tt-write (strcat "- reported: " f))))
)

(defun tdv-max-abs-list (lst / worst)
  (setq worst 0.0)
  (foreach a lst (if (> (abs (tdv-deg a)) worst) (setq worst (abs (tdv-deg a)))))
  worst
)

;; Offtracking is inward ONCE THE RIG IS IN THE TURN, which is not true at the
;; moment it enters. A rig that starts straight is stretched out along the
;; tangent, so its hindmost axle begins FURTHER from the turn centre than the
;; tractor's guide axle and only comes inside as the turn develops. Checking
;; every state from the first would be asserting something physically false --
;; and it is the same fact the short-course advisory exists to explain.
;;
;; So: check the last quarter of the run, by which point the turn is developed.
(defun tdv-tracks-inside-p (driven segment steer / centre lead follow n ok)
  (setq
    centre (tdv-turn-centre (car (car driven))
                            (wiki-turn-seg-get segment "wheelbase") steer)
    n (/ (length (car driven)) 4)
    lead (tdv-tail-of (car driven) n)
    follow (tdv-tail-of (cadr driven) n)
    ok T
  )
  (mapcar
    '(lambda (a b)
       (if (> (distance centre (wiki-turn-trail b))
              (+ 0.001 (distance centre (wiki-turn-guide a))))
         (setq ok nil)
       )
     )
    lead follow
  )
  ok
)

(defun tdv-tail-of (lst n)
  (repeat (- (length lst) n) (setq lst (cdr lst)))
  lst
)

;; Drive mode must hand the rest of the program something it already knows how
;; to use, or nothing downstream works on a driven rig.
(defun tdv-test-shape (/ driven findings rig)
  (tt-section "A driven path is the same shape as a followed one")
  (setq
    rig (tdv-rig)
    driven (wiki-turn-drive-path rig (tdv-inputs 40 (tdv-rad 15.0) 1.0) '(0.0 0.0) 0.0)
  )
  (tt-equal "one list of states per segment" (length rig) (length driven))
  (tt-check "every segment has the same number of states"
            (= (length (car driven)) (length (cadr driven))))
  (tt-check "the course length of a driven path is computable"
            (< 0.0 (wiki-turn-course-length (car driven))))
  (tt-near "and equals the distance actually driven" 40.0
           (wiki-turn-course-length (car driven)) 0.001)
  ;; The judge works on it unchanged. That is the whole reason for the shape.
  (setq findings (wiki-turn-findings rig driven))
  (tt-check "wiki-turn-findings accepts a driven path"
            (or (null findings) (listp findings)))
  (tt-check "15 degrees of steer is inside a 30 degree lock, so no finding"
            (null findings))
)

;; Steering past the lock must be REPORTED, not silently clamped. The kernel
;; does what it is told; wiki-turn-findings is what objects.
(defun tdv-test-over-lock (/ driven findings rig)
  (tt-section "Steering past the lock is reported, not silently clamped")
  (setq
    rig (list (tdv-truck))
    driven (wiki-turn-drive-path rig (tdv-inputs 40 (tdv-rad 45.0) 1.0) '(0.0 0.0) 0.0)
    findings (wiki-turn-findings rig driven)
  )
  (tt-check "driving 45 degrees on a 30 degree lock produces a finding"
            (not (null findings)))
  (if findings (tt-write (strcat "- reported: " (car findings))))
)

;;; ---------------------------------------------------------------------------
(defun tdv-run-all ()
  (tdv-test-straight)
  (tdv-test-steer-round-trip)
  (tdv-test-circle)
  (tdv-test-rest-states)
  (tdv-test-equivalence)
  (tdv-test-trailer-tracks-inside)
  (tdv-test-jackknife)
  (tdv-test-shape)
  (tdv-test-over-lock)
  (princ)
)
