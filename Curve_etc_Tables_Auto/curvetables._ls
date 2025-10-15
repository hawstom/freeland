;;; CURVES.LSP
;;;
;;; Copyright 2005 Thomas Gail Haws
;;; This program is free software under the terms of the
;;; GNU (GNU--acronym for Gnu's Not Unix--sounds like canoe)
;;; General Public License as published by the Free Software Foundation,
;;; version 2 of the License.
;;;
;;; You can redistribute this software for any fee or no fee and/or
;;; modify it in any way, but it and ANY MODIFICATIONS OR DERIVATIONS
;;; continue to be governed by the license, which protects the perpetual
;;; availability of the software for free distribution and modification.
;;;
;;; You CAN'T put this code into any proprietary package.  Read the license.
;;;
;;; If you improve this software, please make a revision submittal to the
;;; copyright owner at www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
;;; Revisions
;;; 20070920  Version 1.0.3 Added location coordinate capabilities.  Made each column in block a separate layer, and their colors byblock.  
;;; 20070915  Version 1.0.2+Renamed command with CRVS prefix.  
;;; 20070718  Version 1.0.2 Replaced distppoint with distpoint so Quick table would work.
;;; 20061219  Version 1.0.1 Added distance suffix option.
;;; 20050815  Version 1.0 released.  Changed prompts and initial defaults.
;;; 20050308  Version 1.0PR released
;;;
;;; Layer settings you can edit---------------------------------------
;;;
;;; CRVS:ARCLAYERS
;;; Put between the quotes the layers from which to allow arcs to be selected for labelling.
(SETQ CRVS:ARCLAYERS "*")		
;;;
;;; CRVS:NUMBERLAYER
;;; Layer name and color to use for curve number insertions.
(SETQ CRVS:NUMBERLAYER '("CN" "y"))	
;;;
;;; CRVS:TABLELAYER
;;; Layer name and color to use for curve table insertions.
(SETQ CRVS:TABLELAYER '("CT" "c"))	
;;;
;;; Other settings you can edit---------------------------------------
;;;
;;; CRVS:ISBEARINGIMPORTANT
;;; T (true) or nil (false).
;;; T means curves must have the same bearing to be the same curve
;;; You are listing bearings in your table,
;;; so curves that differ only by bearing are listed separately.
;;; Nil means you aren't using bearings in your table,
;;; so curves that differ only by bearing are given the same number.
(SETQ CRVS:ISBEARINGIMPORTANT NIL)		
;;;
;;; CRVS:ISLOCATIONIMPORTANT
;;; T (true) or nil (false).
;;; T means curves must have the same location to be the same curve
;;; You are using locations in your table,
;;; so curves that differ only by location are listed separately.
;;; Nil means you aren't using locations in your table,
;;; so curves that differ only by location are given the same number.
(SETQ CRVS:ISLOCATIONIMPORTANT T)		
;;;
;;; CRVS:DISTPOST
;;; Distance suffix (postfix).
(SETQ CRVS:DISTPOST "'")			
;;;
;;; CRVS:PREFIX
;;; Curve number prefix. This must be exactly 1 letter long.
(SETQ CRVS:PREFIX "C")			
;;;
;;; CRVS:TABLEWIDTH
;;; This is the width of your curvetable.dwg block.
;;; This only affects the placement of multiple columns.
(SETQ CRVS:TABLEWIDTH 58)		
;;;
;;; CRVS:TABLEROWSPACING
;;; Spacing of curve table blocks in text heights
(SETQ CRVS:TABLEROWSPACING 2)		
;;;
;;; CRVS:COORDINATEPRECISION
;;; Display precision for coordinates in tables
(SETQ CRVS:COORDINATEPRECISION 2)		
;;;
;;; Start program code-------------------------------------------------
;;;
(VL-LOAD-COM)
(IF (NOT (LOAD "tip" NIL))
  (DEFUN
     HAWS-TIP
	     (ITIP TIPTEXT)
    (PROMPT (STRCAT "\n" TIPTEXT))
  )
)

;;Curves error trapper
(DEFUN
   CRVS-ERRDEF
	      ()
  (SETQ
    CRVS-ERROR
     *ERROR*
    *ERROR*
     CRVS-STPERR
  ) ;_ end of setq
) ;_ end of defun

;;Stperr replaces the standard error function.
;;It sets everything back in case of an error.
(DEFUN
   CRVS-STPERR
	      (S)

  (IF
    (OR
      (= MSG "Function cancelled")
      (= MSG "quit / exit abort")
    )
     (PRINC)
     (PRINC (STRCAT "\nError: " MSG))
  )
  (COMMAND)
  (IF CRVS:VLST
    (FOREACH V CRVS:VLST (SETVAR (CAR V) (CADR V)))
  ) ;_ end of IF
  (IF (= (TYPE F1) (QUOTE FILE))
    (SETQ F1 (CLOSE F1))
  ) ;_ end of IF
  ;; Close files
  (IF (= (TYPE F2) (QUOTE FILE))
    (SETQ F2 (CLOSE F2))
  ) ;_ end of if
  (IF (= (TYPE F3) (QUOTE FILE))
    (SETQ F3 (CLOSE F3))
  ) ;_ end of if
  (IF (= 8 (LOGAND (GETVAR "undoctl") 8))
    (COMMAND "._undo" "end")
  ) ;_ end of IF
  ;; End undo group
  (IF CRVS-ERROR
    (SETQ
      *ERROR*
       CRVS-ERROR
      CRVS-ERROR
       NIL
    ) ;_ end of setq
  ) ;_ end of IF
  ;; Restore old *error* handler
  (PRINC)
) ;_ end of defun

;;Restores old error function
(DEFUN
   CRVS-ERRRST
	      ()
  (SETQ
    UCSP
     NIL
    UCSPP
     NIL
    ENM
     NIL
    F1 NIL
    F2 NIL
    *ERROR*
     OLDERR
    OLDERR
     NIL
  ) ;_ end of setq
) ;_ end of defun
;;END ERROR HANDLER

(DEFUN C:CURVES () (C:CRVS-CURVES))
(DEFUN
   C:CRVS-CURVES
	   (/ OPT SS)
  (SETQ CRVS:VLST (LIST (LIST "CLAYER" (GETVAR "CLAYER"))))
  (HAWS-TIP
    0
    "Select from the following at the next prompt:\n\n-Quick label, table, and burst: make a curve table from selected arcs in one step.\n\n-Labels only: add attributed block curve numbers to selected arcs, but no table yet.\n\n-Tables from labels: make a table from selected curve number blocks.\n\n-Burst smart label blocks: explode smart curve labels, turning label attributes into plain text."
  )
  (INITGET "Quick Label Table Burst")
  (SETQ
    OPT
     (GETKWORD
       "\nQuick label, table, and burst/Labels only/Tables from labels/Burst smart label blocks: "
     )
  )
  (COND
    ((= OPT "Quick")
     (SETQ SS (CRVS-AUTOINSERTCURVENUMBERS))
     (CRVS-MAKECURVETABLE SS)
     (CRVS-BURSTNUMBERS SS)
    )
    ((= OPT "Label") (CRVS-AUTOINSERTCURVENUMBERS))
    ((= OPT "Table") (CRVS-MAKECURVETABLE NIL))
    ((= OPT "Burst") (CRVS-BURSTNUMBERS NIL))
  )
  (HAWS-TIP
    1
    "Thank you for using Curve Table Generator\n\n\n-Labels curves globally.\n\n-Combines duplicate curves.\n\n-Allows multiple column tables.\n\nLimitations:\n\n-World UCS only.  No UCS translations are done at this time.  Curves numbers must be added with world UCS current.\n\n-Xrefs.  You can't select arcs within xrefs at this time, but you can copy curve numbers from one drawing to another and use the 'Table from selected arcs' option to make a curve table in a plan sheet.\n\nCustomization:\n\nUse refedit or your own methods to edit the two blocks that are used.  If you make the CURVETABLE block shorter or narrower, you need to tell Curve Table Generator.  Modify the lines near the top of CURVES.LSP that say (SETQ CRVS:TABLEWIDTH 58) (SETQ CRVS:TABLEROWSPACING 2).\n\nYou can remove any attributes from the CURVETABLE block, but don't remove any from the CURVENUMBER block.\n\nThe order of the attributes in the blocks is flexible."
  )
  (FOREACH V CRVS:VLST (SETVAR (CAR V) (CADR V)))
  (CRVS-ERRRST)
  (PRINC)
)

;;Returns selection set of curve numbers for selected arcs
(DEFUN
   CRVS-AUTOINSERTCURVENUMBERS
			      (/ 2PI ALLARCLIST	ALLCURVELIST ARCDELTA ARCENDANG
			       ARCSTARTANG CURVE CURVESDELETED CURVEDELTA
			       CURVEENDANG CURVESINSERTED CURVESTARTANG	FREENUM
			       I LABEL LABELCOUNTER LABELLIST LABELPREFIX SSUSER
			       SSUSERCURVES TXTHT USERARCLIST USERCURVELIST
			      )
  (HAWS-TIP
    2
    (STRCAT
      "You are about to select arcs to label.\n\n"
      "If you want to label all arcs in all spaces (tabs), press enter instead of selecting objects.  "
      "Note that only arcs will work; polylines won't.\n\n"
      "You can have CURVES.LSP select only from layers you want to label. "
      "Just modify the line near the top of CURVES.LSP that says (SETQ CRVS:LAYERS \"*\")"
      " so that it has the names of the layers you want to use for curves.\n\n"
      "For example: (SETQ CRVS:LAYERS \"curb,centerline\")\n\n"
     )
  )
  (COMMAND "._undo" "group")
  (PROMPT
    "\nSelect arcs to label and any curve numbers to check for deletion/<return to select all arcs and curves on all tabs>: "
  )
  (SETQ
    SSUSER
     (SSGET
       (LIST
	 '(-4 . "<OR")
	 '(-4 . "<AND")
	 '(0 . "INSERT")
	 '(2 . "CURVENUMBER")
	 '(-4 . "AND>")
	 '(-4 . "<AND")
	 '(0 . "ARC")
	 (CONS 8 CRVS:ARCLAYERS)
	 '(-4 . "AND>")
	 '(-4 . "OR>")
       )
     )
  )
  (IF (NOT SSUSER)
    (SETQ
      SSUSER
       (SSGET
	 "X"
	 (LIST
	   '(-4 . "<OR")
	   '(-4 . "<AND")
	   '(0 . "INSERT")
	   '(2 . "CURVENUMBER")
	   '(-4 . "AND>")
	   '(-4 . "<AND")
	   '(0 . "ARC")
	   (CONS 8 CRVS:ARCLAYERS)
	   '(-4 . "AND>")
	   '(-4 . "OR>")
	 )
       )
    )
  )
  (SETQ
    2PI
     (* PI 2)				;Used in comparing deltas to find similar curves.  Should probably add delta to the curve to reduce computation time?  Or just add to list?
    CURVESINSERTED
     0
    CURVESDELETED
     0
    USERCURVELIST
     (CRVS-MAKECURVELIST SSUSER)
    USERARCLIST
     (REVERSE (CRVS-MAKEARCLIST SSUSER))
    ALLCURVELIST
     (CRVS-MAKECURVELIST
       (SSGET
	 "X"
	 '(
	   (0 . "INSERT")
	   (2 . "CURVENUMBER")
	  )
       )
     )
    ALLARCLIST
     (CRVS-MAKEARCLIST
       (SSGET
	 "X"
	 (LIST
	   '(0 . "ARC")
	   (CONS 8 CRVS:ARCLAYERS)
	 )
       )

     )

  )
  ;;Put together an ordered list of available numbers for curve labels.
  (SETQ I 0)
  (WHILE (<= (SETQ I (1+ I)) (LENGTH ALLARCLIST))
    (SETQ
      FREENUM
       T
      LABEL
       (STRCAT CRVS:PREFIX (ITOA I))
    )
    (IF	ALLCURVELIST
      (FOREACH
	 CURVE
	      ALLCURVELIST
	(IF (= LABEL (CADR CURVE))
	  (SETQ FREENUM NIL)
	)
      )
    )
    (IF	FREENUM
      (SETQ LABELLIST (CONS LABEL LABELLIST))
    )
  )
  (SETQ LABELLIST (REVERSE LABELLIST))
  ;;Check selected curves against all arcs.  Delete orphans.
  (IF USERCURVELIST
    (FOREACH
       CURVE
	    USERCURVELIST
      ;;If the curve does not label a found arc anywhere, delete it.
      (COND
	((NOT (MEMBER (CAR CURVE) ALLARCLIST))
	 (ENTDEL (CADDR CURVE))
	 (SETQ CURVESDELETED (1+ CURVESDELETED))
	)
      )
    )
  )
  ;;Check selected arcs against all curves
  ;;Also make a selection set of corresponding curve inserts.
  (SETQ SSUSERCURVES (SSADD))
  (FOREACH
     ARC
	USERARCLIST
    ;;If the arc does not have a label, it needs one.
    ;;Begin by assuming it needs one.
    (SETQ LABEL NIL)
    
    (COND
      ((NOT (ASSOC ARC ALLCURVELIST))
       ;;See if we can use the same label as one of the existing curve numbers.
       ;;Check through allcurvelist for matches.
       (COND
	 (ALLCURVELIST
	  (SETQ I -1)
	  (WHILE (AND
		   (SETQ
		     CURVE
		      (NTH
			(SETQ
			  I (1+ I)
			)
			ALLCURVELIST

		      )
		   )
		   (NOT LABEL)
		 )
	    (SETQ
	      ARCENDANG
	       (ATOF (CADDR ARC))
	      ARCSTARTANG
	       (ATOF (CADR ARC))
	      ARCDELTA
	       (COND
		 ((> ARCSTARTANG ARCENDANG)
		  (- 2PI (- ARCSTARTANG ARCENDANG))
		 )
		 (T (- ARCENDANG ARCSTARTANG))
	       )
	      CURVEENDANG
	       (ATOF (CADDAR CURVE))
	      CURVESTARTANG
	       (ATOF (CADAR CURVE))
	      CURVEDELTA
	       (COND
		 ((> CURVESTARTANG CURVEENDANG)
		  (- 2PI (- CURVESTARTANG CURVEENDANG))
		 )
		 (T (- CURVEENDANG CURVESTARTANG))
	       )
	    )
            ;;If this curve matches this arc in all the required ways,
            ;;use its label instead of a new one.
	    (IF (AND
                  ;; Test most likely to fail is for same radius and delta.
                  ;; We'll run it first.
                  (AND
                    (= (CAR ARC) (CAAR CURVE)) ;radii are equal
                    (EQUAL              ;And deltas are equal
                      ARCDELTA
                      CURVEDELTA
                      0.00000002
                    )
                  )
                  ;; Next test for same bearing if required.
                  (OR
                    (NOT CRVS:ISBEARINGIMPORTANT)
                    (EQUAL
                      (CDDDR (REVERSE ARC))
                      (CDDDR (REVERSE (CAR CURVE)))
                    )
                  )
                  ;; Next test for same location if required.
                  ;; In this case, curves must be identical (a strange situation!).
                  (OR
                    (NOT CRVS:ISLOCATIONIMPORTANT)
                    (EQUAL
                      (REVERSE ARC)
                      (REVERSE (CAR CURVE))
                    )
                  )
                )
              (SETQ LABEL (CADR CURVE)) ;Use existing label
            )
	  )
	 )
       )
       ;;If this arc didn't match any existing curve, get a free label to use.
       (IF (NOT LABEL)
	 (SETQ
	   LABEL
	    (CAR LABELLIST)
	   LABELLIST
	    (CDR LABELLIST)
	 )
       )
       ;;Insert curve and add it to allcurvelist.
       (SETQ
	 ALLCURVELIST
	  (CONS (CRVS-INSERTCURVENUMBER ARC LABEL) ALLCURVELIST)
       )
       (SETQ CURVESINSERTED (1+ CURVESINSERTED))
      )
    )
    (SETQ
      SSUSERCURVES
       (SSADD
	 (CAR (REVERSE (ASSOC ARC ALLCURVELIST)))
	 SSUSERCURVES
       )
    )
  )
  (PROMPT
    (STRCAT
      "\n"
      (ITOA CURVESINSERTED)
      " curve numbers were inserted.\n"
      (ITOA CURVESDELETED)
      " curve numbers were deleted."
    )
  )
  (COMMAND "._undo" "end")
  SSUSERCURVES
)

(DEFUN
   CRVS-MAKECURVETABLE
		      (SSUSER /	2PI ATAG AVAL BEARING CENPT COL1X DELTA	DOVER2
		       DOWN EL EN ENDANG IROW ICOLUMN LABEL NEWCOLUMN RAD ROW1Y
		       SS1 STARTANG TABLEMAXROWS TABLEPT TXTHT USERCURVELIST
		      )
  (COMMAND "._undo" "group")
  (COND
    ((NOT SSUSER)
     (HAWS-TIP
       3
       "Select now the curve numbers whose data you want to put into a table.\n\nAll other curve numbers will be ignored."
     )
     (PROMPT "\nSelect curve numbers to put in table: ")
     (SETQ
       SSUSER
	(SSGET
	  '(
	    (0 . "INSERT")
	    (2 . "CURVENUMBER")
	   )
	)
     )
    )
  )
  (COND
    (SSUSER
     (SETQ
       USERCURVELIST
	(CRVS-SORTCURVELIST (CRVS-MAKECURVELIST SSUSER))
       2PI
	(* 2 PI)
       DOWN
	(/ PI -2)
       TABLEPT
	(COND
	  ((SETQ SS1 (SSGET "X" '((2 . "CURVETABLEHEADER"))))
	   (CDR (ASSOC 10 (ENTGET (SSNAME SS1 (1- (SSLENGTH SS1))))))
	  )
	  (T
	   (GETPOINT "\nStart point for curve table: ")
	  )
	)
       COL1X
	(CAR TABLEPT)
       ROW1Y
	(CADR TABLEPT)
       IROW
	0
       ICOLUMN
	0
       TABLEMAXROWS
	(COND
	  ((GETINT
	     "\nMaximum number of rows for table height <1000>:"
	   )
	  )
	  (1000)
	)
       TXTHT
	(* (GETVAR "dimscale") (GETVAR "dimtxt"))
       NEWCOLUMN
	T
       LANAME
	(CAR CRVS:TABLELAYER)
       LACOLOR
	(CADR CRVS:TABLELAYER)
     )
     (COMMAND "._layer")

     (IF (NOT (TBLSEARCH "LAYER" LANAME))
       (COMMAND "m" LANAME)
     )
     (COMMAND "t" LANAME "on" LANAME "u" LANAME "s" LANAME)
     (IF (/= LACOLOR "")
       (COMMAND "c" LACOLOR "")
     ) ;_ end of if
     (COMMAND "")
     (IF (SETQ SS1 (SSGET "X" '((2 . "CURVETABLE,CURVETABLEHEADER"))))
       (COMMAND "._ERASE" SS1 "")
     )

     (FOREACH
	CURVE
	     USERCURVELIST
       (IF (> (1+ IROW) TABLEMAXROWS)
	 (SETQ
	   IROW
	    0
	   ICOLUMN
	    (1+ ICOLUMN)
	   TABLEPT
	    (LIST (+ COL1X (* ICOLUMN TXTHT CRVS:TABLEWIDTH)) ROW1Y 0.0)
	 )
       )
       (COND
	 ((= IROW 0)
	  (COMMAND "._insert" "curvetableheader" TABLEPT TXTHT "" 0)
	  (SETQ
	    TABLEPT
	     (POLAR TABLEPT DOWN (* TXTHT CRVS:TABLEROWSPACING))
	    IROW
	     (1+ IROW)
	  )
	 )
       )
       (SETQ
	 RAD
	  (ATOF (CAAR CURVE))
	 STARTANG
	  (ATOF (CADAR CURVE))
	 ENDANG
	  (ATOF (CADDAR CURVE))
	 CENPT
	  (LIST
	    (ATOF (CADDDR (CAR CURVE)))
	    (ATOF (NTH 4 (CAR CURVE)))
	    (ATOF (NTH 5 (CAR CURVE)))
	  )
	 LABEL
	  (CADR CURVE)
	 BEARING
	  (+ (/ PI 2)
	     (IF (> STARTANG ENDANG)
	       (REM (/ (+ STARTANG ENDANG 2PI) 2) 2PI)
	       (/ (+ STARTANG ENDANG) 2)
	     )
	  )
	 DELTA
	  (COND
	    ((> STARTANG ENDANG) (- 2PI (- STARTANG ENDANG)))
	    (T (- ENDANG STARTANG))
	  )
	 DOVER2
	  (/ DELTA 2)
       )
       (COMMAND
	 "._insert" "curvetable" "non" TABLEPT TXTHT ""	0
	)
       ;;Change attribute values
       (SETQ EN (ENTLAST))
       (WHILE (AND
		(SETQ EN (ENTNEXT EN))
		(/= "SEQEND" (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
	      )
	 (COND
	   ((= "ATTRIB" (CDR (ASSOC 0 EL)))
	    (SETQ
	      ATAG
		   (CDR (ASSOC 2 EL))
	      AVAL
		   (COND
		     ((= ATAG "CURVE") LABEL)
		     ((= ATAG "RADIUS") (STRCAT (RTOS RAD 2 2) CRVS:DISTPOST))
		     ((= ATAG "LENGTH") (STRCAT (RTOS (* RAD DELTA) 2 2) CRVS:DISTPOST))
		     ((= ATAG "DELTA")
		      (VL-STRING-SUBST "%%d" "d" (ANGTOS DELTA 1 4))
		     )
		     ((= ATAG "CHORD") (STRCAT (RTOS (* 2 RAD (SIN DOVER2)) 2 2) CRVS:DISTPOST))
		     ((= ATAG "TANGENT")
		      (STRCAT (RTOS (* RAD (/ (SIN DOVER2) (COS DOVER2))) 2 2) CRVS:DISTPOST)
		     )
		     ((= ATAG "BEARING")
                       (IF (NOT CRVS:ISBEARINGIMPORTANT)
                         "-"
                         (VL-STRING-SUBST
                           "%%d"
                           "d"
                           (ANGTOS BEARING 4 4)
                         )
                       )
                     )
                     ((= ATAG "STARTNORTHING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (car (polar cenpt startang)) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
                     ((= ATAG "STARTEASTING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (cadr (polar cenpt startang)) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
                     ((= ATAG "ENDNORTHING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (car (polar cenpt endang)) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
                     ((= ATAG "ENDEASTING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (cadr (polar cenpt endang)) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
                     ((= ATAG "CENTERNORTHING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (car cenpt) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
                     ((= ATAG "CENTEREASTING")
                      (IF (NOT CRVS:ISLOCATIONIMPORTANT) "-"
                        (RTOS (cadr cenpt) 2 CRVS:COORDINATEPRECISION)
                      )
                     )
		   )
	    )
	    (ENTMOD (SUBST (CONS 1 AVAL) (ASSOC 1 EL) EL))
	    (ENTUPD EN)
	   )
	 )
       )
       (SETQ
	 TABLEPT
	  (POLAR TABLEPT DOWN (* TXTHT CRVS:TABLEROWSPACING))
	 IROW
	  (1+ IROW)
       )
     )
     (COMMAND "._undo" "end")
     (HAWS-TIP
       4
       "CURVES ships with only RADIUS, LENGTH, and DELTA columns showing.  You may thaw all crvs- layers to see other columns.\n\nYou may choose to list bearings or locations by changing the respective settings in CURVETABLES.LSP"
     )
    )
    (T
     (HAWS-TIP
       5
       "You must select curve numbers to make a table."
     )
    )
  )
)

(DEFUN
   CRVS-BURSTNUMBERS
		    (SSUSER / EN ENCURVE EL ENT)
  (COMMAND "._undo" "g")
  (IF (NOT SSUSER)
    (SETQ
      SSUSER
       (SSGET
	 (LIST
	   '(-4 . "<AND")
	   '(0 . "INSERT")
	   '(2 . "CURVENUMBER")
	   '(-4 . "AND>")
	 )
       )
    )
  )
  (IF (NOT SSUSER)
    (SETQ
      SSUSER
       (SSGET
	 "X"
	 (LIST
	   '(-4 . "<AND")
	   '(0 . "INSERT")
	   '(2 . "CURVENUMBER")
	   '(-4 . "AND>")
	 )
       )
    )
  )
  (COND
    (SSUSER
     (SETQ I -1)
     (WHILE (SETQ EN (SSNAME SSUSER (SETQ I (1+ I))))
       (SETQ
	 EL	 (ENTGET EN)
	 ENCURVE EN
       )
       (COND
	 ((= (CDR (ASSOC 0 EL)) "INSERT")
	  ;;Make a text just like the label, but on the curve number layer.
	  (WHILE (AND
		   (SETQ EN (ENTNEXT EN))
		   (/= "SEQEND" (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
		 )
	    (COND
	      ((AND
		 (= "ATTRIB" (CDR (ASSOC 0 EL)))
		 (= (CDR (ASSOC 2 EL)) "CURVE")
	       )
	       (ENTMAKE
		 (LIST
		   (CONS 0 "TEXT")
		   (ASSOC 67 EL)
		   (ASSOC 410 EL)
		   (CONS 8 (CAR CRVS:NUMBERLAYER))
		   (CONS 100 "AcDbText")
		   (ASSOC 10 EL)
		   (ASSOC 40 EL)
		   (ASSOC 1 EL)
		   (ASSOC 50 EL)
		   (ASSOC 41 EL)
		   (ASSOC 51 EL)
		   (ASSOC 7 EL)
		   (ASSOC 71 EL)
		   (ASSOC 72 EL)
		   (ASSOC 11 EL)
		   (ASSOC 73 EL)
		 )
	       )
	       (SETQ
		 ENT (ENTGET (ENTLAST))
		 ENT (SUBST (ASSOC 11 EL) (ASSOC 11 ENT) ENT)
	       ) ;_ end of setq
	       (ENTMOD ENT)
	      )
	    )
	  )
	  ;;Explode the block
	  (SETQ EN (ENTLAST))
	  (COMMAND "._explode" ENCURVE)
	  ;;Erase all the attdefs and change the rest to curve number layer.
	  (WHILE (SETQ EN (ENTNEXT EN))
	    (IF	(= "ATTDEF" (CDR (ASSOC 0 (ENTGET EN))))
	      (ENTDEL EN)
	      (ENTMOD
		(SUBST
		  (CONS 8 (CAR CRVS:NUMBERLAYER))
		  (ASSOC 8 (ENTGET EN))
		  (ENTGET EN)
		)
	      )
	    )
	  )
	 )
       )
     )
    )
  )
  (COMMAND "._undo" "e")
)


(DEFUN
   CRVS-INSERTCURVENUMBER
			 (ARC LABEL / 2PI ANG1 ATAG AVAL CENPT EL EN ENBLK
			  ENDANG INSPT LACOLOR LANAME RAD ROT STARTANG TXTHT
			 )
  (SETQ
    2PI
     (* 2 PI)
    TXTHT
     (* (GETVAR "dimscale") (GETVAR "dimtxt"))
    RAD
     (ATOF (CAR ARC))
    STARTANG
     (ATOF (CADR ARC))
    ENDANG
     (ATOF (CADDR ARC))
    CENPT
     (LIST
       (ATOF (CADDDR ARC))
       (ATOF (NTH 4 ARC))
       (ATOF (NTH 5 ARC))
     )
    ANG1
     (IF (> STARTANG ENDANG)
       (REM (/ (+ STARTANG ENDANG 2PI) 2) 2PI)
       (/ (+ STARTANG ENDANG) 2)
     )
    INSPT
     (POLAR
       CENPT
       ANG1
       (+ RAD TXTHT)
     )
    ROT
     (IF (MINUSP (SIN (- ANG1 (/ PI 4))))
       (+ ANG1 (/ PI 2))
       (- ANG1 (/ PI 2))
     )
    LANAME
     (CAR CRVS:NUMBERLAYER)
    LACOLOR
     (CADR CRVS:NUMBERLAYER)
  )
  (COMMAND "._layer")

  (IF (NOT (TBLSEARCH "LAYER" LANAME))
    (COMMAND "m" LANAME)
  )
  (COMMAND "t" LANAME "on" LANAME "u" LANAME "s" LANAME)
  (IF (/= LACOLOR "")
    (COMMAND "c" LACOLOR "")
  ) ;_ end of if
  (COMMAND "")
  (COMMAND
    "._insert"
    "curvenumber"
    "non"
    INSPT
    TXTHT
    ""
    (ANGTOS ROT)
  )
  ;;Change attribute values
  (SETQ
    EN	  (ENTLAST)
    ENBLK EN
  )
  (WHILE (AND
	   (SETQ EN (ENTNEXT EN))
	   (/= "SEQEND" (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
	 )
    (COND
      ((= "ATTRIB" (CDR (ASSOC 0 EL)))
       (SETQ
	 ATAG
	      (CDR (ASSOC 2 EL))
	 AVAL
	      (COND
		((= ATAG "CURVE") LABEL)
		((= ATAG "RADIUS") (RTOS RAD 2 8))
		((= ATAG "XCOORD") (RTOS (CAR CENPT) 2 2))
		((= ATAG "YCOORD") (RTOS (CADR CENPT) 2 2))
		((= ATAG "ZCOORD") (RTOS (CADDR CENPT) 2 2))
		((= ATAG "STARTANG") (RTOS STARTANG 2 8))
		((= ATAG "ENDANG") (RTOS ENDANG 2 8))
	      )
       )
       (ENTMOD (SUBST (CONS 1 AVAL) (ASSOC 1 EL) EL))
       (ENTUPD EN)
      )
    )
  )
  (LIST ARC LABEL EN ENBLK)
)



(DEFUN
   CRVS-SORTCURVELIST
		     (CURVELIST / CURVE CURVEBEFORE I NEWCURVELIST SORTED)
  (WHILE (NOT SORTED)
    (SETQ
      I	0
      SORTED
       T
    )
    (WHILE (> (LENGTH CURVELIST) 1)
      (COND
	((< (ATOI (SUBSTR (CADAR CURVELIST) 2))
	    (ATOI (SUBSTR (CADADR CURVELIST) 2))
	 )
	 (SETQ
	   NEWCURVELIST
	    (CONS (CAR CURVELIST) NEWCURVELIST)
	   CURVELIST
	    (CDR CURVELIST)
	 )
	)
	((= (ATOI (SUBSTR (CADAR CURVELIST) 2))
	    (ATOI (SUBSTR (CADADR CURVELIST) 2))
	 )
	 (SETQ
	   CURVELIST
	    (CDR CURVELIST)
	 )
	)
	(T
	 (SETQ
	   NEWCURVELIST
	    (CONS (CADR CURVELIST) NEWCURVELIST)
	   CURVELIST
	    (CONS (CAR CURVELIST) (CDDR CURVELIST))
	   SORTED
	    NIL
	 )
	)
      )
    )
    (SETQ
      CURVELIST
       (REVERSE (CONS (CAR CURVELIST) NEWCURVELIST))
      NEWCURVELIST
       NIL
    )
  )
  CURVELIST
)
;;; Build list of curves from selection set of curve numbers
;;; Curve (list (list rad startang endang xcoord ycoord zcoord) label ename)
(DEFUN
   CRVS-MAKECURVELIST
		     (SS / ATAG	CURVELIST EL EN	ENCURVE	ENDANG I LABEL RAD
		      STARTANG XCOORD YCOORD ZCOORD
		     )
  (COND
    (SS
     (SETQ I -1)
     (WHILE (SETQ EN (SSNAME SS (SETQ I (1+ I))))
       (SETQ
	 EL	 (ENTGET EN)
	 ENCURVE EN
       )
       (COND
	 ((= (CDR (ASSOC 0 EL)) "INSERT")
	  ;;Get attribute values
	  (WHILE (AND
		   (SETQ EN (ENTNEXT EN))
		   (/= "SEQEND" (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
		 )
	    (COND
	      ((= "ATTRIB" (CDR (ASSOC 0 EL)))
	       (SETQ
		 ATAG
		  (CDR (ASSOC 2 EL))
	       )
	       (SET
		 (COND
		   ((= ATAG "CURVE") 'LABEL)
		   ((= ATAG "RADIUS") 'RAD)
		   ((= ATAG "XCOORD") 'XCOORD)
		   ((= ATAG "YCOORD") 'YCOORD)
		   ((= ATAG "ZCOORD") 'ZCOORD)
		   ((= ATAG "STARTANG") 'STARTANG)
		   ((= ATAG "ENDANG") 'ENDANG)
		   (T 'X)
		 )
		 (CDR (ASSOC 1 EL))
	       )
	      )
	    )
	  )
	  (SETQ
	    CURVELIST
	     (CONS
	       (LIST
		 (LIST RAD STARTANG ENDANG XCOORD YCOORD ZCOORD)
		 LABEL
		 ENCURVE
	       )
	       CURVELIST
	     )
	  )
	 )
       )
     )
     CURVELIST
    )
  )
)

;;; Build list of arcs from selection set
;;; Arc  (list rad startang endang xcoord ycoord zcoord)
(DEFUN
   CRVS-MAKEARCLIST
		   (SS / ARCLIST CENPT EL EN ENDANG I RAD STARTANG)
  (COND
    (SS
     (SETQ I -1)
     (WHILE (SETQ EN (SSNAME SS (SETQ I (1+ I))))
       (SETQ
	 EL (ENTGET EN)
       )
       (COND
	 ((= (CDR (ASSOC 0 EL)) "ARC")
	  (SETQ
	    RAD
	     (CDR (ASSOC 40 EL))
	    CENPT
	     (CDR (ASSOC 10 EL))
	    STARTANG
	     (CDR (ASSOC 50 EL))
	    ENDANG
	     (CDR (ASSOC 51 EL))
	    ARCLIST
	     (CONS
	       (LIST
		 (RTOS RAD 2 8)
		 (RTOS STARTANG 2 8)
		 (RTOS ENDANG 2 8)
		 (RTOS (CAR CENPT) 2 2)
		 (RTOS (CADR CENPT) 2 2)
		 (RTOS (CADDR CENPT) 2 2)
	       )
	       ARCLIST
	     )
	  )
	 )
       )
     )
     ARCLIST
    )
  )
)
(PRINC "\nCURVETABLES.LSP loaded.  Type CURVES to start.")
(PRINC)
