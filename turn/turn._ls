;;; AutoCAD Wiki AutoLISP code header.  
;;;
;;; Copy this code to a file on your computer. 
;;; Start highlighting OUTSIDE the code boxes and use the mouse or keyboard to
;;; highlight all the code.
;;; If you select too much, simply delete any extra from your destination file.
;;; In Windows you may want to start below the code and use [Shift]+[Ctrl]+[Home] 
;;; key combination to highlight all the way to the top of the article,
;;; then still holding the [Shift] key, use the arrow keys to shrink the top of
;;; the selection down to the beginning of the code.  Then copy and paste.
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The working version of this software is located at the AutoCAD Wiki.
;;; Please Be Bold in adding clarifying comments and improvements at
;;; http://autocad.wikia.com/wiki/Turning_path_tracker_%28AutoLISP_application%29

;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The working version of this software is located at the AutoCAD Wiki.
;;; Please Be Bold in adding clarifying comments and improvements at
;;; http://autocad.wikia.com/wiki/Turning_path_tracker_%28AutoLISP_application%29

;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The working version of this software is located at the AutoCAD Wiki.
;;; Please Be Bold in adding clarifying comments and improvements at
;;; http://autocad.wikia.com/wiki/Turning_path_tracker_%28AutoLISP_application%29

;;;
;;; TURN.LSP
;;; Copyright 2009 Thomas Gail Haws
;;; Copyright 2008 Stephen Hitchcox
;;; TURN.LSP draws vehicle turning paths in AutoCAD.
;;;
;;; OVERVIEW
;;; TURN.LSP draws a polyline representing a theoretical rear wheel path
;;; as it follows the polyline front wheel path of a turning/weaving
;;; vehicle and also draws the body of the vehicle and a single trailer.
;;; While TURN.LSP is theoretically accurate only for
;;; two-wheeled vehicles, its tested results correlate very well to
;;; published AASHTO turning templates, even for articulated vehicles.
;;;
;;; This version of TURN.LSP has no default vehicle information.  It requires
;;; use of attributed blocks made using the sister program "BuildVehicle".
;;; which contain all required information other than the path.  Note that
;;; Turn.lsp at this moment is at a beta level, and has no error correction,
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
;;; itself does not change size (it is not dynamic).
;;;
;;; If you make a new block with the same name as an existing one, it will overwrite
;;; the old one.
;;;
;;; Draw the path for the vehicle as the route taken by the front left tire.  A future
;;; version of this program might add path by centre or by right side of vehicle, to
;;; suit other driving standards.
;;;
;;; Move the BuildVehicle block of your choice to the beginning of the polyline path.
;;;
;;; Then, run TURN.  When prompted, select the BuildVehicle block, and then
;;; select the front wheel path very near the starting end.
;;; Turn.lsp uses the dimensions of the vehicle block for calculations.
;;; Accept TURN.LSP's suggestions for a calculation step and plotting accuracy
;;; or enter your own.
;;;
;;; Note:  Place the vehicle at the start of the path using the centre of the
;;; FRONT LEFT WHEEL, which should be marked with an "x" type figure.  Rotate the
;;; vehicle to the approximate correct starting angle.
;;;
;;; Note:  Select the LEFT WHEEL PATH (Drivers Side in most locations).  The right
;;; side is drawn off of this.  Note that there is no functional difference
;;; for the path of the vehicle based on where the driver is sitting.
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
;;; Development Notes:
;;; DEVELOPMENT PLANS
;;; 1) implement better error correction
;;;
;;; 2) collect and share correctly dimensioned standard vehicles
;;;
;;; 3) revise  to allow multiple
;;; trailers
;;;
;;; 4) revise to draw tires centred on the tire paths
;;;
;;; 5) 080205 imperial scaling issue resolved, and input for dimensional information
;;; revised to allow picks from drawing
;;;
(DEFUN
   TURN-INITIALIZESETTINGS ()
;;; REVISION HISTORY
  (TURN-SETVAR "General.Version" "1.1.9")
;;; Date     Programmer   Revision
;;; 20090226 TGH          1.1.9 Minor tweak to version reporting
;;; 20081112 TGH          1.1.8 Added layer settings functions to consolidate names in one place
;;; 20080522 SH           1.1.7 Revised layers to an identifiable set, using AIA type standard.  placed under C for Civil
;;;                             and using TURN as a reserve header.  also fixed trailer to draw as a box not a cross.
;;; 20080416 TGH          1.1.6 Added block plotting method with more modular code and defined data structure.
;;;                             combined both methods into one routine
;;; 20080410 TGH          1.1.5 Simplified prompts, added layer defaults, and fixed a few errors.
;;; 20080206 SH           1.1.4 Fixed Imperial dimension storage, and made input consistent to type of data
;;; 20080120 SH           1.1.3 Various, including Centre of Wheels used instead of Outside of Wheels (vehicles
;;;                       steer on the centroids of the wheels, not the rims), "Set-out" point added at Front Left
;;;                       wheel
;;; 20070327 SH           1.1.2 Trailer plotting
;;; 20061213 TGH          1.1.1 Initial vehicle orientation from mandatory block selection instead of prompt.
;;; 20060324 SH           1.1.0 Added BUILDVEHICLE interface to allow overhang and sideswipe analysis.
;;; 20040507 TGH          1.0.1 Added osnap shutoff and restore.
;;; 20021025 TGH          Replaced tracking equation with better algorithm.  Removed plot point reduction algorithm.
;;; 20020627 TGH          Added GETDISTX function to distribution file.
;;; 20020625 TGH          Added capability to follow reverse drawn polylines.
;;;
;;;----------------------------------------------------------------------------
;;; Program settings users can edit--------------------------------------------
;;;----------------------------------------------------------------------------
;;;
;;; Layer settings.
  (TURN-SETLAYER "TruckBody" "C-TURN-TRCK-BODY" "1" "")
  (TURN-SETLAYER "TrailerBody" "C-TURN-TRAL-BODY" "2" "")
  (TURN-SETLAYER "HitchPath" "C-TURN-HTCH-PATH" "3" "")
  (TURN-SETLAYER
    "TruckBackLeftTirePath"
    "C-TURN-TRCK-RLTR-PATH"
    "3"
    "dashed"
  )
  (TURN-SETLAYER
    "TruckBackRightTirePath"
    "C-TURN-TRCK-RRTR-PATH"
    "3"
    "dashed"
  )
  (TURN-SETLAYER
    "TruckFrontRightTirePath"
    "C-TURN-TRCK-FRTR-PATH"
    "3"
    "dashed"
  )
  (TURN-SETLAYER
    "TrailerBackRightTirePath"
    "C-TURN-TRAL-RLTR-PATH"
    "4"
    "dashed"
  )
  (TURN-SETLAYER
    "TrailerBackLeftTirePath"
    "C-TURN-TRAL-RRTR-PATH"
    "4"
    "dashed"
  )
)
;;;
;;;----------------------------------------------------------------------------
;;; End of program settings users can edit-------------------------------------
;;;----------------------------------------------------------------------------
;;;
;;; TURN-SETVAR
(DEFUN
   TURN-SETVAR (VARNAME VALUE / NEWGROUP OLDGROUP)
;;; For future compatibility with other storage options,
;;; We're keeping all values as strings (text).
  ;;Put VarName and Value together into a setting group.
  (SETQ
    VARNAME
     (STRCASE VARNAME)
    NEWGROUP
     (CONS VARNAME VALUE)
  )
  (COND
    ;;If the variable is already set, then
    ((SETQ OLDGROUP (ASSOC VARNAME *TURN:SETTINGS*))
     ;;Replace the old setting with the new setting.
     (SETQ *TURN:SETTINGS* (SUBST NEWGROUP OLDGROUP *TURN:SETTINGS*))
    )
    ;;Else,
    (T
     ;;Add the setting.
     (SETQ *TURN:SETTINGS* (CONS NEWGROUP *TURN:SETTINGS*))
    )
  )
)
;;;
;;; TURN-GETVAR
(DEFUN
   TURN-GETVAR (VARNAME / VARNAMEMIXED)
  (SETQ
    VARNAMEMIXED VARNAME
    VARNAME
     (STRCASE VARNAME)
  )
  (COND
    ;;If the setting is found, then return it
    ((CDR (ASSOC VARNAME *TURN:SETTINGS*)))
    ;;Else
    (T
     ;;1.  Send an error message.
     (ALERT
       (PRINC
         (STRCAT
           "\nNo setting was found for "
           VARNAMEMIXED
           ".\nGeotables can't continue."
         )
       )
     )
     ;;2.  Exit
     (EXIT)
    )
  )
)

;;Sets up a layer setting
(DEFUN
   TURN-SETLAYER (BASENAME LANAME LACOLOR LALTYPE)
  (TURN-SETVAR (STRCAT "Layers." BASENAME ".Name") LANAME)
  (TURN-SETVAR (STRCAT "Layers." BASENAME ".Color") LACOLOR)
  (TURN-SETVAR
    (STRCAT "Layers." BASENAME ".Linetype")
    LALTYPE
  )
)
;;Gets a layer list from a layer base name string.
(DEFUN
   TURN-GETLAYER (BASENAME)
  (LIST
    (TURN-GETVAR (STRCAT "Layers." BASENAME ".Name"))
    (TURN-GETVAR (STRCAT "Layers." BASENAME ".Color"))
    (TURN-GETVAR (STRCAT "Layers." BASENAME ".Linetype"))
  )
)
;;; Layer settings added by Tom Haws 2008-04-10
(DEFUN
   TURN-MAKELAYERS (/ LAYER)
  ;;Layer change 2008-02-22 Stephen Hitchcox
  (FOREACH
     BASENAME '("TruckBody" "TrailerBody" "HitchPath"
                "TruckBackLeftTirePath" "TruckBackRightTirePath"
                "TruckFrontRightTirePath" "TrailerBackRightTirePath"
                "TrailerBackLeftTirePath"
               )
    (SETQ LAYER (TURN-GETLAYER BASENAME))
    (COMMAND
      "._layer"
      "t"
      (CAR LAYER)
      "on"
      (CAR LAYER)
      "un"
      (CAR LAYER)
      "m"
      (CAR LAYER)
      "c"
      (CADR LAYER)
      ""
      "lt"
      (CADDR LAYER)
      ""
      ""
    )
  )
)

(TURN-INITIALIZESETTINGS)
(TURN-MAKELAYERS)

(DEFUN
   C:TURN (/ METHOD VEHNAME)
  (INITGET "User Generated ?")
  (SETQ
    METHOD
     (GETKWORD
       "\nTracking method [User block/Generated vehicle/?]: "
     )
  )
  (COND
    ((= METHOD "User") (TURN-MAIN-USER-BLOCK-METHOD))
    ((= METHOD "Generated")
     (SETQ
       VEHNAME
        (GETSTRING
          "\nName for new vehicle or <select previously generated vehicle>: "
        )
     )
     (COND
       ((= VEHNAME "") (TURN-MAIN-GENERATED-BLOCK-METHOD))
       (T (TURN-BUILDVEHICLE VEHNAME))
     )
    )
    ((= METHOD "?")
     (ALERT
       (PRINC
         (STRCAT
           "TURN currently has two behavior methods or versions."
           "\n\nThe User Block method doesn't keep track of as many vehicle dimensions and paths."
           "\nIt merely drags your block along a path."
           "\nIt also doesn't model hitches at this time, which limits its accuracy for trailers."
           "\n\nThe Generated Vehicle method doesn't show the nuances of a vehicle as well."
           "\nIt merely draws rectangles along with multiple calculated wheel paths."
           "\n\nWhile we hope to harmonize the two methods, they are currently rather independent."
          )
       )
     )
    )
  )
  (PROMPT
    (STRCAT
      "\nTURN version " (TURN-GETVAR "General.Version")" , Copyright (C) 2006 Thomas Gail Haws and Stephen Hitchcox"
      "\nTURN comes with ABSOLUTELY NO WARRANTY."
      "\nThis is free software, and you are welcome to modify and"
      "\nredistribute it under the terms of the GNU General Public License."
      "\nThe latest version of TURN is always available at autocad.wikia.com"
     )
  )
)

;;;C:BV short form call for (TURN-BUILDVEHICLE)
(DEFUN C:BV () (TURN-BUILDVEHICLE))
(DEFUN
   TURN-BUILDVEHICLE (VEHNAME)
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; NEED TO ADD SETTING OF DEFAULT VALUES HERE,
;;; THEN LOOP THROUGH TO CHANGE TO CUSTOM NUMBERS,
;;; THEN PRESENT USER WITH COMPLETE LAYOUT BEFORE CREATING BLOCK,
;;; AND ALLOW USER TO CHANGE BY GOING THROUGH LOOP AGAIN
;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  ;| Code not used at this time.  Prompt hidden and default set by Tom Haws 2008-04-10
  ;;Input change 2008-04-10 Tom Haws
  (initget 1 "M I")
  (SETQ VEHUNITS (GETKWORD "\nMetric or Imperial units [M/I]:  "))
  |;
  (SETQ VEHUNITS "M")
  ;;Prompt change 2008-04-11 Tom Haws
  (SETQ
    STARTDRAWPOINT
     (GETPOINT
       "\nLocation to build vehicle (midpoint of front bumper):  "
     )
  )
  ;;Prompt change 2008-04-10 Tom Haws
  (SETQ
    VEHBODYLENGTH
     (GETDIST STARTDRAWPOINT "\nLength of vehicle body: ")
  )
  ;;Prompt change 2008-04-10 Tom Haws
  (SETQ
    VEHWIDTH
     (* 2
        (GETDIST STARTDRAWPOINT "\nHalf width of vehicle body: ")
     )
  )
  ;; Record VEHWIDTH
  ;; MAKEATTRIBUTE usage: (MakeAttribute InsPoint InsAngle Tag Value AttribLayer AttPrompt TextSize)
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT PI (/ VEHWIDTH 15))
    90.0
    "VEHWIDTH"
    (RTOS VEHWIDTH 2)
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
    (RTOS VEHBODYLENGTH 2)
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
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;;Prompt change 2008-04-11 Tom Haws
  (SETQ
    VEHFRONTHANG
     (GETDIST
       STARTDRAWPOINT
       "\nFront overhang (distance from bumper to axle): "
     )
  )
  ;; Record front axle offset
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (/ VEHFRONTHANG 2))
    0.0
    "VEHFRONTHANG"
    (RTOS VEHFRONTHANG 2)
    "AttributeLayer"
    "Vehicle front overhang"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  (SETQ VEHWHEELBASE (GETDIST "\nEnter vehicle wheelbase: "))
  (IF (< VEHBODYLENGTH (+ VEHFRONTHANG VEHWHEELBASE))
    (PRINC
      "\nCaution, Vehicle Length is shorter than sum of Front Overhang and Wheelbase.  Errors could occur."
    )
  )
  ;; Record rear axle location
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (+ VEHFRONTHANG VEHWHEELBASE))
    90
    "VEHWHEELBASE"
    (RTOS VEHWHEELBASE 2)
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
;;; VehSteerLock isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
  (SETQ VEHSTEERLOCK 0.5)
  ;|
  (SETQ VEHSTEERLOCK (GETANGLE "\nEnter vehicle Steering Lock Angle:  (note that this is required but not used at this time)"))
  |;
  ;; Record vehicle Steering Lock Angle
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 (/ VEHFRONTHANG 3))
    90.0
    "VEHSTEERLOCK"
    (ANGTOS VEHSTEERLOCK 0)
    "AttributeLayer"
    "Vehicle steering lock angle"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
;;; VEHSTEERLOCKTIME isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
  (SETQ VEHSTEERLOCKTIME 0.0)
  ;|
  (SETQ
    VEHSTEERLOCKTIME
     (GETREAL "\nEnter vehicle steering lock time:  (note that this is required but not used at this time)")
  )
  |;
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
  (SETQ
    VEHWHEELWIDTH
     ;;Prompt change 2008-04-11 Tom Haws
     (*
       2
       (GETDIST
         STARTDRAWPOINT
         "\nHalf of maximum axle width to middle of wheels: "
       )
     )
  )
  ;; Record wheel width
  (MAKEATTRIBUTE
    (POLAR STARTDRAWPOINT 0.0 VEHFRONTHANG)
    90.0
    "VEHWHEELWIDTH"
    (RTOS VEHWHEELWIDTH 2)
    "AttributeLayer"
    "Vehicle wheel width"
    (/ VEHWIDTH 15)
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw tires
  ;; Define Tire Size as 1/10th of vehicle dimensions (arbitrary, could be a future setting)
  (SETQ WHEELWIDTH (/ VEHWIDTH 10))
  (SETQ WHEELLENGTH (/ VEHBODYLENGTH 10))
  ;; DRAW FRONT LEFT wheel
  (SETQ
    WHEELFLSTARTX
     (+ (CAR STARTDRAWPOINT)
        (- VEHFRONTHANG (/ WHEELLENGTH 2))
     )
  )
  (SETQ
    WHEELFLSTARTY
     (- (CADR STARTDRAWPOINT)
        (+ (/ VEHWHEELWIDTH 2) (/ WHEELWIDTH 2))
     )
  )
  (DRAWBOX
    (LIST WHEELFLSTARTX WHEELFLSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw front left target point
  (SETQ TARGETX (+ (CAR STARTDRAWPOINT) VEHFRONTHANG))
  (SETQ TARGETY (- (CADR STARTDRAWPOINT) (/ VEHWHEELWIDTH 2)))
  (DRAWTARGET
    (LIST TARGETX TARGETY)
    WHEELLENGTH
    WHEELWIDTH
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw front right wheel
  (SETQ
    WHEELFRSTARTX
     (+ (CAR STARTDRAWPOINT)
        (- VEHFRONTHANG (/ WHEELLENGTH 2))
     )
  )
  (SETQ
    WHEELFRSTARTY
     (+ (CADR STARTDRAWPOINT)
        (- (/ VEHWHEELWIDTH 2) (/ WHEELWIDTH 2))
     )
  )
  (DRAWBOX
    (LIST WHEELFRSTARTX WHEELFRSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw rear left wheel
  (SETQ
    WHEELRLSTARTX
     (+ (CAR STARTDRAWPOINT)
        (- VEHFRONTHANG (/ WHEELLENGTH 2))
        VEHWHEELBASE
     )
  )
  (SETQ
    WHEELRLSTARTY
     (- (CADR STARTDRAWPOINT)
        (+ (/ VEHWHEELWIDTH 2) (/ WHEELWIDTH 2))
     )
  )
  (DRAWBOX
    (LIST WHEELRLSTARTX WHEELRLSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; Draw rear right wheel
  (SETQ
    WHEELRRSTARTX
     (+ (CAR STARTDRAWPOINT)
        (- VEHFRONTHANG (/ WHEELLENGTH 2))
        VEHWHEELBASE
     )
  )
  (SETQ
    WHEELRRSTARTY
     (+ (CADR STARTDRAWPOINT)
        (- (/ VEHWHEELWIDTH 2) (/ WHEELWIDTH 2))
     )
  )
  (DRAWBOX
    (LIST WHEELRRSTARTX WHEELRRSTARTY)
    WHEELLENGTH
    WHEELWIDTH
    "C-TURN-TRCK-BODY"
  )
  (SSADD (ENTLAST) VEHBLOCKLIST)
  ;; End of main vehicle entry
  ;; Start trailer entry
  (INITGET 1 "Yes No")
  (SETQ TRAILHAVE (GETKWORD "\nDoes unit have a trailer? [Yes/No]:  "))
  (MAKEATTRIBUTE
    (POLAR
      STARTDRAWPOINT
      0.0
      (+ VEHFRONTHANG VEHWHEELBASE)     ;(* VEHREARHITCH 0.5)) Edited 2008-04-10 to accomodate prompt order change
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
     ;;Moved hitch stuff 2008-04-10 by Tom Haws so non-trailer builds won't see it.
     (SETQ
       VEHREARHITCH
        (GETDIST
          "\nEnter distance from rear axle to hitch (forward is NEGATIVE):  "
        )
     )
     ;;Draw hitch
     (SETQ
       CIRCLELIST
        (LIST
          (CONS 0 "CIRCLE")             ;(CONS 100 "AcDbEntity")
          (CONS 8 "C-TURN-TRCK-BODY")   ;(CONS 100 "AcDbCircle")
          (CONS 40 (/ VEHWIDTH 10))
          (CONS
            10
            (POLAR
              STARTDRAWPOINT
              0.0
              (+ VEHFRONTHANG VEHWHEELBASE VEHREARHITCH)
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
         (+ VEHFRONTHANG VEHWHEELBASE VEHREARHITCH)
       )
       90.0
       "VEHREARHITCH"
       (RTOS VEHREARHITCH 2)
       "AttributeLayer"
       "Vehicle rear hitch location (forward is NEGATIVE): "
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Vehicle articulation angle not functional.  Prompt hidden by Tom Haws 2008-04-10.
     (SETQ VEHARTANGLE 0.5)
     ;|
     (SETQ VEHARTANGLE
     (GETANGLE "\nEnter vehicle articulation angle:  (note that this is required but not used at this time)")
     )
     |;
     ;; Record wheel width
     (MAKEATTRIBUTE
       (POLAR
         STARTDRAWPOINT
         0.0
         (+ VEHFRONTHANG VEHWHEELBASE (* VEHREARHITCH 1.5))
       )
       90.0
       "VEHARTANGLE"
       (ANGTOS VEHARTANGLE 0)
       "AttributeLayer"
       "Vehicle articulation angle"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     (SETQ TRAILNAME (GETSTRING "\nName for trailer:  "))
     ;| Code not used at this time.  Prompt hidden and default set by Tom Haws 2008-04-10
  ;;Input change 2008-04-10 Tom Haws
  (initget 1 "M I")
  (SETQ TRAILUNITS (GETKWORD "\nMetric or Imperial units [M/I]:  "))
  |; (SETQ TRAILUNITS "M")
     ;;Prompt change 2008-04-11 Tom Haws
     (SETQ
       TRAILERHITCHTOWHEEL
        (GETDIST
          "\nDistance from hitch to trailer axle:  "
        )
     )
     ;;Prompt change 2008-04-11 Tom Haws
     (SETQ
       TRAILERWHEELWIDTH
        (*
          2
          (GETDIST
            "\nHalf of maximum trailer axle width to middle of wheels:  "
          )
        )
     )
     (SETQ
       TRAILERFRONTHANG
        (GETDIST
          "\nDistance from hitch to front of trailer (forward is NEGATIVE):  "
        )
     )
     (SETQ TRAILERBODYLENGTH (GETDIST "\nOverall trailer length:  "))
     (SETQ TRAILERWIDTH (* 2 (GETDIST "\nHalf of trailer width:  ")))
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
       (RTOS TRAILERBODYLENGTH 2)
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
       (RTOS TRAILERFRONTHANG 2)
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
       (RTOS TRAILERHITCHTOWHEEL 2)
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
       (RTOS TRAILERWIDTH 2)
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
       (RTOS TRAILERWHEELWIDTH 2)
       "AttributeLayer"
       "Trailer axle width to middle of wheels"
       (/ VEHWIDTH 15)
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
     ;; Draw trailer
     (DRAWBOX
       (POLAR
         (POLAR
           STARTDRAWPOINT
           0.0
           (+ VEHFRONTHANG VEHWHEELBASE VEHREARHITCH TRAILERFRONTHANG)
         )
         (* 1.5 PI)
         (/ TRAILERWIDTH 2)
       )
       TRAILERBODYLENGTH
       TRAILERWIDTH
       "C-TURN-TRAL-BODY"
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
        (- (CADR STARTDRAWPOINT)
           (+ (/ TRAILERWHEELWIDTH 2) (/ WHEELWIDTH 2))
        )
     )
     (DRAWBOX
       (LIST WHEELRLSTARTX WHEELRLSTARTY)
       WHEELLENGTH
       WHEELWIDTH
       "C-TURN-TRAL-BODY"
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
           (- (/ TRAILERWHEELWIDTH 2) (/ WHEELWIDTH 2))
        )
     )
     (DRAWBOX
       (LIST WHEELRRSTARTX WHEELRRSTARTY)
       WHEELLENGTH
       WHEELWIDTH
       "C-TURN-TRAL-BODY"
     )
     (SSADD (ENTLAST) VEHBLOCKLIST)
    )
  )
;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; ADD REQUEST HERE TO VERIFY DIMENSIONS AND LAYOUT,
;;; DUMP OUT LIST OF VALUES, AND ALSO ZOOM TO HIGHLIGHT VEHICLE
;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  ;;(makeblock VehBlockList StartDrawPoint (strcat "VEHICLELIB" VEHNAME))
  ;;makes a block without accessible attributes, needs fix
  ;;Expert setting added 2008-04-10 by Tom Haws
  ;;to quick and dirty make block redefine without error
  (SETQ OLDEXPERT (GETVAR "expert"))
  (SETVAR "expert" 5)
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
  ;;Expert setting added 2008-04-10 by Tom Haws
  ;;to quick and dirty make block redefine without error
  (SETVAR "expert" OLDEXPERT)
  ;;Prompt change 2008-04-10 Tom Haws
  (ALERT
    (PRINC
      "\nVehicle block definitions complete.  Move vehicle block into initial position.\n\nPosition Front Left Tire on start of path, and rotate vehicle to approximate starting direction.\n\nThen enter TURN to track path."
    )
  )
  (PRINC)
)
;;;==========================================
;;; End Buildvehicle                        |
;;;==========================================

;;;Start buildvehicle subfunctions
(DEFUN
   DRAWTARGET (STARTPOINT XLENGTH YLENGTH TARGETLAYER /)
  (SETQ
    CIRCLELIST
     (LIST
       (CONS 0 "CIRCLE")                ;(CONS 100 "AcDbEntity")
       (CONS 8 TARGETLAYER)             ;(CONS 100 "AcDbCircle")
       (CONS 40 (/ YLENGTH 4.0))
       (CONS 10 STARTPOINT)
     )
  )
  (ENTMAKE CIRCLELIST)
)
;;;
(DEFUN
   DRAWBOX (STARTPOINT XLENGTH YLENGTH BOXLAYER /)
  (SETQ BOXPOLYLIST NIL)
  (SETQ
    BOXPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS 8 BOXLAYER)
       ;; layer name
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ BOXPOLYLIST (CONS (CONS 10 STARTPOINT) BOXPOLYLIST))
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS 10 (POLAR STARTPOINT 0.0 XLENGTH))
       BOXPOLYLIST
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS
         10
         (POLAR
           (POLAR STARTPOINT 0.0 XLENGTH)
           (/ PI 2)
           YLENGTH
         )
       )
       BOXPOLYLIST
     )
  )
  (SETQ
    BOXPOLYLIST
     (CONS
       (CONS 10 (POLAR STARTPOINT (/ PI 2) YLENGTH))
       BOXPOLYLIST
     )
  )
  (SETQ BOXPOLYLIST (REVERSE BOXPOLYLIST))
  ;; commented by Tom haws 2008-04-10  (princ "making boxpolylist")
  (ENTMAKE BOXPOLYLIST)
  ;; commented by Tom haws 2008-04-10   (princ entlast)
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
       (CONS 0 "ATTDEF")                ;(CONS 100 "AcDbEntity")
                                        ;(CONS 100 "AcDbText")
                                        ;(CONS 100 "AcDbAttributeDefinition")
       (CONS 1 VALUE)
       (CONS 2 TAG)
       (CONS 3 ATTPROMPT)
       (CONS 8 ATTRIBLAYER)
       (CONS 10 INSPOINT)               ; not applicable insert point
       (CONS 11 INSPOINT)               ; this is the real insert point
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


(DEFUN
   TURN-MAIN-GENERATED-BLOCK-METHOD (/ ANGTRV DIRREAR1 DIRREAR2 DIRVEH1
                                     DIRVEH2 DSTTRV EMARK ENI ES1 I LVEH
                                     OSMOLD PFRONT1 PFRONT2 PREAR1
                                     PREAR2 TRACKLOCATION
                                     VEHICLEDATALIST
                                    )
  (SETVEHICLEDIMS)
  (SETQ
    ES1
     (ENTSEL "\nSelect starting end of polyline to track:")
     ;;TRACKLOCATION ("L")
     ;;(initget 1 "L M R")
     ;;(setq TRACKLOCATION (getkword "Is this track on the L eft, M iddle, or R ight of the front axle? (L or M or R) ")) 
  )
  (SETQ
    PFRONT1
     (OSNAP (CADR ES1) "endp")
    LVEH VEHWHEELBASE
    ;;(distance pfront1 prear1) ;This was the TURN.LSP method of getting wheelbase length
    DIRVEH1
     (CDR (ASSOC 50 (ENTGET VEHENTNAME)))
    ;;(ANGLE PFRONT1 PREAR1)  ;This was the TURN.LSP method of getting initial angle
    DIRTRAILER
     DIRVEH1
    DIRREAR1 DIRVEH1
    ;; Define step distance as 1/10 length of wheelbase
    ;;Edited 2008-04-10 by Tom Haws
    *TURN-CALCULATIONSTEP*
     (GETDISTX
       PFRONT1
       "\nCalculation step distance along front wheel path"
       *TURN-CALCULATIONSTEP*
       (/ LVEH 10.0)
     )
    ;; Plot frequency added 2008-04-10 by Tom Haws
    ;; Define plot frequency as every 50 steps
    *TURN-PLOTFREQUENCY*
     (GETINTX
       "\nNumber of calculation steps to skip between vehicle plots"
       *TURN-PLOTFREQUENCY*
       50
     )
    SS1
     (SSADD)
    OSMOLD
     (GETVAR "osmode")
  )
  (SETQ
    PREAR1
     (POLAR PFRONT1 DIRVEH1 LVEH)
    PPLT1 PREAR1
  )
  (SETVAR "osmode" 0)
  ;; Draw a point at first point of line
  (COMMAND "._point" PFRONT1)
  ;; Add point to selection set
  (SETQ
    ENI (ENTLAST)
    SS1 (SSADD ENI SS1)
  )
  ;; Divide pline up by step distance
  (COMMAND "._measure" ES1 *TURN-CALCULATIONSTEP*)
  ;; Build selection set of all points generated following first point
  (WHILE (SETQ ENI (ENTNEXT ENI)) (SETQ SS1 (SSADD ENI SS1)))
  (SETQ I (1- (SSLENGTH SS1)))
  ;; 20020625 Revision.  See header.
  ;;Reverse the selection set if the pline is backwards
  ;;(if picked point is closer to last MEASURE command point than first)
  (IF (< (DISTANCE
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
  ;;  End 20020625 Revision
  ;;  Initial Travel Angle from Pick Points
  (SETQ DIRVEHDRAW (ANGLE PREAR1 PFRONT1))
  (SETQ PATHSEGMENTS (1- (SSLENGTH SS1)))
  (DRAWBODY)
  (SETQ I 0)
  ;;_______Initiate Rear Left Path
  (SETQ
    REARLEFTTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS
         8
         (CAR
           (TURN-GETLAYER "TruckBackLeftTirePath")
         )
       )
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARLEFTTIREPATHLIST
     (CONS (CONS 10 PREAR1) REARLEFTTIREPATHLIST)
  )
  ;;_______Complete Initiate Rear Left Path
  ;;
  ;;_______Initiate Front Right Path
  (SETQ
    FRONTRIGHTTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS
         8
         (CAR
           (TURN-GETLAYER
             "TruckFrontRightTirePath"
           )
         )
       )
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    FRONTRIGHTTIREPATHLIST
     (CONS
       (CONS
         10
         (POLAR
           PFRONT1
           (+ DIRVEH1 (/ PI 2))
           VEHWHEELWIDTH
         )
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
       (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS
         8
         (CAR
           (TURN-GETLAYER "TruckBackRightTirePath")
         )
       )
       (CONS 100 "AcDbEntity")
       (CONS 0 "LWPOLYLINE")
     )
  )
  (SETQ
    REARRIGHTTIREPATHLIST
     (CONS
       (CONS
         10
         (POLAR
           PREAR1
           (+ DIRVEH1 (/ PI 2))
           VEHWHEELWIDTH
         )
       )
       REARRIGHTTIREPATHLIST
     )
  )
  ;;_______Complete Initiate Rear Right Path
  ;;
  ;;_______Initate Hitch Path
  (COND
    ((= TRAILHAVE "Yes")
     (SETQ
       HITCHPATHLIST
        (LIST
          (CONS 43 0.0)
          (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
          (CONS 90 PATHSEGMENTS)
          ;; polyline length
          (CONS 100 "AcDbPolyline")
          (CONS 8 (CAR (TURN-GETLAYER "HitchPath")))
          (CONS 100 "AcDbEntity")
          (CONS 0 "LWPOLYLINE")
        )
     )
     (SETQ
       HITCHPATHLIST
        (CONS
          (CONS
            10
            (POLAR
              PFRONT1
              (- DIRVEH1 REARHITCHANG)
              REARHITCHDIST
            )
          )
          HITCHPATHLIST
        )
     )
    )
  )
  ;;_______Complete Initiate Hitch Path
  ;; Calculate rear path.
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (WHILE (SETQ ENI (SSNAME SS1 (SETQ I (1+ I))))
    (PROGN
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
        PREAR1 PREAR2
        DIRVEH1 DIRVEH2
        DIRREAR1 DIRREAR2
        PPLT1
         PREAR2
         ;;End saving
      )
;;;  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Developmental Code, not ready for prime time, leave commented please
      ;; Indicate wheel turn angle on drawing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;(entmake ())
;;;      (princ "\n  start>>>>>>")
;;;    (princ (nth 0 PFRONT2))
;;;    (princ "\n  middle>>>>>>")
;;;    (princ (nth 1 PFRONT2))
;;;        (SETQ
;;;   ANGLETEXTLIST
;;;    (LIST
;;;      (CONS 0 "TEXT")  ; TEXT ENTITY
;;;     ;(CONS 100 "AcDbEntity")
;;;      (CONS 8 (car (turn-getlayer "TruckBody"))) ; TEXT LAYER
;;;     ;(CONS 100 "AcDbCircle")
;;;
;;;      (CONS
;;;        10
;;;        (nth 0 PFRONT2)
;;;      )
;;;      (CONS
;;;        20
;;;        (nth 1 PFRONT2)
;;;      )
;;;      (CONS 40 (/ VEHWIDTH 10)) ;TEXT HEIGHT
;;;      (CONS 1 (ANGTOS ANGTRN 0))
;;;      (CONS 50 (RTOS DIRTRV 2))
;;;    )
;;; )
;;; (ENTMAKE ANGLETEXTLIST)
;;;      (princ "\n  end")
                                        ;(SSADD (ENTLAST) VEHBLOCKLIST)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  End of Developmental Code
      ;;Insert block at 180 from direction of travel
    )
    (SETQ DIRVEHDRAW (+ PI DIRVEH2))
    ;;Logic change 2008-04-10 Tom Haws
    (IF (= (REM I *TURN-PLOTFREQUENCY*) 0)
      (DRAWBODY)
    )
    (SETQ
      REARLEFTTIREPATHLIST
       (CONS (CONS 10 PREAR2) REARLEFTTIREPATHLIST)
    )
    (SETQ
      FRONTRIGHTTIREPATHLIST
       (CONS
         (CONS
           10
           (POLAR
             PFRONT1
             (+ DIRVEH2 (/ PI 2))
             VEHWHEELWIDTH
           )
         )
         FRONTRIGHTTIREPATHLIST
       )
    )
    (SETQ
      REARRIGHTTIREPATHLIST
       (CONS
         (CONS
           10
           (POLAR
             PREAR2
             (+ DIRVEH2 (/ PI 2))
             VEHWHEELWIDTH
           )
         )
         REARRIGHTTIREPATHLIST
       )
    )
    (COND
      ((= TRAILHAVE "Yes")
       (SETQ
         HITCHPATHLIST
          (CONS
            (CONS
              10
              (POLAR
                PFRONT2
                (- DIRVEH2 REARHITCHANG)
                REARHITCHDIST
              )
            )
            HITCHPATHLIST
          )
       )
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
  (IF (= TRAILHAVE "Yes")
    (TRAILERPATH)
    (PRINC "\nTrailer not Included, no trailer calculated.")
  )
  (SETVAR "osmode" OSMOLD)
  (COMMAND "._erase" SS1 "")
  (REDRAW)
  (PRINC)
)
;;; CREATE_VAR
(DEFUN
   CREATE_VAR (PREFIX SUFFIX STRNG /)
  (SET (READ (STRCAT PREFIX SUFFIX)) STRNG)
  (READ (STRCAT PREFIX SUFFIX))
)
;;; SETVEHICLEDIMS
(DEFUN
   SETVEHICLEDIMS ()
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
     VAR '(VEHSTEERLOCK VEHSTEERLOCKTIME VEHARTANGLE VEHFRONTHANG
           VEHWHEELBASE VEHWHEELWIDTH VEHBODYLENGTH VEHWIDTH
           VEHREARHITCH TRAILERHITCHTOWHEEL TRAILERWHEELWIDTH
           TRAILERFRONTHANG TRAILERBODYLENGTH TRAILERWIDTH
          )
    (IF (= (TYPE (EVAL VAR)) 'STR)
      (SET VAR (ATOF (EVAL VAR)))
    )
  )
;;;====================================================================
  (SETQ
    FRONTLEFTBUMPANG
     (ATAN
       (/ (/ (- VEHWIDTH VEHWHEELWIDTH) 2) VEHFRONTHANG)
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
       (+ (* (- VEHWIDTH
                (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
             )
             (- VEHWIDTH
                (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
             )
          )
          (* VEHFRONTHANG VEHFRONTHANG)
       )
     )
  )
  (SETQ
    REARLEFTBUMPANG
     (+ (ATAN
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
     (+
       (ATAN
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
       (+ (* (- VEHWIDTH
                (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
             )
             (- VEHWIDTH
                (/ (- VEHWIDTH VEHWHEELWIDTH) 2)
             )
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
       (+ (* (/ VEHWHEELWIDTH 2) (/ VEHWHEELWIDTH 2))
          (* (+ VEHWHEELBASE VEHREARHITCH)
             (+ VEHWHEELBASE VEHREARHITCH)
          )
       )
     )
  )
  (SETQ
    FRONTLEFTTRAILERANG
     (ATAN (/ (/ TRAILERWIDTH 2) TRAILERFRONTHANG))
  )
  (SETQ
    FRONTLEFTTRAILERDIST
     (SQRT
       (+ (* (/ TRAILERWIDTH 2) (/ TRAILERWIDTH 2))
          (* TRAILERFRONTHANG TRAILERFRONTHANG)
       )
     )
  )
  (SETQ
    REARLEFTTRAILERANG
     (+ (ATAN
          (/ (/ TRAILERWIDTH 2)
             (+ TRAILERFRONTHANG TRAILERBODYLENGTH)
          )
        )
        PI
     )
  )
  (SETQ
    REARLEFTTRAILERDIST
     (SQRT
       (+ (* (/ TRAILERWIDTH 2) (/ TRAILERWIDTH 2))
          (* (+ TRAILERFRONTHANG TRAILERBODYLENGTH)
             (+ TRAILERFRONTHANG TRAILERBODYLENGTH)
          )
       )
     )
  )
)
;;;
;;;
;;;
(DEFUN
   DRAWBODY ()
  (SETQ
    TRUCKBODYPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS 8 (CAR (TURN-GETLAYER "TruckBody")))
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
   DRAWTRAILER ()
  (SETQ TRAILERBODYPOLYLIST NIL)
  (SETQ
    TRAILERBODYPOLYLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 1)
       ;; closed pline if set
       (CONS 90 4)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS 8 (CAR (TURN-GETLAYER "TrailerBody")))
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
           (+ DIRVEHDRAW REARLEFTTRAILERANG)
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
           (- DIRVEHDRAW REARLEFTTRAILERANG)
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
   TRAILERPATH ()
  ;; strip header stuff from trailerpointslist
  (WHILE (/= (CAR (CAR HITCHPATHLIST)) 10)
    (SETQ HITCHPATHLIST (CDR HITCHPATHLIST))
  )
  (SETQ HITCHPATHLISTCOUNT 0)
  (SETQ PPLT1 (CDR (NTH 0 HITCHPATHLIST)))
  (SETQ PFRONT1 PPLT1)
  ;; get first trailer point
  ;; Note that Dirtrailer was set at start of turn from direction of vehicle/trailer block
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
       (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       (CONS
         8
         (CAR
           (TURN-GETLAYER
             "TrailerBackLeftTirePath"
           )
         )
       )
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
  ;;_______Complete Initiate Rear Left Path (Tom Haws 2008-04-10)
  ;;
  ;;_______Initiate Rear Right Path
  ;;Initiation lacked items.  Fixed 2008-04-10 Tom Haws
  (SETQ
    REARRIGHTTRAILERTIREPATHLIST
     (LIST
       (CONS 43 0.0)
       (CONS 70 128)
;;; plinegen added 2008-04-10 by Tom Haws
       (CONS 90 PATHSEGMENTS)
       ;; polyline length
       (CONS 100 "AcDbPolyline")
       ;; polyline length
       (CONS
         8
         (CAR
           (TURN-GETLAYER
             "TrailerBackRightTirePath"
           )
         )
       )                                ;(CONS 100 "AcDbPolyline")
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
    (SETQ PFRONT2 (CDR (NTH HITCHPATHLISTCOUNT HITCHPATHLIST)))
    (SETQ
      ;; angle of travel this step
      DIRTRV
       (ANGLE PFRONT1 PFRONT2)
    )
    ;; angle between angle of travel and angle of vehicle
    (SETQ ALPHA (- DIRVEH1 DIRTRV))
    ;;Distance front wheels traveled this step
    (SETQ DSTTRV (DISTANCE PFRONT1 PFRONT2))
    (SETQ
      ;;Angle vehicle turned this step
      ANGTRN
       (* 2
          (ATAN
            (/ (SIN ALPHA) (- (/ (* 2 LVEH) DSTTRV) (COS ALPHA)))
          )
       )
    )
    (SETQ DIRVEH2 (+ DIRVEH1 ANGTRN))
    (SETQ PREAR2 (POLAR PFRONT2 DIRVEH2 LVEH))
    (SETQ PFRONT1 PFRONT2)
    (SETQ PREAR1 PREAR2)
    (SETQ DIRVEH1 DIRVEH2)
    (SETQ DIRREAR2 (ANGLE PPLT1 PREAR2))
    (SETQ DIRVEHDRAW (+ PI DIRVEH2))
    ;;Logic change 2008-04-10 Tom Haws
    (IF (= (REM HITCHPATHLISTCOUNT *TURN-PLOTFREQUENCY*) 0)
      (DRAWTRAILER)
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
      DIRREAR1 DIRREAR2
      PPLT1 PREAR2
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
   VEHICLEDATAGET (/ CHANGEFROMDEFAULT CONTINUELOAD ENTITYTYPE TAG VALUE
                   VEHICLEDATALISTLEN VEHICLEBLOCKNAME VEHICLEENTITYLIST
                  )
  (SETQ VEHICLEDATALIST NIL)
  (SETQ VEHICLEBLOCKNAME NIL)
  ;;Prompt change 2008-04-10 Tom Haws
  (SETQ VEHICLEBLOCKNAME (CAR (ENTSEL "\nSelect vehicle block: ")))
  (SETQ CHANGEFROMDEFAULT 0)
  ;;If a block was selected, get its data.  Otherwise alert and fail.
  (COND
    ((AND
       VEHICLEBLOCKNAME
       (SETQ VEHICLEENTITYLIST (ENTGET VEHICLEBLOCKNAME))
       (SETQ ENTITYTYPE (CDR (ASSOC 0 VEHICLEENTITYLIST)))
       (= ENTITYTYPE "INSERT")
     )
     ;;Preload default vehicle
     (PROGN
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
            (PROGN
              (SETQ VALUE (CDR (ASSOC 1 VEHICLEENTITYLIST)))
              (SETQ TAG (CDR (ASSOC 2 VEHICLEENTITYLIST)))
              ;;subst values in list
              ;;if a value has been substituted (even with same value),
              ;;then increment ChangeFromDefault by one
              (SETQ COUNT 0)
              (WHILE (< COUNT VEHICLEDATALISTLEN)
                (IF (= (CAR (NTH COUNT VEHICLEDATALIST)) TAG)
                  (PROGN
                    (SETQ OLDPAIR (NTH COUNT VEHICLEDATALIST))
                    (SETQ NEWPAIR (LIST TAG VALUE))
                    (SETQ
                      VEHICLEDATALIST
                       (SUBST
                         NEWPAIR
                         OLDPAIR
                         VEHICLEDATALIST
                       )
                    )
                    (SETQ CHANGEFROMDEFAULT (+ CHANGEFROMDEFAULT 1))
                  )
                )
                (SETQ COUNT (+ 1 COUNT))
              )
            )
           )
           ((= ENTITYTYPE "SEQEND") (SETQ CONTINUELOAD "NO"))
         )
       )
     )
    )                                   ;end progn
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
    ((= CHANGEFROMDEFAULT (1- VEHICLEDATALISTLEN))
                                        ;Edited 2008-04-10 Tom Haws. 
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
  (SETQ VEHICLEBLOCKNAME NIL)
  VEHICLEDATALIST
)
;;; Instead of computing path and plotting on the fly, for modular benefit, I want to build a path list and then
;;; use the list to plot things and get info.
;;; Here's how I think the list should look:
;;; The main list is a list of time frames.  The first time frame has no calculated data; only starting data.
;;; Each time frame list is a list of various vehicle segments.
;;; Each vehicle segment list is a list of points and dimensions for that vehicle segment
;;;
;;; CODE  ITEM
;;;  11   VFL (VEHICLE FRONT LEFT CORNER)
;;;  12   AFL (AXLE           ""  "")
;;;  13   ABL (AXLE    BACK   ""  "")
;;;  14   VBL 
;;;  22   AFM (              MIDDLE) 
;;;  23   ABM 
;;;  25   HITCH/HINGE
;;;  31   VFR 
;;;  32   AFR 
;;;  33   ABR 
;;;  34   VBR 
;;;  41   RFRONT
;;;  42   RBACK
;;;  43   RHINGE
;;;  50   DIRVEH
;;;  51   FRONT WHEEL TILT OR ARTICULATION ANGLE (CCW/LEFT +)
;;;  52   INCREASE IN TILT/ANGLE FROM LAST TIME STEP (CCW/LEFT +)
;;;           
(DEFUN
   TURN-MAIN-USER-BLOCK-METHOD (/ ANGTILT ANGTRV DIRVEH1 DIRVEH2 DSTTRV
                                EMARK ENI ES1 I LVEH OSMOLD PATHLIST
                                PFRONT1 PFRONT2 PBACK1 PBACK2 STEP
                               )
  (SETQ
    ES1
     (ENTSEL
       "\nSelect front axle path polyline at starting end: "
     )
    PFRONT1
     (OSNAP (CADR ES1) "endp")
    PBACK1
     (GETPOINT
       PFRONT1
       "\nEnter initial midpoint of back axle (TURN.LSP calculates wheelbase length and starting vehicle orientation from point entered): "
     )
    PPLT1 PBACK1
    LVEH
     (DISTANCE PFRONT1 PBACK1)
    DIRVEH1
     (ANGLE PFRONT1 PBACK1)
    *TURN-CALCULATIONSTEP*
     (GETDISTX
       PFRONT1
       "\nCalculation step distance along front axle path"
       *TURN-CALCULATIONSTEP*
       (/ LVEH 10.0)
     )
    *TURN-PLOTFREQUENCY*
     (GETINTX
       "\nNumber of calculation steps to skip between vehicle plots"
       *TURN-PLOTFREQUENCY*
       50
     )
    *TURN-VEHBLK*
     (CDR
       (ASSOC
         2
         (TBLSEARCH
           "BLOCK"
           (GETSTRINGX
             "Block name to place along path, or . for none"
             *TURN-VEHBLK*
             "TURNVEHICLE"
           )
         )
       )
     )
    SS1
     (SSADD)
    OSMOLD
     (GETVAR "osmode")
  )
  (SETVAR "osmode" 0)
  (COMMAND "._undo" "g" "._point" PFRONT1)
  (SETQ
    ENI (ENTLAST)
    SS1 (SSADD ENI SS1)
  )
  (COMMAND "._measure" ES1 *TURN-CALCULATIONSTEP*)
  (WHILE (SETQ ENI (ENTNEXT ENI)) (SETQ SS1 (SSADD ENI SS1)))
  (SETQ I (1- (SSLENGTH SS1)))
  ;; Reverse order of ._MEASURE points if PLINE drawn "backwards".
  ;;(if picked point is closer to last MEASURE command point than first)
  (IF (< (DISTANCE
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
  ;;First element in pathlist doesn't have any radius info.
  (SETQ
    I 0
    PATHLIST
     (LIST
       (LIST
         (CONS 22 PFRONT1)
         (CONS 23 PBACK1)
         (CONS 50 DIRVEH1)
       )
     )
  )
  ;; For every ._MEASURE point, calculate points and dimensions and add to pathlist
  ;; For now, only one vehicle is calculated.
  ;; To add more, change the initial prompts to keep asking for successive back points.
  (WHILE (SETQ ENI (SSNAME SS1 (SETQ I (1+ I))))
    (SETQ
      PFRONT2
       (TRANS (CDR (ASSOC 10 (ENTGET ENI))) ENI 1)
      ;; Direction of displacement of front wheels
      DIRTRV
       (ANGLE PFRONT1 PFRONT2)
      ;; Angle between travel vector and original vehicle front-to-back vector
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
      DIRVEH2
       (+ DIRVEH1 ANGTRN)
      ;; Average front wheel radius this step
      RFRONT
       (/ DSTTRV (* 2.0 (SIN (/ ANGTRN 2.0))))
      ;; Average wheel tilt or articulation angle this step
      ANGTILT
       (TURN-ASIN (/ LVEH RFRONT))
      ;; Average back wheel radius this step
      RBACK
       (/ LVEH (TURN-TAN ANGTILT))
      PBACK2
       (POLAR PFRONT2 DIRVEH2 LVEH)
      PFRONT1 PFRONT2
      PBACK1 PBACK2
      DIRVEH1 DIRVEH2
      ;;For now, only one vehicle is calculated.
      PATHLIST
       (CONS
         (LIST
           (CONS 22 PFRONT1)
           (CONS 23 PBACK1)
           (CONS 41 RFRONT)
           (CONS 42 RBACK)
           (CONS 50 DIRVEH1)
           (CONS 51 TILTANG)
         )
         PATHLIST
       )
      PPLT1 PBACK2
    )
  )
  (SETQ PATHLIST (REVERSE PATHLIST))
  ;; Erase the ._MEASURE points.
  (COMMAND "._erase" SS1 "")
  ;;Draw a polyline following one of the points in pathlist
  (COMMAND "._pline" (CDR (ASSOC 23 (CAR PATHLIST))) "w" 0 "")
  (FOREACH
     STEP (CDR PATHLIST)
    (COMMAND (CDR (ASSOC 23 STEP)))
  )
  (COMMAND "")
  ;; Loop insert a block representing one of the vehicles in pathlist.
  (COND
    (*TURN-VEHBLK*
     (SETQ I (* -1 *TURN-PLOTFREQUENCY*))
     (WHILE (SETQ STEP (NTH (SETQ I (+ I *TURN-PLOTFREQUENCY*)) PATHLIST))
       (ENTMAKE
         (LIST
           (CONS 0 "INSERT")
           (CONS 2 *TURN-VEHBLK*)
           (CONS 8 (GETVAR "CLAYER"))
           (CONS 10 (CDR (ASSOC 22 STEP)))
           (CONS 41 1.0)
           (CONS 42 1.0)
           (CONS 43 1.0)
           (CONS 50 (CDR (ASSOC 50 STEP)))
         )
       )
       (ENTMAKE '((0 . "SEQEND")))
     )
    )
  )
  (SETVAR "osmode" OSMOLD)
  (COMMAND "._undo" "e")
  (REDRAW)
  (PRINC)
)

;;; Not yet used.
;;; See TURN-MAIN-USER-BLOCK-METHOD for the working partial impementation of this.
;;; Function TRAILINGPATH
;;; Returns a list of points that define a wheel path
;;; that trails a given front wheel path
;;; with the initial point of the trailing path as given
;;; Usage:
;;;   (trailingpath
;;;     frontpath     The list of points that define the front path
;;;     rearstart     The first point on the trailing path
;;;   )
;;; Not yet used.
;;;
;;; Instead of computing path and plotting on the fly, for modular benefit, I want to build a path list and then
;;; use the list to plot things and get info.
;;; Here's how I think the list should look:
;;; The main list is a list of time frames
;;; Each time frame list is a list of various vehicle segments
;;; Each vehicle segment list is a list of points and dimensions for that vehicle segment
;;;
;;; CODE  ITEM
;;;  11   VFL (VEHICLE FRONT LEFT CORNER)
;;;  12   AFL (AXLE           ""  "")
;;;  13   ABL (AXLE    BACK   ""  "")
;;;  14   VBL
;;;  22   AFM (              MIDDLE)
;;;  23   ABM
;;;  25   HITCH/HINGE
;;;  31   VFR (VEHICLE FRONT RIGHT CORNER)
;;;  32   AFR (VEHICLE FRONT RIGHT CORNER)
;;;  33   ABR (VEHICLE FRONT RIGHT CORNER)
;;;  34   VBR (VEHICLE FRONT RIGHT CORNER)
;;;  41   RFRONT (FRONT PATH RADIUS)
;;;  42   RBACK (BACK PATH RADIUS)
;;;  43   RHINGE (HINGE RADIUS)
;;;  50   DIRVEH (VEHICLE DIRECTION)
;;;  51   FRONT WHEEL TILT OR ARTICULATION ANGLE (CCW/LEFT +)
;;;  52   INCREASE IN TILT/ANGLE FROM LAST TIME STEP (CCW/LEFT +)
(DEFUN
   TRAILINGPATH (FRONTPATH REARSTART / I J)
  (SETQ
    I 0
    PATHLISTLENGTH
     (LENGTH FRONTPATH)
    PREAR1 REARSTART
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
      PREAR1 PREAR2
      DIRVEH1 DIRVEH2
      DIRREAR1 DIRREAR2
      REARPATH
       (CONS PREAR2 REARPATH)
       ;;End saving
    )
  )
  (REVERSE REARPATH)
)

;;; GETDISTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (getdistx startingpoint promptstring currentvalue vanilladefault)
(DEFUN
   GETDISTX (STARTINGPOINT PROMPTSTRING CURRENTVALUE VANILLADEFAULT)
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
          (STRCAT
            PROMPTSTRING
            " <"
            (RTOS CURRENTVALUE)
            ">: "
          )
        )
       )
       (T CURRENTVALUE)
     )
  )
)
;;; Added 2008-04-10 by Tom Haws for vehicle plotting frequency prompt.
;;; GETINTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (getdistx startingpoint promptstring currentvalue vanilladefault)
(DEFUN
   GETINTX (PROMPTSTRING CURRENTVALUE VANILLADEFAULT)
  (SETQ
    CURRENTVALUE
     (COND
       (CURRENTVALUE)
       (VANILLADEFAULT)
       (0)
     )
  )
  (SETQ
    CURRENTVALUE
     (COND
       ((GETINT
          (STRCAT
            PROMPTSTRING
            " <"
            (ITOA CURRENTVALUE)
            ">: "
          )
        )
       )
       (T CURRENTVALUE)
     )
  )
)

(DEFUN
   GETSTRINGX (GX-PROMPT GX-CURRENTVALUE GX-DEFAULTVALUE / GX-INPUT)
  (SETQ
    GX-CURRENTVALUE
     (COND
       (GX-CURRENTVALUE)
       (GX-DEFAULTVALUE)
       ("")
     )
  )
  (SETQ
    GX-INPUT
     (GETSTRING
       (STRCAT "\n" GX-PROMPT " <" GX-CURRENTVALUE ">: ")
     )
  )
  (COND
    ((= GX-INPUT "") GX-CURRENTVALUE)
    ((= GX-INPUT ".") "")
    (T GX-INPUT)
  )
)

(DEFUN TURN-ASIN (X) (/ X (SQRT (- 1 (* X X)))))
(DEFUN TURN-TAN (THETA) (/ (SIN THETA) (COS THETA)))

;;Instructions on load-up added 2008-04-10 by Tom Haws
(PRINC
  (STRCAT
    "\nTURN.LSP version "
    (TURN-GETVAR "General.Version")
    " loaded.  Type TURN to start."
  )
)
(PRINC)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 2 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
