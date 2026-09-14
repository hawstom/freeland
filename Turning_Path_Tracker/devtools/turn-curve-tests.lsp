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
(defun tcv-vehicle ()
  (list
    (wiki-turn-segment "Truck" 14.0 7.0 20.0 8.0 3.0 nil
                       (* pi (/ 30.0 180.0)) (* pi (/ 70.0 180.0)))
  )
)

;;; ---------------------------------------------------------------------------
;;; Helpers
;;; ---------------------------------------------------------------------------
(defun tcv-dxf (en code) (cdr (assoc code (entget en))))

;; Everything TURN draws lands on a C-TURN-* layer. Count them all, so each
;; case can assert that it actually produced geometry.
(defun tcv-count-turn-output (/ n)
  (setq n 0)
  (foreach layer (mapcar '(lambda (r) (wiki-turn-layer 0 (car r))) *wiki-turn-roles*)
    (setq n (+ n (tt-count-on-layer layer)))
  )
  (+ n (tt-count-on-layer "C-TURN-ENVL"))
)

;; Erase everything TURN drew, so the next case starts from a known count.
(defun tcv-clear-turn-output (/ ss)
  (setq ss (ssget "_X" '((8 . "C-TURN-*"))))
  (if ss (command "._erase" ss ""))
  (princ)
)

;; The heading the rig starts at: the direction of the course itself.
(defun tcv-heading (course)
  (angle (car course) (cadr course))
)

;;; ---------------------------------------------------------------------------
;;; One case: sample the entity as a course, run TURN, check the result.
;;; ---------------------------------------------------------------------------
(defun tcv-case (label en step / before course drawn len ok)
  (tt-section (strcat "Course from " label))
  (if (not en)
    (progn (tt-check (strcat label ": an entity was created") nil) nil)
    (progn
      (tt-write (strcat "- entity type: `" (tcv-dxf en 0) "`"))

      ;; 1. vlax-curve-* must understand the object at all. This is the whole
      ;;    premise of 2.0's course sampling, and it is what MEASURE could not do.
      (setq len (vl-catch-all-apply
                  'vlax-curve-getDistAtParam
                  (list en (vlax-curve-getEndParam en))))
      (if (vl-catch-all-error-p len)
        (progn
          (tt-check (strcat label ": vlax-curve-* understands it") nil)
          (tt-write (strcat "  - error: "
                            (vl-catch-all-error-message len)))
          nil
        )
        (progn
          (tt-check (strcat label ": vlax-curve-* understands it") T)
          (tt-write (strcat "- curve length: " (rtos len 2 3)))

          ;; 2. Sampling it yields a usable course.
          (setq course (wiki-turn-course-from-curve
                         en (vlax-curve-getStartPoint en) step))
          (tt-check (strcat label ": course has several points")
                    (< 10 (length course)))
          (tt-near (strcat label ": course spans the curve length")
                   len
                   (* step (1- (length course)))
                   (* step 2.0))

          ;; 3. TURN runs on it and puts geometry in the drawing.
          (setq before (tcv-count-turn-output))
          (setq ok (vl-catch-all-apply
                     'wiki-turn-run
                     (list (tcv-vehicle) course (tcv-heading course) 10)))
          (if (vl-catch-all-error-p ok)
            (progn
              (tt-check (strcat label ": TURN completes") nil)
              (tt-write (strcat "  - error: " (vl-catch-all-error-message ok)))
              nil
            )
            (progn
              (tt-check (strcat label ": TURN completes") T)
              (setq drawn (- (tcv-count-turn-output) before))
              (tt-write (strcat "- entities drawn: " (itoa drawn)))
              (tt-check (strcat label ": TURN drew geometry") (< 0 drawn))
              (tt-equal (strcat label ": one path for the one segment")
                        1 (length ok))
              (tcv-clear-turn-output)
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
(defun tcv-line ()
  (command "._line" '(0.0 0.0) '(-200.0 0.0) "")
  (entlast)
)

(defun tcv-arc ()
  ;; Start, second point, end - a broad sweeping left turn.
  (command "._arc" '(0.0 0.0) '(-80.0 -35.0) '(-140.0 -120.0))
  (entlast)
)

;; SPLINE and ELLIPSE go through ActiveX rather than (command). Their command
;; line syntax has changed across releases -- SPLINE's Method/Fit prompts hung
;; an unattended run on 2026 -- and a hung /b script costs a kill and a rerun.
;; vla-Add* takes the same arguments on every release.
(defun tcv-modelspace ()
  (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
)

(defun tcv-point-array (pts / data i sa)
  (setq data nil)
  (foreach p (reverse pts)
    (setq data (cons (caddr p) (cons (cadr p) (cons (car p) data))))
  )
  (setq sa (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length data)))))
  (vlax-safearray-fill sa data)
  (vlax-make-variant sa)
)

(defun tcv-spline (/ pts)
  (setq pts '((0.0 0.0 0.0) (-60.0 -10.0 0.0) (-110.0 -50.0 0.0) (-140.0 -110.0 0.0)))
  (vlax-vla-object->ename
    (vla-AddSpline
      (tcv-modelspace)
      (tcv-point-array pts)
      (vlax-3d-point '(-1.0 0.0 0.0))
      (vlax-3d-point '(0.0 -1.0 0.0))
    )
  )
)

(defun tcv-ellipse ()
  ;; A quarter of an ellipse: centre, major axis vector, minor/major ratio.
  (vlax-vla-object->ename
    (vla-AddEllipse
      (tcv-modelspace)
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
(defun tcv-join (lst)
  (if lst
    (apply 'strcat (cons (car lst) (mapcar '(lambda (s) (strcat ", " s)) (cdr lst))))
    "**none**"
  )
)

;; Names of a Civil 3D style collection hanging off the document.
(defun tcv-name-list (adoc prop / coll out r)
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
(defun tcv-label-set-names (adoc / r)
  (setq r (vl-catch-all-apply 'vlax-get-property (list adoc 'AlignmentLabelStyles)))
  (if (vl-catch-all-error-p r) nil (tcv-name-list r 'LabelSetStyles))
)

;; Try the documented call shapes in turn and report which one the installed
;; Civil 3D actually accepts. The COM signature has drifted across releases and
;; the error it raises for a wrong argument type is the unhelpful "Type
;; mismatch", so trying is cheaper and more honest than reasoning.
(defun tcv-try-alignment (aligns plobj style labelset / attempts n plvar r)
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
            (tt-write (strcat "  - attempt " (itoa n) " (" (car a) "): "
                              (vl-catch-all-error-message r)))
            (setq r nil)
          )
          (tt-write (strcat "  - attempt " (itoa n) " (" (car a) "): **accepted**"))
        )
      )
    )
  )
  (if (not r)
    (tt-write "- **AddFromPolyline refused every call shape tried.**")
  )
  r
)

;; Build an alignment without a source polyline: create it empty, then add
;; fixed entities to its Entities collection. Two tangents joined by a curve.
(defun tcv-alignment-by-entities (aligns style labelset / al ents r)
  (tt-write "- falling back to building the alignment from entities")
  (setq r (vl-catch-all-apply
            'vlax-invoke-method
            (list aligns 'Add "TURN-curve-ent" "0" style labelset)))
  (if (vl-catch-all-error-p r)
    (progn
      (tt-write (strcat "  - Add failed: " (vl-catch-all-error-message r)))
      nil
    )
    (progn
      (setq al r)
      (setq r (vl-catch-all-apply 'vlax-get-property (list al 'Entities)))
      (if (vl-catch-all-error-p r)
        (progn
          (tt-write (strcat "  - Entities failed: " (vl-catch-all-error-message r)))
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
              (tt-write (strcat "  - AddFixedLine2 failed: "
                                (vl-catch-all-error-message r)))
              nil
            )
            (progn (tt-write "  - **alignment built from entities**") al)
          )
        )
      )
    )
  )
)

(defun tcv-alignment (/ aecc adoc aligns al en labelsets pl r styles)
  (setq aecc nil)
  (foreach progid '("AeccXUiLand.AeccApplication.13.8"
                    "AeccXUiLand.AeccApplication.13.6"
                    "AeccXUiLand.AeccApplication")
    (if (not aecc)
      (progn
        (setq r (vl-catch-all-apply 'vlax-get-or-create-object (list progid)))
        (if (not (vl-catch-all-error-p r))
          (progn (setq aecc r) (tt-write (strcat "- Civil 3D ProgID: `" progid "`")))
        )
      )
    )
  )
  (if (not aecc)
    (progn
      (tt-write "- **No Civil 3D COM interface answered.** Not running as Civil 3D?")
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
      (setq styles (tcv-name-list adoc 'AlignmentStyles))
      (tt-write (strcat "- alignment styles: " (tcv-join styles)))
      (setq labelsets (tcv-label-set-names adoc))
      (tt-write (strcat "- label set styles: " (tcv-join labelsets)))

      (setq r
        (tcv-try-alignment
          aligns (vlax-ename->vla-object pl)
          (if styles (car styles) "Standard")
          (if labelsets (car labelsets) "_No Labels")
        )
      )
      ;; If AddFromPolyline will not play, build the alignment geometrically
      ;; instead: an empty alignment plus fixed entities. Either way we end up
      ;; with a genuine AeccDbAlignment, which is what item 7 is about.
      (if (not r)
        (setq r (tcv-alignment-by-entities
                  aligns
                  (if styles (car styles) "Standard")
                  (if labelsets (car labelsets) "")))
      )
      (if (not r)
        nil
        (progn
          (setq en (vlax-vla-object->ename r))
          (tt-write (strcat "- alignment created, DXF name `" (tcv-dxf en 0) "`"))
          en
        )
      )
    )
  )
)

;;; ---------------------------------------------------------------------------
(defun tcv-run (/ passed)
  (tt-capture-alerts)
  (tt-mark "start")
  (tt-write "")
  (tt-write (strcat "Running as **" (getvar "PRODUCT") "**, acad version "
                    (getvar "ACADVER") "."))

  (tcv-case "a LINE"    (tcv-line)    1.4)
  (tcv-case "an ARC"    (tcv-arc)     1.4)
  (tcv-case "a SPLINE"  (tcv-spline)  1.4)
  (tcv-case "an ELLIPSE" (tcv-ellipse) 4.0)

  (tt-section "Course from a Civil 3D ALIGNMENT")
  (tcv-case "an ALIGNMENT" (tcv-alignment) 1.4)

  (tt-mark "finished")
  (princ)
)
