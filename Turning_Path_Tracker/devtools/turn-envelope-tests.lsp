;;; turn-envelope-tests.lsp - how faithful is the swept-path envelope?
;;;
;;; History worth keeping. The first envelope was the union of the body outline
;;; laid down once per step, and turn.lsp claimed "the only error is the
;;; chord-versus-arc sagitta". That was reasoned, not measured, and wrong: the
;;; rig also sweeps the ground BETWEEN steps, and on the outside of every turn
;;; the union notched in behind the leading corner - a sawtooth 0.30 ft deep on
;;; a WB-67 at a 1.2 step, halving only as fast as the step (first order). The
;;; numbers are in turn-envelope-baseline-log.md. This suite exists so that no
;;; such claim is made again without a measurement behind it.
;;;
;;; The envelope is now built from the traced paths of six points per segment
;;; (turn-segment-sweep). This suite measures it from both sides: ground the rig
;;; covered that the envelope leaves out (escape), and ground the envelope
;;; claims that the rig never covered (overreach).
;;;
;;; THE MEASURE. Between each pair of consecutive states the body is placed at
;;; fractions 1/4, 1/2, 3/4 of the rigid motion that carries one to the other,
;;; and points on those in-between outlines are tested against the envelope.
;;; The worst distance by which any of them lies OUTSIDE the envelope is ground
;;; the rig covered that the envelope leaves out - the escape.
;;;
;;; The rigid motion used is the rotation about the unique pole that maps one
;;; placement onto the next (a translation when the heading does not change).
;;; It is the canonical in-between for two rigid placements. The kernel does not
;;; define the motion between steps, so this is a model; its own disagreement
;;; with any other smooth in-between is second order in the step.
;;;
;;; THE VERDICT is the ORDER of the escape, not a threshold invented here: the
;;; same run at half the step must cut the escape by about 4 if the error is
;;; second order, and by only about 2 if the sawtooth is there. The one number
;;; that is not an order is the floor turn-edge-sweep documents: a strip thinner
;;; than 1e-4 of the body is dropped, and the escape may bottom out there.
;;;
;;; Run:  devtools\turn-tests.bat turn-envelope-tests
;;;
;;; Test scaffolding. None of it ships to users.

;;; ---------------------------------------------------------------------------
;;; Fixtures
;;; ---------------------------------------------------------------------------
;; WB-67 shaped. turn-segment takes front-hang FORWARD-positive; only the
;; block attributes use the trailer's backward convention, converted on the way
;; in. So the trailer's 3 ft of deck ahead of the kingpin is +3.0 here.
(defun turn-test-envelope-rig ()
  (list
    (turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (turn-segment "Trailer" 45.5 8.5 53.0 8.5 3.0 nil
                       0.0 (* pi (/ 70.0 180.0)))
  )
)

;; An intersection corner: 150 straight, a 90 degree left turn on radius 50,
;; 150 straight out. The kind of corner Rob Livingston says is 90% of the job.
(defun turn-test-envelope-corner-course ()
  (command "._pline" '(0.0 0.0) '(-150.0 0.0) "_a" '(-200.0 -50.0)
           "_l" '(-200.0 -200.0) "")
  (entlast)
)

(defun turn-test-envelope-clear (/ ss)
  (foreach filter (list '((8 . "C-TURN-*")) '((0 . "LWPOLYLINE")))
    (if (setq ss (ssget "_X" filter)) (command "._erase" ss ""))
  )
  (princ)
)

;;; ---------------------------------------------------------------------------
;;; The rigid motion between two states
;;; ---------------------------------------------------------------------------
;; Heading change from a0 to a1, normalised to (-pi, pi].
(defun turn-test-envelope-turn (a0 a1 / d)
  (setq d (- a1 a0))
  (while (> d pi) (setq d (- d pi pi)))
  (while (<= d (- pi)) (setq d (+ d pi pi)))
  d
)

;; P rotated about O by A.
(defun turn-test-envelope-rotate (p o a / dx dy)
  (setq dx (- (car p) (car o)) dy (- (cadr p) (cadr o)))
  (list (+ (car o) (- (* dx (cos a)) (* dy (sin a))))
        (+ (cadr o) (+ (* dx (sin a)) (* dy (cos a)))))
)

;; The state a fraction FRAC of the way through the rigid motion from S0 to S1.
;; The pole O solves g1 = O + R(a)(g0 - O).
(defun turn-test-envelope-between (s0 s1 frac / a b c det g0 g1 o rg0 s)
  (setq
    g0 (turn-guide s0)
    g1 (turn-guide s1)
    a (turn-test-envelope-turn (turn-heading s0) (turn-heading s1))
  )
  (if (< (abs a) 1e-12)
    (list
      (cons "guide" (list (+ (car g0) (* frac (- (car g1) (car g0))))
                          (+ (cadr g0) (* frac (- (cadr g1) (cadr g0))))))
      (cons "heading" (turn-heading s0))
    )
    (progn
      (setq
        c (- 1.0 (cos a))
        s (sin a)
        det (+ (* c c) (* s s))
        rg0 (turn-test-envelope-rotate g0 '(0.0 0.0) a)
        b (list (- (car g1) (car rg0)) (- (cadr g1) (cadr rg0)))
        o (list (/ (- (* c (car b)) (* s (cadr b))) det)
                (/ (+ (* s (car b)) (* c (cadr b))) det))
      )
      (list
        (cons "guide" (turn-test-envelope-rotate g0 o (* frac a)))
        (cons "heading" (+ (turn-heading s0) (* frac a)))
      )
    )
  )
)

;; Every in-between body outline for the whole rig, at the given fractions.
(defun turn-test-envelope-bodies (vehicle paths fractions / index out s0 states)
  (setq index 0)
  (foreach segment vehicle
    (setq states (nth index paths) s0 (car states))
    (foreach s1 (cdr states)
      (foreach frac fractions
        (setq out (cons (turn-body-corners segment (turn-test-envelope-between s0 s1 frac)) out))
      )
      (setq s0 s1)
    )
    (setq index (1+ index))
  )
  out
)

;; Points on one outline, each tagged: the four corners, and four points along
;; each edge.
(defun turn-test-envelope-samples (corners / a b i out)
  (setq b (car corners))
  (foreach a (reverse corners)
    (setq out (cons (cons b "corner") out) i 1)
    (repeat 4
      (setq out
        (cons (cons (list (+ (car a) (* (/ i 5.0) (- (car b) (car a))))
                          (+ (cadr a) (* (/ i 5.0) (- (cadr b) (cadr a)))))
                    "mid-edge")
              out)
            i (1+ i))
    )
    (setq b a)
  )
  out
)

;;; ---------------------------------------------------------------------------
;;; Inside and outside the envelope
;;; ---------------------------------------------------------------------------
(defun turn-test-envelope-vertices (en)
  (mapcar '(lambda (x) (list (cadr x) (caddr x)))
          (vl-remove-if-not '(lambda (x) (= 10 (car x))) (entget en)))
)

;; Twice the signed area. Positive = counter-clockwise.
(defun turn-test-envelope-signed-area (pts / a b s)
  (setq s 0.0 b (car (reverse pts)))
  (foreach a pts
    (setq s (+ s (- (* (car b) (cadr a)) (* (car a) (cadr b)))) b a)
  )
  s
)

;; Even-odd ray cast.
(defun turn-test-envelope-inside-p (p pts / a b inside)
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
  inside
)

;; The escape: how far the worst in-between point lies outside the envelope.
;; Returns (distance kind point). The closest-point tangent says which side a
;; point is on, cheaply; the ray cast confirms only a candidate for the worst,
;; because near a concave vertex the tangent alone can mislead.
(defun turn-test-envelope-escape (bodies loop / cp d orient p pts tangent where worst)
  (setq
    pts (turn-test-envelope-vertices loop)
    orient (turn-test-envelope-signed-area pts)
    worst 0.0
  )
  (foreach body bodies
    (foreach sample (turn-test-envelope-samples body)
      (setq
        p (car sample)
        cp (vlax-curve-getClosestPointTo loop (list (car p) (cadr p) 0.0))
        d (distance p (list (car cp) (cadr cp)))
      )
      (if (> d worst)
        (progn
          (setq tangent (vlax-curve-getFirstDeriv loop (vlax-curve-getParamAtPoint loop cp)))
          (if (and (< (* orient (- (* (car tangent) (- (cadr p) (cadr cp)))
                                  (* (cadr tangent) (- (car p) (car cp)))))
                      0.0)
                   (not (turn-test-envelope-inside-p p pts)))
            (setq worst d where sample)
          )
        )
      )
    )
  )
  (list worst (cdr where) (car where))
)

;;; ---------------------------------------------------------------------------
;;; One run
;;; ---------------------------------------------------------------------------
(defun turn-test-envelope-loops ()
  (turn-test-integration-layer-entities (turn-layer nil "ENVL"))
)

;; Draw the envelope for the corner course at STEP. Returns
;; (escape kind point area loops vertices).
(defun turn-test-envelope-measure (vehicle step / area course en escape loops paths)
  (turn-test-envelope-clear)
  (setq
    en (turn-test-envelope-corner-course)
    course (turn-course-from-curve en '(0.0 0.0) step)
    paths (turn-path vehicle course pi)
  )
  (turn-test-mark (strcat "step " (rtos step 2 2) ": envelope starts, "
                          (itoa (turn-test-envelope-polygon-count vehicle paths))
                          " polygons"))
  (setq
    area (turn-draw-envelope vehicle paths)
    loops (turn-test-envelope-loops)
  )
  (turn-test-mark "envelope done")
  (if (= 1 (length loops))
    (progn
      (setq escape (turn-test-envelope-escape
                     (turn-test-envelope-bodies vehicle paths '(0.25 0.5 0.75))
                     (car loops)))
      (turn-test-write
        (strcat "- step " (rtos step 2 2) ": " (itoa (length (car paths))) " states, "
                "area " (rtos area 2 2) ", "
                (itoa (length (turn-test-envelope-vertices (car loops)))) " vertices, "
                "worst escape " (rtos (car escape) 2 4) " (" (cadr escape) " at "
                (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) (caddr escape)))
                ")"))
      (list (car escape) (cadr escape) (caddr escape) area loops)
    )
    (progn
      (turn-test-write (strcat "- step " (rtos step 2 2) ": " (itoa (length loops))
                               " envelope loops; the measure needs exactly one"))
      nil
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; Distance from a point to a body
;;; ---------------------------------------------------------------------------
;; Distance from P to the convex outline CORNERS, 0 if inside.
(defun turn-test-envelope-outside-by (p corners / a b best d dx dy len2 neg pos u)
  (setq b (car (reverse corners)) pos 0 neg 0 best nil)
  (foreach a corners
    (setq
      d (- (* (- (car a) (car b)) (- (cadr p) (cadr b)))
           (* (- (cadr a) (cadr b)) (- (car p) (car b))))
    )
    (cond ((> d 1e-9) (setq pos (1+ pos))) ((< d -1e-9) (setq neg (1+ neg))))
    ;; distance to segment b-a
    (setq
      dx (- (car a) (car b))
      dy (- (cadr a) (cadr b))
      len2 (+ (* dx dx) (* dy dy))
      u (/ (+ (* (- (car p) (car b)) dx) (* (- (cadr p) (cadr b)) dy)) len2)
      u (max 0.0 (min 1.0 u))
      d (distance p (list (+ (car b) (* u dx)) (+ (cadr b) (* u dy))))
    )
    (if (or (null best) (< d best)) (setq best d))
    (setq b a)
  )
  (if (or (zerop pos) (zerop neg)) 0.0 best)
)

(defun turn-test-envelope-polygon-count (vehicle paths / index n)
  (setq index 0 n 0)
  (foreach segment vehicle
    (setq n (+ n (length (turn-segment-sweep segment (nth index paths) index))) index (1+ index))
  )
  n
)

;; Overreach: ground the envelope claims that the rig never covered. Every
;; vertex of the envelope and the midpoint of every one of its sides is tested
;; against the body placed at fractions 0, 1/N, ... of the rigid motion between
;; each pair of states. The worst distance outside all of them is the overreach.
;;
;; That reference has a sawtooth of its own, 1/N as deep as the one the old
;; envelope had, and a point sitting in one of its notches reads as overreach
;; that is not real. So it is measured at two N: an overreach that is real
;; stays put as N grows; a reference artefact shrinks in proportion. At N=16
;; the worst read 0.0095 on the outside of the exit, at N=64 that point was
;; gone and the worst was 0.0017 on the inside of the turn - the inner chord
;; overstating by its sagitta, second order and under the floor.
;;
;; Returns (worst point).
(defun turn-test-envelope-overreach (vehicle paths loop n / a best bodies corners d dc fractions
                                        i index pts rest samples where worst)
  (setq i 0)
  (repeat n (setq fractions (cons (/ (float i) n) fractions) i (1+ i)))
  (setq index 0)
  (foreach segment vehicle
    (foreach corners (turn-test-envelope-bodies (list segment) (list (nth index paths)) fractions)
      (setq bodies (cons (list corners (turn-test-envelope-centre corners)
                               (/ (distance (car corners) (caddr corners)) 2.0))
                         bodies))
    )
    (setq
      corners (turn-body-corners segment (last (nth index paths)))
      bodies (cons (list corners (turn-test-envelope-centre corners)
                         (/ (distance (car corners) (caddr corners)) 2.0))
                   bodies)
      index (1+ index)
    )
  )
  (setq pts (turn-test-envelope-vertices loop) a (car (reverse pts)) worst 0.0)
  (foreach b pts
    (setq samples (cons b (cons (list (/ (+ (car a) (car b)) 2.0) (/ (+ (cadr a) (cadr b)) 2.0)) samples)) a b)
  )
  (foreach p samples
    (setq best 1e99 rest bodies)
    (while (and rest (< 0.0 best))
      (setq dc (distance p (cadr (car rest))))
      (if (< (- dc (caddr (car rest))) best)
        (if (< (setq d (turn-test-envelope-outside-by p (car (car rest)))) best) (setq best d))
      )
      (setq rest (cdr rest))
    )
    (if (> best worst) (setq worst best where p))
  )
  (list worst where)
)

(defun turn-test-envelope-centre (corners)
  (list (/ (+ (car (car corners)) (car (caddr corners))) 2.0)
        (/ (+ (cadr (car corners)) (cadr (caddr corners))) 2.0))
)

;;; ---------------------------------------------------------------------------
;;; The suite
;;; ---------------------------------------------------------------------------
(defun turn-test-envelope-run ()
  (turn-test-capture-alerts)
  (turn-test-envelope-run-escape)
  (turn-test-envelope-run-overreach)
  (turn-test-envelope-run-tires)
  (turn-test-envelope-run-backwards)
)

(defun turn-test-envelope-run-escape (/ coarse fine floor mid ratio-1 ratio-2 rig)
  (setq rig (turn-test-envelope-rig))

  (turn-test-section "Escape: ground the rig covers that the envelope leaves out")
  (turn-test-write "WB-67, 90 degree left turn on radius 50, three step lengths.")
  (turn-test-write "")
  (setq
    coarse (turn-test-envelope-measure rig 2.4)
    mid (turn-test-envelope-measure rig 1.2)
    fine (turn-test-envelope-measure rig 0.6)
  )
  (turn-test-check "every run gave exactly one envelope loop" (and coarse mid fine))
  (if (and coarse mid fine)
    (progn
      (setq
        ratio-1 (/ (car coarse) (max 1e-12 (car mid)))
        ratio-2 (/ (car mid) (max 1e-12 (car fine)))
      )
      (turn-test-write (strcat "- halving the step cut the escape by "
                               (rtos ratio-1 2 2) " then " (rtos ratio-2 2 2)
                               " (about 2 = first order, about 4 = second order)"))
      ;; turn-edge-sweep drops strips thinner than 1e-4 of the body, so the
      ;; escape may not fall below that. Second order until it reaches that
      ;; floor, and never above it after.
      (setq floor (* 1e-4 (apply 'max (mapcar '(lambda (s) (turn-seg-get s "body-length")) rig))))
      (turn-test-write (strcat "- documented floor (1e-4 of the longest body): " (rtos floor 2 4)))
      (turn-test-check "the escape is second order: halving the step cuts it by more than 3"
                       (> ratio-1 3.0))
      (turn-test-check "then second order again, or down at the floor"
                       (or (> ratio-2 3.0) (<= (car fine) floor)))
    )
  )

  (turn-test-envelope-clear)
)

(defun turn-test-envelope-run-overreach (/ coarse fine floor loops paths rig)
  (setq rig (turn-test-envelope-rig))
  (turn-test-section "Overreach: ground the envelope claims that the rig never covered")
  (turn-test-envelope-clear)
  (setq paths (turn-path rig (turn-course-from-curve (turn-test-envelope-corner-course) '(0.0 0.0) 1.2) pi))
  (turn-draw-envelope rig paths)
  (setq loops (turn-test-envelope-loops))
  (turn-test-check "one envelope loop to measure" (= 1 (length loops)))
  (if (= 1 (length loops))
    (progn
      (setq
        coarse (turn-test-envelope-overreach rig paths (car loops) 16)
        fine (turn-test-envelope-overreach rig paths (car loops) 64)
        floor (* 1e-4 (apply 'max (mapcar '(lambda (s) (turn-seg-get s "body-length")) rig)))
      )
      (foreach r (list (cons 16 coarse) (cons 64 fine))
        (turn-test-write (strcat "- step 1.20, reference of " (itoa (car r))
                                 " placements per step: worst envelope point outside them all "
                                 (rtos (cadr r) 2 6) " at "
                                 (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) (caddr r)))))
      )
      (turn-test-check "any overreach is the reference's own sawtooth (4x finer cuts it by more than 3) or under the floor"
                       (or (<= (car fine) floor) (> (/ (car coarse) (car fine)) 3.0)))
    )
  )
  (turn-test-envelope-clear)
)

;;; ---------------------------------------------------------------------------
;;; A rig that starts facing against its course
;;; ---------------------------------------------------------------------------
;;; Tom's turntest.dwg, 2026-09-26: a vehicle block rotated opposite to the
;;; course. The rig folds round in its first steps, edges pivot about points on
;;; themselves, and under the old envelope one self-crossing polygon made UNION
;;; fail outright: 1387 regions left on the layer and one of them exploded.
(defun turn-test-envelope-run-backwards (/ en leftovers loops paths rig ss)
  (turn-test-section "A rig that starts facing against its course")
  (turn-test-envelope-clear)
  (setq
    rig (turn-test-envelope-narrow-rig)
    en (turn-test-envelope-corner-course)
    ;; The course sets off toward -X; the block says +X.
    paths (turn-path rig (turn-course-from-curve en '(0.0 0.0) 2.2) 0.0)
  )
  (turn-draw-envelope rig paths)
  (setq
    ss (ssget "_X" (list '(0 . "REGION") (cons 8 (turn-layer nil "ENVL"))))
    leftovers (if ss (sslength ss) 0)
    loops (turn-test-envelope-loops)
  )
  (turn-test-equal "no regions left on the envelope layer" 0 leftovers)
  (turn-test-check "an envelope was drawn" (< 0 (length loops)))
  (turn-test-check "every envelope loop is flagged closed"
                   (not (vl-some '(lambda (en) (/= 1 (logand 1 (cdr (assoc 70 (entget en)))))) loops)))
  (turn-test-punch-capture-report rig paths nil)
  (turn-test-punch-check-said "the report says the vehicle starts facing away from the course"
                              "starts facing")
  (turn-test-envelope-clear)
)

;;; ---------------------------------------------------------------------------
;;; Every tire path lies inside the envelope
;;; ---------------------------------------------------------------------------
;;; Found by Tom in turntest.dwg, 2026-09-23: a trailer 4 wide on a 6 ft wheel
;;; track. Its wheels stand 1 ft outside the body, the envelope was built from
;;; body outlines only, and the rear right tire path ran 1.03 outside it.

;; A WB-67 tractor towing a flatbed whose deck is narrower than its axle.
(defun turn-test-envelope-narrow-rig ()
  (list
    (turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (turn-segment "Flatbed" 30.0 6.0 34.0 4.0 3.0 nil
                       0.0 (* pi (/ 70.0 180.0)))
  )
)

;; Worst distance by which any tire path vertex or chord midpoint lies outside
;; the one envelope loop. Returns (distance layer-role point).
(defun turn-test-envelope-tire-escape (vehicle paths loop / a cp d index loci pts role roles where worst)
  (setq pts (turn-test-envelope-vertices loop) worst 0.0 index 0)
  (foreach segment vehicle
    ;; A trailer's guide point is its kingpin or drawbar eye, not wheels, so
    ;; its FRNT loci are not tire paths and are not held to this.
    (setq loci (turn-tire-loci segment (nth index paths))
          roles (list "FRNT-LEFT" "FRNT-RGHT" "REAR-LEFT" "REAR-RGHT"))
    (if (< 0 index) (setq loci (cddr loci) roles (cddr roles)))
    (foreach locus loci
      (setq role (strcat (turn-segment-stem index) "-" (car roles)) roles (cdr roles) a (car locus))
      (foreach p (cons a (apply 'append
                                (mapcar '(lambda (b / m)
                                           (setq m (list (/ (+ (car a) (car b)) 2.0) (/ (+ (cadr a) (cadr b)) 2.0)) a b)
                                           (list m b))
                                        (cdr locus))))
        (if (not (turn-test-envelope-inside-p p pts))
          (progn
            (setq cp (vlax-curve-getClosestPointTo loop (list (car p) (cadr p) 0.0))
                  d (distance (list (car p) (cadr p)) (list (car cp) (cadr cp))))
            (if (> d worst) (setq worst d where (cons role p)))
          )
        )
      )
    )
    (setq index (1+ index))
  )
  (list worst (car where) (cdr where))
)

(defun turn-test-envelope-tires-on (label vehicle / esc floor loops paths)
  (turn-test-envelope-clear)
  (setq paths (turn-path vehicle (turn-course-from-curve (turn-test-envelope-corner-course) '(0.0 0.0) 1.2) pi))
  (turn-draw-envelope vehicle paths)
  (setq
    loops (turn-test-envelope-loops)
    floor (* 1e-4 (apply 'max (mapcar '(lambda (s) (turn-seg-get s "body-length")) vehicle)))
  )
  (turn-test-check (strcat label ": one envelope loop") (= 1 (length loops)))
  (if (= 1 (length loops))
    (progn
      (setq esc (turn-test-envelope-tire-escape vehicle paths (car loops)))
      (turn-test-write (strcat "- " label ": worst tire path point outside the envelope "
                               (rtos (car esc) 2 4)
                               (if (cadr esc)
                                 (strcat " (" (cadr esc) " at "
                                         (vl-princ-to-string (mapcar '(lambda (x) (atof (rtos x 2 2))) (caddr esc))) ")")
                                 "")))
      (turn-test-check (strcat label ": every tire path lies inside the envelope, to within the floor "
                               (rtos floor 2 4))
                       (<= (car esc) floor))
    )
  )
)

(defun turn-test-envelope-run-tires ()
  (turn-test-section "Every tire path lies inside the envelope")
  (turn-test-envelope-tires-on "WB-67, track equal to body" (turn-test-envelope-rig))
  (turn-test-envelope-tires-on "flatbed 4 wide on a 6 ft track" (turn-test-envelope-narrow-rig))
  (turn-test-envelope-clear)
)
