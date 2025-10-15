(defun c:TURNC ()                       ;starts main
                                       ;initialise
 (command \"undo\" \"begin\")
 (command \"cmdecho\" \"0\")
 (setq INTERFLAG nil)
 (setq CONVERTFLAG nil)
 (SETQ DXFDEFAULT                      ;establish common dxf group codes for plines
        (LIST
          (CONS 0 \"LWPOLYLINE\")
          (CONS 100 \"AcDbEntity\")
          (CONS 100 \"AcDbPolyline\")
          (CONS 8 \"pathcorrection\")  ;layer=pathcorrection
          (CONS 90 2)
          (CONS 70 0)
          (CONS 43 0)
          (CONS 38 0)
          (CONS 39 0)
          (CONS 62 1)                  ;colour=red
        )
 )

 (INPUTDATA)

 (PROMPT
   \"\\n Does your path define the centre, left, or right hand side of your vehicle\'s movement?\"
 )
 (INITGET 0 \"Left Right Centre\")
 (setq opt (getkword \"\\n [Left/Right/Centre]<Centre> \"))
 (if (not opt)
   (setq TC TCC)
 )
 (if (= opt \"Left\")
   (setq TC TCL)
 )
 (if (= opt \"Right\")
   (setq TC TCR)
 )
 (if (= opt \"Centre\")
   (setq TC TCC)
 )

 (INITGET 0 \"Interrogate Convert\")
 (setq opt2
        (getkword
          \"\\n Do you want to interrogate or convert your path? [Interrogate/Convert] <Interrogate> \"
        )
 )                                     ;QUERY TO EITHER INTERROGATE AN EXISTING POLYLINE OR DRAW A NEW ONE WITH LIMITED RADII.
 (if                                   ;DEFAULT ACTION IS TO INTERROGATE
   (not opt2)
    (INTERROGATE)
 )
 (if
   (= opt2 \"Interrogate\")
    (INTERROGATE)
 )
 (if
   (= opt2 \"Convert\")
    (CONVERTPL)
 )

)                                       ;ends main


;;**************START SUBROUTINES***********************

;;**INTERROGATE
(defun INTERROGATE ()
 (SETQ INTERFLAG 1)
 (prompt \"\\n Please select your path to interrogate\")
 (GETPLINFO)
 (GETRADIILIST)
 (prompt \"\\n Your path contains the following curve radii\")
 (PRINC RADIILIST)
 (terpri)
)                                       ;END INTERROGATE

;;**INPUTDATA**
(defun INPUTDATA ()
                                       ;ENTER TURNING CIRCLE VALUE
 (setq TCL        (getreal
                    \"\\n Please enter the outer turning circle of your vehicle: \"
                  )
       WHEELWIDTH (getreal
                    \"\\n Please enter the width between your vehicle\'s wheels: \"
                  )
       TCR        (- TCL WHEELWIDTH)   ;ESTABLISHES THE RHS TURNING RADIUS
       TCC        (- TCL (/ WHEELWIDTH 2))
                                       ;ESTABLISHES THE CENTRAL TURNING RADIUS
 )
)                                       ;END INPUTDATA

;;**CONVERTPL**
(defun CONVERTPL ()
 (SETQ CONVERTFLAG 1)
 (prompt
   \"\\n Please select your path to convert\"
 )
 (GETPLINFO)
)                                       ;END CONVERTPL

;;**GETPLINFO**
(defun GETPLINFO ()                     ;/BULGEDATA PLINEDATALEN PLINECOUNT PLINEDEF
 (setq PLINEDATA    (entget (ssname (ssget) 0))
       PLINEDATALEN (LENGTH PLINEDATA)
       PLINECOUNT   0
       PLINEDEF     nil
       BULGEDATA    nil
 )
 (WHILE (< PLINECOUNT PLINEDATALEN)    ;GET COORDS FOR PLINE VERTEXES
   (IF
     (= (CAR (NTH PLINECOUNT PLINEDATA)) 10)
      (SETQ PLINEDEF
             (APPEND PLINEDEF          ;ADD COORDS TO PLINEDEF
                     (LIST
                       (CDR (NTH PLINECOUNT PLINEDATA))
                     )
             )
      )
   )
   (IF
     (= (CAR (NTH PLINECOUNT PLINEDATA)) 42)
      (SETQ BULGEDATA
             (APPEND BULGEDATA         ;ADD BULGE TO BULGEDATA
                     (LIST
                       (CDR (NTH PLINECOUNT PLINEDATA))
                     )

             )
      )
   )
   (SETQ PLINECOUNT (1+ PLINECOUNT))
 )
)                                       ;END GETPLINFO
;;**GETRADIILIST**
(defun GETRADIILIST ()
 (SETQ PLINECOUNT
        0
       RADIILIST nil
 )
 (WHILE
   (< PLINECOUNT (1- (LENGTH PLINEDEF)))
    (SETQ PT1    (NTH PLINECOUNT PLINEDEF)
          PT2    (NTH (1+ PLINECOUNT) PLINEDEF)
          BULGES (NTH PLINECOUNT BULGEDATA)
          RADIUS (SEGMENT-RADIUS PT1 PT2 BULGES)
    )
    (IF                                ;IF THE SEGMENT IS A CURVE ADD THE RADIUS TO RADIILIST
      (/= 0 BULGES)
       (progn
         (SETQ RADIILIST (APPEND RADIILIST (LIST RADIUS)))
         (IF
           (AND (< RADIUS TC) (= INTERFLAG 1))
                                       ;IF RADIUS IS LESS THAN THE TURNING CIRCLE PLACE MIN ARCS ON CURVE IF INTERFLAG IS 1
            (REPORTRADII)
         )                             ;end if
       )                               ;end progn
    )                                  ;end if

    (SETQ PLINECOUNT (1+ PLINECOUNT))
 )                                     ;END WHILE
)                                       ;END GETRADIILIST



;;**DXF**
(defun dxf (code elist)
 (cdr (assoc code elist))
)                                       ;END defun


;;**RADIN->DEGREES
(defun Radian->Degrees (nbrOfRadians)
 (* 180.0 (/ nbrOfRadians pi))

)

;;;  SEGMENT-RADIUS
(DEFUN
         SEGMENT-RADIUS
                       (2DPNT1 2DPNT2 BULGE / DELTA DOVER2)
;;;  Returns nil if bulge = 0
 (COND
   ((/= 0 BULGE)
    (SETQ
      DOVER2 (ABS (* 2 (ATAN BULGE)))
      DELTA  (* 2 DOVER2)
    )
    (/ (DISTANCE 2DPNT1 2DPNT2) 2.0 (SIN DOVER2))
   )
   (T NIL)
 )
)

;;**REPORTRADII**
(DEFUN REPORTRADII ()
 (SETQ ARCLIST
        (APPEND
          DXFDEFAULT
          (LIST
            (CONS 10 PT1)
            (IF
              (minusp BULGES)
               (CONS 42 (HAWS-RCTOBULGE TC (- (DISTANCE PT1 PT2))))
                                       ;CALL THE BULGE CALCULATOR THEN MAKE BULGE RESULT NEGATIVE
               (CONS 42 (HAWS-RCTOBULGE TC (DISTANCE PT1 PT2)))
                                       ;ELSE JUST CALL THE BULGE CALCULATOR
            )
            (CONS 10 PT2)
          )
        )
 )
 (ENTMAKE ARCLIST)
 (PROMPT \"\\n ADDED ARC\")
)                                       ;END REPORTRADII

;;**HAWS-RCTOBULGE**
(DEFUN HAWS-RCTOBULGE (RADIUS2 CHORD)
;;;  Converts radius and chord to bulge.
;;;  Returns the bulge of an arc with the given radius and chord..
;;;  Returns 0.0 if either argument is nil
 (IF (AND RADIUS2 CHORD)
   (HAWS-TAN (/ (HAWS-ASIN (/ CHORD RADIUS2 2.0)) 2.0))
   0.0
 )
)

;;;  Trig functions not included with AutoLISP
(DEFUN HAWS-ASIN (X) (ATAN X (SQRT (- 1 (* X X)))))
(DEFUN HAWS-ACOS (X) (ATAN (SQRT (- 1 (* X X))) X))
(DEFUN HAWS-TAN (X) (/ (SIN X) (COS X)))
