;;; turn-punch-tests.lsp - the punch list, automated.
;;;
;;; devtools/turn-2.0.0-punch-list.md was written as eleven hand tests for Tom.
;;; Ten of them assert something mechanical - what gets drawn, on which layer,
;;; what gets reported, what happens when you pick the wrong object - and a
;;; machine should be checking those, not a person. Item 7 was closed this way
;;; already (turn-curve-tests). This file closes 1, 4, 5, 6, 8, 9, 10 and 11.
;;;
;;; ITEMS 2 AND 3 ARE DELIBERATELY NOT HERE. They ask whether the BUILDVEHICLE
;;; prompts READ clearly - whether a user can tell the tractor's rear-hitch
;;; question from the trailer's kingpin question, which is the confusion that
;;; produced the original bug report. A harness can answer a prompt; it cannot
;;; tell you the wording is good. That is judgement and it stays Tom's.
;;;
;;; Run:  devtools\turn-tests.bat turn-punch-tests
;;;
;;; Test scaffolding. None of it ships to users.

;;; ---------------------------------------------------------------------------
;;; Capturing what TURN says
;;;
;;; wiki-turn-report talks to the user with princ, so the only honest way to
;;; assert "the advisory appears" is to catch the text. AutoLISP lets a built-in
;;; be redefined - that is how the harness already tames the modal alert - so
;;; princ is swapped for the duration of ONE call and put straight back.
;;;
;;; The replacement takes exactly one argument, which is safe only because
;;; everything wiki-turn-report calls is a pure computation. Do not widen the
;;; window around anything that might call a bare (princ).
;;; ---------------------------------------------------------------------------
(setq *tpn-said* "")

(defun tpn-capture-report (vehicle paths area / real result)
  (setq *tpn-said* "" real princ)
  (defun princ (s)
    (if (= 'STR (type s)) (setq *tpn-said* (strcat *tpn-said* s)))
    s
  )
  (setq result (vl-catch-all-apply 'wiki-turn-report (list vehicle paths area)))
  (setq princ real)
  (if (vl-catch-all-error-p result)
    (progn
      (tt-write (strcat "  - report raised: " (vl-catch-all-error-message result)))
      nil
    )
    result
  )
)

;; Did the captured text contain this?
(defun tpn-said-p (needle) (if (vl-string-search needle *tpn-said*) T nil))

(defun tpn-check-said (label needle)
  (tt-check label (tpn-said-p needle))
)

;;; ---------------------------------------------------------------------------
;;; Fixtures
;;; ---------------------------------------------------------------------------
;; A WB-67-shaped tractor and trailer: 65 ft rig wheelbase, as the punch list
;; text assumes.
(defun tpn-rig ()
  (list
    (wiki-turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (wiki-turn-segment "Trailer" 45.5 8.5 53.0 8.5 -3.0 nil
                       0.0 (* pi (/ 70.0 180.0)))
  )
)

;; Straight, a long sweeping arc, straight out again - several hundred feet, as
;; item 5 specifies.
(defun tpn-long-course ()
  (command "._pline" '(0.0 0.0) '(-300.0 0.0) "_a" '(-450.0 -150.0)
           "_l" '(-450.0 -400.0) "")
  (entlast)
)

;; About 80 ft: Kenya's course, the one that cannot articulate.
(defun tpn-short-course ()
  (command "._pline" '(0.0 0.0) '(-50.0 0.0) "_a" '(-80.0 -30.0) "")
  (entlast)
)

(defun tpn-clear (/ ss)
  (foreach filter (list '((8 . "C-TURN-*")) '((0 . "LWPOLYLINE")) '((0 . "INSERT")))
    (if (setq ss (ssget "_X" filter)) (command "._erase" ss ""))
  )
  (princ)
)

(defun tpn-count (filter / ss)
  (if (setq ss (ssget "_X" filter)) (sslength ss) 0)
)

;;; ---------------------------------------------------------------------------
;;; 1. Load
;;; ---------------------------------------------------------------------------
(defun tpn-item-1 ()
  (tt-section "Item 1 - Load")
  (tt-equal "version setting reads 2.0.0" "2.0.0" (wiki-turn-getvar "general.version"))
  (tt-check "TURN is defined" (not (null c:turn)))
  (tt-check "BUILDVEHICLE is defined" (not (null c:buildvehicle)))
  (tt-check "the BV alias is defined" (not (null c:bv)))
  (tt-check "DRIVE is not claimed yet (Phase 4)" (null c:drive))
)

;;; ---------------------------------------------------------------------------
;;; 4. Two trailers - the feature that was asked for
;;; ---------------------------------------------------------------------------
(defun tpn-item-4 (/ atts en rig back)
  (tt-section "Item 4 - two trailers, the asked-for feature")
  (setq rig
    (list
      (wiki-turn-segment "Truck"    14.0 7.0 20.0 8.0  3.0  3.0
                         (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
      (wiki-turn-segment "Trailer1" 12.0 7.0 18.0 8.0 -2.0  2.0
                         0.0 (* pi (/ 70.0 180.0)))
      (wiki-turn-segment "Pup"      10.0 7.0 14.0 8.0 -2.0  nil
                         0.0 (* pi (/ 70.0 180.0)))
    )
  )
  (setq en (wiki-turn-build-block '(0.0 0.0) rig))
  (tt-check "a block was produced" (= "INSERT" (cdr (assoc 0 (entget en)))))
  (setq atts (wiki-turn-block-attributes en))
  (tt-check "the block carries the second trailer's tags"
            (not (null (cdr (assoc (wiki-turn-tag 2 "wheelbase") atts)))))
  (setq back (wiki-turn-vehicle-from-attributes atts))
  (tt-equal "three segments read back off the block" 3 (length back))
  (tt-near "the pup's wheelbase survived the round trip"
           10.0 (wiki-turn-seg-get (caddr back) "wheelbase") 0.001)
  (tt-check "only the last segment tows nothing"
            (and (wiki-turn-seg-get (car back) "hitch")
                 (wiki-turn-seg-get (cadr back) "hitch")
                 (null (wiki-turn-seg-get (caddr back) "hitch"))))
)

;;; ---------------------------------------------------------------------------
;;; 5. TURN on a proper course - the headline features
;;; ---------------------------------------------------------------------------
(defun tpn-item-5 (/ area course en envl paths rig)
  (tt-section "Item 5 - a proper course, the headline features")
  (tpn-clear)
  (setq
    rig (tpn-rig)
    en (tpn-long-course)
    course (wiki-turn-course-from-curve en '(0.0 0.0) 1.95)
    paths (wiki-turn-path rig course pi)
  )
  (wiki-turn-draw-path rig paths 10)
  (setq area (wiki-turn-draw-envelope rig paths))

  (tt-check "tire paths drawn for the tractor"
            (= 1 (tpn-count (list (cons 8 (wiki-turn-layer 0 "FRNT-LEFT"))))))
  (tt-check "tire paths drawn for the trailer"
            (= 1 (tpn-count (list (cons 8 (wiki-turn-layer 1 "REAR-RGHT"))))))
  (tt-check "body outlines plotted repeatedly"
            (< 1 (tpn-count (list (cons 8 (wiki-turn-layer 0 "BODY"))))))

  ;; The headline: no 1.1.x version ever drew this.
  (setq envl (tpn-count '((8 . "C-TURN-ENVL"))))
  (tt-check "a swept path envelope exists on C-TURN-ENVL" (< 0 envl))
  (tt-check "the envelope is reported with an area" (and area (< 0.0 area)))
  (tt-check "every envelope loop is a CLOSED polyline" (tpn-loops-closed-p))

  ;; 1.1.17 drew and erased dozens of POINTs via MEASURE. 2.0 uses vlax-curve-*.
  (tt-equal "TURN littered no POINT entities" 0 (tpn-count '((0 . "POINT"))))

  (tpn-capture-report rig paths area)
  (tpn-check-said "the step count is reported" "segment(s), ")
  (tpn-check-said "the course is reported against the wheelbase" "x the rig's ")
  (tpn-check-said "the swept area is reported" "swept area is ")
  (tpn-check-said "the tightest turn is reported" "tightest turn this vehicle")
  (tpn-check-said "a verdict is printed" "manoeuvre achievable")
  (tt-check "a long course draws NO short-course advisory"
            (not (tpn-said-p "Short course")))
)

;; Every loop on C-TURN-ENVL must have its Closed flag set. AutoCAD's PEDIT Join
;; leaves coincident ends with the flag OFF, which looks shut and is not, and
;; hatching, offset and AREA all refuse it.
(defun tpn-loops-closed-p (/ el i ok ss)
  (setq ss (ssget "_X" '((8 . "C-TURN-ENVL"))) ok T i 0)
  (if (not ss)
    nil
    (progn
      (while (< i (sslength ss))
        (setq el (entget (ssname ss i)))
        (if (zerop (logand 1 (cdr (assoc 70 el)))) (setq ok nil))
        (setq i (1+ i))
      )
      ok
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; 6. Kenya's failure, reproduced on purpose
;;; ---------------------------------------------------------------------------
(defun tpn-item-6 (/ area course en paths ratio rig)
  (tt-section "Item 6 - Kenya's failure, reproduced on purpose")
  (tpn-clear)
  (setq
    rig (tpn-rig)
    en (tpn-short-course)
    course (wiki-turn-course-from-curve en '(0.0 0.0) 1.2)
    paths (wiki-turn-path rig course pi)
  )
  (wiki-turn-draw-path rig paths 10)
  (setq area (wiki-turn-draw-envelope rig paths))

  (setq ratio (/ (wiki-turn-course-length (car paths))
                 (wiki-turn-rig-wheelbase rig)))
  (tt-check "the course really is short for this rig" (< ratio 5.0))

  (tpn-capture-report rig paths area)
  (tpn-check-said "the short-course advisory appears" "Short course")
  (tpn-check-said "it explains why, in rig lengths" "several rig lengths")

  ;; Advice, not a refusal: it still draws everything.
  (tt-check "it still drew the trailer's tire paths"
            (= 1 (tpn-count (list (cons 8 (wiki-turn-layer 1 "REAR-LEFT"))))))
  (tt-check "it still drew an envelope" (< 0 (tpn-count '((8 . "C-TURN-ENVL")))))

  ;; Her symptom: the rig plots as one straight box. The claim worth testing is
  ;; not "articulation is under N degrees" -- that would be a number invented
  ;; here. It is that articulation has not DEVELOPED: give the same rig the same
  ;; turn but room to sustain it, and the trailer swings materially further.
  (tpn-compare-articulation rig)
)

;; turn-curve-tests.lsp has its own copy; this suite does not load that file.
(defun tpn-modelspace ()
  (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
)

;; Articulation on ONE arc radius, swept for a given distance. Holding the
;; radius fixed is the whole point: the first attempt at this compared an
;; 80 ft tight arc against a long gentle one and found MORE articulation on the
;; short course -- which measured radius, not duration, and said nothing about
;; Kenya's problem.
(defun tpn-articulation-over (rig radius arc-length / course en paths)
  (tpn-clear)
  (setq en
    (vlax-vla-object->ename
      (vla-AddArc (tpn-modelspace) (vlax-3d-point (list 0.0 0.0 0.0))
                  radius 0.0 (/ arc-length radius))))
  (setq
    course (wiki-turn-course-from-curve en (vlax-curve-getStartPoint en) 1.2)
    paths (wiki-turn-path rig course (angle (car course) (cadr course)))
  )
  (tpn-max-abs (wiki-turn-articulation (car paths) (cadr paths)))
)

;; Same radius, same rig. Only the distance travelled differs. A trailer needs
;; several rig lengths to settle into its true articulation, so the 80 ft run
;; must come out materially short of the sustained one.
(defun tpn-compare-articulation (rig / long short)
  (setq
    short (tpn-articulation-over rig 150.0 80.0)
    long  (tpn-articulation-over rig 150.0 800.0)
  )
  (tt-write (strcat "- 150 ft radius, 80 ft of arc:  "
                    (rtos (/ (* short 180.0) pi) 2 2) " degrees of articulation"))
  (tt-write (strcat "- 150 ft radius, 800 ft of arc: "
                    (rtos (/ (* long 180.0) pi) 2 2) " degrees of articulation"))
  (tt-check "80 ft never develops the articulation the rig really reaches"
            (< short (* 0.9 long)))
)

;; wiki-turn-articulation returns one angle per step, not a single number.
(defun tpn-max-abs (lst / best)
  (setq best 0.0)
  (foreach a lst (if (> (abs a) best) (setq best (abs a))))
  best
)

;;; ---------------------------------------------------------------------------
;;; 8. Picking the block instead of the course
;;; ---------------------------------------------------------------------------
(defun tpn-item-8 (/ en pl)
  (tt-section "Item 8 - the mistake that probably caused the bug report")
  (tpn-clear)
  (setq en (wiki-turn-build-block '(0.0 0.0) (tpn-rig)))
  (tt-check "a vehicle block is an INSERT" (= "INSERT" (cdr (assoc 0 (entget en)))))

  ;; This is the whole guard. 1.1.17 handed the block to MEASURE, which said
  ;; "Cannot measure that object" and then drew nothing useful.
  (tt-check "TURN rejects the block as a course" (null (wiki-turn-curve-p en)))

  (setq pl (tpn-long-course))
  (tt-check "and accepts a real curve" (not (null (wiki-turn-curve-p pl))))
  (tt-check "an ARC is accepted too"
            (progn (command "._arc" '(0.0 0.0) '(-10.0 -5.0) '(-20.0 -20.0))
                   (not (null (wiki-turn-curve-p (entlast))))))
)

;;; ---------------------------------------------------------------------------
;;; 9. An AASHTO library block
;;; ---------------------------------------------------------------------------
(defun tpn-item-9 (/ atts dwg en vehicle)
  (tt-section "Item 9 - a published AASHTO block, no BUILDVEHICLE")
  (tpn-clear)
  (setq dwg (tt-src "Vehicle_Library/turn-wb-67.dwg"))
  (if (not (findfile dwg))
    (tt-check "the WB-67 library drawing is present" nil)
    (progn
      (tt-check "the WB-67 library drawing is present" T)
      (command "._-insert" (strcat "TPN-WB-67=" dwg) '(0.0 0.0) 1.0 1.0 0.0)
      (setq en (entlast))
      (tt-check "it inserted" (= "INSERT" (cdr (assoc 0 (entget en)))))
      (setq atts (wiki-turn-block-attributes en))
      (tt-check "attributes were read off it" (< 0 (length atts)))
      (setq vehicle (wiki-turn-vehicle-from-attributes atts))

      ;; The published figures, from turn-vehicles.dat.
      (tt-near "wheelbase 19.50 comes off the block"
               19.5 (wiki-turn-seg-get (car vehicle) "wheelbase") 0.01)
      (tt-near "front overhang 4.00 comes off the block"
               4.0 (wiki-turn-seg-get (car vehicle) "front-hang") 0.01)
      (tt-near "body width 8.00 comes off the block"
               8.0 (wiki-turn-seg-get (car vehicle) "body-width") 0.01)

      ;; TrailHave is Yes on WB-67, which is the sole gate on the trailer.
      ;; A vehicle that plots as one monolithic box is a missing TrailHave.
      (tt-equal "TrailHave Yes yields two segments" 2 (length vehicle))
      (if (cdr vehicle)
        (tt-near "the trailer's kingpin-to-axle is 45.50"
                 45.5 (wiki-turn-seg-get (cadr vehicle) "wheelbase") 0.01)
      )
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; 10. Layer names are yours now
;;; ---------------------------------------------------------------------------
;; The legacy block lives commented out at the bottom of the shipped
;; turn-layers.dat. Uncommenting it is what a user does; this reads the shipped
;; file, uncomments that block the same way, and checks the names that result.
;; So it tests the file that ships, not a copy of it typed here.
(defun tpn-legacy-records (/ f line out started)
  (setq f (open (tt-src "turn-layers.dat") "r") out nil started nil)
  (while (setq line (read-line f))
    (if (vl-string-search "LEGACY NAMES" line) (setq started T))
    (if (and started (= ";(" (substr (vl-string-trim " \t" line) 1 2)))
      (setq out (cons (read (substr (vl-string-trim " \t" line) 2)) out))
    )
  )
  (close f)
  (reverse out)
)

(defun tpn-item-10 (/ saved legacy)
  (tt-section "Item 10 - layer names are yours now")
  (setq saved *wiki-turn-layer-overrides*)

  (setq *wiki-turn-layer-overrides* nil)
  (tt-equal "default tractor front left" "C-TURN-TRCK-FRNT-LEFT" (wiki-turn-layer 0 "FRNT-LEFT"))
  (tt-equal "default first trailer body" "C-TURN-TRL1-BODY" (wiki-turn-layer 1 "BODY"))
  (tt-equal "a second trailer needs no new entry" "C-TURN-TRL2-BODY" (wiki-turn-layer 2 "BODY"))
  (tt-equal "the envelope has no segment stem" "C-TURN-ENVL" (wiki-turn-layer nil "ENVL"))

  (setq legacy (tpn-legacy-records))
  (tt-check "the shipped turn-layers.dat carries a legacy block" (< 0 (length legacy)))
  (setq *wiki-turn-layer-overrides* legacy)
  (tt-equal "legacy tractor front left" "C-TURN-TRCK-FRONT-LEFT-PATH"
            (wiki-turn-layer 0 "FRNT-LEFT"))
  (tt-equal "legacy trailer body" "C-TURN-TRAL-BODY" (wiki-turn-layer 1 "BODY"))
  (tt-equal "a second trailer keeps its modern name under legacy"
            "C-TURN-TRL2-BODY" (wiki-turn-layer 2 "BODY"))

  (setq *wiki-turn-layer-overrides* saved)
  (tt-write "")
  (tt-write (strcat "> The legacy toggle is exercised through the override list that "
                    "`wiki-turn-read-layers-dat` produces, parsed out of the shipped "
                    "file. Whether `(findfile)` locates that file on a given machine's "
                    "support path is a configuration question, not a code one."))
)

;;; ---------------------------------------------------------------------------
;;; 11. Works with nothing but the .lsp
;;; ---------------------------------------------------------------------------
(defun tpn-item-11 (/ course en paths rig savedl savedv)
  (tt-section "Item 11 - works with nothing but the .lsp")
  (tpn-clear)
  (setq savedl *wiki-turn-layer-overrides* savedv *wiki-turn-vehicles-file*)
  (setq
    *wiki-turn-layer-overrides* nil
    *wiki-turn-library* nil
    ;; The code already has the seam for this: name a file that is not there.
    ;; Nulling the library alone proves nothing, because every library call
    ;; re-reads the .dat through (findfile).
    *wiki-turn-vehicles-file* "turn-vehicles-no-such-file.dat"
  )

  (tt-equal "with no layers.dat the built-in names are used"
            "C-TURN-TRCK-FRNT-LEFT" (wiki-turn-layer 0 "FRNT-LEFT"))
  (tt-check "with no vehicles.dat the library is simply empty"
            (null (wiki-turn-library-keys)))

  (setq
    rig (tpn-rig)
    en (tpn-long-course)
    course (wiki-turn-course-from-curve en '(0.0 0.0) 4.0)
    paths (wiki-turn-path rig course pi)
  )
  (wiki-turn-draw-path rig paths 20)
  (tt-check "and everything still draws"
            (< 0 (tpn-count (list (cons 8 (wiki-turn-layer 0 "BODY"))))))
  (tt-check "layers were still created"
            (not (null (tblsearch "LAYER" (wiki-turn-layer 0 "BODY")))))

  (setq *wiki-turn-layer-overrides* savedl *wiki-turn-vehicles-file* savedv)
  (setq *wiki-turn-library* nil)
)

;;; ---------------------------------------------------------------------------
(defun tpn-run ()
  (tt-capture-alerts)
  (tt-mark "start")
  (tpn-item-1)
  (tpn-item-4)
  (tpn-item-5)
  (tpn-item-6)
  (tpn-item-8)
  (tpn-item-9)
  (tpn-item-10)
  (tpn-item-11)
  (tt-section "Still Tom's, deliberately")
  (tt-write "- **Item 2 and 3: do the BUILDVEHICLE prompts read clearly?**")
  (tt-write "  Specifically whether the tractor's rear-hitch question and the")
  (tt-write "  trailer's kingpin question can be told apart. That confusion is what")
  (tt-write "  produced the original bug report. A harness answers prompts; it cannot")
  (tt-write "  judge their wording.")
  (tt-write "- **Item 2: the 30/70 steering-lock and articulation defaults.** Whether")
  (tt-write "  to keep offering them or to default to 0 and stay silent is an")
  (tt-write "  engineering call about standing behind numbers we did not measure.")
  (tt-mark "finished")
  (princ)
)
