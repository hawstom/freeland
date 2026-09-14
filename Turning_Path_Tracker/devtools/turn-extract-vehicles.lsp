;;; turn-extract-vehicles.lsp - Mine the Vehicle Library DWGs into a data file.
;;;
;;; The 17 drawings in "Vehicle Library" were built by BUILDVEHICLE 1.1.7.1 and
;;; carry real, checked dimensions as block attributes. That is the only
;;; trustworthy source of vehicle numbers in this repository, so the library is
;;; EXTRACTED rather than typed. Nothing here invents a dimension.
;;;
;;; Reads each drawing with ObjectDBX instead of opening it. That avoids SDI,
;;; drawing swaps, save prompts, and the fact that a space in a .scr line is
;;; the same as pressing Enter - which the folder name "Vehicle Library"
;;; walks straight into.

(vl-load-com)

(setq
  *tx-lib* (tt-src "Vehicle_Library/")
  *tx-out* (tt-src "turn-vehicles.dat")
  *tx-log* (tt-dev "turn-extract-log.md")
)

(defun tx-append (path s / f)
  (setq f (open path "a"))
  (write-line s f)
  (close f)
  (princ)
)
(defun tx-write (s) (tx-append *tx-out* s))
(defun tx-note (s) (tx-append *tx-log* s) (princ (strcat "\n" s)))

;; An ObjectDBX document for this AutoCAD release.
(defun tx-dbx (/ doc v)
  (setq v 16)
  (while (and (not doc) (< v 30))
    (setq
      doc
       (vl-catch-all-apply
         'vla-getinterfaceobject
         (list (vlax-get-acad-object) (strcat "ObjectDBX.AxDbDocument." (itoa v)))
       )
    )
    (if (vl-catch-all-error-p doc) (setq doc nil))
    (setq v (1+ v))
  )
  doc
)

;; Every ATTDEF tag and value in a DBX document, plus any attributes on inserts.
;;
;; The 1.1.7.1 library drawings never got as far as BLOCK: their ATTDEFs sit
;; loose in model space, which is a block definition named *Model_Space. So
;; scan every block including the anonymous ones, then pick up attributes on
;; inserts as well for drawings that did get blocked.
(defun tx-attributes (dbx / atts)
  (vlax-for blk (vla-get-blocks dbx)
    (vlax-for obj blk
      (if (= "AcDbAttributeDefinition" (vla-get-objectname obj))
        (setq
          atts
           (cons
             (cons (strcase (vla-get-tagstring obj)) (vla-get-textstring obj))
             atts
           )
        )
      )
    )
  )
  (vlax-for obj (vla-get-modelspace dbx)
    (if (and (= "AcDbBlockReference" (vla-get-objectname obj))
             (= :vlax-true (vla-get-hasattributes obj))
        )
      (foreach a (vlax-safearray->list (vlax-variant-value (vla-getattributes obj)))
        (setq
          atts
           (cons (cons (strcase (vla-get-tagstring a)) (vla-get-textstring a)) atts)
        )
      )
    )
  )
  (reverse atts)
)

(defun tx-num (x) (rtos x 2 4))

;; BUILDVEHICLE 1.1.x never asked for a steering lock or an articulation
;; angle. It hardcoded (setq vehsteerlock 0.5) and (setq vehartangle 0.5) -
;; radians - and wrote them out with angtos, so every library drawing carries
;; 28.6479 degrees. That is a placeholder wearing the costume of data.
;;
;; Emitting it would make TURN report "steering lock exceeded, vehicle has
;; 28.6" with total confidence and no basis. Absent data is safer than fake
;; data: a limit of 0 tells TURN not to check, and the file says why. Any
;; value that is NOT the placeholder is passed through untouched.
(setq *tx-placeholder-angle* 0.5)
(defun tx-angle (radians)
  (if (equal radians *tx-placeholder-angle* 0.0005)
    "0"
    (angtos radians 0 2)
  )
)

(defun tx-placeholder-p (segment)
  (or (equal (wiki-turn-seg-get segment "steer-lock") *tx-placeholder-angle* 0.0005)
      (equal (wiki-turn-seg-get segment "art-angle") *tx-placeholder-angle* 0.0005)
  )
)

(defun tx-segment-record (segment / hitch)
  (setq hitch (wiki-turn-seg-get segment "hitch"))
  (strcat
    "(\"SEGMENT\" \"" (wiki-turn-seg-get segment "name") "\""
    " " (tx-num (wiki-turn-seg-get segment "wheelbase"))
    " " (tx-num (wiki-turn-seg-get segment "axle-width"))
    " " (tx-num (wiki-turn-seg-get segment "body-length"))
    " " (tx-num (wiki-turn-seg-get segment "body-width"))
    " " (tx-num (wiki-turn-seg-get segment "front-hang"))
    " " (if hitch (tx-num hitch) "nil")
    " " (tx-angle (wiki-turn-seg-get segment "steer-lock"))
    " " (tx-angle (wiki-turn-seg-get segment "art-angle"))
    ")"
  )
)

(defun tx-begin (/ f)
  (setq f (open *tx-out* "w"))
  (close f)
  (setq f (open *tx-log* "w"))
  (close f)
  (foreach line
    (list
      ";TURN.LSP vehicle library"
      ";"
      ";TURN-VEHICLES.DAT"
      ";"
      ";Put this file anywhere on your AutoCAD support file search path."
      ";TURN finds it with (findfile). It is optional - without it you build"
      ";vehicles by hand with BUILDVEHICLE."
      ";"
      ";Format, one record per line:"
      ";"
      ";  (\"VEHICLE\" \"KEY\" \"Description\" \"UNITS\")"
      ";  (\"SEGMENT\" \"Name\" wheelbase axle-width body-length body-width"
      ";             front-hang hitch steer-lock art-angle)"
      ";"
      ";SEGMENT records belong to the VEHICLE record above them, powered unit"
      ";first. hitch is nil on the last segment. Angles are in DEGREES."
      ";front-hang is measured FORWARD from the guide point, so it is negative"
      ";on a trailer whose body begins behind the hitch eye."
      ";"
      ";PROVENANCE: extracted by devtools/turn-extract-vehicles from the"
      ";attributed blocks in \"Vehicle Library\", which were built with"
      ";BUILDVEHICLE 1.1.7.1. They are only as good as those drawings."
      ";"
      ";CAUTION - STEERING LOCK AND ARTICULATION ANGLE ARE MISSING, NOT ZERO."
      ";BUILDVEHICLE 1.1.x never asked for either one. It hardcoded 0.5 radians"
      ";and wrote it out as 28.6479 degrees, so every source drawing carries"
      ";that same fake number. It has been replaced with 0 here, because a"
      ";placeholder that looks like data is worse than no data: TURN would"
      ";otherwise report -steering lock exceeded, vehicle has 28.6- with total"
      ";confidence and no basis whatever."
      ";"
      ";A limit of 0 tells TURN not to check. Supply real values from the"
      ";manufacturer or the governing standard before relying on the"
      ";steering-lock and jackknife warnings for these vehicles."
      ";"
      ";CAUTION - WHEELBASES DISAGREE WITH THE OLD REFERENCE TABLE IN TURN.LSP."
      ";That table lists WB-40 as WB1 13 / WB2 27 and WB-50 as WB1 20 / WB2 30."
      ";These drawings say 12.5 / 25.5 and 12.5 / 35.5. The drawings are the"
      ";newer source and are what shipped as the vehicle library, so they are"
      ";what is recorded here. The discrepancy has not been resolved - check"
      ";against your own governing standard before use."
      ";"
    )
    (tx-write line)
  )
  (princ)
)

;; Read one drawing and append its vehicle. key is the library key.
(defun tx-extract (file key units / atts dbx err vehicle)
  (setq dbx (tx-dbx))
  (cond
    ((not dbx) (tx-note (strcat "!! " key ": could not create an ObjectDBX document")) nil)
    (t
     (setq err (vl-catch-all-apply 'vla-open (list dbx (strcat *tx-lib* file))))
     (cond
       ((vl-catch-all-error-p err)
        (tx-note (strcat "!! " key ": " (vl-catch-all-error-message err)))
        nil
       )
       ((not (assoc "VEHWHEELBASE" (setq atts (tx-attributes dbx))))
        (tx-note (strcat "!! " key ": no VEHWHEELBASE attribute. tags found: "
                         (vl-princ-to-string (mapcar 'car atts))))
        nil
       )
       (t
        (setq vehicle (wiki-turn-vehicle-from-attributes atts))
        (tx-write "")
        (tx-write
          (strcat "(\"VEHICLE\" \"" key "\" \""
                  (cond ((cdr (assoc "VEHNAME" atts))) (key))
                  "\" \"" units "\")")
        )
        (foreach s vehicle (tx-write (tx-segment-record s)))
        (tx-note
          (strcat "OK " key ": " (itoa (length vehicle)) " segment(s)"
                  (if (vl-some 'tx-placeholder-p vehicle)
                    "  [placeholder steer/articulation angles zeroed]"
                    ""
                  )
          )
        )
        vehicle
       )
     )
    )
  )
)

;; Everything in the library folder, in one pass, in one session.
(defun tx-run-all (/ file key n)
  (tx-begin)
  (setq n 0)
  (foreach file (vl-directory-files *tx-lib* "turn-*.dwg" 1)
    (setq key (strcase (substr file 6 (- (strlen file) 9))))
    (if (tx-extract file key "ft") (setq n (1+ n)))
  )
  (tx-note (strcat "\nEXTRACTED " (itoa n) " vehicles"))
  (princ)
)

(princ "\nturn-extract-vehicles.lsp loaded. Run (tx-run-all).")
(princ)
