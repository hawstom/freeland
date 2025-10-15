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
;;; PROLABEL.LSP helps you label civile engineering profiles in AutoCAD.
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
;;; Second, insert the CN.dwg block from http://www.hawsedc.com/gnu/cn.dwg twice--
;;; once for each curve.  See below for tools to rotate and edit the block.
;;; Now you have empty curve lables.
;;;
;;; Third, insert the CTHEAD.dwg block from http://www.hawsedc.com/gnu/cthead.dwg,
;;; then the CT.dwg block from http://www.hawsedc.com/gnu/ct.dwg twice below it.
;;; Now you have an empty curve table.
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
;;; REVISION HISTORY
;;;
;;; Date     Programmer   Revision
;;; 20021028 TGH          Put together CURVES package from GEODATA, CA, and EE.
;;;
;;; CURVES - Package together GEODATA, COPYATTS, and edit
(defun C:PROLABEL ( / )
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
      ( (= prolabel_action "Offset") (setq prolabel_offset (getreal "\nPoint offset: ")))
      ( T (prolabel_insertlabel))
    )
  )
)
(defun prolabel_setup ()
  (while
    (progn
      (textscr)
      (prompt
        (strcat
          "\n1. Reference point"
          "\n2. Vertical exaggeration              (" (rtos prolabel_hvexag 2)  ")"
          "\n3. Point label                        (" prolabel_label            ")"
          "\n4. Profile height                     (" (rtos prolabel_height 2 0)")"
          "\n5. Bottom or single elevation prefix  (" prolabel_elprefix1         ")"
          "\n6. Second elevation prefix            (" prolabel_elprefix2         ")"
      (initget "1 2 3 4 5 6 7 8 9")
      (setq prolabel_action (getkword "\n\nNumber of item to change: "))
    )
    (cond
      ( (= prolabel_action 1) (setq prolabel_reference (prolabel_getrefpoint))
      ( (= prolabel_action 2) (setq prolabel_hvexag (getreal "\nNew vertical exaggeration: ")))
      ( (= prolabel_action 3) (setq prolabel_label  (prolabel_getlabel)))
      ( (= prolabel_action 4) (setq prolabel_height (getreal "\nCurb height (or 0 for single line): ")))
      ( (= prolabel_action 5) (setq prolabel_elprefix1 (getstring "\nNew prefix for bottom or single elevation: ")))
      ( (= prolabel_action 6) (setq prolabel_elprefix2 (getstring "\nNew prefix for top elevation: ")))
      ( T (prolabel_insertlabel))
    )
  )
)
(defun prolabel_getrefpoint ()
  (list 100.0 100.0 1000.0 1236.0)
)
(defun prolabel_insertlabel ( / plotpoint plotsta )
  (princ  prolabel_hvexag)
  (princ  prolabel_label) 
  (princ  prolabel_offset)
  (princ  prolabel_height)
  (princ  prolabel_elprefix1)
  (princ  prolabel_elprefix2)
  (setq
    plotpoint (getpoint "Point to label: ")
    plotsta (+ (caddr prolabel_reference) (- (car plotpoint) (car prolabel_reference)))
    plotelev (+ (cadddr prolabel_reference) (- (cadr plotpoint) (cadr prolabel_reference)))
  )
  (princ plotsta)
  (princ plotelev)
)

