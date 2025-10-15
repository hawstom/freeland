;;;
;;;
;;; BuildVehicle.LSP
;;; Copyright 2006 Stephen Hitchcox
;;; BuildVehicle.LSP draws vehicles for use by Tturn.lsp in AutoCAD.
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
;;; copyright owner at hdesign@ica.net
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
;;; OVERVIEW
;;; BuildVehicle.LSP draws attributed blocks of vehicles that are required
;;; by Tturn.lsp, for approximating the paths of trucks as they drive.
;;;
;;; GETTING STARTED
;;; Load and run BuildVehicle.  It will ask you for all of the parameters
;;; for your vehicle, and draw a unique attributed block.  You can build a library
;;; of vehicles for future use.  BuildVehicle.lsp runs using "BV" or "BuildVehicle"
;;; from the command line.  Axles should be the "centroid" of any group of multiple
;;; axles.
;;;
;;; Data for turning angles and time to turn is for future use, so enter
;;; dummy data if you do not know it.
;;;
;;; enter "N" for no trailer, but still give place holder data for the non-existent
;;; trailer.  It will not be drawn.
;;;
;;; The parameters are used to build a scale block of the vehicle you are
;;; defining, which is made into a block.
;;;
;;; You can change the attributes in the block if you make a mistake, but the block
;;; itself does not change size (it is not parametric).
;;;
;;; If you make a new block with the same name as an existing one, it will overwrite
;;; the old one, or perhaps fail.  If this happens, erase all errant blocks, and purge
;;; the old block from the drawing file.
;;;
;;; Remember, there is almost no error correction in this program.  If you enter
;;; impossible geometry, the program will happily draw it.  Please report issues and
;;; requested functionality to the author.
;;;
;;;
;;; REFERENCE
;;; Vehicle dimensions (ft)                  Min. Outside   Min. Inside
;;; Vehicle                Width  WB1  WB2   Rad            Rad. (check)
;;; P (passenger)          7       11        24.0           13.8
;;; SU (single truck)      8.5     20        42.0           27.8
;;; BUS                    8.5     25        42.0           24.4
;;; WB-40                  8.5     13   27   40.0           18.9
;;; WB-50                  8.5     20   30   45.0           19.2
;;;
;;; Development Notes:
;;;
;;; 1) implement better error correction
;;;
;;; 2) collect and share correctly dimensioned standard vehicles
;;;
;;; 3) revise to not require data for non-existent trailers, and to allow multiple
;;; trailers
;;; 4) revise to draw tires centred on the tire paths
;;;

;;;C:BV short form call for (C:BUILDVEHICLE)
(DEFUN
	  C:BV
	      ()
  (C:BUILDVEHICLE)
)
(DEFUN
   C:BUILDVEHICLE
		 ()
  (SETQ VEHNAME (GETSTRING T "\nEnter name of vehicle: "))
  (INITGET 1 "Metric Imperial")
  (SETQ
    VEHUNITS
     (GETSTRING "\nSystem of units [Metric/Imperial]: ")
  )
  (SETQ
    STARTDRAWPOINT
     (GETPOINT "\nPick midpoint of front bumper:  ")
  )
  (SETQ
    VEHBODYLENGTH
     (GETDIST STARTDRAWPOINT "\nLength of vehicle: ")
  )
  (SETQ
    VEHWIDTH
     (* 2 (GETDIST STARTDRAWPOINT "\nHalf width of vehicle: "))
  )
  ;; Record VEHWIDTH
  ;; MAKEATTRIBUTE usage: (MakeAttribute InsPoint InsAngle Tag Value AttribLayer AttPrompt TextSize)
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT PI (/ VEHWIDTH 15))
    90.0
    "VEHWIDTH"
    (RTOS VEHWIDTH)
    "AttributeLayer"
    "Vehicle width"
    (/ VEHWIDTH 15)
  )
  (SETQ VEHBLOCKLIST (SSADD (ENTLAST)))
  ;; Record VEHBODYLENGTH
  (MAKEATTRIBUTE
    (POLAR
      (POLAR STARTDRAWPOINT (* 1.5 PI) (* VEHWIDTH 0.55))
      0.0
      (/ VEHBODYLENGTH 2)
    )
    0.0
    "VEHBODYLENGTH"
    (RTOS VEHBODYLENGTH)
    "AttributeLayer"
    "Vehicle body length"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw BODY
  (DRAWBOX
    (POLAR STARTDRAWPOINT (* 1.5 PI) (/ VEHWIDTH 2))
    VEHBODYLENGTH
    VEHWIDTH
    "truckbody"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (SETQ
    VEHFRONTHANG
     (GETREAL "\nEnter front overhang from bumper to axle: ")
  )
  ;; Record front axle offset
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (/ VEHFRONTHANG 2))
    0.0
    "VEHFRONTHANG"
    (RTOS VEHFRONTHANG)
    "AttributeLayer"
    "Vehicle front overhang"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (SETQ
    VEHWHEELBASE
     (GETREAL "\nEnter vehicle wheelbase: ")
  )
  (IF (< VEHBODYLENGTH (+ VEHFRONTHANG VEHWHEELBASE))
    (PRINC
      "\nCaution, vehicle length is shorter than sum of front overhang and wheelbase.  Errors could occur."
    )
  )
  ;; Record rear axle location
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (+ VEHFRONTHANG VEHWHEELBASE))
    90
    "VEHWHEELBASE"
    (RTOS VEHWHEELBASE)
    "AttributeLayer"
    "Vehicle wheelbase"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Record name of vehicle
  (MAKEATTRIBUTE
    (POLAR
      STARTDRAWPOINT
      0.0
      (+ VEHFRONTHANG (/ VEHWHEELBASE 2))
    )
    0.0
    "VEHNAME"
    VEHNAME
    "AttributeLayer"
    "Vehicle name"
    (/ VEHWIDTH 10)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Record units of vehicle
  (MAKEATTRIBUTE
    (POLAR
      (POLAR STARTDRAWPOINT (* 1.5 PI) (* VEHWIDTH 0.25))
      0.0
      (/ VEHBODYLENGTH 2)
    )
    0.0
    "VEHUNITS"
    VEHUNITS
    "AttributeLayer"
    "Vehicle units (Metric or Imperial)"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
;; VehSteerLock isn't currently functional.
;| (SETQ VEHSTEERLOCK (GETREAL "\nEnter vehicle Steering Lock Angle:  "))
  ;; Record vehicle Steering Lock Angle
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (/ VEHFRONTHANG 3))
    90.0
    "VEHSTEERLOCK"
    (RTOS VEHSTEERLOCK)
    "AttributeLayer"
    "Vehicle steering lock angle"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  |;
;;; VEHSTEERLOCKTIME isn't currently functional.
;|  (SETQ
    VEHSTEERLOCKTIME
     (GETREAL "\nEnter vehicle steering lock time:  ")
  )
  ;; Record vehicle steer lock time
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (* 2 (/ VEHFRONTHANG 3)))
    90.0
    "VEHSTEERLOCKTIME"
    (RTOS VEHSTEERLOCKTIME)
    "AttributeLayer"
    "Vehicle steer lock time"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  |;
  (SETQ
    VEHWHEELWIDTH
     (GETREAL
       "\nEnter maximum axle width to outside of wheels:  "
     )
  )
  ;; Record wheel width
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 VEHFRONTHANG)
    90.0
    "VEHWHEELWIDTH"
    (RTOS VEHWHEELWIDTH)
    "AttributeLayer"
    "Vehicle wheel width"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw tires
  (SETQ WHEELWIDTH (/ VEHWIDTH 10))
  (SETQ WHEELLENGTH (/ VEHBODYLENGTH 10))
  ;; DRAW FRONT LEFT wheel
  (SETQ
    WHEELFLSTARTX
     (+	(CAR STARTDRAWPOINT)
	(- VEHFRONTHANG (/ WHEELLENGTH 2))
     )
  )
  (SETQ WHEELFLSTARTY (- (CADR STARTDRAWPOINT) (/ VEHWHEELWIDTH 2)))
  (DRAWBOX
    (LIST WHEELFLSTARTX WHEELFLSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "truckbody"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw front right wheel
  (SETQ
    WHEELFRSTARTX
     (+	(CAR STARTDRAWPOINT)
	(- VEHFRONTHANG (/ WHEELLENGTH 2))
     )
  )
  (SETQ
    WHEELFRSTARTY
     (+	(CADR STARTDRAWPOINT)
	(- (/ VEHWHEELWIDTH 2) WHEELWIDTH)
     )
  )
  (DRAWBOX
    (LIST WHEELFRSTARTX WHEELFRSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "truckbody"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw rear left wheel
  (SETQ
    WHEELRLSTARTX
     (+	(CAR STARTDRAWPOINT)
	(- VEHFRONTHANG (/ WHEELLENGTH 2))
	VEHWHEELBASE
     )
  )
  (SETQ WHEELRLSTARTY (- (CADR STARTDRAWPOINT) (/ VEHWHEELWIDTH 2)))
  (DRAWBOX
    (LIST WHEELRLSTARTX WHEELRLSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "truckbody"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw rear right wheel
  (SETQ
    WHEELRRSTARTX
     (+	(CAR STARTDRAWPOINT)
	(- VEHFRONTHANG (/ WHEELLENGTH 2))
	VEHWHEELBASE
     )
  )
  (SETQ
    WHEELRRSTARTY
     (+	(CADR STARTDRAWPOINT)
	(- (/ VEHWHEELWIDTH 2) WHEELWIDTH)
     )
  )
  (DRAWBOX
    (LIST WHEELRRSTARTX WHEELRRSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "truckbody"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (SETQ
    VEHREARHITCH
     (GETREAL
       "\nEnter distance from rear axle to hitch (forward is POSITIVE):  "
     )
  )
  ;;Draw hitch
  (SETQ
    CIRCLELIST
     (LIST
       (CONS 0 "CIRCLE")
       (CONS 100 "AcDbEntity")
       (CONS 8 "truckbody")
       (CONS 100 "AcDbCircle")
       (CONS 40 (/ VEHWIDTH 10))
       (CONS
	 10
	 (POLAR
	   STARTDRAWPOINT
	   0.0
	   (- (+ VEHFRONTHANG VEHWHEELBASE) VEHREARHITCH)
	 )
       )
     )
  )
  (ENTMAKE CIRCLELIST)
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (MAKEATTRIBUTE
    (POLAR
      STARTDRAWPOINT
      0.0
      (- (+ VEHFRONTHANG VEHWHEELBASE) VEHREARHITCH)
    )
    90.0
    "VEHREARHITCH"
    (RTOS VEHREARHITCH)
    "AttributeLayer"
    "Vehicle rear hitch location (forward is POSITIVE): "
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; End of main vehicle entry
  ;; Start trailer entry
  (INITGET 1 "Yes No")
  (SETQ
    TRAILHAVE
     (GETKWORD
       "\nDoes unit have a trailer? Yes/No:  "
     )
  )
  (MAKEATTRIBUTE
    (POLAR
      STARTDRAWPOINT
      0.0
      (+ VEHFRONTHANG VEHWHEELBASE (* VEHREARHITCH 0.5))
    )
    90.0
    "TRAILHAVE"
    TRAILHAVE
    "AttributeLayer"
    "Does unit have a trailer"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (COND
    ((= TRAILHAVE "Yes")
     ;|
     ;; Vehicle articulation angle not functional
     ;;  (setq VehArtAngle 20.0)
     (SETQ
       VEHARTANGLE
	(GETREAL "\nEnter vehicle articulation angle:  ")
     )
     ;; Record wheel width
     (MAKEATTRIBUTE
       (POLAR
	 STARTDRAWPOINT
	 0.0
	 (+ VEHFRONTHANG VEHWHEELBASE (* VEHREARHITCH 1.5))
       )
       90.0
       "VEHARTANGLE"
       (RTOS VEHARTANGLE)
       "AttributeLayer"
       "Vehicle articulation angle"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     |;
     (SETQ TRAILNAME (GETSTRING "\nEnter name of trailer:  "))
     (INITGET 1 "Metric Imperial")
     (SETQ
       TRAILUNITS
	(GETKWORD "\nSystem of units [Metric/Imperial]:  ")
     )
     (SETQ
       TRAILERHITCHTOWHEEL
	(GETREAL
	  "\nEnter distance from hitch to trailer wheel:  "
	)
     )
     (SETQ
       TRAILERWHEELWIDTH
	(GETREAL "\nEnter width of trailer wheels:  ")
     )
     (SETQ
       TRAILERFRONTHANG
	(GETREAL
	  "\nEnter overhang distance from hitch to front of trailer (forward is POSITIVE):  "
	)
     )
     (SETQ
       TRAILERBODYLENGTH
	(GETREAL "\nEnter overall trailer length:  ")
     )
     (SETQ TRAILERWIDTH (GETREAL "\nEnter trailer width:  "))
     ;; Record trailer Length
     (MAKEATTRIBUTE
       (POLAR
	 (POLAR STARTDRAWPOINT (* 1.5 PI) (* TRAILERWIDTH 0.55))
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    (/ TRAILERBODYLENGTH 2)
	 )
       )
       0.0
       "TRAILERBODYLENGTH"
       (RTOS TRAILERBODYLENGTH)
       "AttributeLayer"
       "Trailer body length"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailer name
     (MAKEATTRIBUTE
       (POLAR
	 STARTDRAWPOINT
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    (/ TRAILERBODYLENGTH 2)
	 )
       )
       0.0
       "TRAILNAME"
       TRAILNAME
       "AttributeLayer"
       "Trailer name"
       (/ VEHWIDTH 10)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailer units
     (MAKEATTRIBUTE
       (POLAR
	 (POLAR STARTDRAWPOINT (* 1.5 PI) (* TRAILERWIDTH 0.25))
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    (/ TRAILERBODYLENGTH 2)
	 )
       )
       0.0
       "TRAILUNITS"
       TRAILUNITS
       "AttributeLayer"
       "Trailer units"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailerfronthang
     (MAKEATTRIBUTE
       (POLAR
	 (POLAR STARTDRAWPOINT (* 1.5 PI) (* TRAILERWIDTH 0.55))
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    (- VEHREARHITCH (/ TRAILERFRONTHANG 2))
	 )
       )
       0.0
       "TRAILERFRONTHANG"
       (RTOS TRAILERFRONTHANG)
       "AttributeLayer"
       "Trailer front overhang"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailer to wheel length
     (MAKEATTRIBUTE
       (POLAR
	 (POLAR STARTDRAWPOINT (* 0.5 PI) (* TRAILERWIDTH 0.55))
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    (/ TRAILERBODYLENGTH 2)
	 )
       )
       0.0
       "TRAILERHITCHTOWHEEL"
       (RTOS TRAILERHITCHTOWHEEL)
       "AttributeLayer"
       "Trailer hitch to wheel length"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailer width
     (MAKEATTRIBUTE
       (POLAR
	 STARTDRAWPOINT
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    (- TRAILERBODYLENGTH TRAILERFRONTHANG)
	 )
       )
       90.0
       "TRAILERWIDTH"
       (RTOS TRAILERWIDTH)
       "AttributeLayer"
       "Trailer width"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Record trailer wheel width
     (MAKEATTRIBUTE
       (POLAR
	 STARTDRAWPOINT
	 0.0
	 (+ VEHFRONTHANG
	    VEHWHEELBASE
	    VEHREARHITCH
	    TRAILERHITCHTOWHEEL
	 )
       )
       90.0
       "TRAILERWHEELWIDTH"
       (RTOS TRAILERWHEELWIDTH)
       "AttributeLayer"
       "Trailer wheels width (to outside)"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Draw trailer
     (DRAWBOX
       (POLAR
	 (POLAR
	   STARTDRAWPOINT
	   0.0
	   (+ VEHFRONTHANG
	      VEHWHEELBASE
	      (- VEHREARHITCH TRAILERFRONTHANG)
	   )
	 )
	 (* 1.5 PI)
	 (/ TRAILERWIDTH 2)
       )
       TRAILERBODYLENGTH
       TRAILERWIDTH
       "trailerbody"
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Draw rear left trailer tire
     (SETQ
       WHEELRLSTARTX
	(- (+ (CAR STARTDRAWPOINT)
	      VEHFRONTHANG
	      VEHWHEELBASE
	      VEHREARHITCH
	      TRAILERHITCHTOWHEEL
	   )
	   (/ WHEELLENGTH 2)
	)
     )
     (SETQ
       WHEELRLSTARTY
	(- (CADR STARTDRAWPOINT) (/ TRAILERWHEELWIDTH 2))
     )
     (DRAWBOX
       (LIST WHEELRLSTARTX WHEELRLSTARTY)
       WHEELLENGTH
       WHEELWIDTH
       "trailerbody"
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Draw rear right trailer tire
     (SETQ
       WHEELRRSTARTX
	(- (+ (CAR STARTDRAWPOINT)
	      VEHFRONTHANG
	      VEHWHEELBASE
	      VEHREARHITCH
	      TRAILERHITCHTOWHEEL
	   )
	   (/ WHEELLENGTH 2)
	)
     )
     (SETQ
       WHEELRRSTARTY
	(+ (CADR STARTDRAWPOINT)
	   (- (/ TRAILERWHEELWIDTH 2) WHEELWIDTH)
	)
     )
     (DRAWBOX
       (LIST WHEELRRSTARTX WHEELRRSTARTY)
       WHEELLENGTH
       WHEELWIDTH
       "trailerbody"
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
    )
  )
  ;;(makeblock VehBlockList StartDrawPoint (strcat "VEHICLELIB" VEHNAME))
  ;;makes a block without accessible attributes, needs fix
  (COMMAND
    "-block"
    (STRCAT "VEHICLELIB" VEHNAME)
    STARTDRAWPOINT
    VEHBLOCKLIST
    ""
  )
  (COMMAND
    "-insert"
    (STRCAT "VEHICLELIB" VEHNAME)
    STARTDRAWPOINT
    ""
    ""
    ""
  )
  (ALERT
    (PRINC
      "\nDefinitions complete.  Move vehicle into initial position and run TURN to track path."
    )
  )
  (PRINC)
)
;;;==========================================
;;; End Buildvehicle                        |
;;;==========================================

;;;Start buildvehicle subfunctions
(DEFUN
	  DRAWBOX
		 (STARTPOINT XLENGTH YLENGTH BOXLAYER /)
  (SETQ BOXPOLYLIST NIL)
  (SETQ
    BOXPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 8 BOXLAYER)
       ;; layer name
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS
	 10
	 STARTPOINT
       )
       BOXPOLYLIST
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR STARTPOINT 0.0 XLENGTH)
       )
       BOXPOLYLIST
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR (POLAR STARTPOINT 0.0 XLENGTH) (/ PI 2) YLENGTH)
       )
       BOXPOLYLIST
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR STARTPOINT (/ PI 2) YLENGTH)
       )
       BOXPOLYLIST
     )
  )
  (SETQ BOXPOLYLIST (REVERSE BOXPOLYLIST))
  (ENTMAKE BOXPOLYLIST)
)
;;;
;;;
;;;
(DEFUN
	  MAKEATTRIBUTE
	  (INSPOINT INSANGLE TAG VALUE ATTRIBLAYER ATTPROMPT TEXTSIZE)
  (SETQ ATTRIBUTELIST NIL)
  (SETQ
    ATTRIBUTELIST
     (LIST
       (CONS 0 "ATTDEF")
       (CONS 100 "AcDbEntity")
       (CONS 100 "AcDbText")
       (CONS 100 "AcDbAttributeDefinition")
       (CONS 1 VALUE)
       (CONS 2 TAG)
       (CONS 3 ATTPROMPT)
       (CONS 8 ATTRIBLAYER)
       (CONS 10 INSPOINT)		; not applicable insert point
       (CONS 11 INSPOINT)		; this is the real insert point
       (CONS 40 TEXTSIZE)
       (CONS 50 (* (/ INSANGLE 360) (* 2 PI)))
       (CONS 70 8)
       (CONS 72 4)
     )
  )
  (ENTMAKE ATTRIBUTELIST)
)
;;;====================================================================
;;;
;;;
;;;(defun makeblock (sset baspoint name / i e en blocktype)  ;;;  faster and neater than command -block, but needs fix
;;;(if (not sset) (setq sset (ssadd)))
;;;(if (or (/= 'STR (type name)) (= "" name)) (setq name "*A"))
;;;(if (= (substr name 1 1) "*")
;;;        (setq blocktype 1 name "*A")
;;;        (setq blocktype 0)
;;;)
;;;  (setq blocktype 2)  ;; added by srh
;;;(entmake (append
;;;        '((0 . "BLOCK"))
;;;        (list (cons 2  name))
;;;        (list (cons 70 blocktype))
;;;        (list (cons 10 baspoint))
;;;))
;;;(setq i -1)
;;;(while (setq e (ssname sset (setq i (1+ i))))
;;;        (cond
;;;                ((/= 1 (cdr (assoc 66 (entget e))))
;;;                        (if (entget e) (progn
;;;                                (entmake (entget e '("*")))
;;;                                (entdel e)
;;;                        ))
;;;                )
;;;                ((= 1 (cdr (assoc 66 (entget e))))
;;;                        (if (entget e) (progn
;;;                                (entmake (entget e '("*")))
;;;                                (setq en e)
;;;                                (while (/= "SEQEND" (cdr (assoc 0 (entget en))))
;;;                                        (setq en (entnext en))
;;;                                        (entmake (entget en '("*")))
;;;                                )
;;;                                (entdel e)
;;;                        ))
;;;                )
;;;        )
;;;)
;;;(setq name (entmake '((0 . "ENDBLK"))))
;;;(if name (progn
;;;        (entmake (append
;;;                '((0 . "INSERT"))
;;;                (list (cons 2 name))
;;;                (list (cons 10 baspoint))
;;;        ))
;;;
;;;))
;;;(if name (entlast) nil)
;;;)
;;;
;;;(defun c:makeblock ()
;;;(makeblock (ssget) (getpoint "\nInsertionpoint: ") (getstring "\nName:
;;;"))
;;;)

;;;
;;;
;;; TURN.LSP
;;; Copyright 2006 Thomas Gail Haws
;;; Copyright 2006 Stephen Hitchcox
;;; TURN.LSP draws vehicle turning paths in AutoCAD.
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
;;; partial copyright owner at hawstom@sprintmail.com or see www.hawsedc.com.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License on the World Wide Web for more details.
;;;
;;; OVERVIEW
;;; TTURN.LSP draws a polyline along a theoretical rear wheel path
;;; as it follows the polyline front wheel path of a turning/weaving
;;; vehicle and also draws the body of the vehicle and a single trailer.
;;; While TTURN.LSP is theoretically accurate only for
;;; two-wheeled vehicles, its tested results correlate very well to
;;; published AASHTO turning templates, even for articulated vehicles.
;;;
;;; This version of TTURN.LSP has no default vehicle information.  It requires
;;; use of attributed blocks made using the sister program "BuildVehicle".
;;; which contain all required information other than the path.  Note that
;;; Tturn.lsp at this moment is at a beta level, and has no error correction,
;;; and does not check for minimum radius paths allowed by each vehicle.  It
;;; also does not take into account speed, friction, slope, and other variables.
;;; Refer to commercially available programs if you really want a verified
;;; algorithm.
;;;
;;; GETTING STARTED
;;; At minimum, all TURN.LSP needs from you is a front left wheel path polyline
;;; and a BuildVehicle block.  Try the following exercise.
;;;
;;; First, draw a good, long, polyline representing a front wheel path.
;;; For good looks, begin and end the path with plenty of straight length.
;;; then (just for convenience and clarity, not necessity) offset the
;;; polyline the vehicle width to create the other wheel path.
;;;
;;; Second, load and run BuildVehicle.  It will ask you for all of the parameters
;;; for your vehicle, and draw a unique attributed block.  You can build a library
;;; of vehicles for future use.  BuildVehicle.lsp runs using "BV" or "BuildVehicle"
;;; from the command line.
;;;
;;; Third, load and run TTURN.LSP by dragging it into your drawing and typing "TTURN"
;;; or "TT".  When prompted, select the BuildVehicle block of your choice, and then
;;; select the front wheel path very near the starting end,
;;; then pick the point representing the direction to the same side rear wheel.
;;; Tturn.lsp uses the dimensions of the vehicle block for calculations.
;;; Accept TURN.LSP's suggestions for a calculation step and plotting accuracy
;;; or enter your own.
;;;
;;; Turn draws several POINT objects, then erases them and draws the path of the
;;; rear wheel, along with the tractor and trailer bodies, as well as all other tire
;;; paths.
;;;
;;; REFERENCE
;;; Vehicle dimensions (ft)                  Min. Outside   Min. Inside
;;; Vehicle                Width  WB1  WB2   Rad            Rad. (check)
;;; P (passenger)          7       11        24.0           13.8
;;; SU (single truck)      8.5     20        42.0           27.8
;;; BUS                    8.5     25        42.0           24.4
;;; WB-40                  8.5     13   27   40.0           18.9
;;; WB-50                  8.5     20   30   45.0           19.2
;;;
;;; DEVELOPMENT NOTES
;;; Added by Hitchcox: tractor and trailer bodies, trailer path, buildvehicle program.
;;;
;;; Added by Hitchcox: Vehicle defaults and overhang capabilities
;;;
;;; THEORY
;;; For each computation step, a vehicle wheel pair (front and back) is assumed
;;; to be traveling in a circle as though the steering wheel or articulating hinge
;;; were locked.  The front and back wheels are circumscribing two concentric
;;; circles, with the line between back and front wheel always tangent to the
;;; inner circle being made by the back wheel, as shown:
;;;
;;;          <= Counter-clockwise Travel
;;;         ooo
;;;      o       o F0
;;;    o          /o
;;;   o      _  L/  o
;;;  o     /   \/    o
;;;  o    B1 C  B0   o
;;;   o L/ \ _ /    o
;;;    o/          o
;;;   F1 o       o
;;;         ooo
;;;          => Counter-clockwise Travel
;;;
;;; The initial locations of the back and front wheels are known (B0 and F0), and the
;;; final location of the front wheel is known (F1).
;;; Then the turned angle F0|C|F1=B0|C|B1=2*atan{sin(alpha)/[2*L/S-cos(alpha)]}
;;; where
;;;      S=the distance from F0 to F1
;;;      L=the distance from B0 to F0, the wheelbase length
;;;      alpha=angle F1|F0|B0
;;;
;;;
;;; REVISION HISTORY
;;; Date     Programmer   Revision
;;; 20061213 TGH          1.1.1 Initial vehicle orientation from mandatory block selection instead of prompt.
;;; 20060324 SH           1.1.0 Added BUILDVEHICLE interface to allow overhang and sideswipe analysis.
;;; 20040507 TGH          1.0.1 Added osnap shutoff and restore.
;;; 20021025 TGH          Replaced tracking equation with better algorithm.  Removed plot point reduction algorithm.
;;; 20020627 TGH          Added GETDISTX function to distribution file.
;;; 20020625 TGH          Added capability to follow reverse drawn polylines.
;;;

(DEFUN
   C:TURN
	 (/	    ANGTRV    DIRREAR1	DIRREAR2  DIRVEH1   DIRVEH2
	  DELTAL    DSTTRV    EMARK	ENI	  ES1	    I
	  LVEH	    OSMOLD    PFRONT1	PFRONT2	  PREAR1    PREAR2
	 )
  (SETVEHICLEDIMS)
  (SETQ
    ES1
     (ENTSEL
       "\nSelect starting end of polyline to track:"
     )
    PFRONT1
     (OSNAP (CADR ES1) "endp")
    LVEH
     VEHWHEELBASE
    ;;(distance pfront1 prear1) ;This was the TURN.LSP method of getting wheelbase length
    DIRVEH1
     (CDR (ASSOC 50 (ENTGET VEHENTNAME)))
    ;;(ANGLE PFRONT1 PREAR1)  ;This was the TURN.LSP method of getting initial angle
    DIRTRAILER
     DIRVEH1
    DIRREAR1
     DIRVEH1
    ;; Define step distance as 1/10 length of wheelbase
    DELTAL
     (/ LVEH 10.0)
    DELTAL
     (GETDISTX
       PFRONT1
       "\nCalculation step distance along front wheel path"
       DELTAL
       NIL
     )
    SS1
     (SSADD)
    OSMOLD
     (GETVAR "osmode")
  )
  (SETQ
    PREAR1
     (POLAR PFRONT1 DIRVEH1 LVEH)
    PPLT1
     PREAR1
  )
  (SETVAR "osmode" 0)
  ;; Draw a point at first point of line
  (COMMAND "._point" PFRONT1)
  ;; Add point to selection set
  (SETQ
    ENI	(ENTLAST)
    SS1	(SSADD ENI SS1)
  )
  ;; Divide pline up by step distance
  (COMMAND "._measure" ES1 DELTAL)
  ;; Build selection set of all points generated following first point
  (WHILE (SETQ ENI (ENTNEXT ENI)) (SETQ SS1 (SSADD ENI SS1)))
  (SETQ I (1- (SSLENGTH SS1)))
  ;; 20020625 Revision.  See header.
  ;;Reverse the selection set if the pline is backwards
  ;;(if picked point is closer to last MEASURE command point than first)
  (IF (<
	(DISTANCE
	  (TRANS
	    ;; the coordinates of the point to translate
	    (CDR (ASSOC 10 (ENTGET (SSNAME SS1 I))))
	    ;; from pline coordinate system
	    (SSNAME SS1 I)
	    ;; to user coordinate system
	    1
	  )
	  ;; the picked point, which is in the user coordinate system
	  PFRONT1
	)
	(DISTANCE
	  (TRANS
	    ;; the coordinates of the point to translate
	    (CDR (ASSOC 10 (ENTGET (SSNAME SS1 1))))
	    ;; from pline coordinate system
	    (SSNAME SS1 1)
	    ;; to user coordinate system
	    1
	  )
	  ;; the picked point, which is in the user coordinate system
	  PFRONT1
	)
      )
    (WHILE (< 0 (SETQ I (1- I)))
      (SETQ ENI (SSNAME SS1 I))
      (SSDEL ENI SS1)
      (SSADD ENI SS1)
    )
  )
  ;; End 20020625 Revision
  ;;  Initial Travel Angle from Pick Points
  (SETQ DIRVEHDRAW (ANGLE PREAR1 PFRONT1))
  (SETQ
    PATHSEGMENTS
     (1- (SSLENGTH SS1))
  )
  (DRAWBODY)
  (SETQ I 0)
  ;;_______Initiate Rear Left Path
  (SETQ
    REARLEFTTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "RLTirePath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARLEFTTIREPATHLIST
     (CONS
       (CONS 10 PREAR1)
       REARLEFTTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Rear Left Path
  ;;
  ;;_______Initiate Front Right Path
  (SETQ
    FRONTRIGHTTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "FRTirePath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    FRONTRIGHTTIREPATHLIST
     (CONS
       (CONS
	 10
	 (POLAR PFRONT1 (+ DIRVEH1 (/ PI 2)) VEHWHEELWIDTH)
       )
       ;;prear1)
       FRONTRIGHTTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Front Right Path
  ;;
  ;;_______Initiate Rear Right Path
  (SETQ
    REARRIGHTTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "RRTirePath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARRIGHTTIREPATHLIST
     (CONS
       (CONS
	 10
	 (POLAR PREAR1 (+ DIRVEH1 (/ PI 2)) VEHWHEELWIDTH)
       )
       REARRIGHTTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Rear Right Path
  ;;
  ;;_______Initate Hitch Path
  (SETQ
    HITCHPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "HitchPath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    HITCHPATHLIST
     (CONS
       (CONS
	 10
	 (POLAR PFRONT1 (- DIRVEH1 REARHITCHANG) REARHITCHDIST)
       )
       HITCHPATHLIST
     )
  )
  ;;_______Complete Initiate Hitch Path
  ;; Calculate rear path.
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (WHILE (SETQ ENI (SSNAME SS1 (SETQ I (1+ I))))
    (SETQ
      ;; set second point to the location of eni in the current UCS
      PFRONT2
       (TRANS (CDR (ASSOC 10 (ENTGET ENI))) ENI 1)
      ;; angle of travel this step
      DIRTRV
       (ANGLE PFRONT1 PFRONT2)

      ;; angle between angle of travel and angle of vehicle
      ALPHA
       (- DIRVEH1 DIRTRV)
      ;;Distance front wheels traveled this step
      DSTTRV
       (DISTANCE PFRONT1 PFRONT2)
      ;;Angle vehicle turned this step
      ANGTRN
       (* 2
	  (ATAN
	    (/ (SIN ALPHA) (- (/ (* 2 LVEH) DSTTRV) (COS ALPHA)))
	  )
       )
      ;;Direction of vehicle at end of this step
      DIRVEH2
       (+ DIRVEH1 ANGTRN)
      ;;Location of rear wheel at end of this step
      PREAR2
       (POLAR PFRONT2 DIRVEH2 LVEH)
      ;;Direction the rear wheel traveled this step
      DIRREAR2
       (ANGLE PPLT1 PREAR2)
      ;;Save this step's variables
      PFRONT1
       PFRONT2
      PREAR1
       PREAR2
      DIRVEH1
       DIRVEH2
      DIRREAR1
       DIRREAR2
      PPLT1
       PREAR2
       ;;End saving
    )
    ;;Insert block at 180 from direction of travel
    (SETQ DIRVEHDRAW (+ PI DIRVEH2))
    (DRAWBODY)
    (SETQ
      REARLEFTTIREPATHLIST
       (CONS
	 (CONS 10 PREAR2)
	 REARLEFTTIREPATHLIST
       )
    )

    (SETQ
      FRONTRIGHTTIREPATHLIST
       (CONS
	 (CONS
	   10
	   (POLAR PFRONT1 (+ DIRVEH2 (/ PI 2)) VEHWHEELWIDTH)
	 )
	 FRONTRIGHTTIREPATHLIST
       )
    )
    (SETQ
      REARRIGHTTIREPATHLIST
       (CONS
	 (CONS
	   10
	   (POLAR PREAR2 (+ DIRVEH2 (/ PI 2)) VEHWHEELWIDTH)
	 )
	 REARRIGHTTIREPATHLIST
       )
    )
    (SETQ
      HITCHPATHLIST
       (CONS
	 (CONS
	   10
	   (POLAR PFRONT2 (- DIRVEH2 REARHITCHANG) REARHITCHDIST)
	 )
	 HITCHPATHLIST
       )
    )
  )
  (SETQ REARLEFTTIREPATHLIST (REVERSE REARLEFTTIREPATHLIST))
  (ENTMAKE REARLEFTTIREPATHLIST)
  (SETQ FRONTRIGHTTIREPATHLIST (REVERSE FRONTRIGHTTIREPATHLIST))
  (ENTMAKE FRONTRIGHTTIREPATHLIST)
  (SETQ REARRIGHTTIREPATHLIST (REVERSE REARRIGHTTIREPATHLIST))
  (ENTMAKE REARRIGHTTIREPATHLIST)
  (SETQ HITCHPATHLIST (REVERSE HITCHPATHLIST))
  (ENTMAKE HITCHPATHLIST)
  (SETQ HITCHPATH (ENTLAST))
  (IF (= TRAILHAVE "Y")
    (TRAILERPATH)
    (PRINC "\nTrailer not Included, no trailer calculated.")
  )
  (SETVAR "osmode" OSMOLD)
  (COMMAND "._erase" SS1 "")
  (REDRAW)
  (PROMPT
    (STRCAT
      "\nTURN version 1.1.1, Copyright (C) 2006 Thomas Gail Haws and Stephen Hitchcox"
      "\nTURN comes with ABSOLUTELY NO WARRANTY."
      "\nThis is free software, and you are welcome to modify and"
      "\nredistribute it under the terms of the GNU General Public License."
      "\nThe latest version of TURN is always available at www.hawsedc.com")
  )
  (PRINC)
)


;;; GETDISTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (getdistx startingpoint promptstring currentvalue vanilladefault)
(DEFUN
	  GETDISTX
	  (STARTINGPOINT PROMPTSTRING CURRENTVALUE VANILLADEFAULT)
  (SETQ
    CURRENTVALUE
     (COND
       (CURRENTVALUE)
       (VANILLADEFAULT)
       (0.0)
     )
  )
  (SETQ
    CURRENTVALUE
     (COND
       ((GETDIST
	  STARTINGPOINT
	  (STRCAT PROMPTSTRING " <" (RTOS CURRENTVALUE) ">: ")
	)
       )
       (T
	CURRENTVALUE
       )
     )
  )

)
;;; CREATE_VAR
(DEFUN
	  CREATE_VAR
		    (PREFIX SUFFIX STRNG /)
  (SET (READ (STRCAT PREFIX SUFFIX)) STRNG)
  (READ (STRCAT PREFIX SUFFIX))
)
;;; SETVEHICLEDIMS
(DEFUN
	  SETVEHICLEDIMS
			()
  (SETQ VEHICLEDATALIST (VEHICLEDATAGET))
  (SETQ VEHICLEDATALISTLEN (LENGTH VEHICLEDATALIST))
  (SETQ DATACOUNT 0)

  (WHILE (< DATACOUNT VEHICLEDATALISTLEN)
    (PROGN
      (SETQ VARNAME (CAR (NTH DATACOUNT VEHICLEDATALIST)))
      (SETQ VARVALUE (CADR (NTH DATACOUNT VEHICLEDATALIST)))
      ;| No need to change to STRINGS just to change right back to REALS
      (COND
	((= (TYPE VARVALUE) REAL) (SETQ VARVALUE (RTOS VARVALUE)))
	((= (TYPE VARVALUE) INT) (SETQ VARVALUE (ITOA VARVALUE)))
      )|;
      (SET (READ VARNAME) VARVALUE)
      (SETQ DATACOUNT (+ 1 DATACOUNT))
    )
  )

  (PRINC "\n done with loading and defining")
  ;|
  (setq vehName "TestVehicle")
  (setq VehUnits "M")
  (setq VehSteerLock 0.0)
  (setq VehSteerLockTime 0.0)
  (setq VehArtAngle 20.0)
  (setq VehFronthang 1220.0)
  (setq VehWheelbase 6100.0)
  (setq VehWheelWidth 2000.0)
  (setq VehBodyLength 9150.0)
  (setq VehWidth 2440.0)
  (setq VehRearHitch 2100.0)
  (setq TrailerHitchToWheel 10000.0)
  (setq TrailerWheelWidth 2000.0)
  (setq TrailerFrontHang 1000.0)
  (setq TrailerBodyLength 12000.0)
  (setq TrailerWidth 2440.0)
  |;

  ;; reform all numeric variables to reals, to ensure all items are reals to avoid rounding
  (FOREACH
	    VAR
	       '(VEHSTEERLOCK	      VEHSTEERLOCKTIME
		 VEHARTANGLE	      VEHFRONTHANG
		 VEHWHEELBASE	      VEHWHEELWIDTH
		 VEHBODYLENGTH	      VEHWIDTH
		 VEHREARHITCH	      TRAILERHITCHTOWHEEL
		 TRAILERWHEELWIDTH    TRAILERFRONTHANG
		 TRAILERBODYLENGTH    TRAILERWIDTH
		)
    (IF	(= (TYPE (EVAL VAR)) 'STR)
      (SET VAR (ATOF (EVAL VAR)))
    )
  )
;;;====================================================================
  (SETQ
    FRONTLEFTBUMPANG
     (ATAN
       (/ (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	  VEHFRONTHANG
       )
     )
  )
  (SETQ
    FRONTLEFTBUMPDIST
     (SQRT
       (+ (* (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	     (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	  )
	  (* VEHFRONTHANG VEHFRONTHANG)
       )
     )
  )
  (SETQ
    FRONTRIGHTBUMPANG
     (ATAN
       (/ (- (/ (- VEHWIDTH VEHWHEELWIDTH) 2) VEHWIDTH)
	  VEHFRONTHANG
       )
     )
  )
  (SETQ
    FRONTRIGHTBUMPDIST
     (SQRT
       (+ (* (- VEHWIDTH (/ (- VEHWIDTH VEHWHEELWIDTH) 2))
	     (- VEHWIDTH (/ (- VEHWIDTH VEHWHEELWIDTH) 2))
	  )
	  (* VEHFRONTHANG VEHFRONTHANG)
       )
     )
  )
  (SETQ
    REARLEFTBUMPANG
     (+	(ATAN
	  (/ (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	     (- VEHFRONTHANG VEHBODYLENGTH)
	  )
	)
	PI
     )
  )
  (SETQ
    REARLEFTBUMPDIST
     (SQRT
       (+ (* (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	     (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
	  )
	  (* (- VEHFRONTHANG VEHBODYLENGTH)
	     (- VEHFRONTHANG VEHBODYLENGTH)
	  )
       )
     )
  )
  (SETQ
    REARRIGHTBUMPANG
     (+	(ATAN
	  (/ (- (/ (- VEHWIDTH VEHWHEELWIDTH) 2) VEHWIDTH)
	     (- VEHFRONTHANG VEHBODYLENGTH)
	  )
	)
	PI

     )
  )
  (SETQ
    REARRIGHTBUMPDIST
     (SQRT
       (+ (* (- VEHWIDTH (/ (- VEHWIDTH VEHWHEELWIDTH) 2))
	     (- VEHWIDTH (/ (- VEHWIDTH VEHWHEELWIDTH) 2))
	  )
	  (* (- VEHFRONTHANG VEHBODYLENGTH)
	     (- VEHFRONTHANG VEHBODYLENGTH)
	  )
       )
     )
  )
  (SETQ
    REARHITCHANG
     (ATAN
       (/ (/ VEHWHEELWIDTH 2)
	  (- 0 (+ VEHWHEELBASE VEHREARHITCH))
       )
     )
  )
  (SETQ
    REARHITCHDIST
     (SQRT
       (+ (* (/ VEHWHEELWIDTH 2)
	     (/ VEHWHEELWIDTH 2)
	  )
	  (* (+ VEHWHEELBASE VEHREARHITCH)
	     (+ VEHWHEELBASE VEHREARHITCH)
	  )
       )
     )
  )
  (SETQ
    FRONTLEFTTRAILERANG
     (ATAN
       (/ (/ TRAILERWIDTH 2)
	  TRAILERFRONTHANG
       )
     )
  )
  (SETQ
    FRONTLEFTTRAILERDIST
     (SQRT
       (+ (* (/ TRAILERWIDTH 2)
	     (/ TRAILERWIDTH 2)
	  )
	  (* TRAILERFRONTHANG TRAILERFRONTHANG)
       )
     )
  )
  (SETQ
    REARLEFTTRAILERANG
     (+	(ATAN
	  (/ (/ TRAILERWIDTH 2)
	     (- TRAILERFRONTHANG TRAILERBODYLENGTH)
	  )
	)
	PI
     )
  )
  (SETQ
    REARLEFTTRAILERDIST
     (SQRT
       (+ (* (/ TRAILERWIDTH 2)
	     (/ TRAILERWIDTH 2)
	  )
	  (* (- TRAILERFRONTHANG TRAILERBODYLENGTH)
	     (- TRAILERFRONTHANG TRAILERBODYLENGTH)
	  )
       )
     )
  )
)
;;;
;;;
;;;
(DEFUN
	  DRAWBODY
		  ()
  (SETQ
    TRUCKBODYPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 8 "truckbody")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    TRUCKBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ FRONTLEFTBUMPANG DIRVEHDRAW)
	   FRONTLEFTBUMPDIST
	 )
       )
       TRUCKBODYPOLYLIST
     )
  )
  (SETQ
    TRUCKBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ FRONTRIGHTBUMPANG DIRVEHDRAW)
	   FRONTRIGHTBUMPDIST
	 )
       )
       TRUCKBODYPOLYLIST
     )
  )
  (SETQ
    TRUCKBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ REARRIGHTBUMPANG DIRVEHDRAW)
	   REARRIGHTBUMPDIST
	 )
       )
       TRUCKBODYPOLYLIST
     )
  )
  (SETQ
    TRUCKBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ REARLEFTBUMPANG DIRVEHDRAW)
	   REARLEFTBUMPDIST
	 )
       )
       TRUCKBODYPOLYLIST
     )
  )
  (SETQ TRUCKBODYPOLYLIST (REVERSE TRUCKBODYPOLYLIST))
  (ENTMAKE TRUCKBODYPOLYLIST)
)
;;;
;;;
;;;
(DEFUN
	  DRAWTRAILER
		     ()
  (SETQ TRAILERBODYPOLYLIST NIL)
  (SETQ
    TRAILERBODYPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 8 "trailerbody")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    TRAILERBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ DIRVEHDRAW FRONTLEFTTRAILERANG)
	   FRONTLEFTTRAILERDIST
	 )
       )
       TRAILERBODYPOLYLIST
     )
  )
  (SETQ
    TRAILERBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (- DIRVEHDRAW FRONTLEFTTRAILERANG)
	   FRONTLEFTTRAILERDIST
	 )
       )
       TRAILERBODYPOLYLIST
     )
  )
  (SETQ
    TRAILERBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (- DIRVEHDRAW REARLEFTTRAILERANG)
	   REARLEFTTRAILERDIST
	 )
       )
       TRAILERBODYPOLYLIST
     )
  )
  (SETQ
    TRAILERBODYPOLYLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PFRONT1
	   (+ DIRVEHDRAW REARLEFTTRAILERANG)
	   REARLEFTTRAILERDIST
	 )
       )
       TRAILERBODYPOLYLIST
     )
  )
  (SETQ TRAILERBODYPOLYLIST (REVERSE TRAILERBODYPOLYLIST))
  (ENTMAKE TRAILERBODYPOLYLIST)
)

;;; Function TrailerPath

(DEFUN
	  TRAILERPATH
		     ()
  ;; strip header stuff from trailerpointslist
  (WHILE (/= (CAR (CAR HITCHPATHLIST)) 10)
    (SETQ HITCHPATHLIST (CDR HITCHPATHLIST))
  )
  (SETQ HITCHPATHLISTCOUNT 0)
  (SETQ PPLT1 (CDR (NTH 0 HITCHPATHLIST)))
  (SETQ PFRONT1 PPLT1)
  ;; get first trailer point
  (SETQ DIRVEH1 DIRTRAILER)
  (SETQ LVEH TRAILERHITCHTOWHEEL)
  (SETQ PREAR1 (POLAR PPLT1 DIRVEH1 LVEH))
  (SETQ DIRVEHDRAW (ANGLE PREAR1 PFRONT1))
  (DRAWTRAILER)
  ;;
  ;;_______Initiate Rear Left Trailer Path
  (SETQ
    REARLEFTTRAILERTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "RLTrailerTirePath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARLEFTTRAILERTIREPATHLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PREAR1
	   (+ DIRVEH1 (/ PI 2))
	   (/ TRAILERWHEELWIDTH 2)
	 )
       )
       REARLEFTTRAILERTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Rear Right Path
  ;;
  ;;_______Initiate Rear Right Path
  (SETQ
    REARRIGHTTRAILERTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       ;;(cons 70 1) ;;; no 70 code, not a closed pline
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 8 "RRTrailerTirePath")
       (CONS 100 "AcDbPolyline")
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARRIGHTTRAILERTIREPATHLIST
     (CONS
       (CONS
	 10
	 (POLAR
	   PREAR1
	   (- DIRVEH1 (/ PI 2))
	   (/ TRAILERWHEELWIDTH 2)
	 )
       )
       REARRIGHTTRAILERTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Rear Right Path
  (SETQ HITCHPATHLISTCOUNT (1+ HITCHPATHLISTCOUNT))
  (WHILE (< HITCHPATHLISTCOUNT PATHSEGMENTS)
    (SETQ
      PFRONT2
       (CDR (NTH HITCHPATHLISTCOUNT HITCHPATHLIST))
    )
    (SETQ
      ;; angle of travel this step
      DIRTRV
       (ANGLE PFRONT1 PFRONT2)
    )
    ;; angle between angle of travel and angle of vehicle
    (SETQ
      ALPHA
       (- DIRVEH1 DIRTRV)
    )
    ;;Distance front wheels traveled this step
    (SETQ
      DSTTRV
       (DISTANCE PFRONT1 PFRONT2)
    )

    (SETQ
      ;;Angle vehicle turned this step
      ANGTRN
       (* 2
	  (ATAN
	    (/ (SIN ALPHA) (- (/ (* 2 LVEH) DSTTRV) (COS ALPHA)))
	  )
       )
    )
    (SETQ
      DIRVEH2
       (+ DIRVEH1 ANGTRN)
    )
    (SETQ
      PREAR2
       (POLAR PFRONT2 DIRVEH2 LVEH)
    )
    (SETQ
      PFRONT1
       PFRONT2
    )
    (SETQ
      PREAR1
       PREAR2
    )
    (SETQ
      DIRVEH1
       DIRVEH2
    )
    (SETQ
      DIRREAR2
       (ANGLE PPLT1 PREAR2)
    )
    (SETQ DIRVEHDRAW (+ PI DIRVEH2))
    (DRAWTRAILER)
    (SETQ
      REARLEFTTRAILERTIREPATHLIST
       (CONS
	 (CONS
	   10
	   (POLAR
	     PREAR1
	     (+ DIRVEH1 (/ PI 2))
	     (/ TRAILERWHEELWIDTH 2)
	   )
	 )
	 REARLEFTTRAILERTIREPATHLIST
       )
    )
    (SETQ
      REARRIGHTTRAILERTIREPATHLIST
       (CONS
	 (CONS
	   10
	   (POLAR
	     PREAR1
	     (- DIRVEH2 (/ PI 2))
	     (/ TRAILERWHEELWIDTH 2)
	   )
	 )
	 REARRIGHTTRAILERTIREPATHLIST
       )
    )
    (SETQ
      DIRREAR1
	       DIRREAR2
      PPLT1
	       PREAR2
    )
    (SETQ HITCHPATHLISTCOUNT (1+ HITCHPATHLISTCOUNT))
  )
  (DRAWTRAILER)
  (SETQ
    REARLEFTTRAILERTIREPATHLIST
     (REVERSE REARLEFTTRAILERTIREPATHLIST)
  )
  (ENTMAKE REARLEFTTRAILERTIREPATHLIST)
  (SETQ
    REARRIGHTTRAILERTIREPATHLIST
     (REVERSE REARRIGHTTRAILERTIREPATHLIST)
  )
  (ENTMAKE REARRIGHTTRAILERTIREPATHLIST)
)

;; VEHICLEDATAGET gets the vehicle attributes from a BUILDVEHICLE
;; defined block.
;; Returns a list of vehicle properties.
(DEFUN
	  VEHICLEDATAGET
			(/		    CHANGEFROMDEFAULT
			 CONTINUELOAD	    ENTITYTYPE
			 TAG		    VALUE
			 VEHICLEDATALISTLEN VEHICLEBLOCKNAME
			 VEHICLEENTITYLIST
			)
  (SETQ VEHICLEBLOCKNAME (CAR (ENTSEL "\nSelect Vehicle: ")))
  (SETQ CHANGEFROMDEFAULT 0)
  ;;If a block was selected, get its data.  Otherwise alert and fail.
  (COND
    (
     (AND
       VEHICLEBLOCKNAME
       (SETQ VEHICLEENTITYLIST (ENTGET VEHICLEBLOCKNAME))
       (SETQ ENTITYTYPE (CDR (ASSOC 0 VEHICLEENTITYLIST)))
       (= ENTITYTYPE "INSERT")
     )
     ;;Preload default vehicle
     (SETQ
       VEHICLEDATALIST
	(LIST
	  (LIST "VEHENTNAME" VEHICLEBLOCKNAME)
	  (LIST "VEHNAME" "TestVehicle")
	  (LIST "VEHUNITS" "M")
	  (LIST "VEHSTEERLOCK" 0.0)
	  (LIST "VEHSTEERLOCKTIME" 0.0)
	  (LIST "VEHARTANGLE" 20.0)
	  (LIST "VEHFRONTHANG" 1220.0)
	  (LIST "VEHWHEELBASE" 6100.0)
	  (LIST "VEHWHEELWIDTH" 2000.0)
	  (LIST "VEHBODYLENGTH" 9150.0)
	  (LIST "VEHWIDTH" 2440.0)
	  (LIST "VEHREARHITCH" 2100.0)
	  (LIST "TRAILHAVE" "N")
	  (LIST "TRAILNAME" "TestVehicle")
	  (LIST "TRAILUNITS" "M")
	  (LIST "TRAILERHITCHTOWHEEL" 10000.0)
	  (LIST "TRAILERWHEELWIDTH" 2000.0)
	  (LIST "TRAILERFRONTHANG" 1000.0)
	  (LIST "TRAILERBODYLENGTH" 12000.0)
	  (LIST "TRAILERWIDTH" 2440.0)
	)
     )
     (SETQ VEHICLEDATALISTLEN (LENGTH VEHICLEDATALIST))
     (SETQ CONTINUELOAD "YES")
     (WHILE (AND
	      (SETQ VEHICLEBLOCKNAME (ENTNEXT VEHICLEBLOCKNAME))
	      (= CONTINUELOAD "YES")
	    )
       (SETQ VEHICLEENTITYLIST (ENTGET VEHICLEBLOCKNAME))
       (SETQ ENTITYTYPE (CDR (ASSOC 0 VEHICLEENTITYLIST)))
       (COND
	 ((= ENTITYTYPE "ATTRIB")
	  (SETQ VALUE (CDR (ASSOC 1 VEHICLEENTITYLIST)))
	  (SETQ TAG (CDR (ASSOC 2 VEHICLEENTITYLIST)))
	  ;;subst values in list
	  ;;if a value has been substituted (even with same value),
	  ;;then increment ChangeFromDefault by one
	  (SETQ COUNT 0)
	  (WHILE (< COUNT VEHICLEDATALISTLEN)
	    (IF	(= (CAR (NTH COUNT VEHICLEDATALIST)) TAG)
	      (PROGN
		(SETQ OLDPAIR (NTH COUNT VEHICLEDATALIST))
		(SETQ NEWPAIR (LIST TAG VALUE))
		(SETQ
		  VEHICLEDATALIST
		   (SUBST NEWPAIR OLDPAIR VEHICLEDATALIST)
		)
		;;(Replace_Nth Count VehicleDataList NewPair)
		(SETQ CHANGEFROMDEFAULT (+ CHANGEFROMDEFAULT 1))
	      )
	    )
	    (SETQ COUNT (+ 1 COUNT))
	  )
	 )
	 ((= ENTITYTYPE "SEQUEND")
	  (SETQ CONTINUELOAD "NO")
	 )
       )
     )
    )
    (T
     (ALERT
       (PRINC
	 "\n ENTITY SELECTED IS NOT A VALID BLOCK.\n\nRUN BUILDVEHICLE TO DEFINE A VEHICLE."
       )
     )
    )
  )
  ;;check if ChangeFromDefault matches required data list length.  if not, then
  ;;report that not all data was found, and that some default values are being used
  (COND
    ((= CHANGEFROMDEFAULT 0)
     (ALERT
       (PRINC
	 "\n NO DIMENSIONS OR DATA FOUND.\nPLEASE CHECK THAT SOURCE ENTITY IS VALID.\nDEFAULT VALUES WILL BE USED.\n\nRUN BUILDVEHICLE TO DEFINE A VEHICLE."
       )
     )
    )
    ((= CHANGEFROMDEFAULT VEHICLEDATALISTLEN)
     (PRINC
       "\n ALL DIMENSIONS AND DATA FOUND, CUSTOMIZED VEHICLE HAS BEEN DEFINED"
     )
    )
    (ALERT
     (PRINC
       "\n SOME DIMENSIONS OR DATA FOUND.  PLEASE VERIFY THAT SOURCE BLOCK IS VALID.  SOME DEFAULT VALUES WILL BE USED"
     )
    )
  )
  VEHICLEDATALIST
)
;;; Not yet used.
;;; Function TRAILINGPATH
;;; Returns a list of points that define a wheel path
;;; that trails a given front wheel path
;;; with the initial point of the trailing path as given
;;; Usage:
;;;   (trailingpath
;;;     frontpath     The list of points that define the front path
;;;     rearstart     The first point on the trailing path
;;;   )
;;;Not yet used.
(DEFUN
   TRAILINGPATH
	       (FRONTPATH REARSTART / I J)
  (SETQ
    I 0
    PATHLISTLENGTH
     (LENGTH FRONTPATH)
    PREAR1
     REARSTART
    REARPATH
     (LIST REARSTART)
  )
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (WHILE (< (SETQ I (1+ I)) PATHLISTLENGTH)
    (SETQ
      ;; Set initial point to the previous point
      PFRONT1
       (NTH (1- I) FRONTPATH)
      ;; Set final point to current point
      PFRONT2
       (NTH I FRONTPATH)
      ;; Initial direction of vehicle
      DIRVEH1
       (ANGLE PREAR1 PFRONT1)
      ;; Angle of travel this step
      DIRTRV
       (ANGLE PFRONT1 PFRONT2)
      ;; Angle between angle of travel and angle of vehicle
      ALPHA
       (- DIRVEH1 DIRTRV)
      ;; Distance front wheels traveled this step
      DSTTRV
       (DISTANCE PFRONT1 PFRONT2)
      ;; Angle vehicle turned this step
      ANGTRN
       (* 2
	  (ATAN
	    (/ (SIN ALPHA) (- (/ (* 2 LVEH) DSTTRV) (COS ALPHA)))
	  )
       )
      ;; Direction of vehicle at end of this step
      DIRVEH2
       (+ DIRVEH1 ANGTRN)
      ;; Location of rear wheel at end of this step
      PREAR2
       (POLAR PFRONT2 DIRVEH2 LVEH)
      ;; Direction the rear wheel traveled this step
      DIRREAR2
       (ANGLE PREAR1 PREAR2)
      ;; Save this step's variables
      PFRONT1
       PFRONT2
      PREAR1
       PREAR2
      DIRVEH1
       DIRVEH2
      DIRREAR1
       DIRREAR2
      REARPATH
       (CONS PREAR2 REARPATH)
       ;;End saving
    )
  )
  (REVERSE REARPATH)
)