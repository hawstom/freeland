;;; turn-probe-aashto.lsp - What do the published AASHTO vehicle blocks actually carry?
;;;
;;; QUESTION BEING ANSWERED
;;; -----------------------
;;; hawsedc.com/gnu/turn.php serves two vehicle block libraries, both labelled
;;; "version 1.1.13":
;;;
;;;   Turn.lsp_Turn_Radius_Modeling_AASHTO_2004_Edition.zip
;;;   Turn.lsp_Turn_Radius_Modeling_AASHTO_2011_Edition.zip
;;;
;;; Before recommending one to a user whose articulated vehicle plots as a
;;; single monolithic box, we need to know two things about WB-67:
;;;
;;;   1. Does the block carry a TrailHave attribute whose value is "Yes"?
;;;      TURN 1.1.17 draws a trailer ONLY when the global TrailHave equals
;;;      "Yes" (turn-1.1.17.lsp lines 991, 1053, 1069), and that global is set
;;;      purely from an attribute tag of that name by
;;;      wiki-turn-get-vehicle-data-from-block (line 1186). No tag, no trailer,
;;;      no articulation, one box.
;;;
;;;   2. Where is the alignment circle? The instructions PDF in both zips says
;;;      to place "the little circle in the center of the left front tire" on
;;;      the start of the path. TURN has steered on the FRONT AXLE CENTRELINE
;;;      since 1.1.3 (2008-01-20). If the circle is off to the left by half an
;;;      axle width, the published instructions and the published blocks are
;;;      both still on the pre-1.1.3 convention.
;;;
;;; Reads each drawing with ObjectDBX rather than opening it: no SDI, no
;;; drawing swaps, no save prompts, one session. Dumps raw tags - it does not
;;; interpret them through turn-vehicle-from-attributes, because the
;;; question is precisely what the raw tags are.

(vl-load-com)

(setq
  *turn-probe-aashto-log* (turn-test-dev "turn-probe-aashto-log.md")
  *turn-probe-aashto-files*
   (list
     ;; 2004 edition, as published. Byte-identical to the repo's 1.1.7.1
     ;; Vehicle_Library drawings - md5 confirmed on all 17 - so this is also a
     ;; check on what the repo already extracted.
     (cons
       "2004 WB-67 (as published)"
       "C:\\Users\\tomha\\AppData\\Local\\Temp\\claude\\C--TGHFiles-programming-misclisp-freeland-Turning-Path-Tracker\\ccde2cec-050c-4378-b645-60e24e5d0572\\scratchpad\\a2004\\Turn.lsp Turn Radius Modeling AASHTO 2004 Edition\\2004_AASHTO_WB-67.dwg"
     )
     ;; 2011 edition. Different files entirely: 168 KB, dated 2013.
     (cons
       "2011 WB-67 (as published)"
       "C:\\Users\\tomha\\AppData\\Local\\Temp\\claude\\C--TGHFiles-programming-misclisp-freeland-Turning-Path-Tracker\\ccde2cec-050c-4378-b645-60e24e5d0572\\scratchpad\\a2011\\Turn.lsp Turn Radius Modeling AASHTO 2011 Edition\\2011_AASHTO_WB-67.dwg"
     )
     ;; A no-trailer vehicle from each, as a control: whatever distinguishes a
     ;; trailered block from a solo one should show up here as the difference.
     (cons
       "2004 SU (control, no trailer)"
       "C:\\Users\\tomha\\AppData\\Local\\Temp\\claude\\C--TGHFiles-programming-misclisp-freeland-Turning-Path-Tracker\\ccde2cec-050c-4378-b645-60e24e5d0572\\scratchpad\\a2004\\Turn.lsp Turn Radius Modeling AASHTO 2004 Edition\\2004_AASHTO_SU.dwg"
     )
     (cons
       "2011 SU-30 (control, no trailer)"
       "C:\\Users\\tomha\\AppData\\Local\\Temp\\claude\\C--TGHFiles-programming-misclisp-freeland-Turning-Path-Tracker\\ccde2cec-050c-4378-b645-60e24e5d0572\\scratchpad\\a2011\\Turn.lsp Turn Radius Modeling AASHTO 2011 Edition\\2011_AASHTO_SU-30.dwg"
     )
   )
)

(defun turn-probe-aashto-say (s / f)
  (setq f (open *turn-probe-aashto-log* "a"))
  (write-line s f)
  (close f)
  (princ (strcat "\n" s))
  (princ)
)

(defun turn-probe-aashto-num (x) (rtos x 2 4))
(defun turn-probe-aashto-pt (p)
  (strcat "(" (turn-probe-aashto-num (car p)) ", " (turn-probe-aashto-num (cadr p)) ")")
)

;; An ObjectDBX document for whatever release this is.
(defun turn-probe-aashto-dbx (/ doc v)
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

;; Loose ATTDEFs in any block definition, plus ATTRIBs on any model space
;; insert. The 1.1.7.1 drawings never got as far as BLOCK - their ATTDEFs sit
;; in *Model_Space - so both have to be looked at.
(defun turn-probe-aashto-attributes (dbx / atts)
  (vlax-for blk (vla-get-blocks dbx)
    (vlax-for obj blk
      (if (= "AcDbAttributeDefinition" (vla-get-objectname obj))
        (setq
          atts
           (cons
             (list (strcase (vla-get-tagstring obj))
                   (vla-get-textstring obj)
                   (strcat "ATTDEF in " (vla-get-name blk))
             )
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
           (cons
             (list (strcase (vla-get-tagstring a))
                   (vla-get-textstring a)
                   (strcat "ATTRIB on insert of " (vla-get-name obj))
             )
             atts
           )
        )
      )
    )
  )
  (reverse atts)
)

;; Every circle in the drawing, wherever it lives. The alignment marker is one
;; of these, and its position against the axle geometry is the whole question.
(defun turn-probe-aashto-circles (dbx / found)
  (vlax-for blk (vla-get-blocks dbx)
    (vlax-for obj blk
      (if (= "AcDbCircle" (vla-get-objectname obj))
        (setq
          found
           (cons
             (list (vlax-get obj 'center) (vla-get-radius obj) (vla-get-name blk))
             found
           )
        )
      )
    )
  )
  (reverse found)
)

(defun turn-probe-aashto-report (label file / atts circles dbx err tag)
  (turn-probe-aashto-say "")
  (turn-probe-aashto-say (strcat "## " label))
  (turn-probe-aashto-say "")
  (setq dbx (turn-probe-aashto-dbx))
  (cond
    ((not dbx) (turn-probe-aashto-say "!! could not create an ObjectDBX document"))
    ((vl-catch-all-error-p
       (setq err (vl-catch-all-apply 'vla-open (list dbx file)))
     )
     (turn-probe-aashto-say (strcat "!! vla-open failed: " (vl-catch-all-error-message err)))
    )
    (t
     (setq atts (turn-probe-aashto-attributes dbx))
     (turn-probe-aashto-say (strcat "Attributes found: " (itoa (length atts))))
     (turn-probe-aashto-say "")
     (turn-probe-aashto-say "| Tag | Value | Where |")
     (turn-probe-aashto-say "|---|---|---|")
     (foreach a atts
       (turn-probe-aashto-say
         (strcat "| " (car a) " | " (cadr a) " | " (caddr a) " |")
       )
     )
     (turn-probe-aashto-say "")
     ;; The question that decides whether TURN 1.1.17 draws a trailer at all.
     (setq tag (assoc "TRAILHAVE" atts))
     (turn-probe-aashto-say
       (cond
         ((not tag) "VERDICT TrailHave: **ABSENT** - TURN 1.1.17 will not draw a trailer.")
         ((= (strcase (cadr tag)) "YES")
          (strcat "VERDICT TrailHave: present, value \"" (cadr tag)
                  "\" - TURN 1.1.17 will draw a trailer.")
         )
         (t
          (strcat "VERDICT TrailHave: present but value is \"" (cadr tag)
                  "\", not \"Yes\" - TURN 1.1.17 will not draw a trailer.")
         )
       )
     )
     (turn-probe-aashto-say "")
     (setq circles (turn-probe-aashto-circles dbx))
     (turn-probe-aashto-say (strcat "Circles found: " (itoa (length circles))))
     (foreach c circles
       (turn-probe-aashto-say
         (strcat "- centre " (turn-probe-aashto-pt (car c))
                 "  radius " (turn-probe-aashto-num (cadr c))
                 "  in " (caddr c)
         )
       )
     )
     (vlax-release-object dbx)
    )
  )
  (princ)
)

(defun turn-probe-aashto-run (/ f)
  (setq f (open *turn-probe-aashto-log* "w"))
  (close f)
  (turn-probe-aashto-say "# AASHTO published vehicle block probe")
  (turn-probe-aashto-say "")
  (turn-probe-aashto-say "Raw ObjectDBX read of the vehicle blocks published at hawsedc.com/gnu/turn.php.")
  (turn-probe-aashto-say "Question: does WB-67 carry TrailHave=\"Yes\", and where is the alignment circle?")
  (foreach pair *turn-probe-aashto-files* (turn-probe-aashto-report (car pair) (cdr pair)))
  (turn-probe-aashto-say "")
  (turn-probe-aashto-say "END OF PROBE")
  (princ)
)

(princ "\nturn-probe-aashto.lsp loaded. Run (turn-probe-aashto-run).")
(princ)
