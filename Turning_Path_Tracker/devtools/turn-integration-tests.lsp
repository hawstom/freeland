;;; turn-integration-tests.lsp - Drives BUILDVEHICLE and TURN against a real
;;; drawing database, then checks what actually landed there.
;;;
;;; NOTE ON STYLE: this file does the work, and the .scr is a single line that
;;; loads it and calls (tti-run). Feeding prompt answers as script lines is how
;;; the earlier version of this suite kept desynchronising - one wrong prompt
;;; count and AutoCAD sits waiting forever. So the commands are split: the
;;; prompting shells (c:turn, c:buildvehicle) are thin, and everything below
;;; calls the non-interactive cores (wiki-turn-build-block, wiki-turn-run)
;;; directly. Simulating keystrokes is reserved for testing the prompts
;;; themselves, which is what turn-prompt-tests.scr is for.

;;; ---------------------------------------------------------------------------
;;; The vehicle under test: a tractor, a trailer, and a pup. Three segments,
;;; two hitches - the thing 1.1.x could never do.
;;; ---------------------------------------------------------------------------
(defun tti-vehicle ()
  (list
    ;;                    name       wb   axle body len wid  fhang hitch steer            art
    (wiki-turn-segment "Truck"    14.0 7.0  20.0    8.0  3.0   3.0  (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (wiki-turn-segment "Trailer1" 12.0 7.0  18.0    8.0 -2.0   2.0  0.0                   (* pi (/ 70.0 180.0)))
    (wiki-turn-segment "Pup"      10.0 7.0  14.0    8.0 -2.0   nil  0.0                   (* pi (/ 70.0 180.0)))
  )
)

;; A course: straight, then a sweeping left turn. Built as a real polyline so
;; that wiki-turn-course-from-curve is exercised the way TURN uses it.
(defun tti-draw-course (/ en)
  (command "._pline" '(3.0 0.0) '(-100.0 0.0) "_a" '(-150.0 -50.0) '(-150.0 -150.0) "")
  (entlast)
)

;;; ---------------------------------------------------------------------------
;;; Checks
;;; ---------------------------------------------------------------------------
(defun tti-check-segment (index tows-p / role)
  (tt-write (strcat "**Segment " (itoa index) " - " (wiki-turn-segment-stem index) "**"))
  (foreach role '("FRNT-LEFT" "FRNT-RGHT" "REAR-LEFT" "REAR-RGHT")
    (tt-equal
      (strcat "one pline on " (wiki-turn-layer index role))
      1
      (tt-count-on-layer (wiki-turn-layer index role))
    )
  )
  (tt-equal
    (strcat "four corner loci on " (wiki-turn-layer index "CRNR"))
    4
    (tt-count-on-layer (wiki-turn-layer index "CRNR"))
  )
  (tt-equal
    (strcat "hitch path on " (wiki-turn-layer index "HTCH"))
    (if tows-p 1 0)
    (tt-count-on-layer (wiki-turn-layer index "HTCH"))
  )
  (tt-check
    (strcat "body outlines plotted on " (wiki-turn-layer index "BODY"))
    (< 1 (tt-count-on-layer (wiki-turn-layer index "BODY")))
  )
)

;; Every layer name TURN creates must be AIA / NCS legal: hyphen-delimited
;; fields of exactly four characters, after the C- discipline prefix.
(defun tti-check-ncs (/ bad fields index name role)
  (setq bad nil index -1)
  (repeat 3
    (setq index (1+ index))
    (foreach role (mapcar 'car *wiki-turn-roles*)
      (setq
        name (wiki-turn-layer index role)
        fields (tti-split name "-")
      )
      (if (or (/= "C" (car fields))
              (vl-some '(lambda (f) (/= 4 (strlen f))) (cdr fields))
          )
        (setq bad (cons name bad))
      )
    )
  )
  (foreach role (mapcar 'car *wiki-turn-vehicle-roles*)
    (setq
      name (wiki-turn-layer nil role)
      fields (tti-split name "-")
    )
    (if (or (/= "C" (car fields))
            (vl-some '(lambda (f) (/= 4 (strlen f))) (cdr fields))
        )
      (setq bad (cons name bad))
    )
  )
  (if bad (foreach b bad (tt-write (strcat "- non-compliant: " b))))
  (tt-equal "layer names with a field that is not 4 characters" 0 (length bad))
)

(defun tti-split (s delim / i out part)
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

(defun tti-check-vertex-counts (/ bad el en i ss)
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
  (tt-equal "polylines whose DXF 90 disagrees with their vertex count" 0 bad)
  (tt-check "TURN drew some polylines at all" (and ss (< 0 (sslength ss))))
)

;;; ---------------------------------------------------------------------------
;;; The swept-path envelope
;;; ---------------------------------------------------------------------------
;; Bounding box (minx miny maxx maxy) of every group-10 point on every
;; LWPOLYLINE matching a layer wildcard.
(defun tti-bbox (wildcard / box en i p ss)
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

(defun tti-check-envelope (/ closed corners en envl i inside ss)
  (setq envl (wiki-turn-layer nil "ENVL"))
  (tt-check
    (strcat "closed polylines on " envl)
    (< 0 (tt-count-on-layer envl))
  )
  ;; Everything that reaches the drawing must be editable geometry. A region
  ;; left behind means the explode/join step failed.
  (tt-equal
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
  (tt-equal "every envelope polyline is closed" (if ss (sslength ss) 0) closed)
  ;; The envelope must reach at least as far as every body corner locus does,
  ;; because those loci are exactly what generates it.
  (setq
    envl (tti-bbox (wiki-turn-layer nil "ENVL"))
    corners (tti-bbox "C-TURN-*-CRNR")
    inside
     (and envl corners
          (<= (car envl) (+ (car corners) 1e-6))
          (<= (cadr envl) (+ (cadr corners) 1e-6))
          (>= (caddr envl) (- (caddr corners) 1e-6))
          (>= (cadddr envl) (- (cadddr corners) 1e-6))
     )
  )
  (tt-write (strcat "- envelope extents: " (vl-princ-to-string envl)))
  (tt-write (strcat "- corner locus extents: " (vl-princ-to-string corners)))
  (tt-check "the envelope encloses every corner locus" inside)
  (tti-check-envelope-area)
)

;; Shoelace area of one closed LWPOLYLINE.
(defun tti-pline-area (en / a p pts)
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
(defun tti-check-envelope-area (/ box footprint swept)
  (setq
    swept (apply '+ (mapcar 'tti-pline-area
                            (tti-layer-entities (wiki-turn-layer nil "ENVL"))))
    footprint
     (apply '+ (mapcar '(lambda (s) (* (wiki-turn-seg-get s "body-length")
                                       (wiki-turn-seg-get s "body-width")))
                       (tti-vehicle)))
    box (tti-bbox (wiki-turn-layer nil "ENVL"))
  )
  (tt-write (strcat "- swept area: " (rtos swept 2 1)
                    ", standing footprint: " (rtos footprint 2 1)))
  (tt-check "swept area exceeds the rig's standing footprint" (> swept footprint))
  (tt-check
    "swept area fits inside the envelope's own bounding box"
    (< swept (* (- (caddr box) (car box)) (- (cadddr box) (cadr box))))
  )
)

(defun tti-layer-entities (lay / en i out ss)
  (setq
    ss (ssget "_X" (list '(0 . "LWPOLYLINE") (cons 8 lay) '(410 . "Model")))
    i -1
  )
  (if ss (while (setq en (ssname ss (setq i (1+ i)))) (setq out (cons en out))))
  out
)

;; A block built by wiki-turn-build-block must read back as the same vehicle.
(defun tti-check-round-trip (en-block / atts back forward)
  (setq
    forward (tti-vehicle)
    atts (wiki-turn-block-attributes en-block)
    back (wiki-turn-vehicle-from-attributes atts)
  )
  (tt-equal "round trip recovers three segments" 3 (length back))
  (tt-equal "round trip recovers the names"
            (mapcar '(lambda (s) (wiki-turn-seg-get s "name")) forward)
            (mapcar '(lambda (s) (wiki-turn-seg-get s "name")) back))
  (tt-equal "round trip recovers the wheelbases"
            (mapcar '(lambda (s) (wiki-turn-seg-get s "wheelbase")) forward)
            (mapcar '(lambda (s) (wiki-turn-seg-get s "wheelbase")) back))
  (tt-equal "round trip preserves front-hang signs"
            (mapcar '(lambda (s) (wiki-turn-seg-get s "front-hang")) forward)
            (mapcar '(lambda (s) (wiki-turn-seg-get s "front-hang")) back))
  (tt-check "round trip preserves which segments tow"
            (equal (mapcar '(lambda (s) (if (wiki-turn-seg-get s "hitch") 1 0)) forward)
                   (mapcar '(lambda (s) (if (wiki-turn-seg-get s "hitch") 1 0)) back)))
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
(defun tti-check-coarse-step (en-course vehicle / after before coarse loops)
  (setq before (length (tti-layer-entities (wiki-turn-layer nil "ENVL"))))
  (tt-equal "the fine-step run gave exactly one closed envelope" 1 before)
  ;; The shortest body in this rig is the Pup at 14.0, so 20.0 guarantees gaps.
  (setq coarse (wiki-turn-course-from-curve en-course '(-40.0 0.0) 20.0))
  (wiki-turn-run vehicle coarse pi 10)
  (setq
    after (tti-layer-entities (wiki-turn-layer nil "ENVL"))
    loops (- (length after) before)
  )
  (tt-write (strcat "- loops from the coarse run: " (itoa loops)))
  (tt-check "a step longer than the shortest body opens holes" (< 1 loops))
  ;; PEDIT Join returns loops whose ends coincide but whose Closed flag is off.
  ;; Tom's 1284-vertex envelope measured end gap 0.000 with Closed "no", which
  ;; looks shut and is not: hatching, offset and area all refuse it.
  (tt-check "every envelope loop is flagged closed, not merely shut-looking"
            (not (vl-some
                   '(lambda (en) (/= 1 (logand 1 (cdr (assoc 70 (entget en))))))
                   after)))
  ;; Every surviving loop must be real geometry, not a zero-area sliver.
  (tt-check "no zero-area slivers survive"
            (not (vl-some
                   '(lambda (en) (< (abs (tti-pline-area en))
                                    (* 1e-4 (wiki-turn-smallest-body-area vehicle))))
                   after)))
)

(defun tti-run (/ course en-block en-course paths vehicle)
  (tt-capture-alerts)
  (tt-mark "start")
  (setq vehicle (tti-vehicle))

  (tt-section "BUILDVEHICLE: three segments, no prompting")
  (setq en-block (wiki-turn-build-block '(0.0 0.0) vehicle))
  (tt-mark "vehicle block built")
  (tt-check "a block insert was produced" (= "INSERT" (cdr (assoc 0 (entget en-block)))))
  (tti-check-round-trip en-block)

  (tt-section "Course sampled straight off the curve")
  (setq
    en-course (tti-draw-course)
    course (wiki-turn-course-from-curve en-course '(-40.0 0.0) 1.4)
  )
  (tt-mark "course sampled")
  (tt-check "the course has plenty of points" (< 100 (length course)))
  (tt-near "travel starts at the picked end" 0.0
           (distance (car course) '(3.0 0.0)) 0.001)

  (tt-section "TURN: track the chain and draw it")
  (setq paths (wiki-turn-run vehicle course pi 10))
  (tt-mark "TURN finished")
  (tt-equal "one path per segment" 3 (length paths))

  (tt-section "What reached the drawing")
  (tti-check-segment 0 T)
  (tti-check-segment 1 T)
  (tti-check-segment 2 nil)

  (tt-section "AIA / National CAD Standard layer names")
  (tti-check-ncs)

  (tt-section "Swept path envelope")
  (tti-check-envelope)

  (tt-section "Polyline integrity")
  (tti-check-vertex-counts)

  (tt-section "A step coarser than the shortest body opens holes")
  (tti-check-coarse-step en-course vehicle)

  (tt-section "Nothing was left behind")
  (tt-equal "no stray POINT entities (1.1.x littered these)" 0
            (if (ssget "_X" '((0 . "POINT"))) (sslength (ssget "_X" '((0 . "POINT")))) 0))

  (tt-report-census)
  (princ)
)
(princ "\nturn-integration-tests.lsp loaded.")
(princ)
