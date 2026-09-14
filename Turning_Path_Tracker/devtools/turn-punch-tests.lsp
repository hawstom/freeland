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
;;; turn-report talks to the user with princ, so the only honest way to
;;; assert "the advisory appears" is to catch the text. AutoLISP lets a built-in
;;; be redefined - that is how the harness already tames the modal alert - so
;;; princ is swapped for the duration of ONE call and put straight back.
;;;
;;; The replacement takes exactly one argument, which is safe only because
;;; everything turn-report calls is a pure computation. Do not widen the
;;; window around anything that might call a bare (princ).
;;; ---------------------------------------------------------------------------
(setq *turn-test-punch-said* "")

(defun turn-test-punch-capture-report (vehicle paths area / real result)
  (setq *turn-test-punch-said* "" real princ)
  (defun princ (s)
    (if (= 'STR (type s)) (setq *turn-test-punch-said* (strcat *turn-test-punch-said* s)))
    s
  )
  (setq result (vl-catch-all-apply 'turn-report (list vehicle paths area)))
  (setq princ real)
  (if (vl-catch-all-error-p result)
    (progn
      (turn-test-write (strcat "  - report raised: " (vl-catch-all-error-message result)))
      nil
    )
    result
  )
)

;; Did the captured text contain this?
(defun turn-test-punch-said-p (needle) (if (vl-string-search needle *turn-test-punch-said*) T nil))

(defun turn-test-punch-check-said (label needle)
  (turn-test-check label (turn-test-punch-said-p needle))
)

;;; ---------------------------------------------------------------------------
;;; Fixtures
;;; ---------------------------------------------------------------------------
;; A WB-67-shaped tractor and trailer: 65 ft rig wheelbase, as the punch list
;; text assumes.
(defun turn-test-punch-rig ()
  (list
    (turn-segment "Tractor" 19.5 8.0 27.92 8.0 4.0 0.0
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
    (turn-segment "Trailer" 45.5 8.5 53.0 8.5 -3.0 nil
                       0.0 (* pi (/ 70.0 180.0)))
  )
)

;; Straight, a long sweeping arc, straight out again - several hundred feet, as
;; item 5 specifies.
(defun turn-test-punch-long-course ()
  (command "._pline" '(0.0 0.0) '(-300.0 0.0) "_a" '(-450.0 -150.0)
           "_l" '(-450.0 -400.0) "")
  (entlast)
)

;; About 80 ft: Kenya's course, the one that cannot articulate.
(defun turn-test-punch-short-course ()
  (command "._pline" '(0.0 0.0) '(-50.0 0.0) "_a" '(-80.0 -30.0) "")
  (entlast)
)

(defun turn-test-punch-clear (/ ss)
  (foreach filter (list '((8 . "C-TURN-*")) '((0 . "LWPOLYLINE")) '((0 . "INSERT")))
    (if (setq ss (ssget "_X" filter)) (command "._erase" ss ""))
  )
  (princ)
)

(defun turn-test-punch-count (filter / ss)
  (if (setq ss (ssget "_X" filter)) (sslength ss) 0)
)

;;; ---------------------------------------------------------------------------
;;; 1. Load
;;; ---------------------------------------------------------------------------
;; ";;; VERSION x.y.z" in the file header must say the same thing as the
;; general.version setting. turn-release.py names the published file from this,
;; so a disagreement would ship a file whose banner lies about what it is.
(defun turn-test-punch-banner-matches-p (/ f found line want)
  (setq f (open (turn-test-src "turn.lsp") "r") want (turn-getvar "general.version"))
  (while (and (not found) (setq line (read-line f)))
    (if (vl-string-search (strcat ";;; VERSION " want) line) (setq found T))
  )
  (close f)
  found
)

(defun turn-test-punch-item-1 ()
  (turn-test-section "Item 1 - Load")
  ;; Not pinned to a literal: the trunk's version moves, and pinning it here
  ;; would mean a version bump looks like a failing test. What matters is that
  ;; the banner the user sees and the setting the program reads are the same
  ;; string -- which is also what turn-release.py refuses to publish without.
  (turn-test-write (strcat "- version: `" (turn-getvar "general.version") "`"))
  (turn-test-check "a version is set" (< 0 (strlen (turn-getvar "general.version"))))
  (turn-test-check "the header banner agrees with general.version" (turn-test-punch-banner-matches-p))
  (turn-test-check "TURN is defined" (not (null c:turn)))
  (turn-test-check "BUILDVEHICLE is defined" (not (null c:buildvehicle)))
  (turn-test-check "the BV alias is defined" (not (null c:bv)))
)

;;; ---------------------------------------------------------------------------
;;; 4. Two trailers - the feature that was asked for
;;; ---------------------------------------------------------------------------
(defun turn-test-punch-item-4 (/ atts en rig back)
  (turn-test-section "Item 4 - two trailers, the asked-for feature")
  (setq rig
    (list
      (turn-segment "Truck"    14.0 7.0 20.0 8.0  3.0  3.0
                         (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
      (turn-segment "Trailer1" 12.0 7.0 18.0 8.0 -2.0  2.0
                         0.0 (* pi (/ 70.0 180.0)))
      (turn-segment "Pup"      10.0 7.0 14.0 8.0 -2.0  nil
                         0.0 (* pi (/ 70.0 180.0)))
    )
  )
  (setq en (turn-build-block '(0.0 0.0) rig))
  (turn-test-check "a block was produced" (= "INSERT" (cdr (assoc 0 (entget en)))))
  (setq atts (turn-block-attributes en))
  (turn-test-check "the block carries the second trailer's tags"
            (not (null (cdr (assoc (turn-tag 2 "wheelbase") atts)))))
  (setq back (turn-vehicle-from-attributes atts))
  (turn-test-equal "three segments read back off the block" 3 (length back))
  (turn-test-near "the pup's wheelbase survived the round trip"
           10.0 (turn-seg-get (caddr back) "wheelbase") 0.001)
  (turn-test-check "only the last segment tows nothing"
            (and (turn-seg-get (car back) "hitch")
                 (turn-seg-get (cadr back) "hitch")
                 (null (turn-seg-get (caddr back) "hitch"))))
)

;;; ---------------------------------------------------------------------------
;;; 5. TURN on a proper course - the headline features
;;; ---------------------------------------------------------------------------
(defun turn-test-punch-item-5 (/ area course en envl paths rig)
  (turn-test-section "Item 5 - a proper course, the headline features")
  (turn-test-punch-clear)
  (setq
    rig (turn-test-punch-rig)
    en (turn-test-punch-long-course)
    course (turn-course-from-curve en '(0.0 0.0) 1.95)
    paths (turn-path rig course pi)
  )
  (turn-draw-path rig paths 10)
  (setq area (turn-draw-envelope rig paths))

  (turn-test-check "tire paths drawn for the tractor"
            (= 1 (turn-test-punch-count (list (cons 8 (turn-layer 0 "FRNT-LEFT"))))))
  (turn-test-check "tire paths drawn for the trailer"
            (= 1 (turn-test-punch-count (list (cons 8 (turn-layer 1 "REAR-RGHT"))))))
  (turn-test-check "body outlines plotted repeatedly"
            (< 1 (turn-test-punch-count (list (cons 8 (turn-layer 0 "BODY"))))))

  ;; The headline: no 1.1.x version ever drew this.
  (setq envl (turn-test-punch-count '((8 . "C-TURN-ENVL"))))
  (turn-test-check "a swept path envelope exists on C-TURN-ENVL" (< 0 envl))
  (turn-test-check "the envelope is reported with an area" (and area (< 0.0 area)))
  (turn-test-check "every envelope loop is a CLOSED polyline" (turn-test-punch-loops-closed-p))

  ;; 1.1.17 drew and erased dozens of POINTs via MEASURE. 2.0 uses vlax-curve-*.
  (turn-test-equal "TURN littered no POINT entities" 0 (turn-test-punch-count '((0 . "POINT"))))

  (turn-test-punch-capture-report rig paths area)
  (turn-test-punch-check-said "the step count is reported" "segment(s), ")
  (turn-test-punch-check-said "the course is reported against the wheelbase" "x the rig's ")
  (turn-test-punch-check-said "the swept area is reported" "swept area is ")
  (turn-test-punch-check-said "the tightest turn is reported" "tightest turn this vehicle")
  (turn-test-punch-check-said "a verdict is printed" "manoeuvre achievable")
  (turn-test-check "a long course draws NO short-course advisory"
            (not (turn-test-punch-said-p "Short course")))
)

;; Every loop on C-TURN-ENVL must have its Closed flag set. AutoCAD's PEDIT Join
;; leaves coincident ends with the flag OFF, which looks shut and is not, and
;; hatching, offset and AREA all refuse it.
(defun turn-test-punch-loops-closed-p (/ el i ok ss)
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
(defun turn-test-punch-item-6 (/ area course en paths ratio rig)
  (turn-test-section "Item 6 - Kenya's failure, reproduced on purpose")
  (turn-test-punch-clear)
  (setq
    rig (turn-test-punch-rig)
    en (turn-test-punch-short-course)
    course (turn-course-from-curve en '(0.0 0.0) 1.2)
    paths (turn-path rig course pi)
  )
  (turn-draw-path rig paths 10)
  (setq area (turn-draw-envelope rig paths))

  (setq ratio (/ (turn-course-length (car paths))
                 (turn-rig-wheelbase rig)))
  (turn-test-check "the course really is short for this rig" (< ratio 5.0))

  (turn-test-punch-capture-report rig paths area)
  (turn-test-punch-check-said "the short-course advisory appears" "Short course")
  (turn-test-punch-check-said "it explains why, in rig lengths" "several rig lengths")

  ;; Advice, not a refusal: it still draws everything.
  (turn-test-check "it still drew the trailer's tire paths"
            (= 1 (turn-test-punch-count (list (cons 8 (turn-layer 1 "REAR-LEFT"))))))
  (turn-test-check "it still drew an envelope" (< 0 (turn-test-punch-count '((8 . "C-TURN-ENVL")))))

  ;; Her symptom: the rig plots as one straight box. The claim worth testing is
  ;; not "articulation is under N degrees" -- that would be a number invented
  ;; here. It is that articulation has not DEVELOPED: give the same rig the same
  ;; turn but room to sustain it, and the trailer swings materially further.
  (turn-test-punch-compare-articulation rig)
)

;; turn-curve-tests.lsp has its own copy; this suite does not load that file.
(defun turn-test-punch-modelspace ()
  (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
)

;; Articulation on ONE arc radius, swept for a given distance. Holding the
;; radius fixed is the whole point: the first attempt at this compared an
;; 80 ft tight arc against a long gentle one and found MORE articulation on the
;; short course -- which measured radius, not duration, and said nothing about
;; Kenya's problem.
(defun turn-test-punch-articulation-over (rig radius arc-length / course en paths)
  (turn-test-punch-clear)
  (setq en
    (vlax-vla-object->ename
      (vla-AddArc (turn-test-punch-modelspace) (vlax-3d-point (list 0.0 0.0 0.0))
                  radius 0.0 (/ arc-length radius))))
  (setq
    course (turn-course-from-curve en (vlax-curve-getStartPoint en) 1.2)
    paths (turn-path rig course (angle (car course) (cadr course)))
  )
  (turn-test-punch-max-abs (turn-articulation (car paths) (cadr paths)))
)

;; Same radius, same rig. Only the distance travelled differs. A trailer needs
;; several rig lengths to settle into its true articulation, so the 80 ft run
;; must come out materially short of the sustained one.
(defun turn-test-punch-compare-articulation (rig / long short)
  (setq
    short (turn-test-punch-articulation-over rig 150.0 80.0)
    long  (turn-test-punch-articulation-over rig 150.0 800.0)
  )
  (turn-test-write (strcat "- 150 ft radius, 80 ft of arc:  "
                    (rtos (/ (* short 180.0) pi) 2 2) " degrees of articulation"))
  (turn-test-write (strcat "- 150 ft radius, 800 ft of arc: "
                    (rtos (/ (* long 180.0) pi) 2 2) " degrees of articulation"))
  (turn-test-check "80 ft never develops the articulation the rig really reaches"
            (< short (* 0.9 long)))
)

;; turn-articulation returns one angle per step, not a single number.
(defun turn-test-punch-max-abs (lst / best)
  (setq best 0.0)
  (foreach a lst (if (> (abs a) best) (setq best (abs a))))
  best
)

;;; ---------------------------------------------------------------------------
;;; 8. Picking the block instead of the course
;;; ---------------------------------------------------------------------------
(defun turn-test-punch-item-8 (/ en pl)
  (turn-test-section "Item 8 - the mistake that probably caused the bug report")
  (turn-test-punch-clear)
  (setq en (turn-build-block '(0.0 0.0) (turn-test-punch-rig)))
  (turn-test-check "a vehicle block is an INSERT" (= "INSERT" (cdr (assoc 0 (entget en)))))

  ;; This is the whole guard. 1.1.17 handed the block to MEASURE, which said
  ;; "Cannot measure that object" and then drew nothing useful.
  (turn-test-check "TURN rejects the block as a course" (null (turn-curve-p en)))

  (setq pl (turn-test-punch-long-course))
  (turn-test-check "and accepts a real curve" (not (null (turn-curve-p pl))))
  (turn-test-check "an ARC is accepted too"
            (progn (command "._arc" '(0.0 0.0) '(-10.0 -5.0) '(-20.0 -20.0))
                   (not (null (turn-curve-p (entlast))))))
)

;;; ---------------------------------------------------------------------------
;;; 9. An AASHTO library block
;;; ---------------------------------------------------------------------------
(defun turn-test-punch-item-9 (/ atts dwg en vehicle)
  (turn-test-section "Item 9 - a published AASHTO block, no BUILDVEHICLE")
  (turn-test-punch-clear)
  (setq dwg (turn-test-src "Vehicle_Library/turn-wb-67.dwg"))
  (if (not (findfile dwg))
    (turn-test-check "the WB-67 library drawing is present" nil)
    (progn
      (turn-test-check "the WB-67 library drawing is present" T)
      (command "._-insert" (strcat "TPN-WB-67=" dwg) '(0.0 0.0) 1.0 1.0 0.0)
      (setq en (entlast))
      (turn-test-check "it inserted" (= "INSERT" (cdr (assoc 0 (entget en)))))
      (setq atts (turn-block-attributes en))
      (turn-test-check "attributes were read off it" (< 0 (length atts)))
      (setq vehicle (turn-vehicle-from-attributes atts))

      ;; The published figures, from turn-vehicles.dat.
      (turn-test-near "wheelbase 19.50 comes off the block"
               19.5 (turn-seg-get (car vehicle) "wheelbase") 0.01)
      (turn-test-near "front overhang 4.00 comes off the block"
               4.0 (turn-seg-get (car vehicle) "front-hang") 0.01)
      (turn-test-near "body width 8.00 comes off the block"
               8.0 (turn-seg-get (car vehicle) "body-width") 0.01)

      ;; TrailHave is Yes on WB-67, which is the sole gate on the trailer.
      ;; A vehicle that plots as one monolithic box is a missing TrailHave.
      (turn-test-equal "TrailHave Yes yields two segments" 2 (length vehicle))
      (if (cdr vehicle)
        (turn-test-near "the trailer's kingpin-to-axle is 45.50"
                 45.5 (turn-seg-get (cadr vehicle) "wheelbase") 0.01)
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
(defun turn-test-punch-legacy-records (/ f line out started)
  (setq f (open (turn-test-src "turn-layers.dat") "r") out nil started nil)
  (while (setq line (read-line f))
    (if (vl-string-search "LEGACY NAMES" line) (setq started T))
    (if (and started (= ";(" (substr (vl-string-trim " \t" line) 1 2)))
      (setq out (cons (read (substr (vl-string-trim " \t" line) 2)) out))
    )
  )
  (close f)
  (reverse out)
)

(defun turn-test-punch-item-10 (/ saved legacy)
  (turn-test-section "Item 10 - layer names are yours now")
  (setq saved *turn-layer-overrides*)

  (setq *turn-layer-overrides* nil)
  (turn-test-equal "default tractor front left" "C-TURN-TRCK-FRNT-LEFT" (turn-layer 0 "FRNT-LEFT"))
  (turn-test-equal "default first trailer body" "C-TURN-TRL1-BODY" (turn-layer 1 "BODY"))
  (turn-test-equal "a second trailer needs no new entry" "C-TURN-TRL2-BODY" (turn-layer 2 "BODY"))
  (turn-test-equal "the envelope has no segment stem" "C-TURN-ENVL" (turn-layer nil "ENVL"))

  (setq legacy (turn-test-punch-legacy-records))
  (turn-test-check "the shipped turn-layers.dat carries a legacy block" (< 0 (length legacy)))
  (setq *turn-layer-overrides* legacy)
  (turn-test-equal "legacy tractor front left" "C-TURN-TRCK-FRONT-LEFT-PATH"
            (turn-layer 0 "FRNT-LEFT"))
  (turn-test-equal "legacy trailer body" "C-TURN-TRAL-BODY" (turn-layer 1 "BODY"))
  (turn-test-equal "a second trailer keeps its modern name under legacy"
            "C-TURN-TRL2-BODY" (turn-layer 2 "BODY"))

  (setq *turn-layer-overrides* saved)
  (turn-test-write "")
  (turn-test-write (strcat "> The legacy toggle is exercised through the override list that "
                    "`turn-read-layers-dat` produces, parsed out of the shipped "
                    "file. Whether `(findfile)` locates that file on a given machine's "
                    "support path is a configuration question, not a code one."))
)

;;; ---------------------------------------------------------------------------
;;; 11. Works with nothing but the .lsp
;;; ---------------------------------------------------------------------------
(defun turn-test-punch-item-11 (/ course en paths rig savedl savedv)
  (turn-test-section "Item 11 - works with nothing but the .lsp")
  (turn-test-punch-clear)
  (setq savedl *turn-layer-overrides* savedv *turn-vehicles-file*)
  (setq
    *turn-layer-overrides* nil
    *turn-library* nil
    ;; The code already has the seam for this: name a file that is not there.
    ;; Nulling the library alone proves nothing, because every library call
    ;; re-reads the .dat through (findfile).
    *turn-vehicles-file* "turn-vehicles-no-such-file.dat"
  )

  (turn-test-equal "with no layers.dat the built-in names are used"
            "C-TURN-TRCK-FRNT-LEFT" (turn-layer 0 "FRNT-LEFT"))
  (turn-test-check "with no vehicles.dat the library is simply empty"
            (null (turn-library-keys)))

  (setq
    rig (turn-test-punch-rig)
    en (turn-test-punch-long-course)
    course (turn-course-from-curve en '(0.0 0.0) 4.0)
    paths (turn-path rig course pi)
  )
  (turn-draw-path rig paths 20)
  (turn-test-check "and everything still draws"
            (< 0 (turn-test-punch-count (list (cons 8 (turn-layer 0 "BODY"))))))
  (turn-test-check "layers were still created"
            (not (null (tblsearch "LAYER" (turn-layer 0 "BODY")))))

  (setq *turn-layer-overrides* savedl *turn-vehicles-file* savedv)
  (setq *turn-library* nil)
)

;;; ---------------------------------------------------------------------------
(defun turn-test-punch-run ()
  (turn-test-capture-alerts)
  (turn-test-mark "start")
  (turn-test-punch-item-1)
  (turn-test-punch-item-4)
  (turn-test-punch-item-5)
  (turn-test-punch-item-6)
  (turn-test-punch-item-8)
  (turn-test-punch-item-9)
  (turn-test-punch-item-10)
  (turn-test-punch-item-11)
  (turn-test-section "Still Tom's, deliberately")
  (turn-test-write "- **Item 2 and 3: do the BUILDVEHICLE prompts read clearly?**")
  (turn-test-write "  Specifically whether the tractor's rear-hitch question and the")
  (turn-test-write "  trailer's kingpin question can be told apart. That confusion is what")
  (turn-test-write "  produced the original bug report. A harness answers prompts; it cannot")
  (turn-test-write "  judge their wording.")
  (turn-test-write "- **Item 2: the 30/70 steering-lock and articulation defaults.** Whether")
  (turn-test-write "  to keep offering them or to default to 0 and stay silent is an")
  (turn-test-write "  engineering call about standing behind numbers we did not measure.")
  (turn-test-mark "finished")
  (princ)
)
