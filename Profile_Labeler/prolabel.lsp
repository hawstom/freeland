;;; PROLABEL.LSP
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
;;; DEVELOPMENT NOTES
;;;
;;; REVISION HISTORY
;;;
;;; Date     Programmer   Revision
;;; 20021031 TGH          Initial coding 2.0 hrs.  No functioning plot routine.
;;;
(defun C:PROLABEL ( / prolabel_action)
  (prompt
"\nPROLABEL version 1.0, Copyright (C) 2002 Thomas Gail Haws and WRG Design Inc.
PROLABEL comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to modify and
redistribute it under the terms of the GNU General Public License.
The latest version of PROLABEL is always available at www.hawsedc.com"
  )
  (while (not prolabel_reference) (setq prolabel_reference (prolabel_getrefpoint)))
  (if (not prolabel_hvexag) (setq prolabel_hvexag 10))
  (if (not prolabel_label) (setq prolabel_label "MATCH LINE"))
  (if (not prolabel_offset) (setq prolabel_offset nil))
  (if (not prolabel_height) (setq prolabel_height 6))
  (if (not prolabel_elprefix1) (setq prolabel_elprefix1 "G="))
  (if (not prolabel_elprefix2) (setq prolabel_elprefix2 "TC="))
  (while
    (progn
      (initget "Setup Offset")
      (setq prolabel_action (getpoint "\nSetup/Offset/<point to label>: "))
    )
    (cond
      ( (= prolabel_action "Setup") (prolabel_setup))
      ( (= prolabel_action "Offset") (setq prolabel_offset (getreal "\nNew point offset, or . for none: ")))
      ( T (prolabel_insertlabel prolabel_action))
    )
  )
  (princ)
)
(defun prolabel_setup ( / prolabel_action)
  (while
    (progn
      (textscr)
      (prompt
        (strcat
          "\n\n====================================================="
          "\nR  Reference point"
          "\nX  vertical eXaggeration               (" (rtos prolabel_hvexag 2)  ")"
          "\nL  Point Label                         (" prolabel_label            ")"
          "\nH  profile Height                      (" (rtos prolabel_height 2 0)")"
          "\nB  Bottom or single elevation prefix   (" prolabel_elprefix1         ")"
          "\nT  Top elevation prefix                (" prolabel_elprefix2         ")"
        )
      )
      (initget "R X L H B T")
      (setq prolabel_action (getkword "\n\nItem to change: "))
    )
    (cond
      ( (= prolabel_action "R") (graphscr)(setq prolabel_reference (prolabel_getrefpoint)))
      ( (= prolabel_action "X") (setq prolabel_hvexag (getreal "\nNew vertical exaggeration: ")))
      ( (= prolabel_action "L") (setq prolabel_label  (prolabel_getlabel)))
      ( (= prolabel_action "H") (setq prolabel_height (getreal "\nCurb height (or 0 for single line): ")))
      ( (= prolabel_action "B") (setq prolabel_elprefix1 (getstring "\nNew prefix for bottom or single elevation: ")))
      ( (= prolabel_action "T") (setq prolabel_elprefix2 (getstring "\nNew prefix for top elevation: ")))
    )
  )
  (graphscr)
)
(defun prolabel_getrefpoint ()
  (append
    (reverse (cdr (reverse(getpoint "\nReference point on profile grid: "))))
    (list(getreal "\nReference point station: ")(getreal "\nReference point elevation: "))
  )
)
(defun prolabel_getlabel ( / prolabel_action)
  (textscr)
  (prompt
    (strcat
      "\n\n====================================================="
      "\n1. MATCH LINE"
      "\n2. GB"
      "\n3. GC"
      "\n4. PC"
      "\n5. PRC"
      "\n6. PCC"
      "\n7. Other"
    )
  )
  (initget "1 2 3 4 5 6 7 8 9")
  (setq prolabel_action (getkword "\n\nNumber of new label to use: "))
  (cond
    ( (= prolabel_action "1") "MATCH LINE")
    ( (= prolabel_action "2") "GB")
    ( (= prolabel_action "3") "GC")
    ( (= prolabel_action "4") "PC")
    ( (= prolabel_action "5") "PRC")
    ( (= prolabel_action "6") "PCC")
    ( (= prolabel_action "7") (getstring 1 "\nEnter other label: "))
  )
)  
(defun prolabel_insertlabel (plotpoint / plotpoint plotsta )
  (princ  prolabel_hvexag)
  (princ  prolabel_label) 
  (princ  prolabel_offset)
  (princ  prolabel_height)
  (princ  prolabel_elprefix1)
  (princ  prolabel_elprefix2)
  (setq
    plotsta (+ (caddr prolabel_reference) (- (car plotpoint) (car prolabel_reference)))
    plotelev (+ (cadddr prolabel_reference) (- (cadr plotpoint) (cadr prolabel_reference)))
  )
  (princ (rtosta plotsta 2))
  (princ plotelev)
)
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
(defun rtosta (sta lup / isneg after before)
  (setq
    lup (cond (lup)((getvar "luprec")))
    isneg (minusp sta)
    sta (rtos (abs sta) 2 lup)
  )
  (while (< (strlen sta) (if(= lup 0) 3 (+ lup 4)))
    (setq sta (strcat "0" sta))
  )
  (setq
    after (if (= lup 0) (- (strlen sta) 1) (- (strlen sta) lup 2))
    before (substr sta 1 (1- after))
    after (substr sta after)
  )
  (if isneg (setq before (strcat "-(" before) after (strcat after ")")))
  (strcat before "+" after)
)

