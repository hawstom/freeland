;;; turn-integration-tests.lsp - Drives BUILDVEHICLE and TURN against a real
;;; drawing database, then checks what actually landed there.
;;;
;;; NOTE ON STYLE: this file does the work, and the .scr is a single line that
;;; loads it and calls (turn-test-integration-run). Feeding prompt answers as script lines is how
;;; the earlier version of this suite kept desynchronising - one wrong prompt
;;; count and AutoCAD sits waiting forever. So the commands are split: the
;;; prompting shells (c:turn, c:buildvehicle) are thin, and everything below
;;; calls the non-interactive cores (turn-build-block, turn-run)
;;; directly. Simulating keystrokes is reserved for testing the prompts
;;; themselves, which is what turn-prompt-tests.scr is for.

;;; ---------------------------------------------------------------------------
;;; The vehicle under test: a tractor, a trailer, and a pup. Three segments,
;;; two hitches - the thing 1.1.x could never do.
;;; ---------------------------------------------------------------------------
(defun turn-test-integration-vehicle ()
  (list
    ;;                    name       wb   axle body len wid  fhang hitch steer            art
    (turn-segment "Truck"    14.0 7.0  20.0    8.0  3.0   3.0  (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (turn-segment "Trailer1" 12.0 7.0  18.0    8.0 -2.0   2.0  0.0                   (* pi (/ 70.0 180.0)))
    (turn-segment "Pup"      10.0 7.0  14.0    8.0 -2.0   nil  0.0                   (* pi (/ 70.0 180.0)))
  )
)

;; A course: straight, then a sweeping left turn. Built as a real polyline so
;; that turn-course-from-curve is exercised the way TURN uses it.
(defun turn-test-integration-draw-course (/ en)
  (command "._pline" '(3.0 0.0) '(-100.0 0.0) "_a" '(-150.0 -50.0) '(-150.0 -150.0) "")
  (entlast)
)

;;; ---------------------------------------------------------------------------
;;; Checks
;;; ---------------------------------------------------------------------------
(defun turn-test-integration-check-segment (index tows-p / role)
  (turn-test-write (strcat "**Segment " (itoa index) " - " (turn-segment-stem index) "**"))
  (foreach role '("FRNT-LEFT" "FRNT-RGHT" "REAR-LEFT" "REAR-RGHT")
    (turn-test-equal
      (strcat "one pline on " (turn-layer index role))
      1
      (turn-test-count-on-layer (turn-layer index role))
    )
  )
  (turn-test-equal
    (strcat "four corner loci on " (turn-layer index "CRNR"))
    4
    (turn-test-count-on-layer (turn-layer index "CRNR"))
  )
  (turn-test-equal
    (strcat "hitch path on " (turn-layer index "HTCH"))
    (if tows-p 1 0)
    (turn-test-count-on-layer (turn-layer index "HTCH"))
  )
  (turn-test-check
    (strcat "body outlines plotted on " (turn-layer index "BODY"))
    (< 1 (turn-test-count-on-layer (turn-layer index "BODY")))
  )
)

;; Every layer name TURN creates must be AIA / NCS legal: hyphen-delimited
;; fields of exactly four characters, after the C- discipline prefix.
(defun turn-test-integration-check-ncs (/ bad fields index name role)
  (setq bad nil index -1)
  (repeat 3
    (setq index (1+ index))
    (foreach role (mapcar 'car *turn-roles*)
      (setq
        name (turn-layer index role)
        fields (turn-test-integration-split name "-")
      )
      (if (or (/= "C" (car fields))
              (vl-some '(lambda (f) (/= 4 (strlen f))) (cdr fields))
          )
        (setq bad (cons name bad))
      )
    )
  )
  (foreach role (mapcar 'car *turn-vehicle-roles*)
    (setq
      name (turn-layer nil role)
      fields (turn-test-integration-split name "-")
    )
    (if (or (/= "C" (car fields))
            (vl-some '(lambda (f) (/= 4 (strlen f))) (cdr fields))
        )
      (setq bad (cons name bad))
    )
  )
  (if bad (foreach b bad (turn-test-write (strcat "- non-compliant: " b))))
  (turn-test-equal "layer names with a field that is not 4 characters" 0 (length bad))
)

(defun turn-test-integration-split (s delim / i out part)
  (setq part "")
  (setq i 1)
  (while (<= i (strlen s))
    (if (= delim (substr s i 1))
      (setq out (cons part out) part "")
      (setq part (strcat part (substr s i 1)))
    )
    (setq i (1+ i))
  )
  (reverse (cons part out))
)

(defun turn-test-integration-check-vertex-counts (/ bad el en i ss)
  (setq
    ss (ssget "_X" '((0 . "LWPOLYLINE") (8 . "C-TURN-*")))
    i -1
    bad 0
  )
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (setq el (entget en))
      (if (/= (cdr (assoc 90 el))
              (length (vl-remove-if-not '(lambda (x) (= 10 (car x))) el))
          )
        (setq bad (1+ bad))
      )
    )
  )
  (turn-test-equal "polylines whose DXF 90 disagrees with their vertex count" 0 bad)
  (turn-test-check "TURN drew some polylines at all" (and ss (< 0 (sslength ss))))
)

;;; ---------------------------------------------------------------------------
;;; The swept-path envelope
;;; ---------------------------------------------------------------------------
;; Bounding box (minx miny maxx maxy) of every group-10 point on every
;; LWPOLYLINE matching a layer wildcard.
(defun turn-test-integration-bbox (wildcard / box en i p ss)
  (setq
    ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 wildcard) '(410 . "Model")))
    i -1
  )
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (foreach p (entget en)
        (if (= 10 (car p))
          (setq
            p (cdr p)
            box (if box
                  (list (min (car box) (car p)) (min (cadr box) (cadr p))
                        (max (caddr box) (car p)) (max (cadddr box) (cadr p)))
                  (list (car p) (cadr p) (car p) (cadr p))
                )
          )
        )
      )
    )
  )
  box
)

(defun turn-test-integration-check-envelope (/ closed corners en envl i inside ss)
  (setq envl (turn-layer nil "ENVL"))
  (turn-test-check
    (strcat "closed polylines on " envl)
    (< 0 (turn-test-count-on-layer envl))
  )
  ;; Everything that reaches the drawing must be editable geometry. A region
  ;; left behind means the explode/join step failed.
  (turn-test-equal
    "regions left behind on the envelope layer"
    0
    (if (setq ss (ssget "_X" (list '(0 . "REGION") (cons 8 envl))))
      (sslength ss)
      0
    )
  )
  ;; Every envelope polyline must be closed. An open one is a broken boundary.
  (setq
    ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 envl)))
    i -1
    closed 0
  )
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (if (= 1 (logand 1 (cdr (assoc 70 (entget en))))) (setq closed (1+ closed)))
    )
  )
  (turn-test-equal "every envelope polyline is closed" (if ss (sslength ss) 0) closed)
  ;; The envelope must reach at least as far as every body corner locus does,
  ;; because those loci are exactly what generates it.
  (setq
    envl (turn-test-integration-bbox (turn-layer nil "ENVL"))
    corners (turn-test-integration-bbox "C-TURN-*-CRNR")
    inside
     (and envl corners
          (<= (car envl) (+ (car corners) 1e-6))
          (<= (cadr envl) (+ (cadr corners) 1e-6))
          (>= (caddr envl) (- (caddr corners) 1e-6))
          (>= (cadddr envl) (- (cadddr corners) 1e-6))
     )
  )
  (turn-test-write (strcat "- envelope extents: " (vl-princ-to-string envl)))
  (turn-test-write (strcat "- corner locus extents: " (vl-princ-to-string corners)))
  (turn-test-check "the envelope encloses every corner locus" inside)
  (turn-test-integration-check-envelope-area)
)

;; Shoelace area of one closed LWPOLYLINE.
(defun turn-test-integration-pline-area (en / a p pts)
  (setq pts (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= 10 (car x))) (entget en))))
  (setq pts (append pts (list (car pts))) a 0.0)
  (while (cdr pts)
    (setq
      p (car pts)
      a (+ a (- (* (car p) (cadr (cadr pts))) (* (car (cadr pts)) (cadr p))))
      pts (cdr pts)
    )
  )
  (abs (/ a 2.0))
)

;; The swept area TURN reports must be bigger than the rig standing still and
;; smaller than the box the manoeuvre fits in. Those are loose bounds on
;; purpose: they catch a union that silently kept one body, or one that leaked.
(defun turn-test-integration-check-envelope-area (/ box footprint swept)
  (setq
    swept (apply '+ (mapcar 'turn-test-integration-pline-area
                            (turn-test-integration-layer-entities (turn-layer nil "ENVL"))))
    footprint
     (apply '+ (mapcar '(lambda (s) (* (turn-seg-get s "body-length")
                                       (turn-seg-get s "body-width")))
                       (turn-test-integration-vehicle)))
    box (turn-test-integration-bbox (turn-layer nil "ENVL"))
  )
  (turn-test-write (strcat "- swept area: " (rtos swept 2 1)
                    ", standing footprint: " (rtos footprint 2 1)))
  (turn-test-check "swept area exceeds the rig's standing footprint" (> swept footprint))
  (turn-test-check
    "swept area fits inside the envelope's own bounding box"
    (< swept (* (- (caddr box) (car box)) (- (cadddr box) (cadr box))))
  )
)

(defun turn-test-integration-layer-entities (lay / en i out ss)
  (setq
    ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 lay) '(410 . "Model")))
    i -1
  )
  (if ss (while (setq en (ssname ss (setq i (1+ i)))) (setq out (cons en out))))
  out
)

;; A block built by turn-build-block must read back as the same vehicle.
(defun turn-test-integration-check-round-trip (en-block / atts back forward)
  (setq
    forward (turn-test-integration-vehicle)
    atts (turn-block-attributes en-block)
    back (turn-vehicle-from-attributes atts)
  )
  (turn-test-equal "round trip recovers three segments" 3 (length back))
  (turn-test-equal "round trip recovers the names"
            (mapcar '(lambda (s) (turn-seg-get s "name")) forward)
            (mapcar '(lambda (s) (turn-seg-get s "name")) back))
  (turn-test-equal "round trip recovers the wheelbases"
            (mapcar '(lambda (s) (turn-seg-get s "wheelbase")) forward)
            (mapcar '(lambda (s) (turn-seg-get s "wheelbase")) back))
  (turn-test-equal "round trip preserves front-hang signs"
            (mapcar '(lambda (s) (turn-seg-get s "front-hang")) forward)
            (mapcar '(lambda (s) (turn-seg-get s "front-hang")) back))
  (turn-test-check "round trip preserves which segments tow"
            (equal (mapcar '(lambda (s) (if (turn-seg-get s "hitch") 1 0)) forward)
                   (mapcar '(lambda (s) (if (turn-seg-get s "hitch") 1 0)) back)))
)

;;; ---------------------------------------------------------------------------
;; Tom's 2026-09-13 report. A three segment rig plotted on a step of about 23,
;; against a tractor body only 20 long, came back as seventeen loops on
;; C-TURN-ENVL - one real boundary, fifteen holes, and one loop of area 0.001.
;;
;; The holes are not a union bug. The envelope lays each body outline down once
;; per calculation step, so a step longer than the body means consecutive
;; placements never touch and the union honestly has gaps in it. The 0.001 loop
;; is different: that is arithmetic litter and gets dropped.
;;
;; Reproduce both deliberately. The fine-step run above must give exactly one
;; loop; this coarse-step run must give more, and must not leave slivers.
(defun turn-test-integration-check-coarse-step (en-course vehicle / after before coarse loops)
  (setq before (length (turn-test-integration-layer-entities (turn-layer nil "ENVL"))))
  (turn-test-equal "the fine-step run gave exactly one closed envelope" 1 before)
  ;; The shortest body in this rig is the Pup at 14.0, so 20.0 guarantees gaps.
  (setq coarse (turn-course-from-curve en-course '(-40.0 0.0) 20.0))
  (turn-run vehicle coarse pi 10)
  (setq
    after (turn-test-integration-layer-entities (turn-layer nil "ENVL"))
    loops (- (length after) before)
  )
  (turn-test-write (strcat "- loops from the coarse run: " (itoa loops)))
  (turn-test-check "a step longer than the shortest body opens holes" (< 1 loops))
  ;; PEDIT Join returns loops whose ends coincide but whose Closed flag is off.
  ;; Tom's 1284-vertex envelope measured end gap 0.000 with Closed "no", which
  ;; looks shut and is not: hatching, offset and area all refuse it.
  (turn-test-check "every envelope loop is flagged closed, not merely shut-looking"
            (not (vl-some
                   '(lambda (en) (/= 1 (logand 1 (cdr (assoc 70 (entget en))))))
                   after)))
  ;; Every surviving loop must be real geometry, not a zero-area sliver.
  (turn-test-check "no zero-area slivers survive"
            (not (vl-some
                   '(lambda (en) (< (abs (turn-test-integration-pline-area en))
                                    (* 1e-4 (turn-smallest-body-area vehicle))))
                   after)))
)

(defun turn-test-integration-run (/ course en-block en-course paths vehicle)
  (turn-test-capture-alerts)
  (turn-test-mark "start")
  (setq vehicle (turn-test-integration-vehicle))

  (turn-test-section "BUILDVEHICLE: three segments, no prompting")
  (setq en-block (turn-build-block '(0.0 0.0) vehicle))
  (turn-test-mark "vehicle block built")
  (turn-test-check "a block insert was produced" (= "INSERT" (cdr (assoc 0 (entget en-block)))))
  (turn-test-integration-check-round-trip en-block)

  (turn-test-section "Course sampled straight off the curve")
  (setq
    en-course (turn-test-integration-draw-course)
    course (turn-course-from-curve en-course '(-40.0 0.0) 1.4)
  )
  (turn-test-mark "course sampled")
  (turn-test-check "the course has plenty of points" (< 100 (length course)))
  (turn-test-near "travel starts at the picked end" 0.0
           (distance (car course) '(3.0 0.0)) 0.001)

  (turn-test-section "TURN: track the chain and draw it")
  (setq paths (turn-run vehicle course pi 10))
  (turn-test-mark "TURN finished")
  (turn-test-equal "one path per segment" 3 (length paths))

  (turn-test-section "What reached the drawing")
  (turn-test-integration-check-segment 0 T)
  (turn-test-integration-check-segment 1 T)
  (turn-test-integration-check-segment 2 nil)

  (turn-test-section "AIA / National CAD Standard layer names")
  (turn-test-integration-check-ncs)

  (turn-test-section "Swept path envelope")
  (turn-test-integration-check-envelope)

  (turn-test-section "Polyline integrity")
  (turn-test-integration-check-vertex-counts)

  (turn-test-section "A step coarser than the shortest body opens holes")
  (turn-test-integration-check-coarse-step en-course vehicle)

  (turn-test-section "Nothing was left behind")
  (turn-test-equal "no stray POINT entities (1.1.x littered these)" 0
            (if (ssget "_X" '((0 . "POINT"))) (sslength (ssget "_X" '((0 . "POINT")))) 0))

  (turn-test-report-census)
  (princ)
)
(princ "\nturn-integration-tests.lsp loaded.")
(princ)
