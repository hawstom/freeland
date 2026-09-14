;;; turn-core-tests.lsp - Unit tests for the TURN 2.0 tracking kernel.
;;;
;;; The kernel is pure: no prompts, no entmake, no drawing database. So these
;;; tests call it directly and check invariants that have a right answer,
;;; instead of driving AutoCAD prompts and squinting at the result.
;;;
;;; Requires turn-tests.lsp (logging and assertions) and src/turn.lsp.

;;; ---------------------------------------------------------------------------
;;; Extra assertions for real numbers
;;; ---------------------------------------------------------------------------
(defun turn-test-near (label expected actual tol)
  (turn-test-check
    (strcat label " (expected ~" (rtos expected 2 6) ", got " (rtos actual 2 6) ")")
    (< (abs (- expected actual)) tol)
  )
)

;;; ---------------------------------------------------------------------------
;;; Fixtures
;;; ---------------------------------------------------------------------------
;; A straight course along +X, `n` steps of length `step` starting at origin.
(defun turn-test-kernel-straight-course (n step / i out)
  (setq i -1)
  (repeat (1+ n)
    (setq i (1+ i) out (cons (list (* i step) 0.0) out))
  )
  (reverse out)
)

;; A course that walks counter-clockwise around a circle of radius r centred at
;; the origin, starting at (r 0), `n` steps covering `sweep` radians total.
(defun turn-test-kernel-circle-course (r n sweep / i out t-i)
  (setq i -1)
  (repeat (1+ n)
    (setq
      i (1+ i)
      t-i (* sweep (/ (float i) n))
      out (cons (polar '(0.0 0.0) t-i r) out)
    )
  )
  (reverse out)
)

;; A simple tractor. wheelbase 14, no trailer.
(defun turn-test-kernel-tractor ()
  (turn-segment "Tractor" 14.0 7.0 20.0 8.0 3.0 nil (* pi (/ 30.0 180.0)) 0.0)
)

;; A tractor that tows, 3 ft behind its rear axle.
(defun turn-test-kernel-tractor-towing ()
  (turn-segment "Tractor" 14.0 7.0 20.0 8.0 3.0 3.0 (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
)

;; A trailer. front-hang is negative: the body starts behind the hitch eye.
(defun turn-test-kernel-trailer (name hitch)
  (turn-segment name 12.0 7.0 18.0 8.0 -2.0 hitch 0.0 (* pi (/ 70.0 180.0)))
)

;;; ---------------------------------------------------------------------------
;;; Tests
;;; ---------------------------------------------------------------------------

(defun turn-test-kernel-asin ()
  (turn-test-section "Arcsine (1.1.x returned tan(asin x); the atan was missing)")
  (turn-test-near "asin 0.0" 0.0 (turn-asin 0.0) 1e-9)
  (turn-test-near "asin 0.5" 0.523598776 (turn-asin 0.5) 1e-6)
  (turn-test-near "asin -0.5" -0.523598776 (turn-asin -0.5) 1e-6)
  (turn-test-near "asin 1.0" 1.570796327 (turn-asin 1.0) 1e-6)
)

(defun turn-test-kernel-normalize ()
  (turn-test-section "Angle normalisation")
  (turn-test-near "normalize 0" 0.0 (turn-normalize-angle 0.0) 1e-9)
  (turn-test-near "normalize 2pi" 0.0 (turn-normalize-angle (* 2 pi)) 1e-9)
  (turn-test-near "normalize 350 deg reads as -10" (* pi (/ -10.0 180.0))
           (turn-normalize-angle (* pi (/ 350.0 180.0))) 1e-9)
)

;; NOTE: do not name a local `last`. AutoLISP has a `last` function, and a
;; local of that name shadows it, so (last states) becomes a call to nil.
(defun turn-test-kernel-straight (/ course final states)
  (turn-test-section "Straight course: nothing should turn")
  (setq
    course (turn-test-kernel-straight-course 40 2.0)
    states (turn-segment-path 14.0 course 0.0)
    final (last states)
  )
  (turn-test-equal "one state per course point" (length course) (length states))
  (turn-test-near "final heading unchanged" 0.0 (turn-heading final) 1e-9)
  (turn-test-near "trailing axle stays a wheelbase behind"
           14.0 (distance (turn-guide final) (turn-trail final)) 1e-9)
  (turn-test-near "trailing axle stayed on the centreline" 0.0 (cadr (turn-trail final)) 1e-9)
  (turn-test-near "no steer demanded" 0.0 (abs (turn-steer final)) 1e-9)
)

;; The invariant that proves the tracking equation: a guide axle going round a
;; circle of radius R drags a trailing axle round a concentric circle of
;; radius sqrt(R^2 - L^2).
(defun turn-test-kernel-circle (/ course expected r states trail-r wheelbase)
  (turn-test-section "Circular course: trailing axle radius = sqrt(R^2 - L^2)")
  (setq
    r 50.0
    wheelbase 14.0
    ;; Two full turns, so the transient from the assumed straight start decays.
    course (turn-test-kernel-circle-course r 720 (* 4 pi))
    states (turn-segment-path wheelbase course (/ pi 2))
    trail-r (distance '(0.0 0.0) (turn-trail (last states)))
    expected (sqrt (- (* r r) (* wheelbase wheelbase)))
  )
  (turn-test-near "steady-state trailing radius" expected trail-r 0.05)
  (turn-test-near "steer angle = asin(L/R)"
           (turn-asin (/ wheelbase r))
           (abs (turn-steer (last states)))
           0.005)
)

;; The chain. Each towed segment tracks tighter than the one ahead of it.
(defun turn-test-kernel-chain (/ course paths radii vehicle)
  (turn-test-section "Segment chain: a tractor and two trailers")
  (setq
    vehicle (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "Trailer1" 2.0) (turn-test-kernel-trailer "Trailer2" nil))
    course (turn-test-kernel-circle-course 60.0 900 (* 6 pi))
    paths (turn-path vehicle course (/ pi 2))
  )
  (turn-test-equal "one path per segment" 3 (length paths))
  (turn-test-equal "every path has one state per course point"
            (list (length course) (length course) (length course))
            (mapcar 'length paths))
  (setq
    radii
     (mapcar '(lambda (states) (distance '(0.0 0.0) (turn-trail (last states)))) paths)
  )
  (turn-test-write (strcat "- trailing-axle radii by segment: " (vl-princ-to-string radii)))
  (turn-test-check "trailer 1 tracks inside the tractor" (< (cadr radii) (car radii)))
  (turn-test-check "trailer 2 tracks inside trailer 1" (< (caddr radii) (cadr radii)))
  (turn-test-check "all radii are positive and finite" (and (< 0 (caddr radii)) (< (car radii) 61.0)))
)

;; A vehicle with no trailer must produce exactly one path, and adding a hitch
;; must not change how the lead segment tracks.
(defun turn-test-kernel-lead-unaffected (/ course paths-solo paths-towing)
  (turn-test-section "Towing does not disturb the segment doing the towing")
  (setq
    course (turn-test-kernel-circle-course 60.0 300 (* 2 pi))
    paths-solo (turn-path (list (turn-test-kernel-tractor)) course (/ pi 2))
    paths-towing (turn-path (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "T1" nil)) course (/ pi 2))
  )
  (turn-test-equal "solo vehicle yields one path" 1 (length paths-solo))
  (turn-test-equal "towing vehicle yields two paths" 2 (length paths-towing))
  (turn-test-near "lead segment tracks identically either way"
           0.0
           (distance (turn-trail (last (car paths-solo)))
                     (turn-trail (last (car paths-towing))))
           1e-9)
)

(defun turn-test-kernel-body-corners (/ corners segment state)
  (turn-test-section "Body geometry")
  ;; Tractor pointed along +X, guide axle at the origin.
  ;; front-hang 3 => bumper at x=3. body-length 20 => tail at x=-17.
  ;; body-width 8 => sides at y=+/-4.
  (setq
    segment (turn-test-kernel-tractor)
    state (turn-state '(0.0 0.0) '(-14.0 0.0) 0.0 0.0 0.0)
    corners (turn-body-corners segment state)
  )
  (turn-test-near "front left x" 3.0 (car (nth 0 corners)) 1e-9)
  (turn-test-near "front left y" 4.0 (cadr (nth 0 corners)) 1e-9)
  (turn-test-near "front right y" -4.0 (cadr (nth 1 corners)) 1e-9)
  (turn-test-near "rear right x" -17.0 (car (nth 2 corners)) 1e-9)
  (turn-test-near "rear left y" 4.0 (cadr (nth 3 corners)) 1e-9)
)

;; The swept width of the manoeuvre: how far outside and inside the guide
;; circle the body actually reaches. The course here runs counter-clockwise,
;; which is a LEFT turn, so "left" points toward the centre: the front-RIGHT
;; corner is the outer extreme and an inner corner is the tight side.
(defun turn-test-kernel-envelope (/ corner course inner locus outer segment states)
  (turn-test-section "Corner loci - the left/right swept lines users ask for")
  (setq
    segment (turn-test-kernel-tractor)
    course (turn-test-kernel-circle-course 50.0 360 (* 2 pi))
    states (turn-segment-path 14.0 course (/ pi 2))
    locus (turn-corner-locus segment states 1)
    outer 0.0
    inner 1e9
    corner -1
  )
  (turn-test-equal "one locus point per step" (length states) (length locus))
  ;; Outer extreme: the front outboard corner.
  (foreach p locus
    (if (> (distance '(0.0 0.0) p) outer) (setq outer (distance '(0.0 0.0) p)))
  )
  ;; Inner extreme: the closest any corner of the body gets to the centre.
  (repeat 4
    (setq corner (1+ corner))
    (foreach p (turn-corner-locus segment states corner)
      (if (< (distance '(0.0 0.0) p) inner) (setq inner (distance '(0.0 0.0) p)))
    )
  )
  (turn-test-write (strcat "- outer swept radius (front outboard corner): " (rtos outer 2 4)))
  (turn-test-write (strcat "- inner swept radius (tightest body corner): " (rtos inner 2 4)))
  (turn-test-write (strcat "- swept width: " (rtos (- outer inner) 2 4)
                    " for a body only " (rtos (turn-seg-get segment "body-width") 2 4) " wide"))
  (turn-test-check "front outboard corner sweeps outside the guide circle" (> outer 50.0))
  (turn-test-check "body reaches inside the trailing axle circle" (< inner 48.0))
  (turn-test-check "swept width exceeds the body width" (> (- outer inner) (turn-seg-get segment "body-width")))
)

(defun turn-test-kernel-findings (/ course paths tight vehicle findings)
  (turn-test-section "Analysis: steering lock and jackknife")
  ;; A generous vehicle on a gentle curve: nothing to report.
  (setq
    vehicle (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "T1" nil))
    course (turn-test-kernel-circle-course 200.0 400 pi)
    paths (turn-path vehicle course (/ pi 2))
    findings (turn-findings vehicle paths)
  )
  (turn-test-equal "gentle curve reports nothing" 0 (length findings))
  ;; Same vehicle, a radius far tighter than its 30-degree steering lock allows.
  (setq
    course (turn-test-kernel-circle-course 18.0 400 pi)
    paths (turn-path vehicle course (/ pi 2))
    findings (turn-findings vehicle paths)
  )
  (foreach f findings (turn-test-write (strcat "- reported: " f)))
  (turn-test-check "tight radius is reported as unachievable" (< 0 (length findings)))
)

(defun turn-test-kernel-attributes (/ atts vehicle)
  (turn-test-section "Reading a vehicle from block attributes")
  ;; Exactly the tags BUILDVEHICLE has written since 1.1.x, plus a second
  ;; trailer in the new indexed form.
  (setq
    atts
     '(("VEHNAME" . "WB-50") ("VEHBODYLENGTH" . "20.0") ("VEHWIDTH" . "8.0")
       ("VEHFRONTHANG" . "3.0") ("VEHWHEELBASE" . "14.0") ("VEHWHEELWIDTH" . "7.0")
       ("VEHREARHITCH" . "3.0") ("VEHSTEERLOCK" . "30.0") ("VEHARTANGLE" . "70.0")
       ("TRAILHAVE" . "Yes")
       ("TRAILNAME" . "Box") ("TRAILERBODYLENGTH" . "18.0") ("TRAILERWIDTH" . "8.0")
       ("TRAILERFRONTHANG" . "2.0") ("TRAILERHITCHTOWHEEL" . "12.0")
       ("TRAILERWHEELWIDTH" . "7.0") ("TRAILERREARHITCH" . "2.0")
       ("TRAILERARTANGLE" . "70.0") ("TRAILER2HAVE" . "Yes")
       ("TRAILER2NAME" . "Pup") ("TRAILER2BODYLENGTH" . "14.0") ("TRAILER2WIDTH" . "8.0")
       ("TRAILER2FRONTHANG" . "2.0") ("TRAILER2HITCHTOWHEEL" . "10.0")
       ("TRAILER2WHEELWIDTH" . "7.0") ("TRAILER2ARTANGLE" . "70.0")
      )
    vehicle (turn-vehicle-from-attributes atts)
  )
  (turn-test-equal "three segments read" 3 (length vehicle))
  (turn-test-equal "segment names" '("WB-50" "Box" "Pup")
            (mapcar '(lambda (s) (turn-seg-get s "name")) vehicle))
  (turn-test-near "tractor wheelbase" 14.0 (turn-seg-get (car vehicle) "wheelbase") 1e-9)
  (turn-test-near "trailer wheelbase comes from HITCHTOWHEEL"
           12.0 (turn-seg-get (cadr vehicle) "wheelbase") 1e-9)
  (turn-test-near "tractor front-hang is forward-positive"
           3.0 (turn-seg-get (car vehicle) "front-hang") 1e-9)
  (turn-test-near "trailer front-hang is negated to the single convention"
           -2.0 (turn-seg-get (cadr vehicle) "front-hang") 1e-9)
  (turn-test-near "steer lock converted to radians" (* pi (/ 30.0 180.0))
           (turn-seg-get (car vehicle) "steer-lock") 1e-9)
  (turn-test-check "last segment tows nothing" (null (turn-seg-get (caddr vehicle) "hitch")))
  ;; A 1.1.x block with no trailer must still read as a one-segment vehicle.
  (setq
    atts
     '(("VEHNAME" . "SU") ("VEHBODYLENGTH" . "30.0") ("VEHWIDTH" . "8.5")
       ("VEHFRONTHANG" . "4.0") ("VEHWHEELBASE" . "20.0") ("VEHWHEELWIDTH" . "7.0")
       ("TRAILHAVE" . "No")
      )
    vehicle (turn-vehicle-from-attributes atts)
  )
  (turn-test-equal "legacy no-trailer block reads as one segment" 1 (length vehicle))
)

(defun turn-test-kernel-layers ()
  (turn-test-section "Layer keys resolve to NCS-compliant names")
  (turn-test-equal "segment 0 body" "C-TURN-TRCK-BODY" (turn-layer 0 "BODY"))
  (turn-test-equal "segment 1 body" "C-TURN-TRL1-BODY" (turn-layer 1 "BODY"))
  (turn-test-equal "segment 2 body" "C-TURN-TRL2-BODY" (turn-layer 2 "BODY"))
  (turn-test-equal "segment 0 rear left path" "C-TURN-TRCK-REAR-LEFT"
            (turn-layer 0 "REAR-LEFT"))
  (turn-test-equal "segment 3 corner loci" "C-TURN-TRL3-CRNR" (turn-layer 3 "CRNR"))
  ;; The envelope belongs to the rig, not to a segment, so it carries no stem.
  (turn-test-equal "vehicle envelope" "C-TURN-ENVL" (turn-layer nil "ENVL"))
)


;;; ---------------------------------------------------------------------------
;;; The vehicle library
;;; ---------------------------------------------------------------------------
(setq *turn-test-kernel-vehicles-dat*
  (turn-test-src "turn-vehicles.dat"))

(defun turn-test-kernel-library (/ keys p vehicle wb50)
  (turn-test-section "Vehicle library: turn-vehicles.dat")
  ;; Read the real shipped file, not a fixture. If the extraction breaks, this
  ;; test is what notices.
  (setq
    *turn-vehicles-file* *turn-test-kernel-vehicles-dat*
    *turn-library* nil
    keys (turn-library-keys)
  )
  (turn-test-write (strcat "- keys: " (vl-princ-to-string keys)))
  (turn-test-equal "all 17 library drawings are represented" 17 (length keys))
  (turn-test-check "WB-50 is present" (and (member "WB-50" keys) T))
  (turn-test-check "P is present" (and (member "P" keys) T))

  (setq wb50 (turn-library-vehicle "WB-50"))
  (turn-test-equal "WB-50 is a two-segment vehicle" 2 (length wb50))
  (turn-test-near "WB-50 tractor wheelbase" 12.5 (turn-seg-get (car wb50) "wheelbase") 0.001)
  (turn-test-near "WB-50 trailer hitch-to-axle" 35.5 (turn-seg-get (cadr wb50) "wheelbase") 0.001)
  (turn-test-check "WB-50 tractor tows" (turn-seg-get (car wb50) "hitch"))
  (turn-test-check "WB-50 trailer tows nothing" (null (turn-seg-get (cadr wb50) "hitch")))
  ;; front-hang is forward-positive from the guide point, and BOTH signs are
  ;; real. A semi-trailer nose OVERHANGS its fifth wheel, so WB-50 is +3.0.
  ;; An articulated bus rear section starts BEHIND the joint, so A-BUS is -2.0.
  (turn-test-near "WB-50 trailer nose overhangs the fifth wheel"
           3.0 (turn-seg-get (cadr wb50) "front-hang") 0.001)
  (turn-test-near "A-BUS rear section starts behind the articulation joint"
           -2.0 (turn-seg-get (cadr (turn-library-vehicle "A-BUS")) "front-hang") 0.001)

  ;; The placeholder angles must have been stripped. A steering lock of 28.65
  ;; degrees in this file would mean TURN issuing verdicts with no basis.
  (turn-test-near "WB-50 steering lock is absent, not a placeholder"
           0.0 (turn-seg-get (car wb50) "steer-lock") 0.0001)
  (setq p 0)
  (foreach k keys
    (foreach seg (turn-library-vehicle k)
      (if (or (equal (turn-seg-get seg "steer-lock") 0.5 0.0005)
              (equal (turn-seg-get seg "art-angle") 0.5 0.0005))
        (setq p (1+ p))
      )
    )
  )
  (turn-test-equal "segments still carrying the 0.5-radian placeholder angle" 0 p)

  ;; Every library vehicle must actually track.
  (setq p 0)
  (foreach k keys
    (setq vehicle (turn-library-vehicle k))
    (if (or (null vehicle)
            (/= (length vehicle)
                (length (turn-path vehicle (turn-test-kernel-circle-course 100.0 60 pi) (/ pi 2)))))
      (setq p (1+ p))
    )
  )
  (turn-test-equal "library vehicles that fail to track a curve" 0 p)

  ;; A library with no findable file must not explode.
  (setq *turn-vehicles-file* "C:/nowhere/no-such-file.dat" *turn-library* nil)
  (turn-test-equal "a missing library reads as empty, not an error" 0 (length (turn-library-keys)))
  (setq *turn-vehicles-file* *turn-test-kernel-vehicles-dat* *turn-library* nil)
)

(defun turn-test-kernel-library-scaling (/ metric vehicle)
  (turn-test-section "Library unit conversion")
  (turn-test-near "feet to metres" 0.3048 (turn-units-metres "ft") 1e-9)
  (turn-test-near "metres to metres" 1.0 (turn-units-metres "m") 1e-9)
  (turn-test-check "an unknown unit reads as nil" (null (turn-units-metres "cubits")))
  ;; Scaling a vehicle scales every length and leaves angles alone.
  (setq
    vehicle (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "T1" nil))
    metric (turn-scale-vehicle vehicle 0.3048)
  )
  (turn-test-near "wheelbase scaled" (* 14.0 0.3048)
           (turn-seg-get (car metric) "wheelbase") 1e-9)
  (turn-test-near "negative front-hang keeps its sign when scaled" (* -2.0 0.3048)
           (turn-seg-get (cadr metric) "front-hang") 1e-9)
  (turn-test-near "steering lock is an angle and must not scale"
           (turn-seg-get (car vehicle) "steer-lock")
           (turn-seg-get (car metric) "steer-lock") 1e-9)
  (turn-test-check "a segment that tows nothing still tows nothing after scaling"
            (null (turn-seg-get (cadr metric) "hitch")))
)

;;; ---------------------------------------------------------------------------
;;; The figures TURN now reports back to the user
;;; ---------------------------------------------------------------------------
(defun turn-test-kernel-overall-length (/ wb67)
  (turn-test-section "Overall length - the check a user can make with a tape measure")
  ;; The WB-67 out of the shipped library. AASHTO publishes 73.5 ft overall, so
  ;; this is a real external check on both the library data and the arithmetic.
  (setq
    *turn-vehicles-file* *turn-test-kernel-vehicles-dat*
    *turn-library* nil
    wb67 (turn-library-vehicle "WB-67")
  )
  (turn-test-near "WB-67 overall length matches the published 73.5 ft"
           73.5 (turn-overall-length wb67) 0.05)
  ;; A single unit is just its own body.
  (turn-test-near "a lone tractor is its own body length"
           20.0 (turn-overall-length (list (turn-test-kernel-tractor))) 1e-9)
  ;; Kenya's block: the one that came out 125 ft.
  (turn-test-near "Kenya's mis-entered rig comes out at 125"
           125.0
           (turn-overall-length
             (list
               (turn-segment "T" 19.5 8.5 27.9 8.5 4.0 45.5 0.0 0.0)
               (turn-segment "R" 45.5 8.5 53.0 8.5 -3.0 nil 0.0 0.0)
             )
           )
           0.01)
)

(defun turn-test-kernel-min-radius (/ seg)
  (turn-test-section "Minimum turning radius from the steering lock")
  ;; sin(steer) = wheelbase / radius. 19.5 with a 30 degree lock -> 39.0.
  (setq seg (turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil (* pi (/ 30.0 180.0)) 0.0))
  (turn-test-near "19.5 wheelbase at 30 degrees lock" 39.0 (turn-min-radius seg) 0.001)
  ;; The lock that actually yields the AASHTO 45 ft figure.
  (setq seg (turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil (turn-asin (/ 19.5 45.0)) 0.0))
  (turn-test-near "the lock implied by a 45 ft turning radius" 45.0 (turn-min-radius seg) 0.001)
  ;; A placeholder or absent lock must report nothing rather than a fake number.
  (setq seg (turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil 0.0 0.0))
  (turn-test-check "a zero steering lock reports no radius, not a wrong one"
            (null (turn-min-radius seg)))
  ;; Every library vehicle has its lock zeroed, so none should claim a radius.
  (setq *turn-library* nil)
  (turn-test-check "no library vehicle claims a turning radius it cannot support"
            (not (vl-some '(lambda (k) (turn-min-radius (car (turn-library-vehicle k))))
                          (turn-library-keys))))
)
;;; ---------------------------------------------------------------------------
;; Kenya Caldwell's 2026-09 report came down to this and nothing else: an 82 ft
;; course under a WB-67. Everything drew correctly and the result was useless,
;; because a trailer cannot show articulation it has not had room to develop.
(defun turn-test-kernel-course-length (/ course states wb67)
  (turn-test-section "Course length against rig wheelbase")
  (setq
    *turn-vehicles-file* *turn-test-kernel-vehicles-dat*
    *turn-library* nil
    wb67 (turn-library-vehicle "WB-67")
  )
  ;; 19.5 tractor + 0.0 hitch + 45.5 trailer.
  (turn-test-near "WB-67 rig wheelbase is tractor + hitch + trailer"
           65.0 (turn-rig-wheelbase wb67) 0.001)
  ;; A single unit is just its own wheelbase - no hitch to add.
  (turn-test-near "a lone tractor's rig wheelbase is its own wheelbase"
           14.0 (turn-rig-wheelbase (list (turn-test-kernel-tractor))) 1e-9)
  ;; Course length is measured along the guide points actually walked, so a
  ;; straight 100 unit course of 1 unit steps measures 100.
  (setq
    course (turn-test-kernel-straight-course 100 1.0)
    states (turn-segment-path 19.5 course 0.0)
  )
  (turn-test-near "a 100 unit straight course measures 100"
           100.0 (turn-course-length states) 0.01)
  ;; And the ratio that decides whether the advice fires.
  (turn-test-check "82 ft under a WB-67 is below the short-course threshold"
            (< (/ 82.1 (turn-rig-wheelbase wb67)) *turn-short-course*))
  (turn-test-check "500 ft under a WB-67 is not"
            (>= (/ 500.0 (turn-rig-wheelbase wb67)) *turn-short-course*))
)

;; Release readiness. turn-layers.dat and turn-vehicles.dat are both optional -
;; a user downloads one .lsp and loads it, which is the whole FreeLand premise.
;; The absence of either must be a quiet fallback, never an error, and must never
;; silently substitute somebody else's numbers.
(defun turn-test-kernel-no-data-files (/ saved-file saved-lib saved-over)
  (turn-test-section "Runs with neither data file present")
  (setq
    saved-file *turn-vehicles-file*
    saved-lib *turn-library*
    saved-over *turn-layer-overrides*
  )
  ;; No vehicle library. Naming a file that is not there must yield nothing
  ;; rather than falling back to whatever else is on the search path.
  (setq *turn-vehicles-file* "turn-vehicles-no-such-file.dat" *turn-library* nil)
  (turn-test-check "a missing vehicles file yields an empty library"
            (null (turn-read-vehicles-dat)))
  (turn-test-check "and no keys" (null (turn-library-keys)))
  (turn-test-check "and asking for a vehicle gives nil, not an error"
            (null (turn-library-vehicle "WB-67")))
  ;; No layer overrides. The built-in NCS names must still come out.
  (setq *turn-layer-overrides* nil)
  (turn-test-equal "built-in tractor body layer" "C-TURN-TRCK-BODY" (turn-layer 0 "BODY"))
  (turn-test-equal "built-in trailer 2 body layer" "C-TURN-TRL2-BODY" (turn-layer 2 "BODY"))
  (turn-test-equal "built-in envelope layer" "C-TURN-ENVL" (turn-layer nil "ENVL"))
  (turn-test-check "a layer definition still carries colour and linetype"
            (= 3 (length (turn-layer-def 0 "BODY"))))
  ;; And a vehicle built by hand - which is what BUILDVEHICLE produces - still
  ;; tracks with no library at all.
  (turn-test-check "a hand-built rig still tracks with no data files"
            (= 2 (length (turn-path
                           (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "T1" nil))
                           (turn-test-kernel-circle-course 60.0 120 pi)
                           (/ pi 2)))))
  (setq
    *turn-vehicles-file* saved-file
    *turn-library* saved-lib
    *turn-layer-overrides* saved-over
  )
)

;; The units trap Tom hit: a library vehicle recorded in feet, dropped into a
;; drawing whose INSUNITS still says inches because that is what acad.dwt sets,
;; comes out twelve times too big. TURN was not wrong - the drawing was lying -
;; but the answer is to ask rather than to trust INSUNITS silently.
(defun turn-test-kernel-units (/ saved)
  (turn-test-section "Library scaling follows INSUNITS")
  (setq saved (getvar "insunits"))
  (turn-test-equal "ft reads as Feet" "Feet" (turn-units-name "ft"))
  (turn-test-equal "M reads as Meters" "Meters" (turn-units-name "M"))
  (turn-test-equal "in reads as Inches" "Inches" (turn-units-name "in"))
  ;; INSUNITS 1 is inches - what acad.dwt sets, and what made a feet library
  ;; vehicle come out twelve times too big in a drawing that was really feet.
  ;; TURN is right to scale: the drawing said inches. It must SAY so, which is
  ;; turn-report-units, but it must not argue with the setting.
  (setvar "insunits" 1)
  (turn-test-equal "INSUNITS 1 names itself Inches" "Inches" (turn-insunits-name))
  (turn-test-near "a feet library in a drawing declaring inches scales by 12"
           12.0 (turn-library-scale "ft") 1e-6)
  (setvar "insunits" 2)
  (turn-test-equal "INSUNITS 2 names itself Feet" "Feet" (turn-insunits-name))
  (turn-test-near "a feet library in a drawing declaring feet does not scale"
           1.0 (turn-library-scale "ft") 1e-9)
  (setvar "insunits" 6)
  (turn-test-near "a feet library in a drawing declaring metres scales by 0.3048"
           0.3048 (turn-library-scale "ft") 1e-9)
  ;; Undeclared units must not guess a factor.
  (setvar "insunits" 0)
  (turn-test-check "INSUNITS 0 names nothing" (null (turn-insunits-name)))
  (turn-test-near "an undeclared drawing is left unscaled"
           1.0 (turn-library-scale "ft") 1e-9)
  ;; Keyword list for getkword. Hyphens verified in AutoCAD, see
  ;; devtools/turn-probe-initget.
  (turn-test-equal "keyword string is space delimited"
            "A-BUS WB-67" (turn-keyword-string '("A-BUS" "WB-67")))
  (turn-test-equal "a single key has no trailing space"
            "SU" (turn-keyword-string '("SU")))
  (setvar "insunits" saved)
)

;; The remembered calculation step. Tom ran a WB-67 in a drawing declaring
;; inches, so its wheelbase read 234 and the offered step was 23.4. The next run
;; used a rig whose own default was 1.2, but the memory beat the computed value
;; and 23.4 was offered again. Enter accepted it, and a step longer than the
;; body being swept put holes through the envelope.
(defun turn-test-kernel-default-step (/ big saved small)
  (turn-test-section "The remembered step must still suit the vehicle")
  (setq saved *turn-calculationstep*)
  ;; ttc-tractor: wheelbase 14, body 20. Computed default is 1.4.
  (setq small (list (turn-test-kernel-tractor)))
  (setq *turn-calculationstep* nil)
  (turn-test-near "with no memory, the default is wheelbase/10"
           1.4 (turn-default-step small) 1e-9)
  ;; A sane memory is honoured - that is the convenience worth keeping.
  (setq *turn-calculationstep* 0.5)
  (turn-test-near "a finer remembered step is offered again"
           0.5 (turn-default-step small) 1e-9)
  ;; Tom's number, against a 20 long body. Must be refused.
  (setq *turn-calculationstep* 23.4)
  (turn-test-near "a remembered step longer than the shortest body is refused"
           1.4 (turn-default-step small) 1e-9)
  ;; Exactly at the body length is already too coarse: consecutive placements
  ;; touch without overlapping.
  (setq *turn-calculationstep* 20.0)
  (turn-test-near "a remembered step equal to the body length is refused"
           1.4 (turn-default-step small) 1e-9)
  ;; The shortest body governs, not the first one.
  (setq big (list (turn-test-kernel-tractor-towing) (turn-test-kernel-trailer "T1" nil)))
  (turn-test-near "the shortest body in the rig is the one that governs"
           18.0 (turn-shortest-body big) 1e-9)
  (setq *turn-calculationstep* saved)
)

(defun turn-test-kernel-run-all ()
  (turn-test-kernel-asin)
  (turn-test-kernel-normalize)
  (turn-test-kernel-straight)
  (turn-test-kernel-circle)
  (turn-test-kernel-chain)
  (turn-test-kernel-lead-unaffected)
  (turn-test-kernel-body-corners)
  (turn-test-kernel-envelope)
  (turn-test-kernel-findings)
  (turn-test-kernel-attributes)
  (turn-test-kernel-layers)
  (turn-test-kernel-library)
  (turn-test-kernel-library-scaling)
  (turn-test-kernel-overall-length)
  (turn-test-kernel-min-radius)
  (turn-test-kernel-course-length)
  (turn-test-kernel-no-data-files)
  (turn-test-kernel-units)
  (turn-test-kernel-default-step)
  ;; Phase 4, the drive kernel. Pure, so it belongs in this suite.
  (if turn-test-drive-run-all (turn-test-drive-run-all))
  (princ)
)
(princ "\nturn-core-tests.lsp loaded.")
(princ)
