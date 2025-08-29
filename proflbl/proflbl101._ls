;;; PROFLBL.LSP (entire file)
;;; (C) Copyright 2002 by Thomas Gail Haws and WRG Design Inc.
;;; PROLABEL.LSP labels civil engineering profiles by picking.
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
;;; PROLABEL.LSP helps you label civil engineering profiles in AutoCAD.
;;; 
;;; GETTING STARTED
;;;
;;; Drag this file into an AutoCAD drawing, then type PROFLBL or the alias PP,
;;; which you can change below.
;;;
;;; DEVELOPMENT NOTES
;;;
;;; REVISION HISTORY
;;;
;;; Date     Programmer   Revision
;;; 20021031 TGH          Initial coding 2.0 hrs.  No functioning plot routine.
;;; 20021113 TGH          Additional coding 4.0 hrs.  Functional deliverable for WRG.
;;; 20021216 TGH          Additional coding 1.0 hr.  Added downward label. Removed custom scale.
;;;
(defun c:pp () (c:prolabel))
(defun c:proflbl () (c:prolabel))
;;; Main Function PROLABEL
;;; Application name PROLABEL.
;;; Global symbol      Symbol Type   Comment
;;; PROLABEL:HVEXAG    'REAL          Profile horiz. scale / vertical scale
;;; PROLABEL:REFERENCE 'LIST          '(refx refy refsta refelev)
;;; PROLABEL:TYPE      'LIST          '(heightfeet topelevlabel bottomelevlabel)
;;; PROLABEL:LABEL     'STRING        Point label
(defun
   C:PROLABEL
             (/ PROLABEL:action)
  (prompt
    "\nPROLABEL version 1.01, Copyright (C) 2002 Thomas Gail Haws and WRG Design Inc.
PROLABEL comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to modify and
redistribute it under the terms of the GNU General Public License.
The latest version of PROLABEL is always available at www.hawsedc.com"
  )
  (setq PROLABEL:scale (getvar "dimscale"))
  (setq PROLABEL:text (getvar "dimtxt"))
  (if (not PROLABEL:hvexag) (setq PROLABEL:hvexag 10))
  (while (not PROLABEL:reference)
    (PROLABEL:getrefpoint)
  )
  (if (not PROLABEL:label)
    (setq
      PROLABEL:label
       "MATCH LINE"
    )
  )
  (if (not PROLABEL:type)
    (setq PROLABEL:type '(0.5 "TC" "G"))
  )
  (setq PROLABEL:offset ".")
  (while
    (progn
      (initget "Setup Label Offset")
      (setq
        PROLABEL:action
         (getpoint "\nSetup/Label/Offset/<point to label>: ")
      )
    )
     (cond
       ((= PROLABEL:action "Setup") (PROLABEL:setup))
       ((= PROLABEL:action "Label") (PROLABEL:getlabel)(graphscr))
       ((= PROLABEL:action "Offset")
        (initget ".")
        (setq
          PROLABEL:offset
           (getreal
             "\nNew point offset for label (- for left, + for right) or . for none: "
           )
        )
       )
       (T (PROLABEL:insertlabel PROLABEL:action))
     )
  )
  (princ)
)
;;;End Main Function PROLABEL

;;;Function PROLABEL:GETSCALE
(defun
   PROLABEL:getscale
                    (/ temp)
  (if
    (setq
      temp
       (getreal
         (strcat
           "\nDrawing scale (10, 20, 40, etc. Initial default is AutoCAD dimscale.)<"
           (rtos PROLABEL:scale 2 0)
           ">: "
         )
       )
    )
     (setq PROLABEL:scale temp)
  )
  (if
    (setq
      temp
       (getreal
         (strcat
           "\nText height (0.10, 0.125, etc. Initial default is AutoCAD dimtxt.)<"
           (rtos PROLABEL:text 2 4)
           ">: "
         )
       )
    )
     (setq PROLABEL:text temp)
  )
)
;;;End function PROLABEL:GETSCALE

;;;Function PROLABEL:SETUP displays setup menu
(defun
   PROLABEL:setup
                 (/ PROLABEL:action)
  (while
    (progn
      (textscr)
      (prompt
        (strcat
          "\n\n====================================================="
          "\nR  Reference point"
          "\nX  vertical eXaggeration               ("
          (rtos PROLABEL:hvexag 2)
          ")"
          "\nL  Point Label                         ("
          PROLABEL:label
          ")"
          "\nT  profile Type                        ("
          (rtos (* (car PROLABEL:type) 12) 2 0)
          "\")"
          "\nB  Bottom or single elevation prefix   ("
          (caddr PROLABEL:type)
          ")"
          "\nTO  Top elevation prefix               ("
          (cadr PROLABEL:type)
          ")"
        )
      )
      (initget "S R X L T B TOp")
      (setq PROLABEL:action (getkword "\n\nItem to change: "))
    )
     (cond
       ((= PROLABEL:action "S")
        (PROLABEL:getscale)
       )
       ((= PROLABEL:action "R")
        (graphscr)
        (PROLABEL:getrefpoint)
       )
       ((= PROLABEL:action "X")
        (setq PROLABEL:hvexag (getreal "\nNew vertical exaggeration: "))
       )
       ((= PROLABEL:action "L")
        (PROLABEL:getlabel)
       )
       ((= PROLABEL:action "T") (PROLABEL:gettype))
       ((= PROLABEL:action "B")
        (setq
          PROLABEL:type
           (list
             (car PROLABEL:type)
             (cadr PROLABEL:type)
             (getstring
               "\nNew prefix for bottom or single elevation: "
             )
           )
        )
       )
       ((= PROLABEL:action "TOp")
        (setq
          PROLABEL:type
           (list
             (car PROLABEL:type)
             (getstring "\nNew prefix for top elevation: ")
             (caddr PROLABEL:type)
           )
        )
       )
     )
  )
  (graphscr)
)
;;;End function PROLABEL:SETUP

;;;Function PROLABEL:GETREFPOINT gets anchor point for profile
(defun
   PROLABEL:getrefpoint
                       ()
  (setq
    PROLABEL:reference
     (append
       (reverse (cdr (reverse (getpoint "\nReference point: "))))
       (list
         (getreal "\nReference point station: ")
         (getreal "\nReference point elevation: ")
       )
     )
  )
)
;;;End function PROLABEL:GETREFPOINT

;;;Function PROLABEL:GETTYPE displays menu and gets the profile type to be plotted
;;;stores PROLABEL:TYPE in a three element list eg. '(0.5 "TC" "G")
(defun
   PROLABEL:gettype
                   (/)
  (textscr)
  (prompt
    (strcat
      "\n\n====================================================="
      "\n4  4\" curb"
      "\n6  6\" curb"
      "\n0  Edge of pavement (no curb)"
      "\nH  other curb Height"
      "\nC  Centerline"
      "\nR  Ribbon curb"
      "\nF  Flow line"
     )
  )
  (initget "6 4 0 H C R F")
  (setq PROLABEL:action (getkword "\n\nProfile type to label: "))
  (setq
    PROLABEL:type
     (cond
       ((= PROLABEL:action "4") '((/ 4.0 12) "TC" "G"))
       ((= PROLABEL:action "6") '(0.5 "TC" "G"))
       ((= PROLABEL:action "0") '(0.0 "" "EP"))
       ((= PROLABEL:action "H")
        (list (/ (getreal "\nCurb height: ") 12) "TC" "G")
       )
       ((= PROLABEL:action "C") '(0 "" "P"))
       ((= PROLABEL:action "R") '(0 "" "RC"))
       ((= PROLABEL:action "F") '(0 "" "FL"))
     )
  )
)
;;;End function PROLABEL:GETTYPE

;;;Function PROLABEL:GETLABEL displays menu and gets point labels
(defun
   PROLABEL:getlabel
                    (/ PROLABEL:action)
  (textscr)
  (prompt
    (strcat
      "\n\n====================================================="
      "\nDevelopment note:  I am predicting this menu will be more trouble than it's worth."
      "\nI propose a menu with only a few choices with one letter abbreviations"
      "\n(the longest and most common), and you have to type in anything else."
      "\nDon't you end up having to use multiple labels for many points anyway (GB,CB,PT)?"
      "\nM  \"MATCHLINE\""
      "\nC  \"PC\""
      "\nRC \"PRC\""
      "\nT  \"PT\""
      "\nCC \"PCC\""
      "\nB  \"BCR\""
      "\nE  \"ECR\""
      "\nCL \"C/L-C/L\""
      "\nG  \"GB\""
      "\nA  \"ANGLE PT\""
      "\nH  \"HIGH PT\""
      "\nL  \"LOW PT\""
      "\nF  \"FL\""
      "\nTR \"TR\""
      "\nO  Other"
      "\nX  (none)"
     )
  )
  (initget "M C RC T CC B E CL G A H L F TR O X")
  (setq PROLABEL:action (getkword "\n\nNew label to use: "))
  (setq
    PROLABEL:label
     (cond
       ((= PROLABEL:action "M") "MATCHLINE")
       ((= PROLABEL:action "C") "PC")
       ((= PROLABEL:action "RC") "PRC")
       ((= PROLABEL:action "T") "PT")
       ((= PROLABEL:action "CC") "PCC")
       ((= PROLABEL:action "B") "BCR")
       ((= PROLABEL:action "E") "ECR")
       ((= PROLABEL:action "CL") "C/L-C/L")
       ((= PROLABEL:action "G") "GB")
       ((= PROLABEL:action "A") "ANGLE PT")
       ((= PROLABEL:action "H") "HIGH PT")
       ((= PROLABEL:action "L") "LOW PT")
       ((= PROLABEL:action "F") "FL")
       ((= PROLABEL:action "TR") "TR")
       ((= PROLABEL:action "O") (getstring 1 "\nEnter label: "))
       ((= PROLABEL:action "X") "XX")
     )
  )
)
;;;End function PROLABEL:GETLABEL

;;;Function PROLABEL:MAKECIRCLE draws a circle without AutoCAD command.
(defun
   PROLABEL:makecircle
                      (cenpt1 radius1)
  (setq
    cenpt1
     (if (= 2 (length cenpt1))
       (append cenpt1 '(0.0))
       cenpt1
     )
  )
  (entmake
    (list
      (cons 0 "CIRCLE")
      (append '(10) (trans cenpt1 1 0))
      (cons 40 radius1)
    )
  )
)
;;;End function PROLABEL:MAKECIRCLE

;;;Function PROLABEL:MAKELINE draws a line without AutoCAD command.
(defun
   PROLABEL:makeline
                    (pt1 pt2)
  (setq
    pt1 (if (= 2 (length pt1))
          (append pt1 '(0.0))
          pt1
        )
    pt2 (if (= 2 (length pt2))
          (append pt2 '(0.0))
          pt2
        )
  )
  (entmake
    (list
      (cons 0 "LINE")
      (append '(10) (trans pt1 1 0))
      (append '(11) (trans pt2 1 0))
    )
  )
)
;;;Function PROLABEL:MAKELINE

;;;Function PROLABEL:INSERTLABEL inserts an annotated label.
;;;Uses global AutoLISP symbols set by other functions.
(defun
   PROLABEL:insertlabel
                       (plotpoint / plotelev plotsta lblpt1b lblpt1t)
  (PROLABEL:makecircle
    plotpoint
    (* 0.3 PROLABEL:scale PROLABEL:text)
  )
  (if
    (< 0 (car PROLABEL:type))
     (PROLABEL:makecircle
       (polar
         plotpoint
         (/ pi 2)
         (* (car PROLABEL:type) PROLABEL:hvexag)
       )
       (* 0.3 PROLABEL:scale PROLABEL:text)
     )
  )
  (setq
    lblpt1t
     (polar
       plotpoint
       (/ pi 2)
       (+ (* PROLABEL:hvexag (car PROLABEL:type))
          (* PROLABEL:scale PROLABEL:text 0.5)
       )
     )
    lblpt1b
     (polar
       plotpoint
       (/ (* 3 pi) 2)
          (* PROLABEL:scale PROLABEL:text 0.5)
     )
  )
  (setq
    plotsta
     (+ (caddr PROLABEL:reference)
        (- (car plotpoint) (car PROLABEL:reference))
     )
    plotelev
     (+ (cadddr PROLABEL:reference)
        (/ (- (cadr plotpoint) (cadr PROLABEL:reference)) PROLABEL:hvexag)
     )
  )
  (command "._insert" "proflbld" lblpt1t (* PROLABEL:scale PROLABEL:text) "" 0
      "._move"
      "l"
      ""
      (trans (cdr (assoc 10 (entget (entlast)))) (entlast) 1)
      pause
    )
  (setq lblpt2 (trans (cdr (assoc 10 (entget (entlast)))) (entlast) 1))
  (COMMAND
    "._erase" "l" ""
    "._insert"
    (IF (MINUSP (SIN (ANGLE LBLPT1T LBLPT2)))
      "proflblb"
      "proflblt"
    ) ;_ end of if
    LBLPT2
    (* PROLABEL:SCALE PROLABEL:TEXT)
    ""
    0
  ) ;_ end of command
  (command
    (if (= PROLABEL:offset ".")
      ""
      PROLABEL:label
    )
    (if (= PROLABEL:offset ".")
      PROLABEL:label
      (strcat
        (rtos (abs PROLABEL:offset) 2 2)
        (if (minusp PROLABEL:offset)
          "' LT"
          "' RT"
        )
      )
    )
    (strcat "%%uSTA " (rtosta plotsta 2))
    (strcat
      "%%o"
      (if (= "" (cadr PROLABEL:type))
        (strcat (caddr PROLABEL:type) "=")
        (strcat (cadr PROLABEL:type) "=")
      )
    )
    (strcat
      "%%o"
      (if (= "" (cadr PROLABEL:type))
        (rtos plotelev 2 2)
        (rtos (+ plotelev (/ (car PROLABEL:type) 12.0)) 2 2)
      )
    )
    (if (= "" (cadr PROLABEL:type))
      ""
      (strcat (caddr PROLABEL:type) "=")
    )
    (if (= "" (cadr PROLABEL:type))
      ""
      (rtos plotelev 2 2)
    )
  )
  (PROLABEL:makeline
    (IF (MINUSP (SIN (ANGLE LBLPT1T LBLPT2)))
      lblpt1b
      lblpt1t
    ) ;_ end of if
    lblpt2
  )
  ;;Offset is for one-time use only.  Reset here.
  (setq PROLABEL:offset ".")
)
;;;End function PROLABEL:INSERTLABEL

;;; RTOSTA sub-function converts a real number to a base 100 road station.
;;; (C) Copyright 2002 by Thomas Gail Haws
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
(defun
   rtosta
         (sta lup / isneg after before)
  (setq
    lup
     (cond
       (lup)
       ((getvar "luprec"))
     )
    isneg
     (minusp sta)
    sta
     (rtos (abs sta) 2 lup)
  )
  (while (< (strlen sta)
            (if (= lup 0)
              3
              (+ lup 4)
            )
         )
    (setq sta (strcat "0" sta))
  )
  (setq
    after
     (if (= lup 0)
       (- (strlen sta) 1)
       (- (strlen sta) lup 2)
     )
    before
     (substr sta 1 (1- after))
    after
     (substr sta after)
  )
  (if isneg
    (setq
      before
       (strcat "-(" before)
      after
       (strcat after ")")
    )
  )
  (strcat before "+" after)
)

