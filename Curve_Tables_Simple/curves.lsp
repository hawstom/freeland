;;; CURVES.LSP
;;; (C) Copyright 2002 by Thomas Gail Haws
;;; CURVES.LSP extracts curve data and presents civil engineering curve tables in AutoCAD.
;;;
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
;;; copyright owner at hawstom@despammed.com or see www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
;;; OVERVIEW
;;; CURVES.LSP is intended to be an improvement by simplicity of the AutoCAD
;;; Land Development Desktop method of creating civil engineering curve tables.
;;; For jobs that have only a dozen or so curves, the general consensus in my
;;; world is that LDD is far too much a complicated production.
;;; CURVES.LSP, on the other hand, is simple, simple, simple.
;;; 
;;; CURVES.LSP extracts curve data (RADIUS, LENGTH, DELTA, TANGENT, CHORD,
;;; and BEARING)
;;; from one arc or heavy polyline arc segment at a time,
;;; and stores whatever values are accepted in an attributed curve number block
;;; (You supply the curve number).
;;; It then copies the curve data from the curve number block to another block
;;; for presentation in a curve table.
;;;
;;; Very simple.  No grand schemes.  No headaches.  No typos.  No calculator.
;;;
;;; GETTING STARTED
;;; At minimum, all CURVES.LSP needs to work is an arc or polyline arc segment,
;;; a curve number block with a curve number attribute and one or more of
;;; the following attributes:
;;; (RADIUS, LENGTH, DELTA, TANGENT, CHORD, and BEARING),
;;; and a curve data table block with the same attributes.
;;; Try the following exercise
;;; (You can download CURVESTRIAL.DWG instead of doing steps 1-3):
;;;
;;; First, draw an arc and a polyline with an arc segment.
;;; Now you have curves to label.
;;;
;;; Second, insert the CN.dwg (Curve Number) block from
;;; http://www.hawsedc.com/gnu/cn.dwg twice-- once for each curve.
;;; See below for tools to edit and use the block.
;;; Now you have empty curve labels.
;;;
;;; Third, insert the CTHEAD.dwg (Curve Table Header) block
;;; from http://www.hawsedc.com/gnu/cthead.dwg,
;;; then the CT.dwg (Curve Table) block
;;; from http://www.hawsedc.com/gnu/ct.dwg twice below it.
;;; Now you have a short, empty curve table.
;;;
;;; Fourth, load and run CURVES.LSP by dragging it
;;; from Windows Explorer into your drawing and typing CURVES.
;;;
;;; Fifth, follow the prompts to Set your drawing units for a curve table, Get
;;; curve data from a curve and put it into a curve number block, Edit the block
;;; if you want to change the curve number or look at the data, and Copy the data
;;; to a single-line block of the curve table.
;;;
;;; That's all there is to it.  CURVES works with curves that are nested in xrefs
;;; and blocks, too.  It couldn't be simpler.
;;;
;;; EFFICIENCY NOTE
;;;
;;; For increased efficiency, you can invoke the parts of the curves command separately.
;;; GEODATA: get curve data and put into block
;;; EDIT: edit blocks
;;; COPYATTS: copy attributes
;;;
;;; For even better efficiency, you can define shorter aliases for CURVES (CRV) and
;;; the separate commands (CD, EE, CA) by removing the semi-colons from the following lines:
;;; (defun C:CRV () (C:CURVES))
;;; (defun C:CD () (C:GEODATA))
;;; (defun C:EE () (C:EDIT))
;;; (defun C:CA () (C:COPYATTS))
;;;
;;; DEVELOPMENT NOTES
;;;
;;; CRVS is an Autodesk registered symbol to avoid conflicts with other applications.
;;;
;;; REVISION HISTORY
;;;
;;; Date     Programmer   Revision
;;; 20080712 TGH          Fixed missing chord bug.
;;; 20030915 TGH          Added data-on-a-leader option. Streamlined and cleaned code.
;;; 20021028 TGH          Put together CURVES package from GEODATA, CA, and EE.
;;;
;;; CURVES - Package together GEODATA, COPYATTS, and edit

(DEFUN
   C:CURVES
           (/ CRVS:ACTION)
  (PROMPT
    (STRCAT
      "\nCURVES version 1.0.1, Copyright (C) 2002 Thomas Gail Haws" "\nCURVES comes with ABSOLUTELY NO WARRANTY."
      "\nThis is free software, and you are welcome to modify and"
      "\nredistribute it under the terms of the GNU General Public License."
      "\nThe latest version of CURVES is always available at www.hawsedc.com"
     ) ;_ end of STRCAT
 ;_ end of strcat
  ) ;_ end of prompt
  (WHILE
    (PROGN
      (INITGET "Set Get Edit Copy")
      (SETQ
        CRVS:ACTION
         (GETKWORD
           "\nSet AutoCAD units/Get data from curve/Edit block/Copy data between blocks: "
         ) ;_ end of getkword
      ) ;_ end of setq
    ) ;_ end of progn
     (COND
       ((= CRVS:ACTION "Set")
        (FOREACH
           VAR
              '(("lunits" 2) ("luprec" 2) ("aunits" 1) ("auprec" 4))
          (SETVAR (CAR VAR) (CADR VAR))
        ) ;_ end of foreach
        (PROMPT "\nUnits set to 0.00 and 0d00'00\".")
       )
       ((= CRVS:ACTION "Get") (C:GEODATA))
       ((= CRVS:ACTION "Edit") (C:EDIT))
       ((= CRVS:ACTION "Copy") (C:COPYATTS))
     ) ;_ end of cond
  ) ;_ end of while
  (princ);Exit quietly
) ;_ end of defun

;;; GEODATA - Get curve data from an arc and
;;; save to RADIUS, LENGTH, DELTA, CHORD, and TANGENT attributes in a block.
;;; Also report bearing and distance of lines and circumference of circles.
;;; Works with heavy plines.
;;; By Thomas Gail Haws.
;;; (C) Copyright 2000 by Thomas Gail Haws
;;;
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
;;; copyright owner at hawstom@despammed.com or see www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;

;;; ============ Sub-functions to GEODATA ============
(DEFUN
   CRVS-CIRDATA
           (EL / R)
  (SETQ
    R (CDR (ASSOC 40 EL))
  ) ;_ end of setq
  (PRINC "\Radius=")
  (PRINC (RTOS R))
  (PRINC "  Length=")
  (PRINC (RTOS (* 2 PI R)))
  NIL
) ;_ end of defun

(DEFUN
   CRVS-LINEDATA
           (EL / P1 P2)
  (SETQ P1 (CDR (ASSOC 10 EL)))
  (SETQ P2 (CDR (ASSOC 11 EL)))
  (PRINC
    (STRCAT
      (RTOS (DISTANCE P1 P2))
      "   World bearing="
      (ANGTOS (ANGLE P1 P2) 4)
    ) ;_ end of strcat
  ) ;_ end of princ
  NIL
) ;_ end of defun

(DEFUN
   CRVS-ARCDATA
          (EL / DELTA DOVER2 EA R SA)
  (SETQ
    R (CDR (ASSOC 40 EL))
    SA (CDR (ASSOC 50 EL))
    EA (CDR (ASSOC 51 EL))
    DELTA
     (COND
       ((> SA EA) (- (* 2 PI) (- SA EA)))
       (T (- EA SA))
     ) ;_ end of cond
    DOVER2
     (/ DELTA 2)
  ) ;_ end of setq
  (LIST
    (RTOS R)
    (RTOS (* DELTA R))
    (ANGTOS DELTA 1)
    (RTOS (* R (/ (SIN DOVER2) (COS DOVER2))))
    (RTOS (* 2 R (SIN DOVER2)))
    (HAWS-RTOB (/ (+ SA EA (* 3 PI)) 2.0) 4)
  ) ;_ end of list
) ;_ end of defun

(DEFUN
   CRVS-PLDATA
         (ES / BULGE1 D DELTA DOVER2 EN ENEXT P1 P2 R)
  (SETQ
    EN (CAR ES)
    ENEXT
     (ENTNEXT EN)
    P1 (CDR (ASSOC 10 (ENTGET EN)))
    P2 (CDR (ASSOC 10 (ENTGET ENEXT)))
    D (/ (DISTANCE P1 P2) 2)
  ) ;_ end of setq
  (COND
    ((/= 0 (SETQ BULGE1 (CDR (ASSOC 42 (ENTGET EN)))))
     (SETQ
       DOVER2
        (ABS (* 2 (ATAN BULGE1)))
       DELTA
        (* 2 DOVER2)
       R (/ D (SIN DOVER2))
     ) ;_ end of setq
     (LIST
       (RTOS R)
       (RTOS (* DELTA R))
       (ANGTOS DELTA 1)
       (RTOS (* R (/ (SIN DOVER2) (COS DOVER2))))
       (RTOS (* 2 R (SIN DOVER2)))
       (HAWS-RTOB
         (ANGLE
           (CDR (ASSOC 10 (ENTGET EN)))
           (CDR (ASSOC 10 (ENTGET (ENTNEXT EN))))
         ) ;_ end of angle
         4
       ) ;_ end of HAWS-RTOB
     ) ;_ end of list
    )
    (T
     (PRINC "\nL=")
     (PRINC (* 2 D))
     NIL
    )
  ) ;_ end of cond
) ;_ end of defun

(DEFUN
   CRVS-LDR
             (CRVDATA PICKPT / ANG1 DG LEFT PTXT TXHT LLINE PT10 PT11 LBEAR LDIST PT1 PT2 PT3 PT4 ROT
             )
  (SETQ
    DG   (* (GETVAR "dimgap") (GETVAR "dimscale"))
    TXHT (* (GETVAR "dimscale") (GETVAR "dimtxt"))
    PT1  (OSNAP PICKPT "nea")
    PTXT (GETPOINT PT1 "\nPick text location: ")
    ANG1 (ANGLE PT1 PTXT)
    LEFT (MINUSP (COS ANG1))
  ) ;_ end of setq
  (COND
    ((>= (ATOF (GETVAR "acadver")) 14)
     (COMMAND
       "._leader"
       PT1
       PTXT
       ""
       (STRCAT "R=" (CAR CRVDATA))
       (STRCAT "L=" (CADR CRVDATA))
       (STRCAT "DELTA=" (CADDR CRVDATA))
       ""
     ) ;_ end of command
    )
    (T
     (COMMAND
       "dim"
       "leader"
       PT1
       PTXT
       ""
       (STRCAT "R=" (CAR CRVDATA))
       "exit"
     ) ;_ end of command
     (SETQ
       PTXT
        (POLAR
          (POLAR PTXT (/ PI -2) (* 1.667 TXHT))
          (IF LEFT
            PI
            0
          ) ;_ end of if
          (+ (IF (< (ABS (SIN ANG1)) (SIN 0.25))
               0
               TXHT
             ) ;_ end of if
             DG
          ) ;_ end of +
        ) ;_ end of polar
     ) ;_ end of setq
     (MKTEXT
       (IF LEFT
         "mr"
         "ml"
       ) ;_ end of if
       PTXT
       TXHT
       0
       (STRCAT "L=" (CADR CRVDATA))
     ) ;_ end of mktext
     (SETQ
       PTXT
        (POLAR
          (POLAR PTXT (/ PI -2) (* 1.667 TXHT))
          (IF LEFT
            PI
            0
          ) ;_ end of if
          (+ (IF (< (ABS (SIN ANG1)) (SIN 0.25))
               0
               TXHT
             ) ;_ end of if
             DG
          ) ;_ end of +
        ) ;_ end of polar
     ) ;_ end of setq
     (MKTEXT
       (IF LEFT
         "mr"
         "ml"
       ) ;_ end of if
       PTXT
       TXHT
       0
       (STRCAT "DELTA=" (CADDR CRVDATA))
     ) ;_ end of mktext
    )
  ) ;_ end of cond
  (PRINC)
) ;_ end of defun

(DEFUN
   CRVS-SAVEDATA
           (EN CRVDATA / AT AV EL ET N SAVED)
  (TERPRI)
  (WHILE
    (AND
      (SETQ EN (ENTNEXT EN))
      (/= "SEQEND"
          (SETQ ET (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
      ) ;_ end of /=
    ) ;_ end of and
     (COND
       ((= ET "ATTRIB")
        (SETQ
          AT (CDR (ASSOC 2 EL))
          AV (CDR (ASSOC 1 EL))
        ) ;_ end of setq
        (COND
          ((SETQ N (MEMBER AT '("BEARING" "CHORD" "TANGENT" "DELTA" "LENGTH" "RADIUS")))
           (ENTMOD
             (SUBST
               (CONS 1 (NTH (1- (LENGTH N)) CRVDATA))
               (ASSOC 1 EL)
               EL
             ) ;_ end of SUBST
           ) ;_ end of ENTMOD
           (PRINC (STRCAT AT " "))
           (SETQ SAVED T)
          )
        ) ;_ end of cond
        (ENTUPD EN)
       )
     ) ;_ end of cond
  ) ;_ end of while
  (IF (NOT SAVED)
    (PRINC "No ")
  ) ;_ end of if
  (PRINC "data saved to block.")
) ;_ end of defun

;;; ========== End sub-functions to GEODATA ===========

;;; Main function
(DEFUN
   C:GEODATA
            (/ CRVDATA EL EN ES ES1 PICKPT ETYPE
            )
  "\nGEODATA version 2.0, Copyright (C) 2002 Thomas Gail Haws
GEODATA comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to modify and
redistribute it under the terms of the GNU General Public License.
The latest version of GEODATA is always available at www.hawsedc.com"
  (SETQ
    ES (NENTSEL)                        ; Prompt user for an entity on screen.
    PICKPT
     (CADR ES)                          ; Save the pick point.
    EL (ENTGET (CAR ES))                ; Get info for the selected entity.
    ETYPE
     (CDR (ASSOC 0 EL))                 ; Determine the type of entity picked.
    CRVDATA
     (COND
       ((= ETYPE "ARC") (CRVS-ARCDATA EL))   ; For arcs...
       ((= ETYPE "LINE") (CRVS-LINEDATA EL)) ; For lines...
       ((= ETYPE "CIRCLE") (CRVS-CIRDATA EL)) ; For circles...
       ((= ETYPE "VERTEX") (CRVS-PLDATA ES)) ; For plines...
       (T (COMMAND "AREA" "E" PICKPT))  ; Default, invoke AREA command.
     ) ;_ end of cond
  ) ;_ end of SETQ
  (COND
    (CRVDATA
     (PRINC
       (APPLY
         'STRCAT
         (MAPCAR
           'STRCAT
           (LIST
             "\nRadius=" "  Length=" "  Delta=" "  Tangent=" "  Chord=" "  Bearing of Chord="
            ) ;_ end of list
           CRVDATA
         ) ;_ end of mapcar
       ) ;_ end of apply
     ) ;_ end of princ
     (SETQ
       ES1
        (PROGN
          (INITGET "LEader")
          (ENTSEL
            "\n<Select block to receive Radius, Length, Delta, Chord, and Tangent data>/LEader: "
          ) ;_ end of ENTSEL
        ) ;_ end of PROGN
     ) ;_ end of SETQ
     (COND
       ((= ES1 "LEader") (CRVS-LDR CRVDATA PICKPT))
       ((SETQ EN (CAR ES1))
        (CRVS-SAVEDATA EN CRVDATA)
       )
       (T
        (PRINC "\nNo block selected.")
       )
     ) ;_ end of COND
    )
  ) ;_ end of COND
  (PRINC)
) ;_ end of defun
                                        ;end GEODATA

;;; HAWS-RTOB
;;; (C) Copyright 2002 Thomas Gail Haws
;;; Convert a radian angle to a presentation quality bearing.
;;;
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
;;; copyright owner at hawstom@despammed.com or see www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
(DEFUN
   HAWS-RTOB
       (RAD AU / B I)
  (SETQ
    B (ANGTOS RAD AU)
  ) ;_ end of setq
  (IF (WCMATCH B "*d*")
    (PROGN
      (SETQ I 0)
      (WHILE (/= "d" (SUBSTR B (SETQ I (1+ I)) 1)))
      (SETQ B (STRCAT (SUBSTR B 1 (1- I)) "%%d" (SUBSTR B (1+ I))))
    ) ;_ end of progn
  ) ;_ end of if
  (IF (WCMATCH B "*d#[`.']*")
    (PROGN
      (SETQ I 0)
      (WHILE (/= "d" (SUBSTR B (SETQ I (1+ I)) 1)))
      (SETQ B (STRCAT (SUBSTR B 1 I) "0" (SUBSTR B (1+ I))))
    ) ;_ end of progn
  ) ;_ end of if
  (IF (WCMATCH B "*'#[`.\"]*")
    (PROGN
      (SETQ I 0)
      (WHILE (/= "'" (SUBSTR B (SETQ I (1+ I)) 1)))
      (SETQ B (STRCAT (SUBSTR B 1 I) "0" (SUBSTR B (1+ I))))
    ) ;_ end of progn
  ) ;_ end of if
  (SETQ
    B
     (COND
       ((= B "N") "NORTH")
       ((= B "S") "SOUTH")
       ((= B "E") "EAST")
       ((= B "W") "WEST")
       (B)
     ) ;_ end of cond
  ) ;_ end of setq
) ;_ end of defun

;;; EDIT.LSP
;;; Combined multiple sequential editor for
;;; blocks, attdefs, text, and dimensions.

(DEFUN
   C:EDIT
         (/ EG EN ET SS1)
  (SETQ SS1 (SSGET))
  (WHILE
    (AND
      SS1
      (SETQ EN (SSNAME SS1 0))
    ) ;_ end of and
     (SETQ
       EG (ENTGET EN)
       ET (CDR (ASSOC 0 EG))
     ) ;_ end of setq
     (REDRAW EN 3)
     (COND
       ((AND (= ET "INSERT") (CDR (ASSOC 66 EG)))
        (COMMAND ".DDATTE" EN)
       )
       ((OR (= ET "ATTDEF")
            (= ET "TEXT")
            (= ET "MTEXT")
            (= ET "DIMENSION")
        ) ;_ end of or
        (COMMAND ".DDEDIT" EN "")
       )
     ) ;_ end of cond
     (REDRAW EN 4)
     (IF EN
       (SSDEL EN SS1)
     ) ;_ end of if
  ) ;_ end of while
) ;_ end of defun
                                        ;END EDIT.LSP

;;; COPYATTS (COPY ATTRIBUTES) CHANGES ATTRIBUTES IN A BLOCK TO MATCH A SELECTED BLOCK.
;;; (C) Copyright 2001 by Thomas Gail Haws
;;;
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
;;; copyright owner at hawstom@despammed.com or see www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
(DEFUN
   C:COPYATTS
             (/ AT AV EL EN ET SSET MLIST MV EN SSLEN)
  "\nCOPYATTS version 1.0, Copyright (C) 2002 Thomas Gail Haws
COPYATTS comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to modify and
redistribute it under the terms of the GNU General Public License.
The latest version of COPYATTS is always available at www.hawsedc.com"
  (PROMPT "\nBlocks to change:")
  (SETQ SSET (SSGET '((0 . "INSERT"))))
  (IF (NOT SSET)
    (PROGN (PROMPT "\nNone found.") (EXIT))
    (PROGN
      (SETQ
        EN (CAR (ENTSEL "Block to match/<Match single attribute>: "))
      ) ;_ end of setq
      (IF EN
        (WHILE
          (AND
            (SETQ EN (ENTNEXT EN))
            (/= "SEQEND"
                (SETQ ET (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
            ) ;_ end of /=
          ) ;_ end of and
           (COND
             ((= ET "ATTRIB")
              (SETQ
                AT    (CDR (ASSOC 2 EL))
                AV    (CDR (ASSOC 1 EL))
                MLIST (CONS (LIST AT AV) MLIST)
              ) ;_ end of setq
             )
           ) ;_ end of cond
        ) ;_ end of while
        (IF (SETQ
              EN (CAR
                   (NENTSEL "\nAttribute to match/<enter by typing>: ")
                 ) ;_ end of car
            ) ;_ end of setq
          (SETQ
            EL    (ENTGET EN)
            MLIST (LIST (LIST (CDR (ASSOC 2 EL)) (CDR (ASSOC 1 EL))))
          ) ;_ end of setq
          (SETQ
            MLIST
             (LIST
               (LIST
                 (STRCASE
                   (GETSTRING "\nTag of attribute to change: ")
                 ) ;_ end of strcase
                 (GETSTRING "\nNew value: ")
               ) ;_ end of list
             ) ;_ end of list
          ) ;_ end of setq
        ) ;_ end of if
      ) ;_ end of if
;;; Change all of the entities in the selection set.
      (PROMPT "\nChanging text to match selection...")
      (SETQ SSLEN (SSLENGTH SSET))
      (WHILE (> SSLEN 0)
        (SETQ
          EN (SSNAME SSET (SETQ SSLEN (1- SSLEN)))
        ) ;_ end of setq
        (WHILE
          (AND
            (SETQ EN (ENTNEXT EN))
            (/= "SEQEND"
                (SETQ ET (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
            ) ;_ end of /=
          ) ;_ end of and
           (COND
             ((AND
                (= ET "ATTRIB")
                (SETQ
                  AT (CDR (ASSOC 2 EL))
                ) ;_ end of setq
                (ASSOC AT MLIST)
              ) ;_ end of and
              (ENTMOD
                (SUBST (CONS 1 (CADR (ASSOC AT MLIST))) (ASSOC 1 EL) EL)
              ) ;_ end of entmod
              (ENTUPD EN)
             )
           ) ;_ end of cond
        ) ;_ end of while
      ) ;_ end of while
      (PROMPT "done.")
    ) ;_ end of progn
  ) ;_ end of if
  (PRINC)
) ;_ end of defun
