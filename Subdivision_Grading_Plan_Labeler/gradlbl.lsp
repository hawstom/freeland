;;; GRADLBL.LSP
;;; (C) Copyright 2002 by Thomas Gail Haws and WRG Design Inc.
;;; GRADLBL.LSP labels civil engineering grading plan lots by picking.
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
;;; GRADLBL.LSP helps you label civil engineering grading plan lots in AutoCAD.
;;; 
;;; GETTING STARTED
;;; 
;;; DEVELOPMENT NOTES
;;;
;;; REVISION HISTORY
;;;
;;; Date     Programmer   Revision
;;; 20021125 TGH          Initial coding 2.0 hrs.  No functioning change to drawing.
;;; 20021210 TGH          Made values write to selected text or attribute. Made defaults save to Registry, AutoCAD area.
;;;
(DEFUN C:GG () (C:GRADLBL))
(DEFUN
          C:GRADLBL
                   (/ GRADLBL:ACTION GRADLBL:FFHEIGHT GRADLBL:PADHEIGHT GRADLBL:REARHEIGHT GRADLBL:TYPELEV
                   )
  (PROMPT
    "\nGRADLBL version 1.0, Copyright (C) 2002 Thomas Gail Haws and WRG Design Inc.
GRADLBL comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to modify and
redistribute it under the terms of the GNU General Public License.
The latest version of GRADLBL is always available at www.hawsedc.com"
  ) ;_ end of prompt
  (VL-LOAD-COM)
  (VL-REGISTRY-WRITE
    (STRCAT
      "HKEY_CURRENT_USER\\"
      (VLAX-PRODUCT-KEY)
      "\\HawsEDC"
    ) ;_ end of strcat
    ""
    ""
  ) ;_ end of vl-registry-write
  (VL-REGISTRY-WRITE
    (STRCAT
      "HKEY_CURRENT_USER\\"
      (VLAX-PRODUCT-KEY)
      "\\HawsEDC\\GRADLBL"
    ) ;_ end of strcat
    ""
    ""
  ) ;_ end of vl-registry-write
  (SETQ
    GRADLBL:TYPELEV
                       (ATOI
                         (COND
                           ((GRADLBL:GETDEFAULT "typelev"))
                           ((ALERT
                              "\nPlease start by using the Setup option\nto set lot grading defaults."
                            ) ;_ end of alert
                           )
                           ((GRADLBL:SETDEFAULT "typelev" "1190"))
                         ) ;_ end of cond
                       ) ;_ end of atoi
    GRADLBL:PADHEIGHT
                       (ATOF
                         (COND
                           ((GRADLBL:GETDEFAULT "padheight"))
                           ((GRADLBL:SETDEFAULT "padheight" "0.5"))
                         ) ;_ end of cond
                       ) ;_ end of atof
    GRADLBL:FFHEIGHT
                       (ATOF
                         (COND
                           ((GRADLBL:GETDEFAULT "ffheight"))
                           ((GRADLBL:SETDEFAULT "ffheight" "0.67"))
                         ) ;_ end of cond
                       ) ;_ end of atof
    GRADLBL:REARHEIGHT
                       (ATOF
                         (COND
                           ((GRADLBL:GETDEFAULT "rearheight"))
                           ((GRADLBL:SETDEFAULT "rearheight" "-0.2"))
                         ) ;_ end of cond
                       ) ;_ end of atof
  ) ;_ end of setq
  (WHILE
    (PROGN
      (INITGET "Setup")
      (SETQ
        GRADLBL:ACTION
         (NENTSEL "\nSetup/<select top of curb text>: ")
      ) ;_ end of setq
    ) ;_ end of progn
     (COND
       ((= GRADLBL:ACTION "Setup") (GRADLBL:SETUP))
       ((SETQ
          GRADLBL:ACTION
           (DISTOF
             (CDR (ASSOC 1 (ENTGET (CAR GRADLBL:ACTION))))
           ) ;_ end of distof
        ) ;_ end of setq
        (GRADLBL:DOLOT GRADLBL:ACTION)
       )
     ) ;_ end of cond
  ) ;_ end of while
  (PRINC)
) ;_ end of defun

(DEFUN
          GRADLBL:GETDEFAULT
                            (KEY)
  (VL-REGISTRY-READ
    (STRCAT
      "HKEY_CURRENT_USER\\"
      (VLAX-PRODUCT-KEY)
      "\\HawsEDC\\GRADLBL"
    ) ;_ end of strcat
    KEY
  ) ;_ end of vl-registry-read
) ;_ end of defun
(DEFUN
          GRADLBL:SETDEFAULT
                            (KEY STRING)
  (VL-REGISTRY-WRITE
    (STRCAT
      "HKEY_CURRENT_USER\\"
      (VLAX-PRODUCT-KEY)
      "\\HawsEDC\\GRADLBL"
    ) ;_ end of strcat
    KEY
    STRING
  ) ;_ end of vl-registry-write
) ;_ end of defun

(DEFUN
          GRADLBL:SETUP
                       (/ GRADLBL:ACTION GRADLBL:FFHEIGHT GRADLBL:PADHEIGHT GRADLBL:REARHEIGHT GRADLBL:TYPELEV TEMP
                       )
  (WHILE
    (PROGN
      (INITGET "Typical Pad Ff Rear")
      (SETQ
        GRADLBL:ACTION
         (GETKWORD
           (STRCAT
             "\nTypical project elevation ("
             (GRADLBL:GETDEFAULT "typelev")
             ")/Pad height ("
             (GRADLBL:GETDEFAULT "padheight")
             ")/Ff height ("
             (GRADLBL:GETDEFAULT "ffheight")
             ")/Rear yard height ("
             (GRADLBL:GETDEFAULT "rearheight")
             "): "
           ) ;_ end of strcat
         ) ;_ end of getkword
      ) ;_ end of setq
    ) ;_ end of progn
     (COND
       ((= GRADLBL:ACTION "Typical")
        (IF (SETQ
              TEMP
               (GETINT
                 (STRCAT
                   "\nEnter a typical project elevation (to nearest foot) <"
                   (GRADLBL:GETDEFAULT "typelev")
                   ">: "
                 ) ;_ end of strcat
               ) ;_ end of getint
            ) ;_ end of setq
          (GRADLBL:SETDEFAULT
            "typelev"
            (ITOA (SETQ GRADLBL:TYPELEV TEMP))
          ) ;_ end of GRADLBL:setdefault
        ) ;_ end of if
       )
       ((= GRADLBL:ACTION "Pad")
        (IF (SETQ
              TEMP
               (GETREAL
                 (STRCAT
                   "\nHeight of pad above top of curb <"
                   (GRADLBL:GETDEFAULT "padheight")
                   ">: "
                 ) ;_ end of strcat
               ) ;_ end of getreal
            ) ;_ end of setq
          (GRADLBL:SETDEFAULT
            "padheight"
            (RTOS (SETQ GRADLBL:PADHEIGHT TEMP) 2 2)
          ) ;_ end of GRADLBL:setdefault
        ) ;_ end of if
       )
       ((= GRADLBL:ACTION "Ff")
        (IF (SETQ
              TEMP
               (GETREAL
                 (STRCAT
                   "\nHeight of finished floor above pad: <"
                   (GRADLBL:GETDEFAULT "ffheight")
                   ">: "
                 ) ;_ end of strcat
               ) ;_ end of getreal
            ) ;_ end of setq
          (GRADLBL:SETDEFAULT
            "ffheight"
            (RTOS (SETQ GRADLBL:FFHEIGHT TEMP) 2 2)
          ) ;_ end of GRADLBL:setdefault
        ) ;_ end of if
       )
       ((= GRADLBL:ACTION "Rear")
        (IF (SETQ
              TEMP
               (GETREAL
                 (STRCAT
                   "\nHeight of rear yard above pad: <"
                   (GRADLBL:GETDEFAULT "rearheight")
                   ">: "
                 ) ;_ end of strcat
               ) ;_ end of getreal
            ) ;_ end of setq
          (GRADLBL:SETDEFAULT
            "rearheight"
            (RTOS (SETQ GRADLBL:REARHEIGHT TEMP) 2 2)
          ) ;_ end of GRADLBL:setdefault
        ) ;_ end of if
       )
     ) ;_ end of cond
  ) ;_ end of while
) ;_ end of defun


(DEFUN
          GRADLBL:DOLOT
                       (GRADLBL:TCELEVSHORT / EN1 ENTLST GRADLBL:BASE GRADLBL:DELTAPAD GRADLBL:EGPAD GRADLBL:ENPAD
                        GRADLBL:ESPAD GRADLBL:FFELEV GRADLBL:FFELEVSHORT GRADLBL:FFHEIGHT GRADLBL:PADELEV
                        GRADLBL:PADELEVSHORT GRADLBL:PADHEIGHT GRADLBL:REARELEV GRADLBL:REARELEVSHORT
                        GRADLBL:REARHEIGHT GRADLBL:TCELEV GRADLBL:TYPELEV
                       )
  (SETQ
    GRADLBL:TYPELEV    (ATOI (GRADLBL:GETDEFAULT "typelev"))
    GRADLBL:PADHEIGHT  (ATOF (GRADLBL:GETDEFAULT "padheight"))
    GRADLBL:FFHEIGHT   (ATOF (GRADLBL:GETDEFAULT "ffheight"))
    GRADLBL:REARHEIGHT (ATOF (GRADLBL:GETDEFAULT "rearheight"))
    GRADLBL:BASE       (- GRADLBL:TYPELEV (REM GRADLBL:TYPELEV 100))
    GRADLBL:TCELEV
                       (+ GRADLBL:TCELEVSHORT GRADLBL:BASE)
  ) ;_ end of setq
  (COND
    ((< 50.0 (- GRADLBL:TCELEV GRADLBL:TYPELEV))
     (SETQ GRADLBL:TCELEV (- GRADLBL:TCELEV 100))
    )
    ((> -50.0 (- GRADLBL:TCELEV GRADLBL:TYPELEV))
     (SETQ GRADLBL:TCELEV (+ GRADLBL:TCELEV 100))
    )
  ) ;_ end of cond
  (SETQ
    GRADLBL:PADELEV
     (+ GRADLBL:TCELEV GRADLBL:PADHEIGHT)
    GRADLBL:FFELEV
     (+ GRADLBL:PADELEV GRADLBL:FFHEIGHT)
    GRADLBL:REARELEV
     (+ GRADLBL:PADELEV GRADLBL:REARHEIGHT)
    GRADLBL:PADELEVSHORT
     (REM GRADLBL:PADELEV 100)
    GRADLBL:FFELEVSHORT
     (REM GRADLBL:FFELEV 100)
    GRADLBL:REARELEVSHORT
     (REM GRADLBL:REARELEV 100)
  ) ;_ end of setq
  (WHILE
    (NOT
      (SETQ GRADLBL:ESPAD
             (NENTSEL
               (STRCAT "\nPad polyline to move to elevation "
                       (RTOS GRADLBL:PADELEV 2 2)
                       ": "
               ) ;_ end of STRCAT
             ) ;_ end of NENTSEL
      ) ;_ end of SETQ
    ) ;_ end of NOT
     (PROMPT "\nEntity selection required: ")
  ) ;_ end of WHILE
  (SETQ
    GRADLBL:ENPAD    (CAR GRADLBL:ESPAD)
    GRADLBL:EGPAD    (ENTGET GRADLBL:ENPAD)
    GRADLBL:DELTAPAD (- GRADLBL:PADELEV
                        (COND ((CDR (ASSOC 38 GRADLBL:EGPAD)))
                              (T (CADDDR (ASSOC 10 GRADLBL:EGPAD)))
                        ) ;_ end of COND
                     ) ;_ end of -
  ) ;_ end of SETQ
  (COMMAND "._move"
           GRADLBL:ENPAD
           ""
           "none"
           (LIST 0.0 0.0 GRADLBL:DELTAPAD)
           ""
  ) ;_ end of COMMAND
  (SETQ EN1 (CAR (NENTSEL "\nPad label to change: ")))
  (SETQ ENTLST (ENTGET EN1))
  (ENTMOD
    (SUBST
      (CONS 1 (STRCAT "PAD=" (RTOS GRADLBL:PADELEVSHORT 2 2)))
      (ASSOC 1 ENTLST)
      ENTLST
    ) ;_ end of subst
  ) ;_ end of entmod
  (ENTUPD EN1)
  (IF
    (SETQ EN1 (CAR (NENTSEL "\nFF label to change: ")))
     (PROGN
       (SETQ ENTLST (ENTGET EN1))
       (ENTMOD
         (SUBST
           (CONS 1 (STRCAT "FF=" (RTOS GRADLBL:FFELEVSHORT 2 2)))
           (ASSOC 1 ENTLST)
           ENTLST
         ) ;_ end of subst
       ) ;_ end of entmod
       (ENTUPD EN1)
     ) ;_ end of progn
  ) ;_ end of if
  (WHILE
    (SETQ EN1 (CAR (NENTSEL "\nRear lot label to change: ")))
     (SETQ ENTLST (ENTGET EN1))
     (ENTMOD
       (SUBST
         (CONS 1 (RTOS GRADLBL:REARELEVSHORT 2 2))
         (ASSOC 1 ENTLST)
         ENTLST
       ) ;_ end of subst
     ) ;_ end of entmod
     (ENTUPD EN1)
  ) ;_ end of while
) ;_ end of defun
