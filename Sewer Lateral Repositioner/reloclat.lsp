;;; Sewer Laterals Relocater
;;; LATRELOC.LSP
;;;
;;; Moves a lateral object to a new distance from the main line endpoint.
;;;
;;; Copyright 2010 Thomas Gail Haws
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
;;; DESCRIPTION
;;;
;;; LATRELOC is a tool that moves a lateral object to put its endpoint at a
;;; specified new distance from the selected end of a selected lateral.
;;;
;;; Revisions
;;; Revisions
;;; 20110620  TGH     New programming
;;;
;;; The following line defines the RLL command as a shortcut for the RELOCLAT command.
(DEFUN C:RLL () (C:RELOCLAT))

(DEFUN C:RELOCLAT (/ RLL-ALIGNMENT RLL-LATERAL)
  ;; Loop prompt user for the end of a main line until user hits return or selects nothing.
  ;; RLL-GET-ALIGNMENT returns (list BASEPOINT BASEANG)
  (WHILE (SETQ RLL-ALIGNMENT (RLL-GET-ALIGNMENT))
    ;; Loop prompt user for the end of a lateral object
    (WHILE (SETQ RLL-LATERAL (RLL-GET-LATERAL))
      ;; Prompt user for the new lateral distance from main end.
      (SETQ RLL-DISTANCE (RLL-GET-LATERAL-DISTANCE RLL-ALIGNMENT))
      ;; Move lateral to new distance
      (RLL-MOVE-LATERAL RLL-LATERAL RLL-ALIGNMENT RLL-DISTANCE)
    )
  )
  ;; Exit quietly
  (PRINC)
)

(DEFUN RLL-GET-ALIGNMENT (/ BASEANG BASEPOINT ESMAIN)
  ;; Prompt for main line.
  (SETQ ESMAIN (ENTSEL "\nSelect main line toward reference end: "))
  ;; If main is selected, return the base point and angle for polar positioning of laterals.
  (COND
    (ESMAIN
     (SETQ BASEPOINT (OSNAP (CADR ESMAIN) "endp")
           BASEANG   (ANGLE BASEPOINT (OSNAP (CADR ESMAIN) "near"))
     )
     (LIST BASEPOINT BASEANG)
    )
  )
)
(DEFUN RLL-GET-LATERAL (/ BASEANG BASEPOINT ESLATERAL)
  ;; Prompt for lateral.
  (SETQ ESLATERAL (ENTSEL "\nSelect lateral toward main: "))
  ;; If lateral is selected, return the entsel for movement.
  ;; Yeah, this is unnecessary code, but maybe I'll want to throw in some validation later.
  (COND
    (ESLATERAL)
  )
)
(DEFUN RLL-GET-LATERAL-DISTANCE (RLL-ALIGNMENT / RLL-DISTANCE)
  (SETQ RLL-DISTANCE
         (GETDIST (CAR RLL-ALIGNMENT) "\nDistance to lateral: ")
  )
  ;; If distance is entered, return the distance for movement.
  ;; Yeah, this is unnecessary code, but maybe I'll want to throw in some validation later.
  (COND
    (RLL-DISTANCE)
  )
)
(DEFUN RLL-MOVE-LATERAL (RLL-LATERAL RLL-ALIGNMENT RLL-DISTANCE)
  ;; If all data validates, move lateral.
  ;; Yeah, this is overkill for a little routine like this, but it's good practice.
  (COND
    ((AND
       (= (TYPE (CAR RLL-LATERAL)) 'ENAME)
       (= (TYPE (CADR RLL-LATERAL)) 'LIST)
       (= (TYPE (CAR RLL-ALIGNMENT)) 'LIST)
       (= (TYPE (CADR RLL-ALIGNMENT)) 'REAL)
       (= (TYPE (CADR RLL-ALIGNMENT)) 'REAL)
       (= (TYPE RLL-DISTANCE) 'REAL)
     )
     (COMMAND "._move"
              (CAR RLL-LATERAL)
              ""
              (OSNAP (CADR RLL-LATERAL) "endp")
              (POLAR (CAR RLL-ALIGNMENT)
                     (CADR RLL-ALIGNMENT)
                     RLL-DISTANCE
              )
     )
    )
  )
)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 9 2 2 1 nil T nil T)
;*** DO NOT add text below the comment! ***|;
