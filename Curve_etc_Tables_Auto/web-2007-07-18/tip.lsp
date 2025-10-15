'()
;;;TIP.LSP shows a tip using TIP.DVB until user unchecks box
;;;Copyright 2004 by Thomas Gail Haws
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
   C:TIP
	()
  (HAWS-TIP
    0
    "Use TIP.LSP and TIP.DVB to show your users a tip until they uncheck the box below."
  )
  (HAWS-TIP
    1
    "TIP.LSP stores the list of unchecked tips at the top of the file TIPS.LSP."
  )
  (HAWS-TIP
    2
    "Use VBAMAN and VBAIDE to adjust the size of this form as required."
  )
)
(DEFUN
   HAWS-TIP
      (ITIP TIPTEXT / FNAME LINELIST RDLIN TIPLIST USERSOLD1)
  (SETQ
    FNAME
     (FINDFILE "tip.lsp")
    F1 (OPEN FNAME "r")
    RDLIN
     (READ-LINE F1)
  )
  (SETQ F1 (CLOSE F1))
  (COND
    ((AND
       RDLIN
       (SETQ RDLIN (READ RDLIN))
       (= 'LIST (TYPE RDLIN))
       (MEMBER ITIP (SETQ TIPLIST (EVAL RDLIN)))
     )
    )
    (T
     (COND
       ((>= (ATOF (GETVAR "acadver")) 15)
	(SETQ
	  USERS1OLD
	   (GETVAR "users1")
	) ;_ end of setq
	(SETVAR "users1" TIPTEXT)
	(COMMAND "-vbarun" "tip.dvb!modTip.Tip")
	(COND
	  ((= (GETVAR "users1") "BooleanFalse")
	   (SETVAR "users1" USERS1OLD)
	   (SETQ
	     F1	(OPEN FNAME "r")
	     RDLIN
	      (READ-LINE F1)
	     LINELIST
		(COND
		  (TIPLIST
		   (LIST (CONS ITIP TIPLIST))
		  )
		  ((LIST rdlin (LIST ITIP)))
		)
	   )
	   (WHILE (SETQ RDLIN (READ-LINE F1))
	     (SETQ LINELIST (CONS RDLIN LINELIST))
	   )
	   (SETQ F1 (CLOSE F1))
	   (COND
	     ((NOT (SETQ F1 (OPEN FNAME "w")))
	      (ALERT
		(STRCAT
		  "\nThe tip silencing request you just submitted\ncould not be recorded in "
		  FNAME
		  ".\nThe file or folder might be read-only.\n\nPlease copy "
		  FNAME
		  " to a writable location in AutoCAD's search path or try again later."
		  "\n\nIf this is a problem, contact Tom Haws for a different recording solution."
		 )
	      )
	     )
	     (T
	      (PRINC "'" F1)
	      (FOREACH
		 LINE
		     (REVERSE LINELIST)
		(PRINC LINE F1)
		(PRINC "\n" F1)
	      )
	      (SETQ F1 (CLOSE F1))
	     )
	   )
	  )
	)
       )
       (T
	(ALERT
	  "\nSorry.  I don't think this version of AutoCAD can run a Visual Basic Script."
	) ;_ end of alert
       )
     ) ;_ end of COND
    )
  )
) ;_ end of defun
