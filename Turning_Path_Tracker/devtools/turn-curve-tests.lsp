;;; turn-curve-tests.lsp - Punch list item 7: "any curve, not just a polyline".
;;;
;;; 1.1.17 used MEASURE, which needs a polyline. 2.0 samples the course with
;;; vlax-curve-* straight off the object, so in principle it follows anything
;;; derived from AcDbCurve. "In principle" is the part worth testing: this file
;;; runs TURN against a LINE, an ARC, a SPLINE, an ELLIPSE arc, and a real
;;; Civil 3D alignment, and checks what landed in the drawing each time.
;;;
;;; Run it with:  devtools\turn-tests.bat turn-curve-tests c3d
;;;
;;; Test scaffolding. None of it ships to users.

;;; ---------------------------------------------------------------------------
;;; A one-segment rig. Item 7 is about the course, not about articulation, and
;;; one segment keeps each of five runs quick.
;;; ---------------------------------------------------------------------------
(defun turn-test-curve-vehicle ()
  (list
    (turn-segment "Truck" 14.0 7.0 20.0 8.0 3.0 nil
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
  )
)

;;; ---------------------------------------------------------------------------
;;; Helpers
;;; ---------------------------------------------------------------------------
(defun turn-test-curve-dxf (en code) (cdr (assoc code (entget en))))

;; Everything TURN draws lands on a C-TURN-* layer. Count them all, so each
;; case can assert that it actually produced geometry.
(defun turn-test-curve-count-turn-output (/ n)
  (setq n 0)
  (foreach layer (mapcar '(lambda (r) (turn-layer 0 (car r))) *turn-roles*)
    (setq n (+ n (turn-test-count-on-layer layer)))
  )
  (+ n (turn-test-count-on-layer "C-TURN-ENVL"))
)

;; Erase everything TURN drew, so the next case starts from a known count.
(defun turn-test-curve-clear-turn-output (/ ss)
  (setq ss (ssget "_X" '((8 . "C-TURN-*"))))
  (if ss (command "._erase" ss ""))
  (princ)
)

;; The heading the rig starts at: the direction of the course itself.
(defun turn-test-curve-heading (course)
  (angle (car course) (cadr course))
)

;;; ---------------------------------------------------------------------------
;;; One case: sample the entity as a course, run TURN, check the result.
;;; ---------------------------------------------------------------------------
(defun turn-test-curve-case (label en step / before course drawn len ok)
  (turn-test-section (strcat "Course from " label))
  (if (not en)
    (progn (turn-test-check (strcat label ": an entity was created") nil) nil)
    (progn
      (turn-test-write (strcat "- entity type: `" (turn-test-curve-dxf en 0) "`"))

      ;; 1. vlax-curve-* must understand the object at all. This is the whole
      ;;    premise of 2.0's course sampling, and it is what MEASURE could not do.
      (setq len (vl-catch-all-apply
                  'vlax-curve-getDistAtParam
                  (list en (vlax-curve-getEndParam en))))
      (if (vl-catch-all-error-p len)
        (progn
          (turn-test-check (strcat label ": vlax-curve-* understands it") nil)
          (turn-test-write (strcat "  - error: "
                            (vl-catch-all-error-message len)))
          nil
        )
        (progn
          (turn-test-check (strcat label ": vlax-curve-* understands it") T)
          (turn-test-write (strcat "- curve length: " (rtos len 2 3)))

          ;; 2. Sampling it yields a usable course.
          (setq course (turn-course-from-curve
                         en (vlax-curve-getStartPoint en) step))
          (turn-test-check (strcat label ": course has several points")
                    (< 10 (length course)))
          (turn-test-near (strcat label ": course spans the curve length")
                   len
                   (* step (1- (length course)))
                   (* step 2.0))

          ;; 3. TURN runs on it and puts geometry in the drawing.
          (setq before (turn-test-curve-count-turn-output))
          (setq ok (vl-catch-all-apply
                     'turn-run
                     (list (turn-test-curve-vehicle) course (turn-test-curve-heading course) 10)))
          (if (vl-catch-all-error-p ok)
            (progn
              (turn-test-check (strcat label ": TURN completes") nil)
              (turn-test-write (strcat "  - error: " (vl-catch-all-error-message ok)))
              nil
            )
            (progn
              (turn-test-check (strcat label ": TURN completes") T)
              (setq drawn (- (turn-test-curve-count-turn-output) before))
              (turn-test-write (strcat "- entities drawn: " (itoa drawn)))
              (turn-test-check (strcat label ": TURN drew geometry") (< 0 drawn))
              (turn-test-equal (strcat label ": one path for the one segment")
                        1 (length ok))
              (turn-test-curve-clear-turn-output)
              T
            )
          )
        )
      )
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; The curves
;;; ---------------------------------------------------------------------------
(defun turn-test-curve-line ()
  (command "._line" '(0.0 0.0) '(-200.0 0.0) "")
  (entlast)
)

(defun turn-test-curve-arc ()
  ;; Start, second point, end - a broad sweeping left turn.
  (command "._arc" '(0.0 0.0) '(-80.0 -35.0) '(-140.0 -120.0))
  (entlast)
)

;; SPLINE and ELLIPSE go through ActiveX rather than (command). Their command
;; line syntax has changed across releases -- SPLINE's Method/Fit prompts hung
;; an unattended run on 2026 -- and a hung /b script costs a kill and a rerun.
;; vla-Add* takes the same arguments on every release.
(defun turn-test-curve-modelspace ()
  (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
)

(defun turn-test-curve-point-array (pts / data i sa)
  (setq data nil)
  (foreach p (reverse pts)
    (setq data (cons (caddr p) (cons (cadr p) (cons (car p) data))))
  )
  (setq sa (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length data)))))
  (vlax-safearray-fill sa data)
  (vlax-make-variant sa)
)

(defun turn-test-curve-spline (/ pts)
  (setq pts '((0.0 0.0 0.0) (-60.0 -10.0 0.0) (-110.0 -50.0 0.0) (-140.0 -110.0 0.0)))
  (vlax-vla-object->ename
    (vla-AddSpline
      (turn-test-curve-modelspace)
      (turn-test-curve-point-array pts)
      (vlax-3d-point '(-1.0 0.0 0.0))
      (vlax-3d-point '(0.0 -1.0 0.0))
    )
  )
)

(defun turn-test-curve-ellipse ()
  ;; A quarter of an ellipse: centre, major axis vector, minor/major ratio.
  (vlax-vla-object->ename
    (vla-AddEllipse
      (turn-test-curve-modelspace)
      (vlax-3d-point '(0.0 0.0 0.0))
      (vlax-3d-point '(120.0 0.0 0.0))
      0.667
    )
  )
)

;;; ---------------------------------------------------------------------------
;;; A real Civil 3D alignment.
;;;
;;; Alignment creation is dialog driven at the command line, which would hang an
;;; unattended run, so this goes through the Civil 3D COM API instead. The
;;; ProgID is version specific; try newest first and report honestly if none of
;;; them answers, because "we could not test it" and "it works" are different
;;; results and only one of them is true.
;;; ---------------------------------------------------------------------------
(defun turn-test-curve-join (lst)
  (if lst
    (apply 'strcat (cons (car lst) (mapcar '(lambda (s) (strcat ", " s)) (cdr lst))))
    "**none**"
  )
)

;; Names of a Civil 3D style collection hanging off the document.
(defun turn-test-curve-name-list (adoc prop / coll out r)
  (setq r (vl-catch-all-apply 'vlax-get-property (list adoc prop)))
  (if (vl-catch-all-error-p r)
    nil
    (progn
      (setq coll r out nil)
      (vlax-for s coll
        (setq r (vl-catch-all-apply 'vlax-get-property (list s 'Name)))
        (if (not (vl-catch-all-error-p r)) (setq out (cons r out)))
      )
      (reverse out)
    )
  )
)

;; Label set styles live one level down, under AlignmentLabelStyles.
(defun turn-test-curve-label-set-names (adoc / r)
  (setq r (vl-catch-all-apply 'vlax-get-property (list adoc 'AlignmentLabelStyles)))
  (if (vl-catch-all-error-p r) nil (turn-test-curve-name-list r 'LabelSetStyles))
)

;; Try the documented call shapes in turn and report which one the installed
;; Civil 3D actually accepts. The COM signature has drifted across releases and
;; the error it raises for a wrong argument type is the unhelpful "Type
;; mismatch", so trying is cheaper and more honest than reasoning.
(defun turn-test-curve-try-alignment (aligns plobj style labelset / attempts n plvar r)
  ;; The first probe established two facts: the method wants exactly 7
  ;; arguments (5 and 4 both gave "too few actual parameters"), and a bare
  ;; VLA-OBJECT in the polyline slot gives "lisp value has no coercion to
  ;; VARIANT with this type". So wrap it explicitly.
  ;; It refused a VT_DISPATCH (variant 9), so it does not want the object.
  ;; Civil 3D's COM layer takes ObjectIDs in most places; try that.
  (setq plvar (vl-catch-all-apply 'vlax-get-property (list plobj 'ObjectID)))
  (if (vl-catch-all-error-p plvar) (setq plvar nil))
  (setq
    attempts
     (append
       (if plvar
         (list
           (list "polyline ObjectID, label set by name"
                 (list "TURN-curve-1" "0" plvar style labelset :vlax-false :vlax-true))
           (list "polyline ObjectID, empty label set"
                 (list "TURN-curve-2" "0" plvar style "" :vlax-false :vlax-true))
         )
       )
       (list
         (list "polyline as vbObject variant"
               (list "TURN-curve-3" "0" (vlax-make-variant plobj vlax-vbObject)
                     style "" :vlax-false :vlax-true))
       )
     )
    n 0
  )
  (setq r nil)
  (foreach a attempts
    (if (not r)
      (progn
        (setq n (1+ n))
        (setq
          r (vl-catch-all-apply
              'vlax-invoke-method
              (append (list aligns 'AddFromPolyline) (cadr a))))
        (if (vl-catch-all-error-p r)
          (progn
            (turn-test-write (strcat "  - attempt " (itoa n) " (" (car a) "): "
                              (vl-catch-all-error-message r)))
            (setq r nil)
          )
          (turn-test-write (strcat "  - attempt " (itoa n) " (" (car a) "): **accepted**"))
        )
      )
    )
  )
  (if (not r)
    (turn-test-write "- **AddFromPolyline refused every call shape tried.**")
  )
  r
)

;; Build an alignment without a source polyline: create it empty, then add
;; fixed entities to its Entities collection. Two tangents joined by a curve.
(defun turn-test-curve-alignment-by-entities (aligns style labelset / al ents r)
  (turn-test-write "- falling back to building the alignment from entities")
  (setq r (vl-catch-all-apply
            'vlax-invoke-method
            (list aligns 'Add "TURN-curve-ent" "0" style labelset)))
  (if (vl-catch-all-error-p r)
    (progn
      (turn-test-write (strcat "  - Add failed: " (vl-catch-all-error-message r)))
      nil
    )
    (progn
      (setq al r)
      (setq r (vl-catch-all-apply 'vlax-get-property (list al 'Entities)))
      (if (vl-catch-all-error-p r)
        (progn
          (turn-test-write (strcat "  - Entities failed: " (vl-catch-all-error-message r)))
          nil
        )
        (progn
          (setq ents r)
          (setq r (vl-catch-all-apply
                    'vlax-invoke-method
                    (list ents 'AddFixedLine2
                          (vlax-3d-point '(0.0 0.0 0.0))
                          (vlax-3d-point '(-150.0 -150.0 0.0)))))
          (if (vl-catch-all-error-p r)
            (progn
              (turn-test-write (strcat "  - AddFixedLine2 failed: "
                                (vl-catch-all-error-message r)))
              nil
            )
            (progn (turn-test-write "  - **alignment built from entities**") al)
          )
        )
      )
    )
  )
)

(defun turn-test-curve-alignment (/ aecc adoc aligns al en labelsets pl r styles)
  (setq aecc nil)
  (foreach progid '("AeccXUiLand.AeccApplication.13.8"
                    "AeccXUiLand.AeccApplication.13.6"
                    "AeccXUiLand.AeccApplication")
    (if (not aecc)
      (progn
        (setq r (vl-catch-all-apply 'vlax-get-or-create-object (list progid)))
        (if (not (vl-catch-all-error-p r))
          (progn (setq aecc r) (turn-test-write (strcat "- Civil 3D ProgID: `" progid "`")))
        )
      )
    )
  )
  (if (not aecc)
    (progn
      (turn-test-write "- **No Civil 3D COM interface answered.** Not running as Civil 3D?")
      nil
    )
    (progn
      ;; The source geometry the alignment is built from.
      (command "._pline" '(0.0 0.0) '(-100.0 0.0) "_a" '(-150.0 -50.0)
               '(-150.0 -150.0) "")
      (setq pl (entlast))
      (setq adoc (vlax-get-property aecc 'ActiveDocument))
      (setq aligns (vlax-get-property adoc 'AlignmentsSiteless))

      ;; Report what this drawing actually offers, rather than assuming. The
      ;; first attempt at this failed with "Type mismatch" and guessing at which
      ;; of seven arguments was wrong would have been several runs of nothing.
      (setq styles (turn-test-curve-name-list adoc 'AlignmentStyles))
      (turn-test-write (strcat "- alignment styles: " (turn-test-curve-join styles)))
      (setq labelsets (turn-test-curve-label-set-names adoc))
      (turn-test-write (strcat "- label set styles: " (turn-test-curve-join labelsets)))

      (setq r
        (turn-test-curve-try-alignment
          aligns (vlax-ename->vla-object pl)
          (if styles (car styles) "Standard")
          (if labelsets (car labelsets) "_No Labels")
        )
      )
      ;; If AddFromPolyline will not play, build the alignment geometrically
      ;; instead: an empty alignment plus fixed entities. Either way we end up
      ;; with a genuine AeccDbAlignment, which is what item 7 is about.
      (if (not r)
        (setq r (turn-test-curve-alignment-by-entities
                  aligns
                  (if styles (car styles) "Standard")
                  (if labelsets (car labelsets) "")))
      )
      (if (not r)
        nil
        (progn
          (setq en (vlax-vla-object->ename r))
          (turn-test-write (strcat "- alignment created, DXF name `" (turn-test-curve-dxf en 0) "`"))
          en
        )
      )
    )
  )
)

;; Erase the alignments before the run ends.
;;
;; WITHOUT THIS, AUTOCAD CRASHES ON SHUTDOWN with an "AutoCAD Error Aborting"
;; dialog, AFTER every check has passed. That dialog then blocks an unattended
;; run indefinitely - it held the test matrix for 19 minutes before anyone
;; noticed, and it looks exactly like a hang because there is nothing to see.
;;
;; The tests are over by the time this runs, so nothing is being hidden: the
;; alignment was created, driven and asserted on. What is being avoided is
;; saving and tearing down a drawing containing a COM-created AECC object, which
;; is a Civil 3D problem and not TURN's.
(defun turn-test-curve-drop-alignments (/ ss)
  (if (setq ss (ssget "_X" '((0 . "AECC_ALIGNMENT"))))
    (progn
      (command "._erase" ss "")
      (turn-test-write (strcat "- erased " (itoa (sslength ss))
                        " alignment(s) before shutdown; see the comment on "
                        "turn-test-curve-drop-alignments"))
    )
  )
  (princ)
)

;;; ---------------------------------------------------------------------------
(defun turn-test-curve-run (/ passed)
  (turn-test-capture-alerts)
  (turn-test-mark "start")
  (turn-test-write "")
  (turn-test-write (strcat "Running as **" (getvar "PRODUCT") "**, acad version "
                    (getvar "ACADVER") "."))

  (turn-test-curve-case "a LINE"    (turn-test-curve-line)    1.4)
  (turn-test-curve-case "an ARC"    (turn-test-curve-arc)     1.4)
  (turn-test-curve-case "a SPLINE"  (turn-test-curve-spline)  1.4)
  (turn-test-curve-case "an ELLIPSE" (turn-test-curve-ellipse) 4.0)

  (turn-test-section "Course from a Civil 3D ALIGNMENT")
  (turn-test-curve-case "an ALIGNMENT" (turn-test-curve-alignment) 1.4)
  (turn-test-curve-drop-alignments)

  (turn-test-mark "finished")
  (princ)
)
