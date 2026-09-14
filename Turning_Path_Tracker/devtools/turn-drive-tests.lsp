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

(defun turn-test-drive-deg (r) (/ (* r 180.0) pi))
(defun turn-test-drive-rad (d) (/ (* d pi) 180.0))

(defun turn-test-drive-truck ()
  (turn-segment "Truck" 20.0 8.0 30.0 8.0 4.0 nil (turn-test-drive-rad 30.0) (turn-test-drive-rad 70.0))
)

(defun turn-test-drive-rig ()
  (list
    (turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0 (turn-test-drive-rad 30.0) (turn-test-drive-rad 70.0))
    (turn-segment "Trailer" 45.5 8.5 53.0 8.5 -3.0 nil 0.0 (turn-test-drive-rad 70.0))
  )
)

;; n steps of a constant input.
(defun turn-test-drive-inputs (n steer travel / out)
  (repeat n (setq out (cons (cons steer travel) out)))
  out
)

;; AutoLISP has atan but no tan.
(defun turn-test-drive-tan (a) (/ (sin a) (cos a)))

;; THE INSTANTANEOUS TURN CENTRE IS SQUARE TO THE TRAILING AXLE, not to the
;; guide axle. The rear wheels do not steer, so the centre must lie on the line
;; through them perpendicular to the body; the guide axle then rides a larger
;; radius, wheelbase/sin(steer), while the trailing axle rides
;; wheelbase/tan(steer). Putting the centre abeam the guide axle instead was
;; what made the first version of the circle test fail by 20 ft.
(defun turn-test-drive-turn-centre (state wheelbase steer)
  (polar
    (turn-trail state)
    (+ (turn-heading state) (if (minusp steer) (- (/ pi 2.0)) (/ pi 2.0)))
    (abs (/ wheelbase (turn-test-drive-tan steer)))
  )
)

;;; ---------------------------------------------------------------------------
(defun turn-test-drive-straight (/ after before wheelbase)
  (turn-test-section "Driving straight")
  (setq
    wheelbase 20.0
    before (turn-state '(0.0 0.0) '(-20.0 0.0) 0.0 0.0 0.0)
    after (turn-drive-step before wheelbase 0.0 5.0)
  )
  (turn-test-near "the guide axle advances by exactly the distance driven"
           5.0 (distance (turn-guide before) (turn-guide after)) 1e-9)
  (turn-test-near "it advances along the heading" 0.0
           (turn-normalize-angle
             (- (angle (turn-guide before) (turn-guide after)) 0.0)) 1e-9)
  (turn-test-near "heading does not change with no steer"
           0.0 (turn-heading after) 1e-9)
  (turn-test-near "nothing turned" 0.0 (turn-turned after) 1e-9)
  (turn-test-near "the trailing axle stays one wheelbase behind"
           wheelbase (distance (turn-guide after) (turn-trail after)) 1e-9)
)

;; Drive with steer d; turn-step recovers the steer that geometry implies.
;; If those disagree, drive mode and course mode are not the same model.
(defun turn-test-drive-steer-round-trip (/ after before steer wheelbase)
  (turn-test-section "Steer in, steer out")
  (setq wheelbase 20.0)
  (foreach deg '(5.0 15.0 30.0 -20.0)
    (setq
      steer (turn-test-drive-rad deg)
      before (turn-state '(0.0 0.0) '(-20.0 0.0) 0.0 0.0 0.0)
      ;; A short step: the recovered steer is the average over the step, so it
      ;; converges on the input as the step shrinks.
      after (turn-drive-step before wheelbase steer 0.01)
    )
    (turn-test-near (strcat "steering " (rtos deg 2 1) " degrees reads back as "
                     (rtos deg 2 1))
             (abs steer) (abs (turn-steer after)) 0.001)
  )
)

;; Constant steer must trace a circle. For a bicycle model the guide axle runs
;; on radius wheelbase / sin(steer). This is the check that would catch a sign
;; error or a wheelbase used where a half-wheelbase belongs.
(defun turn-test-drive-circle (/ centre first-guide last-guide radius states steer wheelbase)
  (turn-test-section "Constant steer traces a circle of the right radius")
  (setq
    wheelbase 20.0
    steer (turn-test-drive-rad 30.0)
    radius (/ wheelbase (sin steer))
    states (car (turn-drive-path (list (turn-test-drive-truck))
                                      (turn-test-drive-inputs 200 steer 0.25)
                                      '(0.0 0.0) 0.0))
  )
  (turn-test-equal "one state per step, plus the state it started in" 201 (length states))
  (setq centre (turn-test-drive-turn-centre (car states) wheelbase steer))
  (turn-test-write (strcat "- wheelbase 20.0, steer 30 degrees: guide radius "
                    (rtos radius 2 3) ", trailing radius "
                    (rtos (/ wheelbase (turn-test-drive-tan steer)) 2 3)))
  (turn-test-check "the guide axle holds that radius to within 1 percent"
            (< (turn-test-drive-max-radius-error states centre radius) (* 0.01 radius)))
  ;; And the trailing axle rides the smaller radius, which is what offtracking
  ;; IS. If these two came out equal the model would be a rigid body, not a
  ;; steered one.
  (turn-test-check "the trailing axle rides wheelbase/tan(steer), also within 1 percent"
            (< (turn-test-drive-max-trail-error states centre (/ wheelbase (turn-test-drive-tan steer)))
               (* 0.01 radius)))
  (turn-test-drive-convergence)
)

;; The residual is integration error, not a modelling error: each step moves the
;; guide along a straight chord in the direction the wheel points, so a coarser
;; step leaves the circle by more. Asserting a magic tolerance would just be
;; picking a number. Asserting that HALVING THE STEP HALVES THE ERROR is the
;; real claim about a first-order integrator, and it is what would catch the
;; error becoming systematic rather than numerical.
(defun turn-test-drive-convergence (/ coarse fine ratio)
  (setq
    coarse (turn-test-drive-circle-error 0.50)
    fine (turn-test-drive-circle-error 0.25)
    ratio (/ coarse fine)
  )
  (turn-test-write (strcat "- radius error at step 0.50: " (rtos coarse 2 6)))
  (turn-test-write (strcat "- radius error at step 0.25: " (rtos fine 2 6)))
  (turn-test-write (strcat "- ratio: " (rtos ratio 2 3) " (first order predicts ~2)"))
  (turn-test-check "halving the step at least halves the error" (< 1.8 ratio))
)

;; Radius error after driving a fixed DISTANCE at a given step size, so the two
;; runs cover the same arc and only the step differs.
(defun turn-test-drive-circle-error (step / centre radius states steer wheelbase)
  (setq
    wheelbase 20.0
    steer (turn-test-drive-rad 30.0)
    radius (/ wheelbase (sin steer))
    states (car (turn-drive-path
                  (list (turn-test-drive-truck))
                  (turn-test-drive-inputs (fix (/ 50.0 step)) steer step)
                  '(0.0 0.0) 0.0))
    centre (turn-test-drive-turn-centre (car states) wheelbase steer)
  )
  (turn-test-drive-max-radius-error states centre radius)
)

(defun turn-test-drive-max-radius-error (states centre radius / err worst)
  (setq worst 0.0)
  (foreach s states
    (setq err (abs (- (distance centre (turn-guide s)) radius)))
    (if (> err worst) (setq worst err))
  )
  worst
)

(defun turn-test-drive-max-trail-error (states centre radius / err worst)
  (setq worst 0.0)
  (foreach s states
    (setq err (abs (- (distance centre (turn-trail s)) radius)))
    (if (> err worst) (setq worst err))
  )
  worst
)

;;; ---------------------------------------------------------------------------
;;; THE EQUIVALENCE TEST
;;;
;;; Drive the rig, take the course its guide axle actually traced, and follow
;;; that course with turn-path. The two must agree at every step of every
;;; segment. This is what stops drive mode becoming a second implementation of
;;; the tracking model that slowly drifts away from the first.
;;; ---------------------------------------------------------------------------
(defun turn-test-drive-equivalence (/ course driven followed rig worst)
  (turn-test-section "Driving and following a course are the same kinematics")
  (setq
    rig (turn-test-drive-rig)
    driven (turn-drive-path rig (turn-test-drive-inputs 240 (turn-test-drive-rad 20.0) 0.5) '(0.0 0.0) 0.0)
    ;; The course the powered guide axle actually drove.
    course (mapcar 'turn-guide (car driven))
    followed (turn-path rig course 0.0)
  )
  (turn-test-equal "same number of segments" (length driven) (length followed))
  (turn-test-equal "same number of steps" (length (car driven)) (length (car followed)))

  (setq worst (turn-test-drive-worst-guide-gap driven followed))
  (turn-test-write (strcat "- worst guide-point disagreement over "
                    (itoa (* (length driven) (length (car driven))))
                    " states: " (rtos worst 2 12)))
  (turn-test-check "every segment's guide point agrees to within a millionth of a unit"
            (< worst 1e-6))

  (setq worst (turn-test-drive-worst-heading-gap driven followed))
  (turn-test-write (strcat "- worst heading disagreement: " (rtos (turn-test-drive-deg worst) 2 12)
                    " degrees"))
  (turn-test-check "every heading agrees too" (< worst 1e-9))
)

(defun turn-test-drive-worst-guide-gap (a b / gap worst)
  (setq worst 0.0)
  (mapcar
    '(lambda (sa sb)
       (mapcar
         '(lambda (x y)
            (setq gap (distance (turn-guide x) (turn-guide y)))
            (if (> gap worst) (setq worst gap))
          )
         sa sb
       )
     )
    a b
  )
  worst
)

(defun turn-test-drive-worst-heading-gap (a b / gap worst)
  (setq worst 0.0)
  (mapcar
    '(lambda (sa sb)
       (mapcar
         '(lambda (x y)
            (setq gap (abs (turn-normalize-angle
                             (- (turn-heading x) (turn-heading y)))))
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
(defun turn-test-drive-rest-states (/ rig states)
  (turn-test-section "The rig at rest, before it is driven anywhere")
  (setq rig (turn-test-drive-rig) states (turn-rest-states rig '(0.0 0.0) 0.0))
  (turn-test-equal "one state per segment" 2 (length states))
  (turn-test-near "the tractor's guide axle is where we put it"
           0.0 (distance '(0.0 0.0) (turn-guide (car states))) 1e-9)
  (turn-test-near "the tractor's trailing axle is one wheelbase back"
           19.5 (distance (turn-guide (car states)) (turn-trail (car states))) 1e-9)
  ;; Hitch is 0 on this tractor, so the trailer's kingpin sits over the drive
  ;; axle and the trailer's guide axle starts there.
  (turn-test-near "the trailer is hitched at the tractor's drive axle"
           0.0 (distance (turn-trail (car states)) (turn-guide (cadr states))) 1e-9)
  (turn-test-near "and stretches its own wheelbase behind that"
           45.5 (distance (turn-guide (cadr states)) (turn-trail (cadr states))) 1e-9)
  (turn-test-near "everything starts straight, so no articulation"
           0.0 (car (turn-articulation (list (car states)) (list (cadr states)))) 1e-9)
)

;; A gentle enough turn that the rig CAN follow it. See the jackknife test for
;; what happens when it cannot: a WB-67's trailer is 45.5 long, so a tractor
;; whose own trailing axle rides a radius smaller than that has set the trailer
;; an impossible problem, and 25 degrees of steer does exactly that.
(defun turn-test-drive-trailer-tracks-inside (/ art driven rig steer)
  (turn-test-section "A driven trailer tracks inside the tractor")
  (setq
    rig (turn-test-drive-rig)
    steer (turn-test-drive-rad 10.0)
    driven (turn-drive-path rig (turn-test-drive-inputs 400 steer 1.0) '(0.0 0.0) 0.0)
    art (turn-articulation (car driven) (cadr driven))
  )
  (turn-test-write (strcat "- 10 degrees of steer: the tractor's trailing axle rides "
                    (rtos (/ 19.5 (turn-test-drive-tan steer)) 2 2)
                    ", comfortably outside the 45.5 trailer wheelbase"))
  (turn-test-check "articulation starts at zero" (< (abs (car art)) 1e-9))
  (turn-test-check "and grows as the turn is held" (< (abs (car art)) (abs (last art))))
  (turn-test-write (strcat "- articulation after 400 ft: "
                    (rtos (turn-test-drive-max-abs-list art) 2 2) " degrees max"))
  ;; A trailer swinging WIDER than the tractor would mean a sign error.
  (turn-test-check "the trailer's trailing axle stays inside the tractor's path"
            (turn-test-drive-tracks-inside-p driven (car rig) steer))
)

;; Drive a rig into a turn it cannot physically make and the articulation limit
;; must object. This is the analysis 1.1.x collected inputs for and never used,
;; now reachable from the wheel rather than only from a drawn course.
(defun turn-test-drive-jackknife (/ art driven findings rig steer)
  (turn-test-section "Driving into a turn the rig cannot make")
  (setq
    rig (turn-test-drive-rig)
    steer (turn-test-drive-rad 25.0)
    ;; Far enough for it to actually happen. There is no steady state to reach:
    ;; with no radius the trailer can settle on, the articulation just keeps
    ;; growing until the rig is folded.
    driven (turn-drive-path rig (turn-test-drive-inputs 800 steer 0.5) '(0.0 0.0) 0.0)
    art (turn-articulation (car driven) (cadr driven))
    findings (turn-findings rig driven)
  )
  (turn-test-write (strcat "- 25 degrees of steer puts the tractor's trailing axle on "
                    (rtos (/ 19.5 (turn-test-drive-tan steer)) 2 2)
                    ", INSIDE the 45.5 trailer wheelbase - the trailer cannot follow"))
  (turn-test-write (strcat "- articulation reaches " (rtos (turn-test-drive-max-abs-list art) 2 2)
                    " degrees against a 70.0 limit"))
  (turn-test-check "articulation passes the vehicle's articulation limit"
            (< 70.0 (turn-test-drive-max-abs-list art)))
  ;; 25 degrees is INSIDE the 30 degree steering lock, so the driver has done
  ;; nothing the tractor cannot do. The finding has to come from the hitch.
  (turn-test-check "and it is reported, even though the steering lock was never exceeded"
            (not (null findings)))
  (if findings (foreach f findings (turn-test-write (strcat "- reported: " f))))
)

(defun turn-test-drive-max-abs-list (lst / worst)
  (setq worst 0.0)
  (foreach a lst (if (> (abs (turn-test-drive-deg a)) worst) (setq worst (abs (turn-test-drive-deg a)))))
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
(defun turn-test-drive-tracks-inside-p (driven segment steer / centre lead follow n ok)
  (setq
    centre (turn-test-drive-turn-centre (car (car driven))
                            (turn-seg-get segment "wheelbase") steer)
    n (/ (length (car driven)) 4)
    lead (turn-test-drive-tail-of (car driven) n)
    follow (turn-test-drive-tail-of (cadr driven) n)
    ok T
  )
  (mapcar
    '(lambda (a b)
       (if (> (distance centre (turn-trail b))
              (+ 0.001 (distance centre (turn-guide a))))
         (setq ok nil)
       )
     )
    lead follow
  )
  ok
)

(defun turn-test-drive-tail-of (lst n)
  (repeat (- (length lst) n) (setq lst (cdr lst)))
  lst
)

;; Drive mode must hand the rest of the program something it already knows how
;; to use, or nothing downstream works on a driven rig.
(defun turn-test-drive-shape (/ driven findings rig)
  (turn-test-section "A driven path is the same shape as a followed one")
  (setq
    rig (turn-test-drive-rig)
    driven (turn-drive-path rig (turn-test-drive-inputs 40 (turn-test-drive-rad 15.0) 1.0) '(0.0 0.0) 0.0)
  )
  (turn-test-equal "one list of states per segment" (length rig) (length driven))
  (turn-test-check "every segment has the same number of states"
            (= (length (car driven)) (length (cadr driven))))
  (turn-test-check "the course length of a driven path is computable"
            (< 0.0 (turn-course-length (car driven))))
  (turn-test-near "and equals the distance actually driven" 40.0
           (turn-course-length (car driven)) 0.001)
  ;; The judge works on it unchanged. That is the whole reason for the shape.
  (setq findings (turn-findings rig driven))
  (turn-test-check "turn-findings accepts a driven path"
            (or (null findings) (listp findings)))
  (turn-test-check "15 degrees of steer is inside a 30 degree lock, so no finding"
            (null findings))
)

;; Steering past the lock must be REPORTED, not silently clamped. The kernel
;; does what it is told; turn-findings is what objects.
(defun turn-test-drive-over-lock (/ driven findings rig)
  (turn-test-section "Steering past the lock is reported, not silently clamped")
  (setq
    rig (list (turn-test-drive-truck))
    driven (turn-drive-path rig (turn-test-drive-inputs 40 (turn-test-drive-rad 45.0) 1.0) '(0.0 0.0) 0.0)
    findings (turn-findings rig driven)
  )
  (turn-test-check "driving 45 degrees on a 30 degree lock produces a finding"
            (not (null findings)))
  (if findings (turn-test-write (strcat "- reported: " (car findings))))
)

;;; ---------------------------------------------------------------------------
;;; Steering toward a target. This is what the cursor does in DRIVE, and it is
;;; the one place the steering lock clamps: a driver cannot haul the wheel past
;;; the stops, so an intention the vehicle cannot carry out is not available.
;;; ---------------------------------------------------------------------------
(defun turn-test-drive-steer-toward (/ lock state)
  (turn-test-section "Steering toward a target point")
  (setq
    lock (turn-test-drive-rad 30.0)
    state (turn-state '(0.0 0.0) '(-20.0 0.0) 0.0 0.0 0.0)
  )
  (turn-test-near "dead ahead needs no steer"
           0.0 (turn-steer-toward state '(50.0 0.0) lock) 1e-9)
  (turn-test-near "a target 10 degrees to the left asks for 10 degrees"
           (turn-test-drive-rad 10.0) (turn-steer-toward state '(50.0 8.8163) lock) 0.001)
  (turn-test-near "a target 10 degrees to the right asks for -10"
           (turn-test-drive-rad -10.0) (turn-steer-toward state '(50.0 -8.8163) lock) 0.001)
  ;; The clamp.
  (turn-test-near "a target square to the left is limited to the lock"
           lock (turn-steer-toward state '(0.0 50.0) lock) 1e-9)
  (turn-test-near "and square to the right, to minus the lock"
           (- lock) (turn-steer-toward state '(0.0 -50.0) lock) 1e-9)
  ;; Behind: the rig cannot reverse, so the best it can do is turn as hard as it
  ;; can. Which way it picks does not matter; that it picks a full lock does.
  (turn-test-near "a target directly behind still asks for full lock"
           lock (abs (turn-steer-toward state '(-50.0 0.1) lock)) 1e-9)
  ;; A vehicle with no recorded lock must not have one invented for it. Every
  ;; library vehicle's angle is the zeroed placeholder.
  (turn-test-near "a vehicle with no lock recorded is not clamped"
           (/ pi 2.0) (turn-steer-toward state '(0.0 50.0) 0.0) 1e-9)
)

;; DRIVE's loop does one thing the kernel does not: it turns cursor positions
;; into (steer . travel) inputs. That rule is small enough to restate here and
;; run without a human, which is the only way any of the interaction gets tested
;; at all -- grread waits for a person and a harness is not one.
;; One cursor event. Returns the new states and pushes an input, or returns the
;; states unchanged when the cursor is not yet a step ahead. Exactly the rule in
;; turn-drive-read.
(defun turn-test-drive-cursor-event (vehicle states target step lock / steer)
  (if (>= (distance (turn-guide (car states)) target) step)
    (progn
      (setq
        steer (turn-steer-toward (car states) target lock)
        *turn-test-drive-inputs* (cons (cons steer step) *turn-test-drive-inputs*)
      )
      (turn-drive vehicle states steer step)
    )
    states
  )
)

;; Feed n cursor events at a fixed target and report where the rig ended up.
(defun turn-test-drive-drive-at (vehicle target step lock n / states)
  (setq states (turn-rest-states vehicle '(0.0 0.0) 0.0) *turn-test-drive-inputs* nil)
  (repeat n (setq states (turn-test-drive-cursor-event vehicle states target step lock)))
  states
)

(defun turn-test-drive-cursor-rule (/ driven lock states step vehicle)
  (turn-test-section "The cursor rule, replayed without a cursor")
  (setq vehicle (list (turn-test-drive-truck)) lock (turn-test-drive-rad 30.0) step 1.0)

  ;; A reachable target: straight ahead.
  (setq states (turn-test-drive-drive-at vehicle '(60.0 0.0) step lock 200))
  (turn-test-check "200 cursor events can never spend more than 200 steps"
            (<= (length *turn-test-drive-inputs*) 200))
  (turn-test-check "the rig reaches a target dead ahead"
            (< (distance (turn-guide (car states)) '(60.0 0.0)) step))
  (turn-test-write (strcat "- arrived after " (itoa (length *turn-test-drive-inputs*))
                    " of 200 offered steps, then stopped"))
  (turn-test-check "and stops there, spending no further steps"
            (< (length *turn-test-drive-inputs*) 200))

  ;; Replaying the collected inputs through the kernel must land in the same
  ;; place. This is what DRIVE actually does: the loop only collects inputs, the
  ;; tested kernel computes everything that gets drawn.
  (setq driven (turn-drive-path vehicle (reverse *turn-test-drive-inputs*) '(0.0 0.0) 0.0))
  (turn-test-near "replaying the collected inputs lands in the same place"
           0.0
           (distance (turn-guide (car states))
                     (turn-guide (last (car driven))))
           1e-9)

  ;; THE ONE THAT HUNG AUTOCAD. A 20 ft wheelbase on a 30 degree lock has a
  ;; minimum guide radius of 40, so a cursor 40 out and square abeam is a point
  ;; the rig can never reach: it orbits. The first version of the loop drove
  ;; "until the cursor is reached" and never came back. One step per event makes
  ;; termination structural rather than something to hope for.
  (setq states (turn-test-drive-drive-at vehicle '(0.0 40.0) step lock 500))
  (turn-test-equal "an unreachable cursor spends exactly one step per event, and returns"
            500 (length *turn-test-drive-inputs*))
  (turn-test-check "the rig is still circling, not arrived"
            (>= (distance (turn-guide (car states)) '(0.0 40.0)) step))
  (turn-test-write "- 500 events, 500 steps, no hang: the rig orbits a point it cannot reach")
)

;;; ---------------------------------------------------------------------------
(defun turn-test-drive-run-all ()
  (turn-test-drive-straight)
  (turn-test-drive-steer-round-trip)
  (turn-test-drive-circle)
  (turn-test-drive-rest-states)
  (turn-test-drive-equivalence)
  (turn-test-drive-trailer-tracks-inside)
  (turn-test-drive-jackknife)
  (turn-test-drive-steer-toward)
  (turn-test-drive-cursor-rule)
  (turn-test-drive-shape)
  (turn-test-drive-over-lock)
  (princ)
)
