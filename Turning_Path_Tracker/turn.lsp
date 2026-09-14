;;; TURN.LSP - Turning Path Tracker
;;; Copyright 2026 Thomas Gail Haws
;;; Copyright 2008 Stephen Hitchcox
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; ===========================================================================
;;; VERSION 2.1.0-dev
;;; ===========================================================================
;;;
;;; UNRELEASED. 2.0.0 is what hawsedc.com serves; this trunk is ahead of it.
;;; devtools/turn-release.py refuses to publish while the version carries -dev,
;;; so the shipped 2.0.0 cannot be overwritten by a work in progress. Drop the
;;; suffix when the work is ready to go out.
;;;
;;; NEW IN 2.1.0: drive mode. The kernel can be driven a step at a time from a
;;; steer angle and a travel distance, instead of only following a course that
;;; was drawn first. turn-drive-path returns the same shape as
;;; turn-path, so the envelope, the findings and the report all work on a
;;; driven rig unchanged.
;;; ===========================================================================
;;;
;;; WHAT CHANGED FROM 1.1.17, AND WHY
;;;
;;; 1.1.17 modelled "a truck, and maybe one trailer" as two hand-written code
;;; paths. This version models a vehicle as an ordered list of SEGMENTS and
;;; tracks them as a chain: each segment's hitch locus becomes the next
;;; segment's course. Any number of trailers falls out of that for free.
;;;
;;; The tracking mathematics are unchanged. They were already right.
;;;
;;; The file is organised so that SECTION 3 (the kernel) is pure: it prompts
;;; for nothing, draws nothing, and touches no drawing database. That is what
;;; makes it testable without a human driving AutoCAD. Keep it that way.
;;;
;;; SECTION 1  Settings and layers
;;; SECTION 2  Small helpers
;;; SECTION 3  The tracking kernel        (pure - no I/O, no prompts, no entmake)
;;; SECTION 4  The vehicle model          (pure data)
;;; SECTION 5  Vehicle block <-> vehicle  (drawing database I/O)
;;; SECTION 5c The vehicle library        (vehicles as data)
;;; SECTION 6  Drawing the results
;;; SECTION 7  Commands
;;;
;;; ===========================================================================
;;; DEFINITIONS (carried forward from the 2.0 design notes, 2010-2015)
;;;
;;; COURSE   An alignment followed by a steerable guide axle. A list of points.
;;; PATH     The set of states that result from following a course.
;;; STEP     The state at the end of one calculation interval.
;;; SEGMENT  One rigid body of a vehicle: a tractor, a trailer, a dolly.
;;; STATE    Where one segment is, and how it is pointed, at one instant.
;;; VEHICLE  An ordered list of segments, powered unit first.
;;;
;;; A SEGMENT is an alist:
;;;   ("name"        . string)
;;;   ("wheelbase"   . real)   guide axle to trailing axle
;;;   ("axle-width"  . real)   track width, centre of tire to centre of tire
;;;   ("body-length" . real)
;;;   ("body-width"  . real)
;;;   ("front-hang"  . real)   guide axle FORWARD to front of body (may be
;;;                            negative; on a trailer the body starts behind
;;;                            the hitch eye)
;;;   ("hitch"       . real)   trailing axle BACKWARD to the hitch that tows
;;;                            the next segment. nil when nothing is towed.
;;;   ("steer-lock"  . real)   maximum steer angle, radians. Lead segment only.
;;;   ("art-angle"   . real)   maximum articulation at this segment's hitch,
;;;                            radians.
;;;
;;; A STATE is an alist:
;;;   ("guide"   . point)  centre of the steering axle, or the hitch eye
;;;   ("trail"   . point)  centre of the trailing axle
;;;   ("heading" . real)   direction the segment points, radians
;;;   ("steer"   . real)   steer angle demanded at this step, radians
;;;   ("turned"  . real)   heading change over this step, radians
;;;
;;; THEORY
;;; For each step, a wheel pair is assumed to travel in a circle as though the
;;; steering were locked. The line between rear and front wheel stays tangent
;;; to the circle the rear wheel describes:
;;;
;;;          <= Counter-clockwise Travel
;;;         ooo
;;;      o       o F0
;;;    o          /o
;;;   o      _  L/  o
;;;  o     /   \/    o
;;;  o    B1 C  B0   o
;;;   o L/ \ _ /    o
;;;    o/          o
;;;   F1 o       o
;;;         ooo
;;;
;;; Turned angle F0|C|F1 = B0|C|B1 = 2*atan{sin(alpha)/[2*L/S-cos(alpha)]}
;;; where S = distance F0 to F1, L = wheelbase, alpha = angle F1|F0|B0.
;;; ===========================================================================

;;; ===========================================================================
;;; SECTION 1  SETTINGS AND LAYERS
;;; ===========================================================================
;;; Layer names are generated per segment so that a five-trailer rig gets five
;;; sets of layers. Segment 0 (the powered unit) and segment 1 (the first
;;; trailer) keep the names 1.1.x used, so existing drawings and layer filters
;;; keep working. Segments 2 and up extend the same pattern.

(setq
  *turn-settings*
   (list
     ;;-----------------------------------------------------------------------
     ;; Program settings users can edit
     ;;-----------------------------------------------------------------------
     ;; Colours, by role. Applied to whichever segment layers get created.
     (list "color.body" "1" 'str)
     (list "color.frontpath" "1" 'str)
     (list "color.rearpath" "2" 'str)
     (list "color.hitchpath" "3" 'str)
     (list "color.corner" "6" 'str)
     (list "color.envelope" "4" 'str)
     ;; Draw the locus of each body corner (the "left and right side" lines)?
     (list "general.drawcorners" "Yes" 'str)
     ;; Draw the swept-path envelope - the outer boundary of everything every
     ;; body sweeps, as a closed polyline. This is the plan-sheet deliverable.
     (list "general.drawenvelope" "Yes" 'str)
     ;; Warn when the course demands more steer than the vehicle has?
     (list "general.checksteerlock" "Yes" 'str)
     ;;-----------------------------------------------------------------------
     ;; End of program settings users can edit
     ;;-----------------------------------------------------------------------
     (list "general.icadmode" "False" 'str)
     (list "general.version" "2.1.0-dev" 'str)
   )
)

(defun turn-setvar (var val)
  (setq var (strcase var t))
  (if (assoc var *turn-settings*)
    (setq
      *turn-settings*
       (subst
         (list var val (caddr (assoc var *turn-settings*)))
         (assoc var *turn-settings*)
         *turn-settings*
       )
    )
    (setq *turn-settings* (cons (list var val 'str) *turn-settings*))
  )
  val
)

(defun turn-getvar (var)
  (cadr (assoc (strcase var t) *turn-settings*))
)

;;; ---------------------------------------------------------------------------
;;; Layers: keys in the code, names in a data file
;;; ---------------------------------------------------------------------------
;;; The code never mentions a layer name. It asks for a KEY, and the key is
;;; resolved to a name, colour and linetype - from turn-layers.dat if the user
;;; has one anywhere on the support path, otherwise from the defaults below.
;;; This is the Layers.dat pattern from the flagship, and it is what makes a
;;; five-trailer rig possible without inventing five sets of names in code.
;;;
;;; Names follow AIA / National CAD Standard: every field is exactly four
;;; characters. 1.1.x did not manage this - C-TURN-TRCK-FRONT-LEFT-PATH has a
;;; five-character field and two fields too many. The names below are the
;;; compliant form. A user who needs the old names can say so in
;;; turn-layers.dat without touching code.
;;;
;;; Key   = <segment stem>-<role>, e.g. TRCK-BODY, TRL1-REAR-LEFT
;;; Stem  = TRCK for the powered unit, TRL1, TRL2 ... for towed segments
;;; Entry = ("KEY" "LAYER NAME" "COLOUR" "LINETYPE")

;; role -> (default colour setting key, description)
(setq
  *turn-roles*
   '(("BODY" "color.body" "vehicle body outline at a step along the path")
     ("FRNT-LEFT" "color.frontpath" "guide axle left tire path")
     ("FRNT-RGHT" "color.frontpath" "guide axle right tire path")
     ("REAR-LEFT" "color.rearpath" "trailing axle left tire path")
     ("REAR-RGHT" "color.rearpath" "trailing axle right tire path")
     ("HTCH" "color.hitchpath" "path of the hitch towing the next segment")
     ("CRNR" "color.corner" "body corner swept path")
    )
  ;; Roles that belong to the whole vehicle rather than to one segment. Their
  ;; keys carry no segment stem, so the layer is C-TURN-ENVL, not
  ;; C-TURN-TRCK-ENVL: one rig sweeps one envelope.
  *turn-vehicle-roles*
   '(("ENVL" "color.envelope" "swept path envelope of the whole vehicle"))
  ;; Filled in by turn-read-layers-dat. nil means "use the defaults".
  *turn-layer-overrides* nil
)

(defun turn-segment-stem (index)
  (if (zerop index) "TRCK" (strcat "TRL" (itoa index)))
)

;; A nil index means the whole vehicle, and the key is the bare role.
(defun turn-layer-key (index role)
  (if index
    (strcat (turn-segment-stem index) "-" role)
    role
  )
)

;; Read turn-layers.dat if the user has one. Same shape as the flagship's
;; Layers.dat: one parenthesised list per line, semicolon comments.
(defun turn-read-layers-dat (/ f line lst path)
  (if (setq path (findfile "turn-layers.dat"))
    (progn
      (setq f (open path "r"))
      (while (setq line (read-line f))
        (setq line (vl-string-trim " \t" line))
        (if (and (< 0 (strlen line)) (= "(" (substr line 1 1)))
          (setq lst (cons (read line) lst))
        )
      )
      (close f)
      (setq *turn-layer-overrides* (reverse lst))
    )
  )
  *turn-layer-overrides*
)

;; The role's entry, whether it is a per-segment role or a whole-vehicle one.
(defun turn-role (role)
  (cond ((assoc role *turn-roles*))
        ((assoc role *turn-vehicle-roles*))
  )
)

;; (name colour linetype) for one segment and role.
(defun turn-layer-def (index role / key override)
  (setq
    key (turn-layer-key index role)
    override (assoc key *turn-layer-overrides*)
  )
  (if override
    (cdr override)
    (list
      (strcat "C-TURN-" key)
      (turn-getvar (cadr (turn-role role)))
      ""
    )
  )
)

(defun turn-layer (index role) (car (turn-layer-def index role)))

;; Create a layer if it is absent. Linetype is left at Continuous on purpose:
;; naming a linetype that is not loaded desynchronises -LAYER and silently
;; costs you the layer, which cost 1.1.9 users their tire paths.
;; -LAYER _make makes the new layer current, which is not what a caller asking
;; for a layer to exist wants. Put CLAYER back.
;;
;; An empty linetype means Continuous. Naming a linetype that is not loaded
;; desynchronises -LAYER and silently costs you the layer, which is what cost
;; 1.1.9 users their tire paths: its path layers asked for "dashed".
(defun turn-make-layer (name color description linetype / clayer)
  (if (not (tblsearch "layer" name))
    (progn
      (setq clayer (getvar "clayer"))
      (command
        "._-layer" "_thaw" name "_on" name "_unlock" name
        "_make" name
        "_color" color name
        "_description" description name
      )
      (if (and linetype (< 0 (strlen linetype)) (tblsearch "ltype" linetype))
        (command "_ltype" linetype name)
      )
      (command "")
      (setvar "clayer" clayer)
    )
  )
  name
)

;; Every layer one segment needs. Called at run time, never at load time.
;; 1.1.9 made its layers at LOAD time, so loading TURN in one drawing and
;; running it in another left entmake silently failing on absent layers.
(defun turn-make-segment-layers (index / def role)
  (foreach role *turn-roles*
    (setq def (turn-layer-def index (car role)))
    (turn-make-layer
      (car def)
      (cadr def)
      (strcat "TURN.LSP " (caddr role))
      (caddr def)
    )
  )
)

(defun turn-make-vehicle-layers (/ def role)
  (foreach role *turn-vehicle-roles*
    (setq def (turn-layer-def nil (car role)))
    (turn-make-layer
      (car def)
      (cadr def)
      (strcat "TURN.LSP " (caddr role))
      (caddr def)
    )
  )
)

;;; ===========================================================================
;;; SECTION 2  SMALL HELPERS
;;; ===========================================================================

;; AutoLISP has no arcsine. 1.1.x carried (/ x (sqrt (- 1 (* x x)))), which is
;; the TANGENT of the arcsine, not the arcsine. The missing atan is restored.
(defun turn-asin (x)
  (cond
    ((>= x 1.0) (/ pi 2))
    ((<= x -1.0) (/ pi -2))
    (t (atan (/ x (sqrt (- 1.0 (* x x))))))
  )
)

;; Fold an angle into -pi..pi so that articulation angles read as "18 degrees
;; left", not "342 degrees right".
(defun turn-normalize-angle (a)
  (while (> a pi) (setq a (- a (* 2 pi))))
  (while (<= a (- pi)) (setq a (+ a (* 2 pi))))
  a
)

(defun turn-left (pt heading dist) (polar pt (+ heading (/ pi 2)) dist))
(defun turn-right (pt heading dist) (polar pt (- heading (/ pi 2)) dist))

;; TURN never calls (alert) directly. A modal dialog stops an unattended script
;; dead, and redefining the built-in alert to get around that clobbers it for
;; every other application sharing the session. So TURN owns this one and lets
;; the caller decide how a message should behave.
;;
;; Set *turn-alert-handler* to a function of one string argument to
;; redirect messages - a test harness points it at its log writer. Leave it nil
;; and messages go to a dialog, as a user expects.
(setq *turn-alert-handler* nil)
(defun turn-alert (msg)
  (princ (strcat "\n" msg))
  (if *turn-alert-handler*
    (apply *turn-alert-handler* (list msg))
    (alert msg)
  )
  (princ)
)

;;; ===========================================================================
;;; SECTION 3  THE TRACKING KERNEL
;;; ===========================================================================
;;; PURE. No prompts, no entmake, no getvar. Everything here can be called
;;; directly from a test file. Do not add drawing code to this section.

(defun turn-state (guide trail heading steer turned)
  (list
    (cons "guide" guide)
    (cons "trail" trail)
    (cons "heading" heading)
    (cons "steer" steer)
    (cons "turned" turned)
  )
)

(defun turn-guide (state) (cdr (assoc "guide" state)))
(defun turn-trail (state) (cdr (assoc "trail" state)))
(defun turn-heading (state) (cdr (assoc "heading" state)))
(defun turn-steer (state) (cdr (assoc "steer" state)))
(defun turn-turned (state) (cdr (assoc "turned" state)))

;; How far the segment's heading changes as its guide point moves from its
;; current position to guide-1. This is the 2002 equation, unchanged.
(defun turn-angle-turned (guide-0 heading-0 wheelbase guide-1 / deviation
                               deviation-supplement direction travelled
                              )
  (setq travelled (distance guide-0 guide-1))
  ;; MEASURE can place two points at the same spot on a zero-length segment.
  ;; Without this the next expression divides by zero.
  (if (zerop travelled)
    0.0
    (progn
      (setq
        direction (angle guide-0 guide-1)
        deviation (- heading-0 direction)
        deviation-supplement (- pi (abs deviation))
      )
      (* 2
         (if (minusp deviation) 1 -1)
         (atan
           (/ (sin deviation-supplement)
              (- (/ (* 2 wheelbase) travelled) (cos deviation-supplement))
           )
         )
      )
    )
  )
)

;; Advance one segment by one step.
(defun turn-step (state wheelbase guide-1 / heading-1 radius steer travelled turned)
  (setq
    turned (turn-angle-turned (turn-guide state) (turn-heading state) wheelbase guide-1)
    heading-1 (+ (turn-heading state) turned)
    travelled (distance (turn-guide state) guide-1)
    ;; Radius the guide axle is describing this step, and the steer angle that
    ;; radius demands. sin(steer) = wheelbase / radius for a bicycle model.
    radius (if (zerop turned) nil (/ travelled 2 (sin (/ turned 2))))
    steer (if radius (turn-asin (/ wheelbase radius)) 0.0)
  )
  (turn-state guide-1 (polar guide-1 heading-1 (- wheelbase)) heading-1 steer turned)
)

;; Track one segment along a whole course. Returns a list of states, one per
;; course point.
(defun turn-segment-path (wheelbase course heading-0 / guide-1 state states)
  (setq
    state (turn-state (car course) (polar (car course) heading-0 (- wheelbase)) heading-0 0.0 0.0)
    states (list state)
  )
  (foreach guide-1 (cdr course)
    (setq
      state (turn-step state wheelbase guide-1)
      states (cons state states)
    )
  )
  (reverse states)
)

;; Where this segment's hitch is in one state: a fixed distance behind its
;; trailing axle. This is the next segment's guide point.
(defun turn-hitch-point (hitch state)
  (polar (turn-trail state) (turn-heading state) (- hitch))
)

;; The course the NEXT segment's guide point follows: the locus of this
;; segment's hitch across every state.
(defun turn-hitch-course (hitch states)
  (mapcar '(lambda (state) (turn-hitch-point hitch state)) states)
)

;; THE CHAIN. Track a whole vehicle along a course.
;; Returns a list of state-lists, one per segment, in vehicle order.
;;
;; The rig is assumed to start straight, so every segment starts on heading-0.
(defun turn-path (vehicle course heading-0 / hitch paths segment states)
  (foreach segment vehicle
    (setq
      states (turn-segment-path (turn-seg-get segment "wheelbase") course heading-0)
      paths (cons states paths)
      hitch (turn-seg-get segment "hitch")
    )
    (if hitch
      (setq course (turn-hitch-course hitch states))
    )
  )
  (reverse paths)
)

;;; ---------------------------------------------------------------------------
;;; DRIVING
;;;
;;; Following a course answers "this is where the guide axle went; what did the
;;; rig do?". Driving answers the question a user actually asks at the wheel:
;;; "I am steering this hard and moving forward this far; where does the rig
;;; end up?" It is the same kinematics read the other way round, and it needs
;;; no new mathematics -- only the next guide point, which a steer angle and a
;;; travel distance determine.
;;;
;;; In a bicycle model the steered wheel rolls in the direction it points, so
;;; the guide axle centre travels along (heading + steer). turn-step then
;;; recovers the heading change and the steer that geometry implies, exactly as
;;; it does when following a drawn course. Driving with steer d and reading the
;;; resulting state's steer back must give d again; the test suite asserts it.
;;;
;;; NOTHING HERE CLAMPS TO THE STEERING LOCK. The kernel reports what the
;;; geometry does; turn-findings is what judges it against the vehicle's
;;; limits, and the command shell is what refuses to steer further. Keeping the
;;; judgement in one place is why the limits could be switched on at all.
;;; ---------------------------------------------------------------------------

;; Advance one segment by one step of driving, rather than by following a course.
;;
;; THE ARGUMENT IS CALLED "travel", NOT "distance", AND MUST STAY THAT WAY.
;; AutoLISP scopes arguments dynamically, so a parameter named `distance` would
;; shadow the `distance` subr for the whole call - including inside
;; turn-step, which calls it. The first version of this function did
;; exactly that and died with "bad function: 5.0", 5.0 being the travel
;; distance evaluated in function position. Same trap as `last`, but worse: the
;; shadowing reaches into functions this one calls, so the breakage surfaces far
;; from the name that caused it.
(defun turn-drive-step (state wheelbase steer travel)
  (turn-step
    state
    wheelbase
    (polar (turn-guide state) (+ (turn-heading state) steer) travel)
  )
)

;; The whole rig, standing straight and still with its powered guide axle at
;; GUIDE. Each segment is hitched to the one ahead. This is where driving starts.
(defun turn-rest-states (vehicle guide heading-0 / hitch out state)
  (foreach segment vehicle
    (setq
      state (turn-state
              guide
              (polar guide heading-0 (- (turn-seg-get segment "wheelbase")))
              heading-0 0.0 0.0)
      out (cons state out)
      hitch (turn-seg-get segment "hitch")
    )
    (if hitch (setq guide (turn-hitch-point hitch state)))
  )
  (reverse out)
)

;; Drive the whole rig one step. Takes one state per segment and returns one
;; state per segment. Only the powered unit is steered; every segment behind it
;; is dragged to wherever the hitch ahead of it has moved, which is the same
;; chain turn-path walks, one step at a time instead of all at once.
(defun turn-drive (vehicle states steer travel / guide-1 hitch out segment state)
  (setq out nil guide-1 nil)
  (while vehicle
    (setq
      segment (car vehicle)
      state (car states)
      state
       (if guide-1
         (turn-step state (turn-seg-get segment "wheelbase") guide-1)
         (turn-drive-step state (turn-seg-get segment "wheelbase") steer travel)
       )
      out (cons state out)
      hitch (turn-seg-get segment "hitch")
      guide-1 (if hitch (turn-hitch-point hitch state))
      vehicle (cdr vehicle)
      states (cdr states)
    )
  )
  (reverse out)
)

;; The steer angle that aims the guide axle at a target point, limited to what
;; the vehicle's steering can actually do.
;;
;; THIS is where the steering lock clamps, because here it is the truth: a
;; driver hauling the wheel further than the stops does not turn tighter. The
;; kernel's stepping functions deliberately do not clamp - they report what the
;; geometry does and let turn-findings judge it - but a driver aiming at a
;; point is asking for an intention, not stating a fact, and an intention the
;; vehicle cannot carry out is simply not available.
(defun turn-steer-toward (state target lock / wanted)
  (setq wanted
    (turn-normalize-angle
      (- (angle (turn-guide state) target) (turn-heading state))))
  (cond
    ((null lock) wanted)
    ((< lock 1e-9) wanted)          ; no lock recorded: do not invent one
    ((> wanted lock) lock)
    ((< wanted (- lock)) (- lock))
    (t wanted)
  )
)

;; Drive a sequence of inputs, each a (steer . distance) pair.
;;
;; RETURNS THE SAME SHAPE AS turn-path -- one list of states per segment,
;; in vehicle order - so everything that draws, measures or judges a path works
;; on a driven one with no change at all. That equivalence is the point of
;; building drive mode on this kernel rather than beside it.
(defun turn-drive-path (vehicle inputs guide heading-0 / history states)
  (setq
    states (turn-rest-states vehicle guide heading-0)
    history (list states)
  )
  (foreach input inputs
    (setq
      states (turn-drive vehicle states (car input) (cdr input))
      history (cons states history)
    )
  )
  ;; history is newest-first and grouped by step; the drawing code wants it
  ;; oldest-first and grouped by segment.
  (apply 'mapcar (cons 'list (reverse history)))
)

;; Articulation angle between two coupled segments at every step.
(defun turn-articulation (states-lead states-follow)
  (mapcar
    '(lambda (a b) (turn-normalize-angle (- (turn-heading a) (turn-heading b))))
    states-lead
    states-follow
  )
)

;; The four body corners of one segment in one state, front-left first, going
;; clockwise as seen from above: FL, FR, RR, RL.
(defun turn-body-corners (segment state / front-mid half heading rear-mid)
  (setq
    heading (turn-heading state)
    half (/ (turn-seg-get segment "body-width") 2.0)
    front-mid (polar (turn-guide state) heading (turn-seg-get segment "front-hang"))
    rear-mid (polar front-mid heading (- (turn-seg-get segment "body-length")))
  )
  (list
    (turn-left front-mid heading half)
    (turn-right front-mid heading half)
    (turn-right rear-mid heading half)
    (turn-left rear-mid heading half)
  )
)

;; The locus of one body corner across every step. Corner 0=FL 1=FR 2=RR 3=RL.
;; These are the "lines for the left and right side of the vehicle" that no
;; version of TURN has ever drawn.
(defun turn-corner-locus (segment states corner)
  (mapcar
    '(lambda (state) (nth corner (turn-body-corners segment state)))
    states
  )
)

;; Tire loci for one segment: front-left, front-right, rear-left, rear-right.
(defun turn-tire-loci (segment states / half)
  (setq half (/ (turn-seg-get segment "axle-width") 2.0))
  (list
    (mapcar '(lambda (s) (turn-left (turn-guide s) (turn-heading s) half)) states)
    (mapcar '(lambda (s) (turn-right (turn-guide s) (turn-heading s) half)) states)
    (mapcar '(lambda (s) (turn-left (turn-trail s) (turn-heading s) half)) states)
    (mapcar '(lambda (s) (turn-right (turn-trail s) (turn-heading s) half)) states)
  )
)

;;; ===========================================================================
;;; SECTION 4  THE VEHICLE MODEL
;;; ===========================================================================
;;; PURE. A vehicle is a list of segments. A segment is an alist.

(defun turn-seg-get (segment key) (cdr (assoc key segment)))

(defun turn-segment (name wheelbase axle-width body-length body-width front-hang hitch steer-lock art-angle)
  (list
    (cons "name" name)
    (cons "wheelbase" wheelbase)
    (cons "axle-width" axle-width)
    (cons "body-length" body-length)
    (cons "body-width" body-width)
    (cons "front-hang" front-hang)
    (cons "hitch" hitch)
    (cons "steer-lock" steer-lock)
    (cons "art-angle" art-angle)
  )
)

;; Analysis. Given a vehicle and its path, what went wrong and where?
;; Returns a list of finding strings. An empty list means the manoeuvre is
;; achievable by this vehicle.
(defun turn-findings (vehicle paths / art art-limit i index findings lead
                           max-art max-steer segment states steer-limit
                          )
  (setq index 0)
  (foreach segment vehicle
    (setq states (nth index paths))
    ;; Steer lock, powered unit only.
    (if (and (zerop index) (setq steer-limit (turn-seg-get segment "steer-lock")) (< 0 steer-limit))
      (progn
        (setq max-steer 0.0)
        (foreach s states
          (if (> (abs (turn-steer s)) max-steer) (setq max-steer (abs (turn-steer s))))
        )
        (if (> max-steer steer-limit)
          (setq
            findings
             (cons
               (strcat
                 "Steering lock exceeded on " (turn-seg-get segment "name")
                 ": course demands " (angtos max-steer 0 1)
                 ", vehicle has " (angtos steer-limit 0 1) "."
               )
               findings
             )
          )
        )
      )
    )
    ;; Articulation at this segment's hitch.
    (if (and (turn-seg-get segment "hitch") (nth (1+ index) paths))
      (progn
        (setq
          art (turn-articulation states (nth (1+ index) paths))
          art-limit (turn-seg-get segment "art-angle")
          max-art 0.0
        )
        (foreach a art (if (> (abs a) max-art) (setq max-art (abs a))))
        (if (and art-limit (< 0 art-limit) (> max-art art-limit))
          (setq
            findings
             (cons
               (strcat
                 "Jackknife: articulation behind " (turn-seg-get segment "name")
                 " reaches " (angtos max-art 0 1)
                 ", limit is " (angtos art-limit 0 1) "."
               )
               findings
             )
          )
        )
      )
    )
    (setq index (1+ index))
  )
  (reverse findings)
)

;;; ===========================================================================
;;; SECTION 5  VEHICLE BLOCK <-> VEHICLE
;;; ===========================================================================
;;; Reads the attributed block BUILDVEHICLE writes. The tag names of 1.1.x are
;;; preserved exactly, so every vehicle block ever built still loads. Trailers
;;; beyond the first use the same tags with an index inserted.

;; Attribute tag for one segment property.
;; index 0 = powered unit, 1 = first trailer (legacy tags), 2+ = new tags.
(defun turn-tag (index key / prefix)
  (cond
    ((zerop index)
     (cdr
       (assoc key
         '(("name" . "VEHNAME") ("wheelbase" . "VEHWHEELBASE") ("axle-width" . "VEHWHEELWIDTH")
           ("body-length" . "VEHBODYLENGTH") ("body-width" . "VEHWIDTH")
           ("front-hang" . "VEHFRONTHANG") ("hitch" . "VEHREARHITCH")
           ("steer-lock" . "VEHSTEERLOCK") ("art-angle" . "VEHARTANGLE")
          )
       )
     )
    )
    (t
     (setq prefix (if (= index 1) "TRAILER" (strcat "TRAILER" (itoa index))))
     (cond
       ;; The first trailer's name tag is TRAILNAME, not TRAILERNAME. Legacy.
       ((and (= key "name") (= index 1)) "TRAILNAME")
       ((= key "name") (strcat prefix "NAME"))
       ((= key "wheelbase") (strcat prefix "HITCHTOWHEEL"))
       ((= key "axle-width") (strcat prefix "WHEELWIDTH"))
       ((= key "body-length") (strcat prefix "BODYLENGTH"))
       ((= key "body-width") (strcat prefix "WIDTH"))
       ((= key "front-hang") (strcat prefix "FRONTHANG"))
       ((= key "hitch") (strcat prefix "REARHITCH"))
       ((= key "art-angle") (strcat prefix "ARTANGLE"))
     )
    )
  )
)

;; Tag that says whether segment `index` tows anything.
(defun turn-have-tag (index)
  (if (zerop index) "TRAILHAVE" (strcat "TRAILER" (itoa (1+ index)) "HAVE"))
)

;; All attributes of a block insert, as ("TAG" . "value").
(defun turn-block-attributes (en / el et out)
  (while (and
           (setq en (entnext en))
           (setq el (entget en))
           (setq et (cdr (assoc 0 el)))
           (/= et "SEQEND")
         )
    (if (= et "ATTRIB")
      (setq out (cons (cons (strcase (cdr (assoc 2 el))) (cdr (assoc 1 el))) out))
    )
  )
  (reverse out)
)

(defun turn-att-real (atts tag default / v)
  (if (and tag (setq v (cdr (assoc tag atts))) (setq v (distof v)))
    v
    default
  )
)

(defun turn-att-angle (atts tag default / v)
  (if (and tag (setq v (cdr (assoc tag atts))))
    (cond ((distof v) (* pi (/ (distof v) 180.0))) (t default))
    default
  )
)

;; Build one segment from a block's attributes.
;; front-hang sign: on the powered unit VEHFRONTHANG runs FORWARD from the
;; guide axle to the bumper. On a trailer TRAILERFRONTHANG runs BACKWARD from
;; the hitch eye ("forward is NEGATIVE" in the old prompt). The model keeps a
;; single convention - forward positive - so trailer values are negated here.
(defun turn-segment-from-attributes (atts index / front-hang hitch)
  (setq
    front-hang (turn-att-real atts (turn-tag index "front-hang") 0.0)
    front-hang (if (zerop index) front-hang (- front-hang))
    hitch
     (if (= "YES" (strcase (cond ((cdr (assoc (turn-have-tag index) atts))) ("No"))))
       (turn-att-real atts (turn-tag index "hitch") 0.0)
       nil
     )
  )
  (turn-segment
    (cond ((cdr (assoc (turn-tag index "name") atts))) ((strcat "Segment" (itoa index))))
    (turn-att-real atts (turn-tag index "wheelbase") 0.0)
    (turn-att-real atts (turn-tag index "axle-width") 0.0)
    (turn-att-real atts (turn-tag index "body-length") 0.0)
    (turn-att-real atts (turn-tag index "body-width") 0.0)
    front-hang
    hitch
    (turn-att-angle atts (turn-tag index "steer-lock") 0.0)
    (turn-att-angle atts (turn-tag index "art-angle") 0.0)
  )
)

;; The whole vehicle. Walks the chain until a segment tows nothing.
(defun turn-vehicle-from-attributes (atts / index segment vehicle)
  (setq index 0)
  (while
    (progn
      (setq
        segment (turn-segment-from-attributes atts index)
        vehicle (cons segment vehicle)
        index (1+ index)
      )
      (and (turn-seg-get segment "hitch") (< index 12))
    )
  )
  (reverse vehicle)
)

;;; ===========================================================================
;;; SECTION 5b  BUILDING A COURSE FROM A DRAWN OBJECT
;;; ===========================================================================
;;; 1.1.x built the course by running MEASURE on the polyline, harvesting the
;;; POINT entities it left behind, guessing the travel direction by comparing
;;; distances, and then erasing the points. That approach cost us three
;;; separate defects:
;;;
;;;   - It called (osnap pick "_end") to find the start of the path, so whether
;;;     TURN worked at all depended on the zoom level and APERTURE at the
;;;     instant of the pick.
;;;   - The vehicle block sits exactly on the start of the path, which is
;;;     precisely where the user is told to pick, so the pick often grabbed the
;;;     block instead. MEASURE then failed with "Cannot measure that object"
;;;     and TURN carried on and drew nothing useful.
;;;   - It littered and erased dozens of POINT entities per run.
;;;
;;; vlax-curve-* asks the object itself. It works on lines, arcs, polylines,
;;; splines and Civil 3D alignments alike, needs no screen picking accuracy,
;;; and leaves nothing behind.

(defun turn-curve-p (en)
  (and en (vl-catch-all-apply 'vlax-curve-getEndParam (list en))
       (not (vl-catch-all-error-p (vl-catch-all-apply 'vlax-curve-getEndParam (list en))))
  )
)

;; Sample a curve into a course of points, `step` apart, travelling away from
;; whichever end the user picked nearest.
(defun turn-course-from-curve (en pick step / dist far len out reverse-p)
  (setq
    len (vlax-curve-getDistAtParam en (vlax-curve-getEndParam en))
    reverse-p
     (> (vlax-curve-getDistAtPoint en (vlax-curve-getClosestPointTo en pick)) (/ len 2))
    dist 0.0
  )
  (while (< dist len)
    (setq
      out (cons (trans (vlax-curve-getPointAtDist en (if reverse-p (- len dist) dist)) 0 1) out)
      dist (+ dist step)
    )
  )
  ;; The last sample rarely lands exactly on the far end. Add it.
  (setq far (trans (vlax-curve-getPointAtDist en (if reverse-p 0.0 len)) 0 1))
  (if (> (distance far (car out)) (/ step 100.0))
    (setq out (cons far out))
  )
  (reverse out)
)

;;; ===========================================================================
;;; SECTION 5c  THE VEHICLE LIBRARY
;;; ===========================================================================
;;; Vehicles are data, not code and not drawings.
;;;
;;; 1.1.x had exactly one way to get a vehicle: run BUILDVEHICLE and answer
;;; twenty prompts, or be sent a DWG containing somebody else's block. Neither
;;; can be diffed, reviewed, or contributed to by e-mail. A plain text file can.
;;;
;;; turn-vehicles.dat is found with (findfile), so it can live anywhere on the
;;; support path. It is optional: with no library present TURN still works, you
;;; just build vehicles by hand.
;;;
;;; Format is the flagship's Layers.dat idiom - one parenthesised record per
;;; line, leading token names the record type, semicolon comments:
;;;
;;;   ("VEHICLE" "KEY" "Description" "UNITS")
;;;   ("SEGMENT" "Name" wheelbase axle-width body-length body-width
;;;              front-hang hitch steer-lock art-angle)
;;;
;;; SEGMENT records attach to the VEHICLE record above them, powered unit
;;; first. hitch is nil on the last segment. Angles are in DEGREES, because a
;;; person editing this file thinks in degrees. front-hang is forward-positive
;;; from the guide point, so it is negative on a trailer whose body starts
;;; behind the hitch eye.

(setq
  *turn-library* nil
  ;; Set this to read a specific file instead of searching the support
  ;; path. Tests use it; leave it nil in normal use.
  *turn-vehicles-file* nil
)

(defun turn-library-record-to-segment (rec)
  (turn-segment
    (nth 1 rec)
    (float (nth 2 rec))
    (float (nth 3 rec))
    (float (nth 4 rec))
    (float (nth 5 rec))
    (float (nth 6 rec))
    (if (nth 7 rec) (float (nth 7 rec)))
    (* pi (/ (float (nth 8 rec)) 180.0))
    (* pi (/ (float (nth 9 rec)) 180.0))
  )
)

;; Read turn-vehicles.dat into *turn-library*, a list of
;; ("KEY" "Description" "UNITS" vehicle).
(defun turn-read-vehicles-dat (/ desc f key line lst path rec segs units)
  ;; findfile on an absolute path returns it only if it exists, so a bad
  ;; explicit path falls through to nil instead of handing (open) a name that
  ;; is not there.
  ;;
  ;; NOTE: this must be (if ...), not (and ...). AutoLISP -and- returns T, not
  ;; its last value, so (and file (findfile file)) yields T and (open T) fails
  ;; with -bad argument type: stringp T-. Common Lisp habits do not transfer.
  ;; Naming a file explicitly means THAT file or nothing. Falling back to a
  ;; different library when the named one is absent would silently give you
  ;; somebody else vehicles.
  (if (setq path
        (if *turn-vehicles-file*
          (findfile *turn-vehicles-file*)
          (findfile "turn-vehicles.dat")
        )
      )
    (progn
      (setq f (open path "r"))
      (while (setq line (read-line f))
        (setq line (vl-string-trim " \t" line))
        (if (and (< 0 (strlen line)) (= "(" (substr line 1 1)))
          (progn
            (setq rec (read line))
            (cond
              ((= "VEHICLE" (strcase (car rec)))
               ;; A new VEHICLE line closes the one before it.
               (if key (setq lst (cons (list key desc units (reverse segs)) lst)))
               (setq
                 key (nth 1 rec)
                 desc (nth 2 rec)
                 units (nth 3 rec)
                 segs nil
               )
              )
              ((and (= "SEGMENT" (strcase (car rec))) key)
               (setq segs (cons (turn-library-record-to-segment rec) segs))
              )
            )
          )
        )
      )
      (close f)
      (if key (setq lst (cons (list key desc units (reverse segs)) lst)))
      (setq *turn-library* (reverse lst))
    )
  )
  *turn-library*
)

(defun turn-library-keys ()
  (mapcar 'car (turn-read-vehicles-dat))
)

(defun turn-library-entry (key / hit)
  (foreach e (turn-read-vehicles-dat)
    (if (= (strcase key) (strcase (car e))) (setq hit e))
  )
  hit
)

(defun turn-library-vehicle (key / e)
  (if (setq e (turn-library-entry key)) (cadddr e))
)

(defun turn-library-description (key / e)
  (if (setq e (turn-library-entry key)) (cadr e))
)

(defun turn-library-units (key / e)
  (if (setq e (turn-library-entry key)) (caddr e))
)

;; Scale a vehicle by a constant. Library vehicles are stored in the units the
;; standard publishes them in; a drawing in other units needs them converted.
(defun turn-scale-segment (segment factor)
  (turn-segment
    (turn-seg-get segment "name")
    (* factor (turn-seg-get segment "wheelbase"))
    (* factor (turn-seg-get segment "axle-width"))
    (* factor (turn-seg-get segment "body-length"))
    (* factor (turn-seg-get segment "body-width"))
    (* factor (turn-seg-get segment "front-hang"))
    (if (turn-seg-get segment "hitch")
      (* factor (turn-seg-get segment "hitch"))
    )
    (turn-seg-get segment "steer-lock")
    (turn-seg-get segment "art-angle")
  )
)

(defun turn-scale-vehicle (vehicle factor)
  (mapcar '(lambda (s) (turn-scale-segment s factor)) vehicle)
)

;; Length of one drawing unit, expressed in metres, from INSUNITS.
;; Returns nil when INSUNITS is 0, which means the drawing declines to say.
;; INSUNITS is the drawing's own declaration of its units and TURN follows it.
;; It is not TURN's place to second-guess an AutoCAD setting: AutoCAD has
;; settings for this and we honour them. What TURN does owe the user is to say
;; out loud what it read and what it is therefore doing - see
;; turn-report-units - so a drawing that is set up wrong shows itself as a
;; number at the command line rather than as a vehicle the wrong size.
(defun turn-drawing-unit-metres (/ code)
  (setq code (getvar "insunits"))
  (cdr
    (assoc
      code
      '((1 . 0.0254) (2 . 0.3048) (3 . 1609.344) (4 . 0.001) (5 . 0.01)
        (6 . 1.0) (7 . 1000.0) (8 . 0.0000254) (9 . 0.0000000254)
        (10 . 0.9144) (11 . 0.0000000001) (12 . 0.000000001)
        (13 . 0.000001) (14 . 0.1) (15 . 10.0) (16 . 100.0)
       )
    )
  )
)

(defun turn-units-metres (units / u)
  (setq u (strcase units))
  (cond
    ((member u '("FT" "FEET" "F" "I" "IMPERIAL")) 0.3048)
    ((member u '("IN" "INCH" "INCHES")) 0.0254)
    ((member u '("M" "METRE" "METER" "METRES" "METERS" "METRIC")) 1.0)
    ((member u '("MM" "MILLIMETRE" "MILLIMETER")) 0.001)
    ((member u '("CM")) 0.01)
  )
)

;; The factor that turns library units into drawing units. 1.0, plus a warning,
;; when the drawing has not declared its units.
(defun turn-library-scale (units / drawing library)
  (setq
    library (turn-units-metres units)
    drawing (turn-drawing-unit-metres)
  )
  (cond
    ((not library)
     (turn-alert
       (strcat "The library says this vehicle is in \"" units "\", which TURN does not"
               "\nrecognise. Using its dimensions unscaled.")
     )
     1.0
    )
    ((not drawing)
     (princ
       (strcat "\nTURN: this drawing does not declare its units (INSUNITS is 0), so the"
               "\n      vehicle is being used unscaled, as " units ".")
     )
     1.0
    )
    (t (/ library drawing))
  )
)

;; A library vehicle, scaled into this drawing's units.
(defun turn-library-vehicle-scaled (key / units vehicle)
  (if (setq vehicle (turn-library-vehicle key))
    (progn
      (setq units (turn-library-units key))
      (turn-scale-vehicle vehicle (turn-library-scale units))
    )
  )
)

;;; ===========================================================================
;;; SECTION 6  DRAWING THE RESULTS
;;; ===========================================================================

(defun turn-draw-pline (points layer closed / lst)
  (setq
    lst
     (list
       (cons 0 "LWPOLYLINE")
       (cons 100 "AcDbEntity")
       (cons 8 layer)
       (cons 100 "AcDbPolyline")
       (cons 90 (length points))
       (cons 70 (if closed 1 128))
       (cons 43 0.0)
     )
  )
  (foreach p points (setq lst (append lst (list (cons 10 p)))))
  (entmake lst)
)

;; Everything one segment contributes to the drawing.
(defun turn-draw-segment (segment states index plot-frequency / corner i loci)
  (setq loci (turn-tire-loci segment states))
  (turn-draw-pline (nth 0 loci) (turn-layer index "FRNT-LEFT") nil)
  (turn-draw-pline (nth 1 loci) (turn-layer index "FRNT-RGHT") nil)
  (turn-draw-pline (nth 2 loci) (turn-layer index "REAR-LEFT") nil)
  (turn-draw-pline (nth 3 loci) (turn-layer index "REAR-RGHT") nil)
  (if (turn-seg-get segment "hitch")
    (turn-draw-pline
      (turn-hitch-course (turn-seg-get segment "hitch") states)
      (turn-layer index "HTCH")
      nil
    )
  )
  ;; The locus of each body corner. These are the four curves that generate
  ;; the envelope; drawn on their own so you can see which corner governs.
  (if (= "Yes" (turn-getvar "general.drawcorners"))
    (progn
      (setq corner -1)
      (repeat 4
        (setq corner (1+ corner))
        (turn-draw-pline
          (turn-corner-locus segment states corner)
          (turn-layer index "CRNR")
          nil
        )
      )
    )
  )
  ;; Body outlines at intervals.
  (setq i -1)
  (foreach state states
    (setq i (1+ i))
    (if (zerop (rem i plot-frequency))
      (turn-draw-pline
        (turn-body-corners segment state)
        (turn-layer index "BODY")
        T
      )
    )
  )
)

(defun turn-draw-path (vehicle paths plot-frequency / index segment)
  (setq index 0)
  (foreach segment vehicle
    (turn-make-segment-layers index)
    (turn-draw-segment segment (nth index paths) index plot-frequency)
    (setq index (1+ index))
  )
)

;;; ---------------------------------------------------------------------------
;;; The swept-path envelope
;;; ---------------------------------------------------------------------------
;;; No version of TURN has ever drawn this, and it is the thing an engineer
;;; actually puts on a plan sheet: the outer boundary of every square foot the
;;; rig touches.
;;;
;;; The boundary of a swept region is a polygon-union problem, and a polygon
;;; union written in AutoLISP over a few hundred bodies would be too slow to
;;; use. AutoCAD already has the boolean, in C++, in the REGION and UNION
;;; commands. So: lay down the body outline at EVERY step (not at the plot
;;; frequency - the plotted boxes are a sparse illustration, the envelope needs
;;; the dense sweep), turn them into regions, union them, and reduce the result
;;; back to polylines.
;;;
;;; Consecutive bodies overlap heavily - a step is a fraction of a wheelbase
;;; and a body is longer than its wheelbase - so the union has no gaps. The
;;; only error is the chord-versus-arc sagitta between steps, which is the same
;;; discretisation the tire paths already carry.

;; Every entity created after MARKER, in database order. A marker of nil means
;; "everything". Used to find what a command produced without trusting entlast
;; to still point at it.
(defun turn-entities-after (marker / en out)
  (setq en (if marker (entnext marker) (entnext)))
  (while en
    (setq out (cons en out)
          en (entnext en)
    )
  )
  (reverse out)
)

(defun turn-selection (enames / ss)
  (setq ss (ssadd))
  (foreach en enames (ssadd en ss))
  ss
)

;; Returns the swept area, or nil if no envelope was produced.
;; The shortest body in the rig. The envelope lays each body outline down once
;; per calculation step, so this is the distance a step must stay under if
;; consecutive placements are to overlap at all.
(defun turn-shortest-body (vehicle / len best)
  (foreach segment vehicle
    (setq len (turn-seg-get segment "body-length"))
    (if (or (null best) (< len best)) (setq best len))
  )
  best
)

;; The smallest body area, used as the scale against which a loop counts as
;; real geometry rather than union litter.
(defun turn-smallest-body-area (vehicle / a best)
  (foreach segment vehicle
    (setq a (* (turn-seg-get segment "body-length")
               (turn-seg-get segment "body-width")))
    (if (or (null best) (< a best)) (setq best a))
  )
  best
)

;; A union of hundreds of overlapping rectangles leaves the odd loop of
;; essentially no area where two boundaries almost coincide. That is arithmetic
;; litter, not swept path, and it is indistinguishable from real geometry once
;; it is sitting on the layer. Anything above the tolerance is left alone: a
;; genuine hole is the drawing telling the truth about a coarse step, and
;; deleting it would hide that.
(defun turn-drop-slivers (entities tolerance / a dropped)
  (setq dropped 0)
  (foreach en entities
    (command "._area" "_object" en)
    (setq a (getvar "area"))
    (if (< a tolerance)
      (progn (entdel en) (setq dropped (1+ dropped)))
    )
  )
  dropped
)

;; Nothing closes in AutoCAD unless you tell it to. PEDIT Join joins; it does not
;; close, and there was never any reason to expect it would. So a loop comes back
;; with its first and last vertices coinciding exactly and its Closed flag off -
;; measured on Tom's 1284-vertex envelope, end gap 0.000, Closed "no". It looks
;; shut on screen and is not, and hatching, offset, AREA and any boolean
;; downstream all refuse it.
;;
;; This is the telling, and it is done here rather than with PEDIT Close so the
;; duplicated last vertex goes too: closing over a coincident pair would leave a
;; zero-length segment behind, which is its own nuisance downstream.
;;
;; A loop whose ends are genuinely apart is left alone and counted. That is
;; missing geometry rather than a missing flag, and the two want opposite fixes.
(defun turn-close-loops (entities layer tolerance / closed el gap opened pts)
  (setq closed 0 opened 0)
  (foreach en entities
    (setq
      el (entget en)
      pts (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= 10 (car x))) el))
    )
    (cond
      ((< (length pts) 3) nil)
      ((= 1 (logand 1 (cdr (assoc 70 el)))) nil)   ; already closed
      ((< (setq gap (distance (car pts) (last pts))) tolerance)
       (turn-draw-pline (reverse (cdr (reverse pts))) layer T)
       (entdel en)
       (setq closed (1+ closed))
      )
      (t (setq opened (1+ opened)))
    )
  )
  (list closed opened)
)

(defun turn-draw-envelope (vehicle paths / area clayer index layer loops
                                marker peditaccept regions segment ss state
                                kept slivers shut
                               )
  (turn-make-vehicle-layers)
  (setq
    layer (turn-layer nil "ENVL")
    marker (entlast)
    index 0
    clayer (getvar "clayer")
  )
  ;; REGION, UNION and EXPLODE put their output on the CURRENT layer, not on
  ;; the layer of the objects they consumed. entmake honours the layer it is
  ;; given; these commands do not. So make the envelope layer current for the
  ;; whole operation.
  (setvar "clayer" layer)
  (foreach segment vehicle
    (foreach state (nth index paths)
      (turn-draw-pline (turn-body-corners segment state) layer T)
    )
    (setq index (1+ index))
  )
  (setq ss (turn-selection (turn-entities-after marker)))
  (cond
    ((zerop (sslength ss)) (setvar "clayer" clayer) nil)
    (t
     (command "._region" ss "")
     ;; REGION consumes the polylines, so whatever survives after the marker is
     ;; the regions it made.
     (setq regions (turn-entities-after marker))
     (if (< 1 (length regions))
       (progn
         (command "._union" (turn-selection regions) "")
         (setq regions (turn-entities-after marker))
       )
     )
     ;; AREA _Object on a region reports its area, islands already deducted.
     ;; Read it before exploding, while there is still a region to ask.
     (setq area 0.0)
     (foreach en regions
       (command "._area" "_object" en)
       (setq area (+ area (getvar "area")))
     )
     ;; Reduce to polylines. A region is not editable geometry; a closed
     ;; LWPOLYLINE is what an engineer offsets, hatches and plots.
     (setq peditaccept (getvar "peditaccept"))
     (setvar "peditaccept" 1)
     (command "._explode" (turn-selection regions))
     (command "._pedit" "_multiple" (turn-selection (turn-entities-after marker)) ""
              "_join" 0.0 ""
     )
     (setvar "peditaccept" peditaccept)
     ;; Clear the litter, then say how many loops are really there. More than
     ;; one means the envelope encloses holes, which is worth saying out loud
     ;; rather than leaving as stray polylines nobody can account for.
     (setq
       slivers
        (turn-drop-slivers (turn-entities-after marker)
                                (* 1e-4 (turn-smallest-body-area vehicle)))
       shut
        (turn-close-loops (turn-entities-after marker) layer
                               (* 1e-6 (turn-shortest-body vehicle)))
       loops (length (turn-entities-after marker))
     )
     (if (< 0 slivers)
       (princ (strcat "\nTURN: discarded " (itoa slivers)
                      " zero-area sliver(s) left by the union."))
     )
     (if (< 0 (cadr shut))
       (princ (strcat "\nTURN: " (itoa (cadr shut))
                      " envelope loop(s) did not close. The boundary has a gap in it."))
     )
     (cond
       ((= 1 loops) (princ "\nTURN: envelope is one closed boundary."))
       ((< 1 loops)
        (princ (strcat "\nTURN: envelope is " (itoa loops)
                       " closed loops - one outer boundary and "
                       (itoa (1- loops)) " hole(s) inside it."))
       )
     )
     (setvar "clayer" clayer)
     area
    )
  )
)

;; The whole job, with no prompting anywhere: track, draw, report.
;; c:turn is a thin prompting shell over this. Tests call it directly, which is
;; why the integration suite needs no simulated keystrokes.
(defun turn-run (vehicle course heading-0 plot-frequency / area paths)
  (setq paths (turn-path vehicle course heading-0))
  (turn-draw-path vehicle paths plot-frequency)
  (if (= "Yes" (turn-getvar "general.drawenvelope"))
    (setq area (turn-draw-envelope vehicle paths))
  )
  (turn-report vehicle paths area)
  paths
)

;; Below this many rig wheelbases of travel, an articulated rig never reaches
;; the articulation it would really settle at, and plots looking far straighter
;; than the truth. Advice, not a verdict: a short course is not an error, it
;; just does not show you much.
(setq *turn-short-course* 5.0)

(defun turn-report (vehicle paths area / body findings len radius ratio spacing wheelbase)
  (setq findings (turn-findings vehicle paths))
  (princ (strcat "\nTURN: " (itoa (length vehicle)) " segment(s), "
                 (itoa (length (car paths))) " steps."))
  (setq
    len (turn-course-length (car paths))
    wheelbase (turn-rig-wheelbase vehicle)
  )
  (if (< 0.0001 wheelbase)
    (progn
      (setq ratio (/ len wheelbase))
      (princ (strcat "\nTURN: course " (rtos len 2 1) " long, " (rtos ratio 2 1)
                     " x the rig's " (rtos wheelbase 2 1) " wheelbase."))
      ;; A step longer than the shortest body means consecutive placements of
      ;; that body do not overlap, so the swept envelope is guaranteed to come
      ;; out with gaps in it. That is not a union bug; it is the sampling being
      ;; coarser than the thing being sampled.
      (if (and (< 1 (length (car paths)))
               (setq body (turn-shortest-body vehicle))
               (> (setq spacing (distance (turn-guide (car (car paths)))
                                          (turn-guide (cadr (car paths)))))
                  body))
        (princ
          (strcat
            "\n  ! Calculation step " (rtos spacing 2 2) " is longer than the shortest"
            "\n    body (" (rtos body 2 2) "), so the envelope will have gaps between"
            "\n    consecutive positions. Re-run with a step well under "
            (rtos body 2 2) "."
          )
        )
      )
      ;; Only worth saying for something that articulates. A single unit is
      ;; tracking its true path almost immediately.
      (if (and (cdr vehicle) (< ratio *turn-short-course*))
        (princ
          (strcat
            "\n  ! Short course. A trailer takes several rig lengths to settle into its"
            "\n    true articulation. Hundreds of feet is normal; long does not hurt."
          )
        )
      )
    )
  )
  (if area
    (princ (strcat "\nTURN: swept area is " (rtos area 2 1) " square drawing units."))
  )
  (if (setq radius (turn-min-radius (car vehicle)))
    (princ (strcat "\nTURN: tightest turn this vehicle can make is "
                   (rtos radius 2 2) " radius at the steering axle."))
  )
  (cond
    (findings
     (foreach f findings (princ (strcat "\n  ! " f)))
     (princ "\nTURN: this manoeuvre is NOT achievable as drawn.")
    )
    (t (princ "\nTURN: manoeuvre achievable. No limits exceeded."))
  )
  findings
)

;;; ===========================================================================
;;; SECTION 7  COMMANDS
;;; ===========================================================================
;;; The block a vehicle is drawn as points in -X: the insertion point is the
;;; middle of the front bumper and the body runs off in +X. 1.1.x built them
;;; that way and read the heading back as (block rotation + pi), so every
;;; vehicle block ever made still reads correctly. Do not "fix" this.

(setq
  *turn-calculationstep* nil
  *turn-plotfrequency* 10
)

;; The calculation step to offer.
;;
;; Remembering the last step is a real convenience when you run the same vehicle
;; again. It becomes a trap when the next vehicle is a different size, because
;; the memory used to beat the computed default unconditionally: a WB-67 whose
;; drawing declared inches has a wheelbase of 234, so its default step was 23.4,
;; and that 23.4 was then offered for a rig whose own default was 1.2. Pressing
;; Enter accepted it and the swept envelope came out full of holes, because the
;; step was longer than the body being swept.
;;
;; So the memory is offered only while it still suits this vehicle. The test is
;; the one that actually matters: a step at or beyond the shortest body length
;; guarantees gaps in the envelope.
(defun turn-default-step (vehicle / body computed)
  (setq
    computed (/ (turn-seg-get (car vehicle) "wheelbase") 10.0)
    body (turn-shortest-body vehicle)
  )
  (cond
    ((null *turn-calculationstep*) computed)
    ((and body (>= *turn-calculationstep* body))
     (princ
       (strcat "\nTURN: the remembered step " (rtos *turn-calculationstep* 2 2)
               " is longer than this rig's shortest body ("
               (rtos body 2 2) ")."
               "\n      Offering " (rtos computed 2 2) " instead.")
     )
     computed
    )
    (*turn-calculationstep*)
  )
)

(defun turn-getdistx (basept prompt default / input)
  (setq input (getdist basept (strcat prompt " <" (rtos default) ">: ")))
  (if input (setq default input))
  default
)

(defun turn-getintx (prompt default / input)
  (setq input (getint (strcat prompt " <" (itoa default) ">: ")))
  (if input (setq default input))
  default
)

;;; ---------------------------------------------------------------------------
;;; TURN
;;; ---------------------------------------------------------------------------
(defun c:turn (/ atts course en-vehicle es-course heading-0 pick step vehicle)
  (turn-read-layers-dat)
  (setq en-vehicle (car (entsel "\nSelect vehicle block: ")))
  (cond
    ((or (null en-vehicle) (/= "INSERT" (cdr (assoc 0 (entget en-vehicle)))))
     (turn-alert "That is not a vehicle block.\n\nRun BUILDVEHICLE (BV) to define a vehicle.")
    )
    ((null (setq atts (turn-block-attributes en-vehicle)))
     (turn-alert "That block carries no vehicle dimensions.\n\nRun BUILDVEHICLE (BV) to define a vehicle.")
    )
    (t
     (setq
       vehicle (turn-vehicle-from-attributes atts)
       heading-0 (+ pi (cdr (assoc 50 (entget en-vehicle))))
       es-course (entsel "\nSelect the course to follow, near the end travel starts: ")
     )
     (cond
       ((null es-course) (princ "\nNothing selected."))
       ((not (turn-curve-p (car es-course)))
        (alert
          (princ
            (strcat
              "\nThat object cannot be followed as a course."
              "\n\nPick the path polyline, not the vehicle block. The block sits"
              "\non top of the start of the path, so zoom in and pick a part of"
              "\nthe path that is clear of the vehicle."
            )
          )
        )
       )
       (t
        (setq
          pick (cadr es-course)
          step
           (turn-getdistx
             pick
             "\nCalculation step distance along the course"
             (turn-default-step vehicle)
           )
          *turn-calculationstep* step
          *turn-plotfrequency*
           (turn-getintx "\nCalculation steps to skip between vehicle plots" *turn-plotfrequency*)
          course (turn-course-from-curve (car es-course) pick step)
        )
        (cond
          ((< (length course) 2) (princ "\nThe course is too short to track."))
          (t
           (command "._undo" "_begin")
           (turn-run vehicle course heading-0 *turn-plotfrequency*)
           (command "._undo" "_end")
          )
        )
       )
     )
    )
  )
  (princ)
)

;;; ---------------------------------------------------------------------------
;;; BUILDVEHICLE
;;; ---------------------------------------------------------------------------
(defun turn-make-attribute (inspoint rotation tag value prompt height layer)
  (entmake
    (list
      '(0 . "ATTDEF")
      (cons 8 layer)
      (cons 10 inspoint)
      (cons 40 height)
      (cons 1 value)
      (cons 3 prompt)
      (cons 2 tag)
      '(70 . 0)
      (cons 50 rotation)
    )
  )
  (entlast)
)

;; A rectangle centred on the segment axis, from x0 to x1, `width` across.
(defun turn-make-box (x0 x1 y width layer / half)
  (setq half (/ width 2.0))
  (turn-draw-pline
    (list
      (list x0 (- y half)) (list x1 (- y half))
      (list x1 (+ y half)) (list x0 (+ y half))
    )
    layer
    T
  )
  (entlast)
)

;;; ---------------------------------------------------------------------------
;;; Turning a vehicle into block attributes
;;; ---------------------------------------------------------------------------
;; The attribute (tag value) pairs one segment contributes. Pure.
;; front-hang is written the way 1.1.x wrote it: forward-positive on the
;; powered unit, backward-positive on a trailer. The model uses one
;; forward-positive convention internally, so trailers are un-negated here.
(defun turn-segment-attributes (index segment / atts hitch)
  (setq
    hitch (turn-seg-get segment "hitch")
    atts
     (list
       (list (turn-tag index "name") (turn-seg-get segment "name"))
       (list (turn-tag index "body-length") (rtos (turn-seg-get segment "body-length") 2))
       (list (turn-tag index "body-width") (rtos (turn-seg-get segment "body-width") 2))
       (list
         (turn-tag index "front-hang")
         (rtos
           (if (zerop index)
             (turn-seg-get segment "front-hang")
             (- (turn-seg-get segment "front-hang"))
           )
           2
         )
       )
       (list (turn-tag index "wheelbase") (rtos (turn-seg-get segment "wheelbase") 2))
       (list (turn-tag index "axle-width") (rtos (turn-seg-get segment "axle-width") 2))
       (list (turn-tag index "art-angle") (angtos (turn-seg-get segment "art-angle") 0 4))
       (list (turn-have-tag index) (if hitch "Yes" "No"))
     )
  )
  (if (zerop index)
    (setq
      atts
       (append
         atts
         (list (list (turn-tag index "steer-lock")
                     (angtos (turn-seg-get segment "steer-lock") 0 4)
               )
         )
       )
    )
  )
  (if hitch
    (setq atts (append atts (list (list (turn-tag index "hitch") (rtos hitch 2)))))
  )
  atts
)

;; Draw the vehicle block. NO PROMPTS - the caller supplies the whole vehicle.
;; base is the middle of the front bumper. The body runs off in +X and TURN
;; reads the heading back as (block rotation + pi), exactly as 1.1.x did, so
;; every vehicle block ever built still reads correctly.
(defun turn-build-block (base vehicle / a atts axle-x guide-x hitch-x index name
                              row segment side ss text-height trail-x wheel-len
                              wheel-wid x0 x1
                             )
  (turn-read-layers-dat)
  (setq
    index 0
    hitch-x 0.0
    ss (ssadd)
  )
  (foreach segment vehicle
    (turn-make-segment-layers index)
    (setq
      atts (turn-segment-attributes index segment)
      guide-x (if (zerop index) (turn-seg-get segment "front-hang") hitch-x)
      trail-x (+ guide-x (turn-seg-get segment "wheelbase"))
      x0 (- guide-x (turn-seg-get segment "front-hang"))
      x1 (+ x0 (turn-seg-get segment "body-length"))
      text-height (/ (turn-seg-get segment "body-width") 15.0)
      wheel-len (/ (turn-seg-get segment "body-length") 10.0)
      wheel-wid (/ (turn-seg-get segment "body-width") 10.0)
    )
    (ssadd
      (turn-make-box
        (+ (car base) x0)
        (+ (car base) x1)
        (cadr base)
        (turn-seg-get segment "body-width")
        (turn-layer index "BODY")
      )
      ss
    )
    (foreach axle-x (if (zerop index) (list guide-x trail-x) (list trail-x))
      (foreach side (list -1.0 1.0)
        (ssadd
          (turn-make-box
            (+ (car base) axle-x (- (/ wheel-len 2.0)))
            (+ (car base) axle-x (/ wheel-len 2.0))
            (+ (cadr base) (* side (/ (turn-seg-get segment "axle-width") 2.0)))
            wheel-wid
            (turn-layer index "BODY")
          )
          ss
        )
      )
    )
    (setq row 0)
    (foreach a atts
      (ssadd
        (turn-make-attribute
          (list
            (+ (car base) x0 text-height)
            (- (cadr base) (* text-height (- (* 1.5 row) 3.0)))
          )
          0.0
          (car a)
          (cadr a)
          (car a)
          text-height
          (turn-layer index "BODY")
        )
        ss
      )
      (setq row (1+ row))
    )
    (setq
      hitch-x
       (if (turn-seg-get segment "hitch")
         (+ trail-x (turn-seg-get segment "hitch"))
         nil
       )
      index (1+ index)
    )
  )
  (setq name (turn-seg-get (car vehicle) "name"))
  (command "._-block" (strcat "VEHICLELIB" name) base ss "")
  (command "._-insert" (strcat "VEHICLELIB" name) base "" "" "")
  (entlast)
)

;;; ---------------------------------------------------------------------------
;;; The prompting shell
;;; ---------------------------------------------------------------------------
;;; ---------------------------------------------------------------------------
;;; Asking a person for dimensions
;;; ---------------------------------------------------------------------------
;;; Rules learned from watching a real user get every one of these wrong:
;;;
;;;   - Ask for what is measured, not half of it. "Half width" made the doubling
;;;     invisible, so a wrong answer looked right.
;;;   - Name BOTH ends of every measurement. "Rear axle to hitch" and "hitch to
;;;     trailer axle" are adjacent links in a chain; a user who cannot see that
;;;     answers the same number twice.
;;;   - Put the sign in the question, not in a parenthetical. Ask which way the
;;;     thing sticks out and take the common direction as positive.
;;;   - Offer a default for anything that usually has one. The commonest answer
;;;     should be the cheapest to give.

;; A required distance. initget 1 refuses an empty answer, so there is no way to
;; fall through with nil and corrupt the arithmetic later.
(defun turn-ask-dist (prompt)
  (initget 1)
  (getdist (strcat "\n" prompt ": "))
)

;; A distance with a default. Enter takes the default.
(defun turn-ask-dist-default (prompt default / v)
  (setq v (getdist (strcat "\n" prompt " <" (rtos default 2 2) ">: ")))
  (cond (v) (default))
)

(defun turn-ask-angle-default (prompt degrees / v)
  (setq v (getangle (strcat "\n" prompt " <" (rtos degrees 2 0) " degrees>: ")))
  (cond (v) ((* pi (/ degrees 180.0))))
)

(defun turn-ask-name (prompt default / v)
  (setq v (getstring t (strcat "\n" prompt " <" default ">: ")))
  (if (= v "") default v)
)

;; Prompt for one segment. index 0 is the powered unit. Returns a segment.
(defun turn-prompt-segment (index / art axle-width body-length body-width
                                 front-hang hitch name steer-lock tows wheelbase
                                )
  (princ
    (strcat "\n\n--- "
            (if (zerop index) "Powered unit" (strcat "Trailer " (itoa index)))
            " ---")
  )
  (cond
    ((zerop index)
     (setq
       name (turn-ask-name "Name for this vehicle" "Truck")
       body-length (turn-ask-dist "Overall length of the tractor body")
       body-width (turn-ask-dist "Overall width of the tractor body, outside to outside")
       front-hang (turn-ask-dist "Front overhang, front bumper back to the steering axle")
       wheelbase
        (turn-ask-dist
          "Wheelbase, steering axle back to the rear axle (use the centroid if there are several)"
        )
       axle-width (turn-ask-dist "Track width, centre of one tire to centre of the other")
       steer-lock (turn-ask-angle-default "Maximum steering lock angle" 30.0)
     )
    )
    (t
     (setq
       name (turn-ask-name "Name for this trailer" (strcat "Trailer" (itoa index)))
       wheelbase
        (turn-ask-dist
          "Hitch back to THIS trailer's axle - the trailer's own wheelbase"
        )
       axle-width (turn-ask-dist "Track width, centre of one tire to centre of the other")
       ;; Asked forward-positive, which is the common case for a semitrailer,
       ;; so the usual answer needs no minus sign.
       front-hang
        (turn-ask-dist-default
          "How far the trailer nose reaches FORWARD of the hitch (0 if it starts at the hitch)"
          0.0
        )
       body-length (turn-ask-dist "Overall length of the trailer body")
       body-width (turn-ask-dist "Overall width of the trailer body, outside to outside")
       steer-lock 0.0
     )
    )
  )
  (initget 1 "Yes No")
  (setq tows (getkword (strcat "\nDoes " name " tow another trailer? [Yes/No]: ")))
  (cond
    ((= tows "Yes")
     (setq
       hitch
        (turn-ask-dist-default
          (strcat
            "How far BEHIND " name "'s rear axle its hitch sits"
            "\n  (0 for a fifth wheel over the axle; negative if ahead of it)"
          )
          0.0
        )
       art (turn-ask-angle-default "Maximum articulation angle at that hitch" 70.0)
     )
    )
    (t (setq hitch nil art 0.0))
  )
  (turn-segment
    name wheelbase axle-width body-length body-width front-hang hitch steer-lock art
  )
)

;;; ---------------------------------------------------------------------------
;;; Telling the person what they just described
;;; ---------------------------------------------------------------------------
;;; A user cannot check a number they never see again. These give back the two
;;; figures that catch a mistake: how long the rig came out, and how tight a
;;; turn it can make.

;; Bumper to the back of the last body. Mirrors the layout turn-build-block
;; uses, so it is the length that will actually be drawn.
(defun turn-overall-length (vehicle / guide-x hitch-x index segment tail trail-x x0 x1)
  (setq index 0 hitch-x 0.0 tail 0.0)
  (foreach segment vehicle
    (setq
      guide-x (if (zerop index) (turn-seg-get segment "front-hang") hitch-x)
      trail-x (+ guide-x (turn-seg-get segment "wheelbase"))
      x0 (- guide-x (turn-seg-get segment "front-hang"))
      x1 (+ x0 (turn-seg-get segment "body-length"))
    )
    (if (> x1 tail) (setq tail x1))
    (if (turn-seg-get segment "hitch")
      (setq hitch-x (+ trail-x (turn-seg-get segment "hitch")))
    )
    (setq index (1+ index))
  )
  tail
)

;; The tightest circle the steering axle can describe. For a bicycle model,
;; sin(steer) = wheelbase / radius. nil when no real steering lock is known -
;; and 0 is not a real steering lock, it is the placeholder the old vehicle
;; library is full of.
(defun turn-min-radius (segment / lock)
  (setq lock (turn-seg-get segment "steer-lock"))
  (if (and lock (< 0.0001 lock) (< lock (/ pi 2)))
    (/ (turn-seg-get segment "wheelbase") (sin lock))
  )
)

;; How far the guide axle actually travelled, summed along the lead segment's
;; path. Deliberately not the course object's own length: the path is what was
;; walked, and it is what the trailer had to respond to.
(defun turn-course-length (states / previous total)
  (setq total 0.0)
  (foreach s states
    (if previous (setq total (+ total (distance previous (turn-guide s)))))
    (setq previous (turn-guide s))
  )
  total
)

;; Front axle to the last axle in the train: every segment's wheelbase, plus
;; each hitch offset that carries you on to the next segment. "hitch" is nil on
;; the last segment, which is what ends the sum.
(defun turn-rig-wheelbase (vehicle / hitch total)
  (setq total 0.0)
  (foreach segment vehicle
    (setq total (+ total (turn-seg-get segment "wheelbase")))
    (if (setq hitch (turn-seg-get segment "hitch"))
      (setq total (+ total hitch))
    )
  )
  total
)

(defun turn-describe (vehicle / index radius segment)
  (princ "\n")
  (setq index 0)
  (foreach segment vehicle
    (princ
      (strcat "\n  " (if (zerop index) "Tractor" (strcat "Trailer " (itoa index)))
              " \"" (turn-seg-get segment "name") "\""
              "  body " (rtos (turn-seg-get segment "body-length") 2 2)
              " x " (rtos (turn-seg-get segment "body-width") 2 2)
              ",  wheelbase " (rtos (turn-seg-get segment "wheelbase") 2 2))
    )
    (setq index (1+ index))
  )
  (princ (strcat "\n  Overall length, bumper to tail: "
                 (rtos (turn-overall-length vehicle) 2 2)))
  (setq radius (turn-min-radius (car vehicle)))
  (princ
    (if radius
      (strcat "\n  Tightest turn this vehicle can make: "
              (rtos radius 2 2) " radius at the steering axle")
      "\n  Tightest turn: unknown, because no steering lock angle was given"
    )
  )
  (princ)
)

;;; ---------------------------------------------------------------------------
;;; DRIVE - steer the rig with the cursor instead of drawing a course first.
;;;
;;; The cursor is the driver's eyes: the rig steers toward wherever it is, as
;;; hard as the steering lock allows, and takes one calculation step forward
;;; each time the cursor gets a step ahead of the guide axle. Let go of the
;;; wheel - stop moving - and the rig stops.
;;;
;;; The geometry is all in SECTION 3 and all tested. What is here is only the
;;; interaction, which is the part a test harness cannot drive: grread waits for
;;; a human. So this function stays as thin as it can be, and everything it
;;; decides that could be got wrong is computed by something testable.
;;; ---------------------------------------------------------------------------

;; Rubber-band the rig on screen without touching the drawing database. These
;; vectors accumulate deliberately: each step leaves its outline behind, so the
;; user watches the swept path build up as they drive. (redraw) clears them.
(defun turn-flash (vehicle states / corners i)
  (setq i -1)
  (mapcar
    '(lambda (segment state / corners)
       (setq
         i (1+ i)
         corners (turn-body-corners segment state)
       )
       (grdraw (nth 0 corners) (nth 1 corners) (if (zerop i) 1 4))
       (grdraw (nth 1 corners) (nth 2 corners) (if (zerop i) 1 4))
       (grdraw (nth 2 corners) (nth 3 corners) (if (zerop i) 1 4))
       (grdraw (nth 3 corners) (nth 0 corners) (if (zerop i) 1 4))
     )
    vehicle states
  )
  (princ)
)

(defun c:drive (/ atts en-vehicle heading-0 start step vehicle)
  (turn-read-layers-dat)
  (setq en-vehicle (car (entsel "\nSelect vehicle block: ")))
  (cond
    ((or (null en-vehicle) (/= "INSERT" (cdr (assoc 0 (entget en-vehicle)))))
     (turn-alert "That is not a vehicle block.\n\nRun BUILDVEHICLE (BV) to define a vehicle.")
    )
    ((null (setq atts (turn-block-attributes en-vehicle)))
     (turn-alert "That block carries no vehicle dimensions.\n\nRun BUILDVEHICLE (BV) to define a vehicle.")
    )
    (t
     (setq
       vehicle (turn-vehicle-from-attributes atts)
       heading-0 (+ pi (cdr (assoc 50 (entget en-vehicle))))
       ;; Same convention as TURN: the block gives the heading, the user says
       ;; where the front axle centre is. TURN takes that from the end of the
       ;; course; with no course drawn, it has to be asked for.
       start (getpoint "\nStart point of the front axle centre: ")
     )
     (if (null start)
       (princ "\nNothing picked.")
       (progn
         (setq
           step (turn-getdistx start "\nCalculation step distance"
                                    (turn-default-step vehicle))
           *turn-calculationstep* step
           *turn-plotfrequency*
            (turn-getintx "\nCalculation steps to skip between vehicle plots"
                               *turn-plotfrequency*)
         )
         (turn-drive-command vehicle start heading-0 step)
       )
     )
    )
  )
  (princ)
)

(defun turn-drive-command (vehicle start heading-0 step / inputs lock)
  (setq
    lock (turn-seg-get (car vehicle) "steer-lock")
    inputs (turn-drive-read vehicle start heading-0 step lock)
  )
  (redraw)
  (cond
    ((null inputs) (princ "\nNothing driven."))
    (t
     (command "._undo" "_begin")
     (turn-run vehicle
                    (turn-drive-path vehicle inputs start heading-0)
                    heading-0
                    *turn-plotfrequency*)
     (command "._undo" "_end")
    )
  )
  (princ)
)

;; The loop. Returns the list of (steer . travel) inputs the user drove, which
;; is then handed to the same kernel a drawn course goes through.
;;
;; turn-drive-path replays those inputs from the start, so what gets drawn
;; is computed by the tested kernel and not by anything that happened on screen.
(defun turn-drive-read (vehicle start heading-0 step lock / done input inputs
                             states steer target
                            )
  (princ (strcat "\nDrive with the cursor. ENTER or SPACE to finish."
                 "\nSteering lock " (rtos (/ (* 180.0 lock) pi) 2 1) " degrees."))
  (setq states (turn-rest-states vehicle start heading-0) inputs nil)
  (turn-flash vehicle states)
  (while (not done)
    (setq input (grread T 15 0))
    (cond
      ;; 5 is a cursor move while tracking; 3 is a pick. Both give a point, and
      ;; both mean the same thing here: drive toward it.
      ((and (member (car input) '(3 5)) (listp (cadr input)))
       (setq target (cadr input))
       ;; ONE STEP PER CURSOR EVENT, and only once the cursor is genuinely a
       ;; step ahead. Both halves matter:
       ;;
       ;; The distance gate stops the rig crawling forward on every twitch of
       ;; the mouse. The one-step rule stops it running away: driving *until*
       ;; the rig reaches the cursor never terminates when the cursor sits
       ;; inside the minimum turning circle, which is a point the vehicle
       ;; cannot reach however long it drives. A WB-67 cannot reach a spot 40
       ;; feet abeam of it, and the first version of this loop hung trying.
       ;;
       ;; The mouse produces events continuously, so one step each is still
       ;; smooth; it just cannot outrun the user.
       (if (>= (distance (turn-guide (car states)) target) step)
         (progn
           (setq
             steer (turn-steer-toward (car states) target lock)
             states (turn-drive vehicle states steer step)
             inputs (cons (cons steer step) inputs)
           )
           (turn-flash vehicle states)
         )
       )
      )
      ;; 2 is a keystroke. 13 Enter, 32 space.
      ((and (= 2 (car input)) (member (cadr input) '(13 32))) (setq done T))
      (t nil)
    )
  )
  (reverse inputs)
)

(defun c:bv () (c:buildvehicle))

(defun c:buildvehicle (/ base index keys mode oldexpert segment vehicle)
  (setq keys (turn-library-keys))
  (initget "Library New ?")
  (setq
    mode
     (cond
       ((not keys) "New")
       ((getkword
          (strcat "\nVehicle source [Library/New/?] <"
                  (if keys "Library" "New") ">: ")))
       (keys "Library")
       ("New")
     )
  )
  (if (= mode "?")
    (progn
      (turn-alert
        (strcat "Library: pick a standard vehicle from turn-vehicles.dat.\n"
                "New: answer prompts and define one yourself.\n\n"
                (itoa (length keys)) " vehicles are in the library:\n"
                (turn-key-columns keys))
      )
      (setq mode "Library")
    )
  )
  (setq
    base (getpoint "\nLocation to build vehicle (middle of the front bumper): ")
    index 0
  )
  (if (= mode "Library")
    (setq vehicle (turn-prompt-library-vehicle keys))
  )
  (if vehicle
    (progn
      (setq oldexpert (getvar "expert"))
      (setvar "expert" 5)
      (turn-build-block base vehicle)
      (setvar "expert" oldexpert)
      (princ
        (strcat "\n\nVehicle \"" (turn-seg-get (car vehicle) "name") "\" placed, "
                (itoa (length vehicle)) " segment(s), as block "
                "VEHICLELIB" (turn-seg-get (car vehicle) "name") ".")
      )
      (turn-describe vehicle)
      (princ
        (strcat "\n\nMove it so the middle of the steering axle sits on the start of"
                "\nyour course, rotate it to the starting direction, then run TURN.")
      )
      (princ)
    )
    (c:buildvehicle-new base)
  )
)

;; Lay a list of keys out in columns so an alert stays readable.
(defun turn-key-columns (keys / i out)
  (setq i 0 out "")
  (foreach k keys
    (setq
      out (strcat out (if (zerop (rem i 4)) "\n  " "  ") k)
      i (1+ i)
    )
  )
  out
)

;; The keyword string initget wants: the keys, space delimited.
;;
;; Hyphens are safe here. Probed in AutoCAD rather than assumed, because the
;; keys are WB-67 and S-BUS-36 and the manual says nothing about hyphens:
;; initget accepts the list, getkword matches case-insensitively and returns the
;; key verbatim, and empty input returns nil so the caller can default.
;; See devtools/turn-probe-initget.
(defun turn-keyword-string (keys / out)
  (setq out "")
  (foreach k keys (setq out (strcat out k " ")))
  (vl-string-trim " " out)
)

;; The name INSUNITS is currently claiming, or nil when it claims nothing.
(defun turn-insunits-name (/ code)
  (setq code (getvar "insunits"))
  (cdr (assoc code '((1 . "Inches") (2 . "Feet") (3 . "Miles") (4 . "Millimeters")
                     (5 . "Centimeters") (6 . "Meters") (7 . "Kilometers")
                     (10 . "Yards"))))
)

;; State the units and the scale, every time, before anything is drawn.
;;
;; TURN follows INSUNITS; it does not argue with it. But an architect works in
;; inches and a civil engineer in feet, both legitimately, and the stock
;; acad.dwt declares inches - so a civil drawing that was never set up will
;; scale a library vehicle by twelve and look broken. Saying the numbers out
;; loud costs one line and turns a mystery into an obvious setting to fix.
(defun turn-report-units (key / drawing factor library)
  (setq
    library (turn-units-name (turn-library-units key))
    drawing (turn-insunits-name)
    factor (turn-library-scale (turn-library-units key))
  )
  (princ (strcat "\nTURN: library records " key " in " library "."))
  (cond
    ((null drawing)
     (princ (strcat "\n      This drawing does not declare its units (INSUNITS is 0),"
                    "\n      so " key " is used unscaled, as " library "."))
    )
    (t
     (princ (strcat "\n      INSUNITS says this drawing is in " drawing
                    ", so scaling by " (rtos factor 2 4) "."))
     (if (not (equal factor 1.0 1e-9))
       (princ (strcat "\n      If that is wrong, the drawing's INSUNITS is wrong."
                      " Set it and run again."))
     )
    )
  )
  factor
)

;; The tidy name for a units string out of the data file.
(defun turn-units-name (units / m)
  (setq m (turn-units-metres units))
  (cond ((null m) units)
        ((equal m 0.3048 1e-9) "Feet")
        ((equal m 0.0254 1e-9) "Inches")
        ((equal m 1.0 1e-9) "Meters")
        ((equal m 0.001 1e-9) "Millimeters")
        ((equal m 0.01 1e-9) "Centimeters")
        (units)
  )
)

(defun turn-prompt-library-vehicle (keys / key vehicle)
  (princ (strcat "\nLibrary vehicles:" (turn-key-columns keys)))
  ;; getkword, not getstring: it validates against the library, accepts any
  ;; case, and will not let a typo through to an alert.
  (initget (turn-keyword-string keys))
  (setq key (getkword (strcat "\nVehicle key <" (car keys) ">: ")))
  (if (null key) (setq key (car keys)))
  (turn-report-units key)
  (cond
    ((setq vehicle (turn-library-vehicle-scaled key))
     (princ (strcat "\n" key ": " (turn-library-description key)
                    " (" (turn-library-units key) ", "
                    (itoa (length vehicle)) " segments)"))
     vehicle
    )
    (t
     (turn-alert (strcat "No vehicle called \"" key "\" is in the library."))
     nil
    )
  )
)

(defun c:buildvehicle-new (base / index oldexpert segment vehicle)
  (setq index 0)
  (while
    (progn
      (setq
        segment (turn-prompt-segment index)
        vehicle (append vehicle (list segment))
        index (1+ index)
      )
      (and (turn-seg-get segment "hitch") (< index 12))
    )
  )
  ;; Redefining an existing block would otherwise raise a dialog.
  (setq oldexpert (getvar "expert"))
  (setvar "expert" 5)
  (turn-build-block base vehicle)
  (setvar "expert" oldexpert)
  (princ
    (strcat
      "\n\nVehicle \"" (turn-seg-get (car vehicle) "name") "\" built, "
      (itoa (length vehicle)) " segment(s), as block "
      ;; Say the real block name. The VEHICLELIB prefix is added silently, and a
      ;; user who never sees it cannot find their own block.
      "VEHICLELIB" (turn-seg-get (car vehicle) "name") "."
    )
  )
  (turn-describe vehicle)
  (princ
    (strcat
      "\n\nCheck those figures before you go on."
      "\nThen move the block so the middle of the steering axle sits on the start"
      "\nof your course, rotate it to the starting direction, and run TURN."
    )
  )
  (princ)
)


(princ (strcat "\nTURN " (turn-getvar "general.version") " loaded. Type TURN, DRIVE or BV."))
(princ)
