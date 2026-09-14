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
(defun tt-near (label expected actual tol)
  (tt-check
    (strcat label " (expected ~" (rtos expected 2 6) ", got " (rtos actual 2 6) ")")
    (< (abs (- expected actual)) tol)
  )
)

;;; ---------------------------------------------------------------------------
;;; Fixtures
;;; ---------------------------------------------------------------------------
;; A straight course along +X, `n` steps of length `step` starting at origin.
(defun ttc-straight-course (n step / i out)
  (setq i -1)
  (repeat (1+ n)
    (setq i (1+ i) out (cons (list (* i step) 0.0) out))
  )
  (reverse out)
)

;; A course that walks counter-clockwise around a circle of radius r centred at
;; the origin, starting at (r 0), `n` steps covering `sweep` radians total.
(defun ttc-circle-course (r n sweep / i out t-i)
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
(defun ttc-tractor ()
  (wiki-turn-segment "Tractor" 14.0 7.0 20.0 8.0 3.0 nil (* pi (/ 30.0 180.0)) 0.0)
)

;; A tractor that tows, 3 ft behind its rear axle.
(defun ttc-tractor-towing ()
  (wiki-turn-segment "Tractor" 14.0 7.0 20.0 8.0 3.0 3.0 (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
)

;; A trailer. front-hang is negative: the body starts behind the hitch eye.
(defun ttc-trailer (name hitch)
  (wiki-turn-segment name 12.0 7.0 18.0 8.0 -2.0 hitch 0.0 (* pi (/ 70.0 180.0)))
)

;;; ---------------------------------------------------------------------------
;;; Tests
;;; ---------------------------------------------------------------------------

(defun ttc-test-asin ()
  (tt-section "Arcsine (1.1.x returned tan(asin x); the atan was missing)")
  (tt-near "asin 0.0" 0.0 (wiki-turn-asin 0.0) 1e-9)
  (tt-near "asin 0.5" 0.523598776 (wiki-turn-asin 0.5) 1e-6)
  (tt-near "asin -0.5" -0.523598776 (wiki-turn-asin -0.5) 1e-6)
  (tt-near "asin 1.0" 1.570796327 (wiki-turn-asin 1.0) 1e-6)
)

(defun ttc-test-normalize ()
  (tt-section "Angle normalisation")
  (tt-near "normalize 0" 0.0 (wiki-turn-normalize-angle 0.0) 1e-9)
  (tt-near "normalize 2pi" 0.0 (wiki-turn-normalize-angle (* 2 pi)) 1e-9)
  (tt-near "normalize 350 deg reads as -10" (* pi (/ -10.0 180.0))
           (wiki-turn-normalize-angle (* pi (/ 350.0 180.0))) 1e-9)
)

;; NOTE: do not name a local `last`. AutoLISP has a `last` function, and a
;; local of that name shadows it, so (last states) becomes a call to nil.
(defun ttc-test-straight (/ course final states)
  (tt-section "Straight course: nothing should turn")
  (setq
    course (ttc-straight-course 40 2.0)
    states (wiki-turn-segment-path 14.0 course 0.0)
    final (last states)
  )
  (tt-equal "one state per course point" (length course) (length states))
  (tt-near "final heading unchanged" 0.0 (wiki-turn-heading final) 1e-9)
  (tt-near "trailing axle stays a wheelbase behind"
           14.0 (distance (wiki-turn-guide final) (wiki-turn-trail final)) 1e-9)
  (tt-near "trailing axle stayed on the centreline" 0.0 (cadr (wiki-turn-trail final)) 1e-9)
  (tt-near "no steer demanded" 0.0 (abs (wiki-turn-steer final)) 1e-9)
)

;; The invariant that proves the tracking equation: a guide axle going round a
;; circle of radius R drags a trailing axle round a concentric circle of
;; radius sqrt(R^2 - L^2).
(defun ttc-test-circle (/ course expected r states trail-r wheelbase)
  (tt-section "Circular course: trailing axle radius = sqrt(R^2 - L^2)")
  (setq
    r 50.0
    wheelbase 14.0
    ;; Two full turns, so the transient from the assumed straight start decays.
    course (ttc-circle-course r 720 (* 4 pi))
    states (wiki-turn-segment-path wheelbase course (/ pi 2))
    trail-r (distance '(0.0 0.0) (wiki-turn-trail (last states)))
    expected (sqrt (- (* r r) (* wheelbase wheelbase)))
  )
  (tt-near "steady-state trailing radius" expected trail-r 0.05)
  (tt-near "steer angle = asin(L/R)"
           (wiki-turn-asin (/ wheelbase r))
           (abs (wiki-turn-steer (last states)))
           0.005)
)

;; The chain. Each towed segment tracks tighter than the one ahead of it.
(defun ttc-test-chain (/ course paths radii vehicle)
  (tt-section "Segment chain: a tractor and two trailers")
  (setq
    vehicle (list (ttc-tractor-towing) (ttc-trailer "Trailer1" 2.0) (ttc-trailer "Trailer2" nil))
    course (ttc-circle-course 60.0 900 (* 6 pi))
    paths (wiki-turn-path vehicle course (/ pi 2))
  )
  (tt-equal "one path per segment" 3 (length paths))
  (tt-equal "every path has one state per course point"
            (list (length course) (length course) (length course))
            (mapcar 'length paths))
  (setq
    radii
     (mapcar '(lambda (states) (distance '(0.0 0.0) (wiki-turn-trail (last states)))) paths)
  )
  (tt-write (strcat "- trailing-axle radii by segment: " (vl-princ-to-string radii)))
  (tt-check "trailer 1 tracks inside the tractor" (< (cadr radii) (car radii)))
  (tt-check "trailer 2 tracks inside trailer 1" (< (caddr radii) (cadr radii)))
  (tt-check "all radii are positive and finite" (and (< 0 (caddr radii)) (< (car radii) 61.0)))
)

;; A vehicle with no trailer must produce exactly one path, and adding a hitch
;; must not change how the lead segment tracks.
(defun ttc-test-lead-unaffected (/ course paths-solo paths-towing)
  (tt-section "Towing does not disturb the segment doing the towing")
  (setq
    course (ttc-circle-course 60.0 300 (* 2 pi))
    paths-solo (wiki-turn-path (list (ttc-tractor)) course (/ pi 2))
    paths-towing (wiki-turn-path (list (ttc-tractor-towing) (ttc-trailer "T1" nil)) course (/ pi 2))
  )
  (tt-equal "solo vehicle yields one path" 1 (length paths-solo))
  (tt-equal "towing vehicle yields two paths" 2 (length paths-towing))
  (tt-near "lead segment tracks identically either way"
           0.0
           (distance (wiki-turn-trail (last (car paths-solo)))
                     (wiki-turn-trail (last (car paths-towing))))
           1e-9)
)

(defun ttc-test-body-corners (/ corners segment state)
  (tt-section "Body geometry")
  ;; Tractor pointed along +X, guide axle at the origin.
  ;; front-hang 3 => bumper at x=3. body-length 20 => tail at x=-17.
  ;; body-width 8 => sides at y=+/-4.
  (setq
    segment (ttc-tractor)
    state (wiki-turn-state '(0.0 0.0) '(-14.0 0.0) 0.0 0.0 0.0)
    corners (wiki-turn-body-corners segment state)
  )
  (tt-near "front left x" 3.0 (car (nth 0 corners)) 1e-9)
  (tt-near "front left y" 4.0 (cadr (nth 0 corners)) 1e-9)
  (tt-near "front right y" -4.0 (cadr (nth 1 corners)) 1e-9)
  (tt-near "rear right x" -17.0 (car (nth 2 corners)) 1e-9)
  (tt-near "rear left y" 4.0 (cadr (nth 3 corners)) 1e-9)
)

;; The swept width of the manoeuvre: how far outside and inside the guide
;; circle the body actually reaches. The course here runs counter-clockwise,
;; which is a LEFT turn, so "left" points toward the centre: the front-RIGHT
;; corner is the outer extreme and an inner corner is the tight side.
(defun ttc-test-envelope (/ corner course inner locus outer segment states)
  (tt-section "Corner loci - the left/right swept lines users ask for")
  (setq
    segment (ttc-tractor)
    course (ttc-circle-course 50.0 360 (* 2 pi))
    states (wiki-turn-segment-path 14.0 course (/ pi 2))
    locus (wiki-turn-corner-locus segment states 1)
    outer 0.0
    inner 1e9
    corner -1
  )
  (tt-equal "one locus point per step" (length states) (length locus))
  ;; Outer extreme: the front outboard corner.
  (foreach p locus
    (if (> (distance '(0.0 0.0) p) outer) (setq outer (distance '(0.0 0.0) p)))
  )
  ;; Inner extreme: the closest any corner of the body gets to the centre.
  (repeat 4
    (setq corner (1+ corner))
    (foreach p (wiki-turn-corner-locus segment states corner)
      (if (< (distance '(0.0 0.0) p) inner) (setq inner (distance '(0.0 0.0) p)))
    )
  )
  (tt-write (strcat "- outer swept radius (front outboard corner): " (rtos outer 2 4)))
  (tt-write (strcat "- inner swept radius (tightest body corner): " (rtos inner 2 4)))
  (tt-write (strcat "- swept width: " (rtos (- outer inner) 2 4)
                    " for a body only " (rtos (wiki-turn-seg-get segment "body-width") 2 4) " wide"))
  (tt-check "front outboard corner sweeps outside the guide circle" (> outer 50.0))
  (tt-check "body reaches inside the trailing axle circle" (< inner 48.0))
  (tt-check "swept width exceeds the body width" (> (- outer inner) (wiki-turn-seg-get segment "body-width")))
)

(defun ttc-test-findings (/ course paths tight vehicle findings)
  (tt-section "Analysis: steering lock and jackknife")
  ;; A generous vehicle on a gentle curve: nothing to report.
  (setq
    vehicle (list (ttc-tractor-towing) (ttc-trailer "T1" nil))
    course (ttc-circle-course 200.0 400 pi)
    paths (wiki-turn-path vehicle course (/ pi 2))
    findings (wiki-turn-findings vehicle paths)
  )
  (tt-equal "gentle curve reports nothing" 0 (length findings))
  ;; Same vehicle, a radius far tighter than its 30-degree steering lock allows.
  (setq
    course (ttc-circle-course 18.0 400 pi)
    paths (wiki-turn-path vehicle course (/ pi 2))
    findings (wiki-turn-findings vehicle paths)
  )
  (foreach f findings (tt-write (strcat "- reported: " f)))
  (tt-check "tight radius is reported as unachievable" (< 0 (length findings)))
)

(defun ttc-test-attributes (/ atts vehicle)
  (tt-section "Reading a vehicle from block attributes")
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
    vehicle (wiki-turn-vehicle-from-attributes atts)
  )
  (tt-equal "three segments read" 3 (length vehicle))
  (tt-equal "segment names" '("WB-50" "Box" "Pup")
            (mapcar '(lambda (s) (wiki-turn-seg-get s "name")) vehicle))
  (tt-near "tractor wheelbase" 14.0 (wiki-turn-seg-get (car vehicle) "wheelbase") 1e-9)
  (tt-near "trailer wheelbase comes from HITCHTOWHEEL"
           12.0 (wiki-turn-seg-get (cadr vehicle) "wheelbase") 1e-9)
  (tt-near "tractor front-hang is forward-positive"
           3.0 (wiki-turn-seg-get (car vehicle) "front-hang") 1e-9)
  (tt-near "trailer front-hang is negated to the single convention"
           -2.0 (wiki-turn-seg-get (cadr vehicle) "front-hang") 1e-9)
  (tt-near "steer lock converted to radians" (* pi (/ 30.0 180.0))
           (wiki-turn-seg-get (car vehicle) "steer-lock") 1e-9)
  (tt-check "last segment tows nothing" (null (wiki-turn-seg-get (caddr vehicle) "hitch")))
  ;; A 1.1.x block with no trailer must still read as a one-segment vehicle.
  (setq
    atts
     '(("VEHNAME" . "SU") ("VEHBODYLENGTH" . "30.0") ("VEHWIDTH" . "8.5")
       ("VEHFRONTHANG" . "4.0") ("VEHWHEELBASE" . "20.0") ("VEHWHEELWIDTH" . "7.0")
       ("TRAILHAVE" . "No")
      )
    vehicle (wiki-turn-vehicle-from-attributes atts)
  )
  (tt-equal "legacy no-trailer block reads as one segment" 1 (length vehicle))
)

(defun ttc-test-layers ()
  (tt-section "Layer keys resolve to NCS-compliant names")
  (tt-equal "segment 0 body" "C-TURN-TRCK-BODY" (wiki-turn-layer 0 "BODY"))
  (tt-equal "segment 1 body" "C-TURN-TRL1-BODY" (wiki-turn-layer 1 "BODY"))
  (tt-equal "segment 2 body" "C-TURN-TRL2-BODY" (wiki-turn-layer 2 "BODY"))
  (tt-equal "segment 0 rear left path" "C-TURN-TRCK-REAR-LEFT"
            (wiki-turn-layer 0 "REAR-LEFT"))
  (tt-equal "segment 3 corner loci" "C-TURN-TRL3-CRNR" (wiki-turn-layer 3 "CRNR"))
  ;; The envelope belongs to the rig, not to a segment, so it carries no stem.
  (tt-equal "vehicle envelope" "C-TURN-ENVL" (wiki-turn-layer nil "ENVL"))
)


;;; ---------------------------------------------------------------------------
;;; The vehicle library
;;; ---------------------------------------------------------------------------
(setq *ttc-vehicles-dat*
  (tt-src "turn-vehicles.dat"))

(defun ttc-test-library (/ keys p vehicle wb50)
  (tt-section "Vehicle library: turn-vehicles.dat")
  ;; Read the real shipped file, not a fixture. If the extraction breaks, this
  ;; test is what notices.
  (setq
    *wiki-turn-vehicles-file* *ttc-vehicles-dat*
    *wiki-turn-library* nil
    keys (wiki-turn-library-keys)
  )
  (tt-write (strcat "- keys: " (vl-princ-to-string keys)))
  (tt-equal "all 17 library drawings are represented" 17 (length keys))
  (tt-check "WB-50 is present" (and (member "WB-50" keys) T))
  (tt-check "P is present" (and (member "P" keys) T))

  (setq wb50 (wiki-turn-library-vehicle "WB-50"))
  (tt-equal "WB-50 is a two-segment vehicle" 2 (length wb50))
  (tt-near "WB-50 tractor wheelbase" 12.5 (wiki-turn-seg-get (car wb50) "wheelbase") 0.001)
  (tt-near "WB-50 trailer hitch-to-axle" 35.5 (wiki-turn-seg-get (cadr wb50) "wheelbase") 0.001)
  (tt-check "WB-50 tractor tows" (wiki-turn-seg-get (car wb50) "hitch"))
  (tt-check "WB-50 trailer tows nothing" (null (wiki-turn-seg-get (cadr wb50) "hitch")))
  ;; front-hang is forward-positive from the guide point, and BOTH signs are
  ;; real. A semi-trailer nose OVERHANGS its fifth wheel, so WB-50 is +3.0.
  ;; An articulated bus rear section starts BEHIND the joint, so A-BUS is -2.0.
  (tt-near "WB-50 trailer nose overhangs the fifth wheel"
           3.0 (wiki-turn-seg-get (cadr wb50) "front-hang") 0.001)
  (tt-near "A-BUS rear section starts behind the articulation joint"
           -2.0 (wiki-turn-seg-get (cadr (wiki-turn-library-vehicle "A-BUS")) "front-hang") 0.001)

  ;; The placeholder angles must have been stripped. A steering lock of 28.65
  ;; degrees in this file would mean TURN issuing verdicts with no basis.
  (tt-near "WB-50 steering lock is absent, not a placeholder"
           0.0 (wiki-turn-seg-get (car wb50) "steer-lock") 0.0001)
  (setq p 0)
  (foreach k keys
    (foreach seg (wiki-turn-library-vehicle k)
      (if (or (equal (wiki-turn-seg-get seg "steer-lock") 0.5 0.0005)
              (equal (wiki-turn-seg-get seg "art-angle") 0.5 0.0005))
        (setq p (1+ p))
      )
    )
  )
  (tt-equal "segments still carrying the 0.5-radian placeholder angle" 0 p)

  ;; Every library vehicle must actually track.
  (setq p 0)
  (foreach k keys
    (setq vehicle (wiki-turn-library-vehicle k))
    (if (or (null vehicle)
            (/= (length vehicle)
                (length (wiki-turn-path vehicle (ttc-circle-course 100.0 60 pi) (/ pi 2)))))
      (setq p (1+ p))
    )
  )
  (tt-equal "library vehicles that fail to track a curve" 0 p)

  ;; A library with no findable file must not explode.
  (setq *wiki-turn-vehicles-file* "C:/nowhere/no-such-file.dat" *wiki-turn-library* nil)
  (tt-equal "a missing library reads as empty, not an error" 0 (length (wiki-turn-library-keys)))
  (setq *wiki-turn-vehicles-file* *ttc-vehicles-dat* *wiki-turn-library* nil)
)

(defun ttc-test-library-scaling (/ metric vehicle)
  (tt-section "Library unit conversion")
  (tt-near "feet to metres" 0.3048 (wiki-turn-units-metres "ft") 1e-9)
  (tt-near "metres to metres" 1.0 (wiki-turn-units-metres "m") 1e-9)
  (tt-check "an unknown unit reads as nil" (null (wiki-turn-units-metres "cubits")))
  ;; Scaling a vehicle scales every length and leaves angles alone.
  (setq
    vehicle (list (ttc-tractor-towing) (ttc-trailer "T1" nil))
    metric (wiki-turn-scale-vehicle vehicle 0.3048)
  )
  (tt-near "wheelbase scaled" (* 14.0 0.3048)
           (wiki-turn-seg-get (car metric) "wheelbase") 1e-9)
  (tt-near "negative front-hang keeps its sign when scaled" (* -2.0 0.3048)
           (wiki-turn-seg-get (cadr metric) "front-hang") 1e-9)
  (tt-near "steering lock is an angle and must not scale"
           (wiki-turn-seg-get (car vehicle) "steer-lock")
           (wiki-turn-seg-get (car metric) "steer-lock") 1e-9)
  (tt-check "a segment that tows nothing still tows nothing after scaling"
            (null (wiki-turn-seg-get (cadr metric) "hitch")))
)

;;; ---------------------------------------------------------------------------
;;; The figures TURN now reports back to the user
;;; ---------------------------------------------------------------------------
(defun ttc-test-overall-length (/ wb67)
  (tt-section "Overall length - the check a user can make with a tape measure")
  ;; The WB-67 out of the shipped library. AASHTO publishes 73.5 ft overall, so
  ;; this is a real external check on both the library data and the arithmetic.
  (setq
    *wiki-turn-vehicles-file* *ttc-vehicles-dat*
    *wiki-turn-library* nil
    wb67 (wiki-turn-library-vehicle "WB-67")
  )
  (tt-near "WB-67 overall length matches the published 73.5 ft"
           73.5 (wiki-turn-overall-length wb67) 0.05)
  ;; A single unit is just its own body.
  (tt-near "a lone tractor is its own body length"
           20.0 (wiki-turn-overall-length (list (ttc-tractor))) 1e-9)
  ;; Kenya's block: the one that came out 125 ft.
  (tt-near "Kenya's mis-entered rig comes out at 125"
           125.0
           (wiki-turn-overall-length
             (list
               (wiki-turn-segment "T" 19.5 8.5 27.9 8.5 4.0 45.5 0.0 0.0)
               (wiki-turn-segment "R" 45.5 8.5 53.0 8.5 -3.0 nil 0.0 0.0)
             )
           )
           0.01)
)

(defun ttc-test-min-radius (/ seg)
  (tt-section "Minimum turning radius from the steering lock")
  ;; sin(steer) = wheelbase / radius. 19.5 with a 30 degree lock -> 39.0.
  (setq seg (wiki-turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil (* pi (/ 30.0 180.0)) 0.0))
  (tt-near "19.5 wheelbase at 30 degrees lock" 39.0 (wiki-turn-min-radius seg) 0.001)
  ;; The lock that actually yields the AASHTO 45 ft figure.
  (setq seg (wiki-turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil (wiki-turn-asin (/ 19.5 45.0)) 0.0))
  (tt-near "the lock implied by a 45 ft turning radius" 45.0 (wiki-turn-min-radius seg) 0.001)
  ;; A placeholder or absent lock must report nothing rather than a fake number.
  (setq seg (wiki-turn-segment "T" 19.5 8.0 27.9 8.0 4.0 nil 0.0 0.0))
  (tt-check "a zero steering lock reports no radius, not a wrong one"
            (null (wiki-turn-min-radius seg)))
  ;; Every library vehicle has its lock zeroed, so none should claim a radius.
  (setq *wiki-turn-library* nil)
  (tt-check "no library vehicle claims a turning radius it cannot support"
            (not (vl-some '(lambda (k) (wiki-turn-min-radius (car (wiki-turn-library-vehicle k))))
                          (wiki-turn-library-keys))))
)
;;; ---------------------------------------------------------------------------
;; Kenya Caldwell's 2026-09 report came down to this and nothing else: an 82 ft
;; course under a WB-67. Everything drew correctly and the result was useless,
;; because a trailer cannot show articulation it has not had room to develop.
(defun ttc-test-course-length (/ course states wb67)
  (tt-section "Course length against rig wheelbase")
  (setq
    *wiki-turn-vehicles-file* *ttc-vehicles-dat*
    *wiki-turn-library* nil
    wb67 (wiki-turn-library-vehicle "WB-67")
  )
  ;; 19.5 tractor + 0.0 hitch + 45.5 trailer.
  (tt-near "WB-67 rig wheelbase is tractor + hitch + trailer"
           65.0 (wiki-turn-rig-wheelbase wb67) 0.001)
  ;; A single unit is just its own wheelbase - no hitch to add.
  (tt-near "a lone tractor's rig wheelbase is its own wheelbase"
           14.0 (wiki-turn-rig-wheelbase (list (ttc-tractor))) 1e-9)
  ;; Course length is measured along the guide points actually walked, so a
  ;; straight 100 unit course of 1 unit steps measures 100.
  (setq
    course (ttc-straight-course 100 1.0)
    states (wiki-turn-segment-path 19.5 course 0.0)
  )
  (tt-near "a 100 unit straight course measures 100"
           100.0 (wiki-turn-course-length states) 0.01)
  ;; And the ratio that decides whether the advice fires.
  (tt-check "82 ft under a WB-67 is below the short-course threshold"
            (< (/ 82.1 (wiki-turn-rig-wheelbase wb67)) *wiki-turn-short-course*))
  (tt-check "500 ft under a WB-67 is not"
            (>= (/ 500.0 (wiki-turn-rig-wheelbase wb67)) *wiki-turn-short-course*))
)

;; Release readiness. turn-layers.dat and turn-vehicles.dat are both optional -
;; a user downloads one .lsp and loads it, which is the whole FreeLand premise.
;; The absence of either must be a quiet fallback, never an error, and must never
;; silently substitute somebody else's numbers.
(defun ttc-test-no-data-files (/ saved-file saved-lib saved-over)
  (tt-section "Runs with neither data file present")
  (setq
    saved-file *wiki-turn-vehicles-file*
    saved-lib *wiki-turn-library*
    saved-over *wiki-turn-layer-overrides*
  )
  ;; No vehicle library. Naming a file that is not there must yield nothing
  ;; rather than falling back to whatever else is on the search path.
  (setq *wiki-turn-vehicles-file* "turn-vehicles-no-such-file.dat" *wiki-turn-library* nil)
  (tt-check "a missing vehicles file yields an empty library"
            (null (wiki-turn-read-vehicles-dat)))
  (tt-check "and no keys" (null (wiki-turn-library-keys)))
  (tt-check "and asking for a vehicle gives nil, not an error"
            (null (wiki-turn-library-vehicle "WB-67")))
  ;; No layer overrides. The built-in NCS names must still come out.
  (setq *wiki-turn-layer-overrides* nil)
  (tt-equal "built-in tractor body layer" "C-TURN-TRCK-BODY" (wiki-turn-layer 0 "BODY"))
  (tt-equal "built-in trailer 2 body layer" "C-TURN-TRL2-BODY" (wiki-turn-layer 2 "BODY"))
  (tt-equal "built-in envelope layer" "C-TURN-ENVL" (wiki-turn-layer nil "ENVL"))
  (tt-check "a layer definition still carries colour and linetype"
            (= 3 (length (wiki-turn-layer-def 0 "BODY"))))
  ;; And a vehicle built by hand - which is what BUILDVEHICLE produces - still
  ;; tracks with no library at all.
  (tt-check "a hand-built rig still tracks with no data files"
            (= 2 (length (wiki-turn-path
                           (list (ttc-tractor-towing) (ttc-trailer "T1" nil))
                           (ttc-circle-course 60.0 120 pi)
                           (/ pi 2)))))
  (setq
    *wiki-turn-vehicles-file* saved-file
    *wiki-turn-library* saved-lib
    *wiki-turn-layer-overrides* saved-over
  )
)

;; The units trap Tom hit: a library vehicle recorded in feet, dropped into a
;; drawing whose INSUNITS still says inches because that is what acad.dwt sets,
;; comes out twelve times too big. TURN was not wrong - the drawing was lying -
;; but the answer is to ask rather than to trust INSUNITS silently.
(defun ttc-test-units (/ saved)
  (tt-section "Library scaling follows INSUNITS")
  (setq saved (getvar "insunits"))
  (tt-equal "ft reads as Feet" "Feet" (wiki-turn-units-name "ft"))
  (tt-equal "M reads as Meters" "Meters" (wiki-turn-units-name "M"))
  (tt-equal "in reads as Inches" "Inches" (wiki-turn-units-name "in"))
  ;; INSUNITS 1 is inches - what acad.dwt sets, and what made a feet library
  ;; vehicle come out twelve times too big in a drawing that was really feet.
  ;; TURN is right to scale: the drawing said inches. It must SAY so, which is
  ;; wiki-turn-report-units, but it must not argue with the setting.
  (setvar "insunits" 1)
  (tt-equal "INSUNITS 1 names itself Inches" "Inches" (wiki-turn-insunits-name))
  (tt-near "a feet library in a drawing declaring inches scales by 12"
           12.0 (wiki-turn-library-scale "ft") 1e-6)
  (setvar "insunits" 2)
  (tt-equal "INSUNITS 2 names itself Feet" "Feet" (wiki-turn-insunits-name))
  (tt-near "a feet library in a drawing declaring feet does not scale"
           1.0 (wiki-turn-library-scale "ft") 1e-9)
  (setvar "insunits" 6)
  (tt-near "a feet library in a drawing declaring metres scales by 0.3048"
           0.3048 (wiki-turn-library-scale "ft") 1e-9)
  ;; Undeclared units must not guess a factor.
  (setvar "insunits" 0)
  (tt-check "INSUNITS 0 names nothing" (null (wiki-turn-insunits-name)))
  (tt-near "an undeclared drawing is left unscaled"
           1.0 (wiki-turn-library-scale "ft") 1e-9)
  ;; Keyword list for getkword. Hyphens verified in AutoCAD, see
  ;; devtools/turn-probe-initget.
  (tt-equal "keyword string is space delimited"
            "A-BUS WB-67" (wiki-turn-keyword-string '("A-BUS" "WB-67")))
  (tt-equal "a single key has no trailing space"
            "SU" (wiki-turn-keyword-string '("SU")))
  (setvar "insunits" saved)
)

;; The remembered calculation step. Tom ran a WB-67 in a drawing declaring
;; inches, so its wheelbase read 234 and the offered step was 23.4. The next run
;; used a rig whose own default was 1.2, but the memory beat the computed value
;; and 23.4 was offered again. Enter accepted it, and a step longer than the
;; body being swept put holes through the envelope.
(defun ttc-test-default-step (/ big saved small)
  (tt-section "The remembered step must still suit the vehicle")
  (setq saved *wiki-turn-calculationstep*)
  ;; ttc-tractor: wheelbase 14, body 20. Computed default is 1.4.
  (setq small (list (ttc-tractor)))
  (setq *wiki-turn-calculationstep* nil)
  (tt-near "with no memory, the default is wheelbase/10"
           1.4 (wiki-turn-default-step small) 1e-9)
  ;; A sane memory is honoured - that is the convenience worth keeping.
  (setq *wiki-turn-calculationstep* 0.5)
  (tt-near "a finer remembered step is offered again"
           0.5 (wiki-turn-default-step small) 1e-9)
  ;; Tom's number, against a 20 long body. Must be refused.
  (setq *wiki-turn-calculationstep* 23.4)
  (tt-near "a remembered step longer than the shortest body is refused"
           1.4 (wiki-turn-default-step small) 1e-9)
  ;; Exactly at the body length is already too coarse: consecutive placements
  ;; touch without overlapping.
  (setq *wiki-turn-calculationstep* 20.0)
  (tt-near "a remembered step equal to the body length is refused"
           1.4 (wiki-turn-default-step small) 1e-9)
  ;; The shortest body governs, not the first one.
  (setq big (list (ttc-tractor-towing) (ttc-trailer "T1" nil)))
  (tt-near "the shortest body in the rig is the one that governs"
           18.0 (wiki-turn-shortest-body big) 1e-9)
  (setq *wiki-turn-calculationstep* saved)
)

(defun ttc-run-all ()
  (ttc-test-asin)
  (ttc-test-normalize)
  (ttc-test-straight)
  (ttc-test-circle)
  (ttc-test-chain)
  (ttc-test-lead-unaffected)
  (ttc-test-body-corners)
  (ttc-test-envelope)
  (ttc-test-findings)
  (ttc-test-attributes)
  (ttc-test-layers)
  (ttc-test-library)
  (ttc-test-library-scaling)
  (ttc-test-overall-length)
  (ttc-test-min-radius)
  (ttc-test-course-length)
  (ttc-test-no-data-files)
  (ttc-test-units)
  (ttc-test-default-step)
  ;; Phase 4, the drive kernel. Pure, so it belongs in this suite.
  (if tdv-run-all (tdv-run-all))
  (princ)
)
(princ "\nturn-core-tests.lsp loaded.")
(princ)
