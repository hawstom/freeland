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
;;; Second, load and run TURN.   TURN currently has two behavior methods or versions.
;;; They are presented to you as options User block method/Generated block method:
;;; The User Block method doesn't keep track of as many vehicle dimensions and paths.
;;; It merely drags your block along a path.
;;; It also doesn't model hitches at this time, which limits its accuracy for trailers.
;;; The Generated Vehicle method doesn't show the nuances of a vehicle as well.
;;; It merely draws rectangles along with multiple calculated wheel paths.
;;; While we hope to harmonize the two methods, they are currently rather independent.
;;; If you choose the Generated vehicle method, TURN will ask you for all of the parameters
;;; for your vehicle, and draw a unique attributed block.  You can build a library
;;; of vehicles for future use. For any any group of multiple axles, use their "centroid"
;;; to model them as a single axle.
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
;;; For each computation step, a vehicle wheel pair (front and rear) is assumed
;;; to be traveling in a circle as though the steering wheel or articulating hinge
;;; were locked.  The front and rear wheels are circumscribing two concentric
;;; circles, with the line between rear and front wheel always tangent to the
;;; inner circle being made by the rear wheel, as shown:
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
;;; The initial locations of the rear and front wheels are known (B0 and F0), and the
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
(defun
   turn-initializesettings ()
;;; REVISION HISTORY
  (turn-setvar "General.Version" "1.2.0")
;;; Date     Programmer   Revision
;;; 201510   TGH          1.2.0  Major refactor DRY progress. Fixed turned angle.  Changed layer settings. Fixed trailer plotting.
;;; 20151022 TGH          1.1.14 Made some compatibility changes for IntelliCAD: "undo" "begin", "._-layer", skip first MEASURE point
;;; 20120425 TGH          1.1.13 Turned trailer box from bowtie into box (Again?!? See v. 1.1.10 and 1.1.7)
;;; 20110405 TGH          1.1.12 For CADDIT, changed local variable name from "layer" to "layer-list"
;;; 20100504 TGH          1.1.11 For Bricscad, changed "endp" osnap to "end"
;;; 20090312 TGH          1.1.10 Turned trailer box from bowtie into box (Again?!? See v. 1.1.7)
;;; 20090226 TGH          1.1.9  Minor tweak to version reporting
;;; 20081112 TGH          1.1.8  Added layer settings functions to consolidate names in one place
;;; 20080522 SH           1.1.7  Revised layers to an identifiable set, using AIA type standard.  placed under C for Civil
;;;                              and using TURN as a reserve header.  Also fixed trailer to draw as a box not a cross.
;;; 20080416 TGH          1.1.6  Added block plotting method with more modular code and defined data structure.
;;;                              combined both methods into one routine
;;; 20080410 TGH          1.1.5  Simplified prompts, added layer defaults, and fixed a few errors.;;; 20080206 SH           1.1.4  Fixed Imperial dimension storage, and made input consistent to type of data
;;; 20080120 SH           1.1.3  Various, including Centre of Wheels used instead of Outside of Wheels (vehicles
;;;                              steer on the centroids of the wheels, not the rims), "Set-out" point added at Front Left
;;;                              wheel
;;; 20070327 SH           1.1.2  Trailer plotting
;;; 20061213 TGH          1.1.1  Initial vehicle orientation from mandatory block selection instead of prompt.
;;; 20060324 SH           1.1.0  Added BUILDVEHICLE interface to allow overhang and sideswipe analysis.
;;; 20040507 TGH          1.0.1  Added osnap shutoff and restore.
;;; 20021025 TGH                 Replaced tracking equation with better algorithm.  Removed plot point reduction algorithm.
;;; 20020627 TGH          Added GETDISTX function to distribution file.
;;; 20020625 TGH          Added capability to follow reverse drawn polylines.
;;;
;;;----------------------------------------------------------------------------
;;; Program settings users can edit--------------------------------------------
;;;----------------------------------------------------------------------------
;;;
  (turn-setvar
    "IcadMode"
    (if (wcmatch (getvar "acadver") "*i")
      "TRUE"
      "FALSE"
    )
  )
;;; Layer settings.
;;; Descriptions aren't currently used.
  (turn-setlayer
    "TruckBody" "C-TURN-TRCK-BODY"
    "TURN.LSP rectangular box representing position of a vehicle at a step along a path"
    "1" ""
   )
  (turn-setlayer
    "TruckFrontLeftTirePath" "C-TURN-TRCK-FRONT-LEFT-PATH"
    "TURN.LSP vehicle front left tire path" "1" ""
   )
  (turn-setlayer
    "TruckFrontRightTirePath" "C-TURN-TRCK-FRONT-RGHT-PATH"
    "TURN.LSP vehicle front right tire path" "1" ""
   )
  (turn-setlayer
    "TruckRearLeftTirePath" "C-TURN-TRCK-REAR-LEFT-PATH"
    "TURN.LSP vehicle rear left tire path" "2" ""
   )
  (turn-setlayer
    "TruckrearRightTirePath" "C-TURN-TRCK-REAR-RGHT-PATH"
    "TURN.LSP vehicle rear right tire path" "2" ""
   )
  (turn-setlayer
    "HitchPath" "C-TURN-HTCH-PATH"
    "TURN.LSP path of connection between trailer and the vehicle pulling it" "3"
    ""
   )
  (turn-setlayer
    "TrailerBody" "C-TURN-TRAL-BODY"
    "TURN.LSP rectangular box representing position of a vehicle trailer at a step along a path"
    "4" ""
   )
  (turn-setlayer
    "TrailerRearLeftTirePath" "C-TURN-TRAL-REAR-LEFT-PATH"
    "TURN.LSP trailer rear left tire path" "4" ""
   )
  (turn-setlayer
    "TrailerRearRightTirePath" "C-TURN-TRAL-REAR-RGHT-PATH"
    "TURN.LSP trailer rear right tire path" "4" ""
   )
)
;;;
;;;----------------------------------------------------------------------------
;;; End of program settings users can edit-------------------------------------
;;;----------------------------------------------------------------------------
;;;
;;; TURN-SETVAR
(defun
   turn-setvar (varname value / newgroup oldgroup)
;;; For future compatibility with other storage options,
;;; We're keeping all values as strings (text).
  ;;Put VarName and Value together into a setting group.
  (setq
    varname
     (strcase varname)
    newgroup
     (cons varname value)
  )
  (cond
    ;;If the variable is already set, then
    ((setq oldgroup (assoc varname *turn:settings*))
     ;;Replace the old setting with the new setting.
     (setq *turn:settings* (subst newgroup oldgroup *turn:settings*))
    )
    ;;Else,
    (t
     ;;Add the setting.
     (setq *turn:settings* (cons newgroup *turn:settings*))
    )
  )
)
;;;
;;; TURN-GETVAR
(defun
   turn-getvar (varname / varnamemixed)
  (setq
    varnamemixed varname
    varname
     (strcase varname)
  )
  (cond
    ;;If the setting is found, then return it
    ((cdr (assoc varname *turn:settings*)))
    ;;Else
    (t
     ;;1.  Send an error message.
     (alert
       (princ
         (strcat
           "\nNo setting was found for "
           varnamemixed
           ".\nGeotables can't continue."
         )
       )
     )
     ;;2.  Exit
     (exit)
    )
  )
)

;;Sets up a layer setting
(defun
   turn-setlayer (basename laname ladesc lacolor laltype)
  (turn-setvar (strcat "Layers." basename ".Name") laname)
  (turn-setvar (strcat "Layers." basename ".Description") ladesc)
  (turn-setvar (strcat "Layers." basename ".Color") lacolor)
  (turn-setvar (strcat "Layers." basename ".Linetype") laltype)
)
;;Gets a layer list from a layer base name string.
(defun
   turn-getlayer (basename)
  (list
    (turn-getvar (strcat "Layers." basename ".Name"))
    (turn-getvar (strcat "Layers." basename ".Description"))
    (turn-getvar (strcat "Layers." basename ".Color"))
    (turn-getvar (strcat "Layers." basename ".Linetype"))
  )
)

;;; Layer settings added by Tom Haws 2008-04-10
(defun
   turn-makelayers (/ existing-layer layer-list)
  ;;Layer change 2008-02-22 Stephen Hitchcox
  (foreach
     basename '("TruckBody" "TrailerBody" "HitchPath" "TruckFrontLeftTirePath"
                "TruckFrontRightTirePath" "TruckRearLeftTirePath"
                "TruckRearRightTirePath" "TrailerRearLeftTirePath"
                "TrailerRearRightTirePath"
               )
    (setq
      layer-list
       (turn-getlayer basename)
      existing-layer-list
       (tblsearch "layer" (car layer-list))
    )
    (command
      "._-layer"
      "_thaw"
      (car layer-list)
      "_on"
      (car layer-list)
      "_unlock"
      (car layer-list)
      "_make"
      (car layer-list)
    )
    (if (not existing-layer-list)
      (command "_description" (cadr layer-list) (car layer-list))
    )
    (command "_color" (caddr layer-list) "" "_ltype" (cadddr layer-list) "" "")
  )
)

(turn-initializesettings)
(turn-makelayers)

(defun
   c:turn (/ method vehname)
  (initget "User Generated ?")
  (setq
    method
     (getkword "\nTracking method [User block/Generated vehicle/?]: ")
  )
  (cond
    ((= method "User") (turn-main-user-block-method))
    ((= method "Generated")
     (setq
       vehname
        (getstring
          "\nName for new vehicle or <select previously generated vehicle>: "
        )
     )
     (cond
       ((= vehname "") (turn-main-generated-block-method))
       (t (turn-buildvehicle vehname))
     )
    )
    ((= method "?")
     (alert
       (princ
         (strcat
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
  (prompt
    (strcat
      "\nTURN version "
      (turn-getvar "General.Version")
      " , Copyright (C) 2006 Thomas Gail Haws and Stephen Hitchcox"
      "\nTURN comes with ABSOLUTELY NO WARRANTY."
      "\nThis is free software, and you are welcome to modify and"
      "\nredistribute it under the terms of the GNU General Public License."
      "\nThe latest version of TURN is always available at autocad.wikia.com"
    )
  )
)

;;;C:BV short form call for (TURN-BUILDVEHICLE)
(defun c:bv () (turn-buildvehicle))
(defun
   turn-buildvehicle (vehname / layer-key circlelist heading-angle
                      heading-length oldexpert point-rear-mid startdrawpoint
                      swath-width targetx targety trailerbodylength
                      trailerfronthang trailerhitchtowheel trailerwheelwidth
                      trailerwidth trailhave trailname trailunits vehartangle
                      vehblocklist vehbodylength vehfronthang vehrearhitch
                      vehsteerlock vehsteerlocktime vehunits vehwheelbase
                      vehwheelwidth vehwidth wheel-f-x wheel-l-y wheel-r-x
                      wheel-r-y wheel-x wheellength wheelwidth
                     )
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
  (setq vehunits "M")
  ;;Prompt change 2008-04-11 Tom Haws
  (setq
    startdrawpoint
     (getpoint
       "\nLocation to build vehicle (midpoint of front bumper):  "
     )
  )
  ;;Prompt change 2008-04-10 Tom Haws
  (setq vehbodylength (getdist startdrawpoint "\nLength of vehicle body: "))
  ;;Prompt change 2008-04-10 Tom Haws
  (setq
    vehwidth
     (* 2 (getdist startdrawpoint "\nHalf width of vehicle body: "))
  )
  ;; Record VEHWIDTH
  ;; MAKEATTRIBUTE usage: (MakeAttribute InsPoint InsAngle Tag Value AttribLayer AttPrompt TextSize)
  (makeattribute
    (polar startdrawpoint pi (/ vehwidth 15))
    90.0
    "VEHWIDTH"
    (rtos vehwidth 2)
    "AttributeLayer"
    "Vehicle width"
    (/ vehwidth 15)
  )
  (setq vehblocklist (ssadd (entlast)))
  ;; Record VEHBODYLENGTH
  (makeattribute
    (polar
      (polar startdrawpoint (* 1.5 pi) (* vehwidth 0.55))
      0.0
      (/ vehbodylength 2)
    )
    0.0
    "VEHBODYLENGTH"
    (rtos vehbodylength 2)
    "AttributeLayer"
    "Vehicle body length"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  ;; Draw BODY
  (setq
    point-rear-mid
     (polar startdrawpoint 0 vehbodylength)
    heading-angle pi
    heading-length vehbodylength
    swath-width vehwidth
    layer-key "TruckBody"
  )
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (ssadd (entlast) vehblocklist)
  ;;Prompt change 2008-04-11 Tom Haws
  (setq
    vehfronthang
     (getdist
       startdrawpoint
       "\nFront overhang (distance from bumper to axle): "
     )
  )
  ;; Record front axle offset
  (makeattribute
    (polar startdrawpoint 0.0 (/ vehfronthang 2))
    0.0
    "VEHFRONTHANG"
    (rtos vehfronthang 2)
    "AttributeLayer"
    "Vehicle front overhang"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  (setq vehwheelbase (getdist "\nEnter vehicle wheelbase: "))
  (if (< vehbodylength (+ vehfronthang vehwheelbase))
    (princ
      "\nCaution, Vehicle Length is shorter than sum of Front Overhang and Wheelbase.  Errors could occur."
    )
  )
  ;; Record rear axle location
  (makeattribute
    (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase))
    90
    "VEHWHEELBASE"
    (rtos vehwheelbase 2)
    "AttributeLayer"
    "Vehicle wheelbase"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  ;; Record name of vehicle
  (makeattribute
    (polar startdrawpoint 0.0 (+ vehfronthang (/ vehwheelbase 2)))
    0.0
    "VEHNAME"
    vehname
    "AttributeLayer"
    "Vehicle name"
    (/ vehwidth 10)
  )
  (ssadd (entlast) vehblocklist)
  ;; Record units of vehicle
  (makeattribute
    (polar
      (polar startdrawpoint (* 1.5 pi) (* vehwidth 0.25))
      0.0
      (/ vehbodylength 2)
    )
    0.0
    "VEHUNITS"
    vehunits
    "AttributeLayer"
    "Vehicle units (Metric or Imperial)"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
;;; VehSteerLock isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
  (setq vehsteerlock 0.5)
  ;|
  (SETQ VEHSTEERLOCK (GETANGLE "\nEnter vehicle Steering Lock Angle:  (note that this is required but not used at this time)"))
  |;
  ;; Record vehicle Steering Lock Angle
  (makeattribute
    (polar startdrawpoint 0.0 (/ vehfronthang 3))
    90.0
    "VEHSTEERLOCK"
    (angtos vehsteerlock 0)
    "AttributeLayer"
    "Vehicle steering lock angle"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
;;; VEHSTEERLOCKTIME isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
  (setq vehsteerlocktime 0.0)
  ;|
  (SETQ
    VEHSTEERLOCKTIME
     (GETREAL "\nEnter vehicle steering lock time:  (note that this is required but not used at this time)")
  )
  |;
  ;; Record vehicle steer lock time
  (makeattribute
    (polar startdrawpoint 0.0 (* 2 (/ vehfronthang 3)))
    90.0
    "VEHSTEERLOCKTIME"
    (rtos vehsteerlocktime)
    "AttributeLayer"
    "Vehicle steer lock time"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  (setq
    vehwheelwidth
     ;;Prompt change 2008-04-11 Tom Haws
     (* 2
        (getdist
          startdrawpoint
          "\nHalf of maximum axle width to middle of wheels: "
        )
     )
  )
  ;; Record wheel width
  (makeattribute
    (polar startdrawpoint 0.0 vehfronthang)
    90.0
    "VEHWHEELWIDTH"
    (rtos vehwheelwidth 2)
    "AttributeLayer"
    "Vehicle wheel width"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  ;; Draw tires
  ;; Define Tire Size as 1/10th of vehicle dimensions (arbitrary, could be a future setting)
  (setq wheelwidth (/ vehwidth 10))
  (setq wheellength (/ vehbodylength 10))
  ;; Calculate coordinates of wheel rear midpoints
  (setq
    wheel-f-x
     (+ (car startdrawpoint) vehfronthang (/ wheellength 2))
    wheel-r-x
     (+ wheel-f-x vehwheelbase)
    wheel-l-y
     (- (cadr startdrawpoint) (/ vehwheelwidth 2))
    wheel-r-y
     (+ wheel-l-y vehwheelwidth)
  )
  ;; DRAW FRONT LEFT wheel
  (setq
    point-rear-mid
     (list wheel-f-x wheel-l-y)
    heading-angle pi
    heading-length wheellength
    swath-width wheelwidth
    layer-key "TruckBody"
  )
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (ssadd (entlast) vehblocklist)
  ;; Draw front right wheel
  (setq point-rear-mid (list wheel-f-x wheel-r-y))
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (ssadd (entlast) vehblocklist)
  ;; Draw rear left wheel
  (setq point-rear-mid (list wheel-r-x wheel-l-y))
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (ssadd (entlast) vehblocklist)
  ;; Draw rear right wheel
  (setq point-rear-mid (list wheel-r-x wheel-r-y))
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (ssadd (entlast) vehblocklist)
  ;; Draw front left target point
  (drawtarget
    (list (+ (car startdrawpoint) vehfronthang) (cadr startdrawpoint))
    wheellength
    wheelwidth
    "C-TURN-TRCK-BODY"
  )
  (ssadd (entlast) vehblocklist)
  ;; End of main vehicle entry
  ;; Start trailer entry
  (initget 1 "Yes No")
  (setq trailhave (getkword "\nDoes unit have a trailer? [Yes/No]:  "))
  (makeattribute
    (polar
      startdrawpoint
      0.0
      (+ vehfronthang vehwheelbase)     ;(* VEHREARHITCH 0.5)) Edited 2008-04-10 to accomodate prompt order change
    )
    90.0
    "TRAILHAVE"
    trailhave
    "AttributeLayer"
    "Does unit have a trailer"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  (cond
    ((= trailhave "Yes")
     ;;Moved hitch stuff 2008-04-10 by Tom Haws so non-trailer builds won't see it.
     (setq
       vehrearhitch
        (getdist
          "\nEnter distance from rear axle to hitch (forward is NEGATIVE):  "
        )
     )
     ;;Draw hitch
     (setq
       circlelist
        (list
          (cons 0 "CIRCLE")             ;(CONS 100 "AcDbEntity")
          (cons 8 "C-TURN-TRCK-BODY")   ;(CONS 100 "AcDbCircle")
          (cons 40 (/ vehwidth 10))
          (cons
            10
            (polar
              startdrawpoint
              0.0
              (+ vehfronthang vehwheelbase vehrearhitch)
            )
          )
        )
     )
     (entmake circlelist)
     (ssadd (entlast) vehblocklist)
     (makeattribute
       (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase vehrearhitch))
       90.0
       "VEHREARHITCH"
       (rtos vehrearhitch 2)
       "AttributeLayer"
       "Vehicle rear hitch location (forward is NEGATIVE): "
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Vehicle articulation angle not functional.  Prompt hidden by Tom Haws 2008-04-10.
     (setq vehartangle 0.5)
     ;|
     (SETQ VEHARTANGLE
     (GETANGLE "\nEnter vehicle articulation angle:  (note that this is required but not used at this time)")
     )
     |;
     ;; Record wheel width
     (makeattribute
       (polar
         startdrawpoint
         0.0
         (+ vehfronthang vehwheelbase (* vehrearhitch 1.5))
       )
       90.0
       "VEHARTANGLE"
       (angtos vehartangle 0)
       "AttributeLayer"
       "Vehicle articulation angle"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     (setq trailname (getstring "\nName for trailer:  "))
     ;| Code not used at this time.  Prompt hidden and default set by Tom Haws 2008-04-10
  ;;Input change 2008-04-10 Tom Haws
  (initget 1 "M I")
  (SETQ TRAILUNITS (GETKWORD "\nMetric or Imperial units [M/I]:  "))
  |; (setq trailunits "M")
     ;;Prompt change 2008-04-11 Tom Haws
     (setq
       trailerhitchtowheel
        (getdist "\nDistance from hitch to trailer axle:  ")
     )
     ;;Prompt change 2008-04-11 Tom Haws
     (setq
       trailerwheelwidth
        (*
          2
          (getdist
            "\nHalf of maximum trailer axle width to middle of wheels:  "
          )
        )
     )
     (setq
       trailerfronthang
        (getdist
          "\nDistance from hitch to front of trailer (forward is NEGATIVE):  "
        )
     )
     (setq trailerbodylength (getdist "\nOverall trailer length:  "))
     (setq trailerwidth (* 2 (getdist "\nHalf of trailer width:  ")))
     ;; Record trailer Length
     (makeattribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILERBODYLENGTH"
       (rtos trailerbodylength 2)
       "AttributeLayer"
       "Trailer body length"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer name
     (makeattribute
       (polar
         startdrawpoint
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILNAME"
       trailname
       "AttributeLayer"
       "Trailer name"
       (/ vehwidth 10)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer units
     (makeattribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.25))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILUNITS"
       trailunits
       "AttributeLayer"
       "Trailer units"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailerfronthang
     (makeattribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase (- vehrearhitch (/ trailerfronthang 2)))
       )
       0.0
       "TRAILERFRONTHANG"
       (rtos trailerfronthang 2)
       "AttributeLayer"
       "Trailer front overhang"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer to wheel length
     (makeattribute
       (polar
         (polar startdrawpoint (* 0.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILERHITCHTOWHEEL"
       (rtos trailerhitchtowheel 2)
       "AttributeLayer"
       "Trailer hitch to wheel length"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer width
     (makeattribute
       (polar
         startdrawpoint
         0.0
         (+ vehfronthang
            vehwheelbase
            vehrearhitch
            (- trailerbodylength trailerfronthang)
         )
       )
       90.0
       "TRAILERWIDTH"
       (rtos trailerwidth 2)
       "AttributeLayer"
       "Trailer width"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer wheel width
     (makeattribute
       (polar
         startdrawpoint
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch trailerhitchtowheel)
       )
       90.0
       "TRAILERWHEELWIDTH"
       (rtos trailerwheelwidth 2)
       "AttributeLayer"
       "Trailer axle width to middle of wheels"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Draw trailer
     (setq
       point-rear-mid
        (polar
          startdrawpoint
          0
          (- (+ vehfronthang vehwheelbase vehrearhitch trailerhitchtowheel
                trailerbodylength
               )
             trailerfronthang
          )
        )
       heading-angle pi
       heading-length trailerbodylength
       swath-width trailerwidth
       layer-key "TrailerBody"
     )
     (wiki-turn-draw-box-v2
       point-rear-mid heading-angle heading-length swath-width layer-key
      )
     (ssadd (entlast) vehblocklist)
     ;; Calculate coordinates of wheel rear midpoints
     (setq
       wheel-x
        (+ (car startdrawpoint)
           vehfronthang
           vehwheelbase
           vehrearhitch
           trailerhitchtowheel
           (/ wheellength 2)
        )
       wheel-l-y
        (- (cadr startdrawpoint) (+ (/ trailerwheelwidth 2)))
       wheel-r-y
        (+ wheel-l-y trailerwheelwidth)
     )
     ;; DRAW LEFT wheel
     (setq
       point-rear-mid
        (list wheel-x wheel-l-y)
       heading-angle pi
       heading-length wheellength
       swath-width wheelwidth
       layer-key "TrailerBody"
     )
     (wiki-turn-draw-box-v2
       point-rear-mid heading-angle heading-length swath-width layer-key
      )
     (ssadd (entlast) vehblocklist)
     ;; Draw right wheel
     (setq point-rear-mid (list wheel-x wheel-r-y))
     (wiki-turn-draw-box-v2
       point-rear-mid heading-angle heading-length swath-width layer-key
      )
     (ssadd (entlast) vehblocklist)
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
  (setq oldexpert (getvar "expert"))
  (setvar "expert" 5)
  (command
    "-block"
    (strcat "VEHICLELIB" vehname)
    startdrawpoint
    vehblocklist
    ""
  )
  (command "-insert" (strcat "VEHICLELIB" vehname) startdrawpoint "" "" "")
  ;;Expert setting added 2008-04-10 by Tom Haws
  ;;to quick and dirty make block redefine without error
  (setvar "expert" oldexpert)
  ;;Prompt change 2008-04-10 Tom Haws
  (alert
    (princ
      "\nVehicle block definitions complete.  Move vehicle block into initial position.\n\nPosition middle of front axle on start of path, and rotate vehicle to approximate starting direction.\n\nThen enter TURN to track path."
    )
  )
  (princ)
)
;;;==========================================
;;; End Buildvehicle                        |
;;;==========================================

;;;Start buildvehicle subfunctions
(defun
   drawtarget (startpoint xlength ylength targetlayer /)
  (setq
    circlelist
     (list
       (cons 0 "CIRCLE")                ;(CONS 100 "AcDbEntity")
       (cons 8 targetlayer)             ;(CONS 100 "AcDbCircle")
       (cons 40 (/ ylength 4.0))
       (cons 10 startpoint)
     )
  )
  (entmake circlelist)
)
;;;
(defun
   drawbox (startpoint xlength ylength boxlayer /)
  (setq boxpolylist nil)
  (setq
    boxpolylist
     (list
       (cons 43 0.0)
       ;; closed pline if set
       (cons 70 1)
       ;; polyline length
       (cons 90 4)
       (cons 100 "AcDbPolyline")
       (cons 8 boxlayer)
       ;; layer name
       (cons 100 "AcDbEntity")
       (cons 0 "LWPOLYLINE")
     )
  )
  (setq boxpolylist (cons (cons 10 startpoint) boxpolylist))
  (setq boxpolylist (cons (cons 10 (polar startpoint 0.0 xlength)) boxpolylist))
  (setq
    boxpolylist
     (cons
       (cons
         10
         (polar (polar startpoint 0.0 xlength) (/ pi 2) ylength)
       )
       boxpolylist
     )
  )
  (setq
    boxpolylist
     (cons (cons 10 (polar startpoint (/ pi 2) ylength)) boxpolylist)
  )
  (setq boxpolylist (reverse boxpolylist))
  ;; commented by Tom haws 2008-04-10  (princ "making boxpolylist")
  (entmake boxpolylist)
  ;; commented by Tom haws 2008-04-10   (princ entlast)
)
;; Added 2015-10-28 by Tom Haws to resolve trailer plotting bowtie and front offset issues.
(defun
   wiki-turn-draw-box-v2 (point-rear-mid heading-angle heading-length
                          swath-width layer-key / box-pline-list
                          point-front-left point-front-right point-rear-left
                          point-rear-right
                         )
  (setq
    box-pline-list
     (list
       (cons 43 0.0)
       ;; closed pline if set
       (cons 70 1)
       ;; number of pline coordinates
       (cons 90 4)
       (cons 100 "AcDbPolyline")
       (cons 100 "AcDbEntity")
       (cons 0 "LWPOLYLINE")
     )
    point-rear-left
     (polar
       point-rear-mid
       (+ heading-angle (/ pi 2))
       (/ swath-width 2)
     )
    point-rear-right
     (polar
       point-rear-mid
       (- heading-angle (/ pi 2))
       (/ swath-width 2)
     )
    point-front-left
     (polar point-rear-left heading-angle heading-length)
    point-front-right
     (polar point-rear-right heading-angle heading-length)
  )
  (if layer-key
    (setq
      box-pline-list
       (cons
         (cons 8 (car (turn-getlayer layer-key)))
         box-pline-list
       )
    )
  )
  (wiki-turn-add-point-to-box-pline-list point-front-left)
  (wiki-turn-add-point-to-box-pline-list point-rear-left)
  (wiki-turn-add-point-to-box-pline-list point-rear-right)
  (wiki-turn-add-point-to-box-pline-list point-front-right)
  (setq box-pline-list (reverse box-pline-list))
  ;; commented by Tom haws 2008-04-10  (princ "making box-pline-list")
  (entmake box-pline-list)
  ;; commented by Tom haws 2008-04-10   (princ entlast)
)


(defun
   wiki-turn-add-point-to-box-pline-list (add-point)
  (setq box-pline-list (cons (cons 10 add-point) box-pline-list))
)


;;;
;;;
;;;
(defun
   makeattribute (inspoint insangle tag value attriblayer attprompt textsize)
  (setq attributelist nil)
  (setq
    attributelist
     (list
       (cons 0 "ATTDEF")                ;(CONS 100 "AcDbEntity")
                                        ;(CONS 100 "AcDbText")
                                        ;(CONS 100 "AcDbAttributeDefinition")
       (cons 1 value)
       (cons 2 tag)
       (cons 3 attprompt)
       (cons 8 attriblayer)
       (cons 10 inspoint)               ; not applicable insert point
       (cons 11 inspoint)               ; this is the real insert point
       (cons 40 textsize)
       (cons 50 (* (/ insangle 360) (* 2 pi)))
       (cons 70 8)
       (cons 72 4)
     )
  )
  (entmake attributelist)
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


(defun
   turn-main-generated-block-method (/ alpha angle-turned layer-key dirtrailer dirtrv
                                     heading-0 heading-1 dirvehdraw dsttrv en-guide-point-i es-guide-path
                                     frontlefttirepathlist
                                     frontrighttirepathlist heading-angle
                                     heading-length hitchpath hitchpathlist i wheelbase
                                     osmold pathsegments point-calc-front-0
                                     point-calc-front-1 point-rear-mid
                                     point-calc-rear-0 point-calc-rear-1
                                     rearhitchang rearhitchdist
                                     rearlefttirepathlist rearrighttirepathlist
                                     ss-guide-points swath-width trailhave vehbodylength
                                     vehentname vehfronthang vehwheelbase
                                     vehwheelwidth vehwidth
                                    )
  (setvehicledims)
  (setq
    es-guide-path
     (entsel "\nSelect starting end of polyline to track:")
     ;;TRACKLOCATION ("L")
     ;;(initget 1 "L M R")
     ;;(setq TRACKLOCATION (getkword "Is this track on the L eft, M iddle, or R ight of the front axle? (L or M or R) ")) 
  )
  (setq
    ;; The two fundamental geometric values are prfront1 and point-calc-rear-0.  From them we easily calculate anything else on the fly.
    point-calc-front-0
     (osnap (cadr es-guide-path) "end")
    point-calc-rear-0
     (polar
       point-calc-front-0
       (cdr (assoc 50 (entget vehentname)))
       vehwheelbase
     )
    wheelbase vehwheelbase
    heading-0
     (angle point-calc-rear-0 point-calc-front-0)
    dirtrailer heading-0
    ;; Define step distance as 1/10 length of wheelbase
    ;;Edited 2008-04-10 by Tom Haws
    *turn-calculationstep*
     (getdistx
       point-calc-front-0
       "\nCalculation step distance along front wheel path"
       *turn-calculationstep*
       (/ wheelbase 10.0)
     )
    ;; Plot frequency added 2008-04-10 by Tom Haws
    ;; Define plot frequency as every 50 steps
    *turn-plotfrequency*
     (max
       (getintx
         "\nNumber of calculation steps to skip between vehicle plots"
         *turn-plotfrequency*
         50
       )
       1
     )
    ss-guide-points
     (ssadd)
    osmold
     (getvar "osmode")
  )
  (setq
    point-calc-rear-0
     (polar point-calc-front-0 heading-0 (* -1 wheelbase))
    point-calc-rear-0
  )
  (setvar "osmode" 0)
  ;; Draw a point at first point of line
  (command "._point" point-calc-front-0)
  ;; Add point to selection set
  (setq
    en-guide-point-i (entlast)
    ss-guide-points (ssadd en-guide-point-i ss-guide-points)
  )
  ;; Divide pline up by step distance
  (command "._measure" es-guide-path *turn-calculationstep*)
  ;; MEASURE command in IntelliCAD places a point at beginning of polyline. 
  ;; If in IntelliCAD, skip that point.
  (if (= (turn-getvar "IcadMode") "TRUE")
    (setq en-guide-point-i (entnext en-guide-point-i))
  )
  ;; Build selection set of all points generated following first point
  (while (setq en-guide-point-i (entnext en-guide-point-i)) (setq ss-guide-points (ssadd en-guide-point-i ss-guide-points)))
  (setq i (1- (sslength ss-guide-points)))
  ;; 20020625 Revision.  See header.
  ;;Reverse the selection set if the pline is rearwards
  ;;(if picked point is closer to last MEASURE command point than first)
  (if (< (distance
           (trans
             ;; the coordinates of the point to translate
             (cdr (assoc 10 (entget (ssname ss-guide-points i))))
             ;; from pline coordinate system
             (ssname ss-guide-points i)
             ;; to user coordinate system
             1
           )
           ;; the picked point, which is in the user coordinate system
           point-calc-front-0
         )
         (distance
           (trans
             ;; the coordinates of the point to translate
             (cdr (assoc 10 (entget (ssname ss-guide-points 1))))
             ;; from pline coordinate system
             (ssname ss-guide-points 1)
             ;; to user coordinate system
             1
           )
           ;; the picked point, which is in the user coordinate system
           point-calc-front-0
         )
      )
    (while (< 0 (setq i (1- i)))
      (setq en-guide-point-i (ssname ss-guide-points i))
      (ssdel en-guide-point-i ss-guide-points)
      (ssadd en-guide-point-i ss-guide-points)
    )
  )
  ;;  End 20020625 Revision
  ;;  Initial Travel Angle from Pick Points
  (setq dirvehdraw dirveh)
  (setq pathsegments (1- (sslength ss-guide-points)))
  (setq
    point-rear-mid
     (polar
       point-calc-front-0
       (angle point-calc-front-0 point-calc-rear-0)
       (- vehbodylength vehfronthang)
     )
    heading-angle
     (angle point-calc-rear-0 point-calc-front-0)
    heading-length vehbodylength
    swath-width vehwidth
    layer-key "TruckBody"
  )
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (setq i 0)
  ;; Initiate path pline plots
  (wt-initiate-path
    'frontlefttirepathlist
    pathsegments
    "TruckFrontLeftTirePath"
    (polar point-calc-front-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wt-initiate-path
    'frontrighttirepathlist
    pathsegments
    "TruckFrontRightTirePath"
    (polar point-calc-front-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wt-initiate-path
    'rearlefttirepathlist
    pathsegments
    "TruckRearLeftTirePath"
    (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wt-initiate-path
    'rearrighttirepathlist
    pathsegments
    "TruckRearRightTirePath"
    (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (cond
    ((= trailhave "Yes")
     (wt-initiate-path
       'hitchpathlist
       pathsegments
       "HitchPath"
       (polar point-calc-rear-0 heading-0 (* vehrearhitch -1))
     )
    )
  )
  ;; Calculate rear path.
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (while (setq en-guide-point-i (ssname ss-guide-points (setq i (1+ i))))
      (setq
        ;; set second point to the location of en-guide-point-i in the current UCS
        point-calc-front-1
         (trans (cdr (assoc 10 (entget en-guide-point-i))) en-guide-point-i 1)
        ;;Angle vehicle turned this step
        angle-turned
         (wt-angle-turned point-calc-front-0 heading-0 point-calc-front-1 wheelbase)
        ;;Direction of vehicle at end of this step
        heading-1
         (+ heading-0 angle-turned)
        ;;Location of rear wheel at end of this step
        point-calc-rear-1
         (polar point-calc-front-1 heading-1 (* -1 wheelbase))
        distrear
         (distance point-calc-rear-0 point-calc-rear-1)
        ;;Save this step's variables
        point-calc-front-0
         point-calc-front-1
        point-calc-rear-0 point-calc-rear-1
        heading-0 heading-1
         ;;End saving
      )
;;;  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Developmental Code, not ready for prime time, leave commented please
      ;; Indicate wheel turn angle on drawing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;(entmake ())
;;;      (princ "\n  start>>>>>>")
;;;    (princ (nth 0 point-calc-front-1))
;;;    (princ "\n  middle>>>>>>")
;;;    (princ (nth 1 point-calc-front-1))
;;;        (SETQ
;;;   ANGLETEXTLIST
;;;    (LIST
;;;      (CONS 0 "TEXT")  ; TEXT ENTITY
;;;     ;(CONS 100 "AcDbEntity")
;;;      (CONS 8 (cadr (turn-getlayer "TruckBody"))) ; TEXT LAYER
;;;     ;(CONS 100 "AcDbCircle")
;;;
;;;      (CONS
;;;        10
;;;        (nth 0 point-calc-front-1)
;;;      )
;;;      (CONS
;;;        20
;;;        (nth 1 point-calc-front-1)
;;;      )
;;;      (CONS 40 (/ VEHWIDTH 10)) ;TEXT HEIGHT
;;;      (CONS 1 (ANGTOS angle-turned 0))
;;;      (CONS 50 (RTOS DIRTRV 2))
;;;    )
;;; )
;;; (ENTMAKE ANGLETEXTLIST)
;;;      (princ "\n  end")
                                        ;(SSADD (ENTLAST) VEHBLOCKLIST)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  End of Developmental Code
    ;|
    ;; Test logic
    ;; Vehicle direction is perpendicular to radius of turning circle.
    ;; Try drawing a line from center of that circle to rear axle.
    (wt-mkline
      point-calc-rear-1
      (polar
        point-calc-rear-1
        (+ heading-0 (/ pi 2))
        (/ distrear 2 (sin (/ angle-turned 2)))
      )
    )|;
    ;;Logic change 2008-04-10 Tom Haws
    (cond
      ((= (rem i *turn-plotfrequency*) 0)
       (setq
         point-rear-mid
          (polar
            point-calc-front-0
            heading-0
            (- vehfronthang vehbodylength)
          )
         heading-angle
          (angle point-calc-rear-0 point-calc-front-0)
         heading-length vehbodylength
         swath-width vehwidth
         layer-key "TruckBody"
       )
       (wiki-turn-draw-box-v2
         point-rear-mid heading-angle heading-length swath-width layer-key
        )
      )
    )
    (wt-add-point-to-path
      'frontlefttirepathlist
      (polar point-calc-front-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wt-add-point-to-path
      'frontrighttirepathlist
      (polar point-calc-front-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wt-add-point-to-path
      'rearlefttirepathlist
      (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wt-add-point-to-path
      'rearrighttirepathlist
      (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (cond
      ((= trailhave "Yes")
       (setq
         hitchpathlist
          (cons
            (cons
              10
              (polar point-calc-rear-0 heading-0 (* -1 vehrearhitch))
            )
            hitchpathlist
          )
       )
      )
    )
  )
  (setq frontlefttirepathlist (reverse frontlefttirepathlist))
  (entmake frontlefttirepathlist)
  (setq frontrighttirepathlist (reverse frontrighttirepathlist))
  (entmake frontrighttirepathlist)
  (setq rearlefttirepathlist (reverse rearlefttirepathlist))
  (entmake rearlefttirepathlist)
  (setq rearrighttirepathlist (reverse rearrighttirepathlist))
  (entmake rearrighttirepathlist)
  (setq hitchpathlist (reverse hitchpathlist))
  (entmake hitchpathlist)
  (setq hitchpath (entlast))
  (if (= trailhave "Yes")
    (trailerpath)
    (princ "\nTrailer not Included, no trailer calculated.")
  )
  (setvar "osmode" osmold)
  (command "._erase" ss-guide-points "")
  (redraw)
  (princ)
)

(defun wt-track=step (point-calc-rear-0 point-calc-front-0 point-calc-front-1 / )
  
  (list
    (cons "angle-turned" angle-turned)
    (cons "rear-radius" rear-radius)
    (cons "front-radius" front-radius)
    (cons "point-calc-rear-1" point-calc-rear-1)
  )
)

(defun
   wt-angle-turned (point-calc-front-0 heading-0 point-calc-front-1 wheelbase /
                    front-direction front-distance course-deviation
                   )
  (setq
    ;; angle of travel this step
    front-direction
     (angle point-calc-front-0 point-calc-front-1)
    ;; angle between angle of travel and angle of vehicle
    course-deviation
     (- heading-0 front-direction)
    course-deviation-supplementary
     (- pi (abs course-deviation))
    ;;Distance front wheels traveled this step
    front-distance
     (distance point-calc-front-0 point-calc-front-1)
    ;;Angle vehicle turned this step
    angle-turned
     (* 2
        (if (minusp course-deviation) 1 -1)
        (atan
          (/ (sin course-deviation-supplementary)
             (- (/ (* 2 wheelbase) front-distance) (cos course-deviation-supplementary))
          )
        )
     )
  )
)
   
(defun
   wt-initiate-path (list-name n-points layer-key first-point)
  (set
    list-name
    (list
      (cons 43 0.0)
      ;; plinegen added 2008-04-10 by Tom Haws
      (cons 70 128)
      (cons 90 pathsegments)
      ;; polyline length
      (cons 100 "AcDbPolyline")
      (cons 8 (car (turn-getlayer layer-key)))
      (cons 100 "AcDbEntity")
      (cons 0 "LWPOLYLINE")
    )
  )
  (wt-add-point-to-path list-name first-point)
)
(defun
   wt-add-point-to-path (list-name add-point)
  (set list-name (cons (cons 10 add-point) (eval list-name)))
)

;;; CREATE_VAR
(defun
   create_var (prefix suffix strng /)
  (set (read (strcat prefix suffix)) strng)
  (read (strcat prefix suffix))
)
;;; SETVEHICLEDIMS
(defun
   setvehicledims ()
  (setq vehicledatalist (vehicledataget))
  (setq vehicledatalistlen (length vehicledatalist))
  (setq datacount 0)
  (while (< datacount vehicledatalistlen)
    (progn
      (setq varname (car (nth datacount vehicledatalist)))
      (setq varvalue (cadr (nth datacount vehicledatalist)))
      ;| No need to change to STRINGS just to change right rear to REALS
      (COND
 ((= (TYPE VARVALUE) REAL) (SETQ VARVALUE (RTOS VARVALUE)))
 ((= (TYPE VARVALUE) INT) (SETQ VARVALUE (ITOA VARVALUE)))
      )|;
      (set (read varname) varvalue)
      (setq datacount (+ 1 datacount))
    )
  )
  (princ "\n done with loading and defining")
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
  (foreach
     var '(vehsteerlock vehsteerlocktime vehartangle vehfronthang vehwheelbase
           vehwheelwidth vehbodylength vehwidth vehrearhitch trailerhitchtowheel
           trailerwheelwidth trailerfronthang trailerbodylength trailerwidth
          )
    (if (= (type (eval var)) 'str)
      (set var (atof (eval var)))
    )
  )
;;;====================================================================
)

;;; Function TrailerPath

(defun
   trailerpath ()
  ;; strip header stuff from trailerpointslist
  (while (/= (car (car hitchpathlist)) 10)
    (setq hitchpathlist (cdr hitchpathlist))
  )
  (setq hitchpathlistcount 0)
  (setq point-calc-front-0 (cdr (nth 0 hitchpathlist)))
  ;; get first trailer point
  ;; Note that Dirtrailer was set at start of turn from direction of vehicle/trailer block
  (setq heading-0 dirtrailer)
  (setq point-calc-rear-0 (polar point-calc-front-0 heading-0 (* -1 trailerhitchtowheel)))
  ;; Draw initial position of trailer.
  (setq
    point-rear-mid
     (polar
       point-calc-rear-0
       heading-0
       (- trailerfronthang trailerbodylength)
     )
    heading-angle
     heading-0
    heading-length trailerbodylength
    swath-width trailerwidth
    layer-key "TrailerBody"
  )
  (wiki-turn-draw-box-v2
    point-rear-mid heading-angle heading-length swath-width layer-key
   )
  (wt-initiate-path
    'rearlefttrailertirepathlist
    pathsegments
    "TrailerRearLeftTirePath"
    (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ trailerwheelwidth 2))
  )
  (wt-initiate-path
    'rearrighttrailertirepathlist
    pathsegments
    "TrailerRearRightTirePath"
    (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ trailerwheelwidth 2))
  )
  (setq hitchpathlistcount (1+ hitchpathlistcount))
  (while (< hitchpathlistcount pathsegments)
    (setq
      point-calc-front-1
       (cdr (nth hitchpathlistcount hitchpathlist))
      ;;Angle vehicle turned this step
      angle-turned
       (wt-angle-turned
         point-calc-front-0
         heading-0
         point-calc-front-1
         trailerhitchtowheel
       )
      heading-1
       (+ heading-0 angle-turned)
      point-calc-rear-1
       (polar point-calc-front-1 heading-1 (* -1 trailerhitchtowheel))
      point-calc-front-0 point-calc-front-1
      point-calc-rear-0 point-calc-rear-1
      heading-0 heading-1
      dirvehdraw
       (+ pi heading-1)
    )
    ;;Logic change 2008-04-10 Tom Haws
    ;; Draw trailer
    (cond
      ((= (rem hitchpathlistcount *turn-plotfrequency*) 0)
       (setq
         point-rear-mid
          (polar
            point-calc-rear-0
            heading-0
            (- trailerfronthang trailerbodylength)
          )
         heading-angle
          (angle point-calc-rear-0 point-calc-front-0)
         heading-length trailerbodylength
         swath-width trailerwidth
         layer-key "TrailerBody"
       )
       (wiki-turn-draw-box-v2
         point-rear-mid heading-angle heading-length swath-width layer-key
        )
      )
    )
    (wt-add-point-to-path
      'rearlefttrailertirepathlist
      (polar
             point-calc-rear-0
             (+ heading-0 (/ pi 2))
             (/ trailerwheelwidth 2)
           )
    )
    (wt-add-point-to-path
      'rearrighttrailertirepathlist
      (polar
             point-calc-rear-0
             (- heading-1 (/ pi 2))
             (/ trailerwheelwidth 2)
           )
    )
    (setq hitchpathlistcount (1+ hitchpathlistcount))
  )
  (setq rearlefttrailertirepathlist (reverse rearlefttrailertirepathlist))
  (entmake rearlefttrailertirepathlist)
  (setq rearrighttrailertirepathlist (reverse rearrighttrailertirepathlist))
  (entmake rearrighttrailertirepathlist)
)

;; VEHICLEDATAGET gets the vehicle attributes from a BUILDVEHICLE
;; defined block.
;; Returns a list of vehicle properties.
(defun
   vehicledataget (/ changefromdefault continueload entitytype tag value
                   vehicledatalistlen vehicleblockname vehicleentitylist
                  )
  (setq vehicledatalist nil)
  (setq vehicleblockname nil)
  ;;Prompt change 2008-04-10 Tom Haws
  (setq vehicleblockname (car (entsel "\nSelect vehicle block: ")))
  (setq changefromdefault 0)
  ;;If a block was selected, get its data.  Otherwise alert and fail.
  (cond
    ((and
       vehicleblockname
       (setq vehicleentitylist (entget vehicleblockname))
       (setq entitytype (cdr (assoc 0 vehicleentitylist)))
       (= entitytype "INSERT")
     )
     ;;Preload default vehicle
     (progn
       (setq
         vehicledatalist
          (list
            (list "VEHENTNAME" vehicleblockname)
            (list "VEHNAME" "TestVehicle")
            (list "VEHUNITS" "M")
            (list "VEHSTEERLOCK" 0.0)
            (list "VEHSTEERLOCKTIME" 0.0)
            (list "VEHARTANGLE" 20.0)
            (list "VEHFRONTHANG" 1220.0)
            (list "VEHWHEELBASE" 6100.0)
            (list "VEHWHEELWIDTH" 2000.0)
            (list "VEHBODYLENGTH" 9150.0)
            (list "VEHWIDTH" 2440.0)
            (list "VEHREARHITCH" 2100.0)
            (list "TRAILHAVE" "N")
            (list "TRAILNAME" "TestVehicle")
            (list "TRAILUNITS" "M")
            (list "TRAILERHITCHTOWHEEL" 10000.0)
            (list "TRAILERWHEELWIDTH" 2000.0)
            (list "TRAILERFRONTHANG" 1000.0)
            (list "TRAILERBODYLENGTH" 12000.0)
            (list "TRAILERWIDTH" 2440.0)
          )
       )
       (setq vehicledatalistlen (length vehicledatalist))
       (setq continueload "YES")
       (while (and
                (setq vehicleblockname (entnext vehicleblockname))
                (= continueload "YES")
              )
         (setq vehicleentitylist (entget vehicleblockname))
         (setq entitytype (cdr (assoc 0 vehicleentitylist)))
         (cond
           ((= entitytype "ATTRIB")
            (progn
              (setq value (cdr (assoc 1 vehicleentitylist)))
              (setq tag (cdr (assoc 2 vehicleentitylist)))
              ;;subst values in list
              ;;if a value has been substituted (even with same value),
              ;;then increment ChangeFromDefault by one
              (setq count 0)
              (while (< count vehicledatalistlen)
                (if (= (car (nth count vehicledatalist)) tag)
                  (progn
                    (setq oldpair (nth count vehicledatalist))
                    (setq newpair (list tag value))
                    (setq
                      vehicledatalist
                       (subst newpair oldpair vehicledatalist)
                    )
                    (setq changefromdefault (+ changefromdefault 1))
                  )
                )
                (setq count (+ 1 count))
              )
            )
           )
           ((= entitytype "SEQEND") (setq continueload "NO"))
         )
       )
     )
    )                                   ;end progn
    (t
     (alert
       (princ
         "\n ENTITY SELECTED IS NOT A VALID BLOCK.\n\nRUN BUILDVEHICLE TO DEFINE A VEHICLE."
       )
     )
    )
  )
  ;;check if ChangeFromDefault matches required data list length.  if not, then
  ;;report that not all data was found, and that some default values are being used
  (cond
    ((= changefromdefault 0)
     (alert
       (princ
         "\n NO DIMENSIONS OR DATA FOUND.\nPLEASE CHECK THAT SOURCE ENTITY IS VALID.\nDEFAULT VALUES WILL BE USED.\n\nRUN BUILDVEHICLE TO DEFINE A VEHICLE."
       )
     )
    )
    ((= changefromdefault (1- vehicledatalistlen))
                                        ;Edited 2008-04-10 Tom Haws. 
     (princ
       "\n ALL DIMENSIONS AND DATA FOUND, CUSTOMIZED VEHICLE HAS BEEN DEFINED"
     )
    )
    (alert
     (princ
       "\n SOME DIMENSIONS OR DATA FOUND.  PLEASE VERIFY THAT SOURCE BLOCK IS VALID.  SOME DEFAULT VALUES WILL BE USED"
     )
    )
  )
  (setq vehicleblockname nil)
  vehicledatalist
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
;;;  13   ABL (AXLE    REAR   ""  "")
;;;  14   VBL 
;;;  22   AFM (              MIDDLE) 
;;;  23   ABM 
;;;  25   HITCH/HINGE
;;;  31   VFR 
;;;  32   AFR 
;;;  33   ABR 
;;;  34   VBR 
;;;  41   RFRONT
;;;  42   RREAR
;;;  43   RHINGE
;;;  50   DIRVEH
;;;  51   FRONT WHEEL TILT OR ARTICULATION ANGLE (CCW/LEFT +)
;;;  52   INCREASE IN TILT/ANGLE FROM LAST TIME STEP (CCW/LEFT +)
;;;           
(defun
   turn-main-user-block-method (/ angtilt angle-turned dirtrv heading-0 heading-1
                                dsttrv en-guide-point-i es-guide-path i wheelbase osmold pathlist
                                point-calc-rear-0 prear2 point-calc-front-0
                                point-calc-front-1 rrear rfront ss-guide-points step
                                tiltang
                               )
  (setq
    es-guide-path
     (entsel "\nSelect front axle path polyline at starting end: ")
    point-calc-front-0
     (osnap (cadr es-guide-path) "end")
    point-calc-rear-0
     (getpoint
       point-calc-front-0
       "\nEnter initial midpoint of rear axle (TURN.LSP calculates wheelbase length and starting vehicle orientation from point entered): "
     )
    wheelbase (distance point-calc-front-0 point-calc-rear-0)
    heading-0
     (angle point-calc-front-0 point-calc-rear-0)
    *turn-calculationstep*
     (getdistx
       point-calc-front-0
       "\nCalculation step distance along front axle path"
       *turn-calculationstep*
       (/ wheelbase 10.0)
     )
    *turn-plotfrequency*
     (getintx
       "\nNumber of calculation steps to skip between vehicle plots"
       *turn-plotfrequency*
       50
     )
    *turn-vehblk*
     (cdr
       (assoc
         2
         (tblsearch
           "BLOCK"
           (getstringx
             "Block name to place along path, or . for none"
             *turn-vehblk*
             "TURNVEHICLE"
           )
         )
       )
     )
    ss-guide-points
     (ssadd)
    osmold
     (getvar "osmode")
  )
  (setvar "osmode" 0)
  (command "._undo" "begin" "._point" point-calc-front-0)
  (setq
    en-guide-point-i (entlast)
    ss-guide-points (ssadd en-guide-point-i ss-guide-points)
  )
  (command "._measure" es-guide-path *turn-calculationstep*)
  ;; MEASURE command in IntelliCAD places a point at beginning of polyline. 
  ;; If in IntelliCAD, skip that point.
  (if (= (turn-getvar "IcadMode") "TRUE")
    (setq en-guide-point-i (entnext en-guide-point-i))
  )
  (while (setq en-guide-point-i (entnext en-guide-point-i)) (setq ss-guide-points (ssadd en-guide-point-i ss-guide-points)))
  (setq i (1- (sslength ss-guide-points)))
  ;; Reverse order of ._MEASURE points if PLINE drawn "rearwards".
  ;;(if picked point is closer to last MEASURE command point than first)
  (if (< (distance
           (trans
             ;; the coordinates of the point to translate
             (cdr (assoc 10 (entget (ssname ss-guide-points i))))
             ;; from pline coordinate system
             (ssname ss-guide-points i)
             ;; to user coordinate system
             1
           )
           ;; the picked point, which is in the user coordinate system
           point-calc-front-0
         )
         (distance
           (trans
             ;; the coordinates of the point to translate
             (cdr (assoc 10 (entget (ssname ss-guide-points 1))))
             ;; from pline coordinate system
             (ssname ss-guide-points 1)
             ;; to user coordinate system
             1
           )
           ;; the picked point, which is in the user coordinate system
           point-calc-front-0
         )
      )
    (while (< 0 (setq i (1- i)))
      (setq en-guide-point-i (ssname ss-guide-points i))
      (ssdel en-guide-point-i ss-guide-points)
      (ssadd en-guide-point-i ss-guide-points)
    )
  )
  ;;First element in pathlist doesn't have any radius info.
  (setq
    i 0
    pathlist
     (list
       (list
         (cons 22 point-calc-front-0)
         (cons 23 point-calc-rear-0)
         (cons 50 heading-0)
       )
     )
  )
  ;; For every ._MEASURE point, calculate points and dimensions and add to pathlist
  ;; For now, only one vehicle is calculated.
  ;; To add more, change the initial prompts to keep asking for successive rear points.
  (while (setq en-guide-point-i (ssname ss-guide-points (setq i (1+ i))))
    (setq
      point-calc-front-1
       (trans (cdr (assoc 10 (entget en-guide-point-i))) en-guide-point-i 1)
      ;;Angle vehicle turned this step
      angle-turned
       (wt-angle-turned
         point-calc-front-0
         heading-0
         point-calc-front-1
         wheelbase
       )
      heading-1
       (+ heading-0 angle-turned)
      ;; Average front wheel radius this step
      rfront
       (/ distrear 2 (sin (/ angle-turned 2)))tghtgh
       (/ dsttrv (* 2.0 (sin (/ angle-turned 2.0))))
      ;; Average wheel tilt or articulation angle this step
      angtilt
       (turn-asin (/ wheelbase rfront))
      ;; Average rear wheel radius this step
      rrear
       (/ wheelbase (turn-tan angtilt))
      prear2
       (polar point-calc-front-1 heading-1 wheelbase)
      point-calc-front-0 point-calc-front-1
      point-calc-rear-0 prear2
      heading-0 heading-1
      ;;For now, only one vehicle is calculated.
      pathlist
       (cons
         (list
           (cons 22 point-calc-front-0)
           (cons 23 point-calc-rear-0)
           (cons 41 rfront)
           (cons 42 rrear)
           (cons 50 heading-0)
           (cons 51 tiltang)
         )
         pathlist
       )
    )
  )
  (setq pathlist (reverse pathlist))
  ;; Erase the ._MEASURE points.
  (command "._erase" ss-guide-points "")
  ;;Draw a polyline following one of the points in pathlist
  (command "._pline" (cdr (assoc 23 (car pathlist))) "w" 0 "")
  (foreach step (cdr pathlist) (command (cdr (assoc 23 step))))
  (command "")
  ;; Loop insert a block representing one of the vehicles in pathlist.
  (cond
    (*turn-vehblk*
     (setq i (* -1 *turn-plotfrequency*))
     (while (setq step (nth (setq i (+ i *turn-plotfrequency*)) pathlist))
       (entmake
         (list
           (cons 0 "INSERT")
           (cons 2 *turn-vehblk*)
           (cons 8 (getvar "CLAYER"))
           (cons 10 (cdr (assoc 22 step)))
           (cons 41 1.0)
           (cons 42 1.0)
           (cons 43 1.0)
           (cons 50 (cdr (assoc 50 step)))
         )
       )
       (entmake '((0 . "SEQEND")))
     )
    )
  )
  (setvar "osmode" osmold)
  (command "._undo" "end")
  (redraw)
  (princ)
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
;;;  13   ABL (AXLE    REAR   ""  "")
;;;  14   VBL
;;;  22   AFM (              MIDDLE)
;;;  23   ABM
;;;  25   HITCH/HINGE
;;;  31   VFR (VEHICLE FRONT RIGHT CORNER)
;;;  32   AFR (VEHICLE FRONT RIGHT CORNER)
;;;  33   ABR (VEHICLE FRONT RIGHT CORNER)
;;;  34   VBR (VEHICLE FRONT RIGHT CORNER)
;;;  41   RFRONT (FRONT PATH RADIUS)
;;;  42   RREAR (REAR PATH RADIUS)
;;;  43   RHINGE (HINGE RADIUS)
;;;  50   DIRVEH (VEHICLE DIRECTION)
;;;  51   FRONT WHEEL TILT OR ARTICULATION ANGLE (CCW/LEFT +)
;;;  52   INCREASE IN TILT/ANGLE FROM LAST TIME STEP (CCW/LEFT +)
(defun
   trailingpath (frontpath rearstart / i j)
  (setq
    i 0
    pathlistlength
     (length frontpath)
    point-calc-rear-0 rearstart
    rearpath
     (list rearstart)
  )
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (while (< (setq i (1+ i)) pathlistlength)
    (setq
      ;; Set initial point to the previous point
      point-calc-front-0
       (nth (1- i) frontpath)
      ;; Set final point to current point
      point-calc-front-1
       (nth i frontpath)
      ;; Initial direction of vehicle
      heading-0
       (angle point-calc-rear-0 point-calc-front-0)
      ;;Angle vehicle turned this step
      angle-turned
       (wt-angle-turned
         point-calc-front-0
         heading-0
         point-calc-front-1
         wheelbase
       )
      ;; Direction of vehicle at end of this step
      heading-1
       (+ heading-0 angle-turned)
      ;; Location of rear wheel at end of this step
      point-calc-rear-1
       (polar point-calc-front-1 heading-1 wheelbase)
      ;; Save this step's variables
      point-calc-front-0
       point-calc-front-1
      point-calc-rear-0 point-calc-rear-1
      heading-0 heading-1
      rearpath
       (cons point-calc-rear-1 rearpath)
       ;;End saving
    )
  )
  (reverse rearpath)
)

;;; GETDISTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (getdistx startingpoint promptstring currentvalue vanilladefault)
(defun
   getdistx (startingpoint promptstring currentvalue vanilladefault)
  (setq
    currentvalue
     (cond
       (currentvalue)
       (vanilladefault)
       (0.0)
     )
  )
  (setq
    currentvalue
     (cond
       ((getdist
          startingpoint
          (strcat promptstring " <" (rtos currentvalue) ">: ")
        )
       )
       (t currentvalue)
     )
  )
)
;;; Added 2008-04-10 by Tom Haws for vehicle plotting frequency prompt.
;;; GETINTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (getdistx startingpoint promptstring currentvalue vanilladefault)
(defun
   getintx (promptstring currentvalue vanilladefault)
  (setq
    currentvalue
     (cond
       (currentvalue)
       (vanilladefault)
       (0)
     )
  )
  (setq
    currentvalue
     (cond
       ((getint
          (strcat promptstring " <" (itoa currentvalue) ">: ")
        )
       )
       (t currentvalue)
     )
  )
)

(defun
   getstringx (gx-prompt gx-currentvalue gx-defaultvalue / gx-input)
  (setq
    gx-currentvalue
     (cond
       (gx-currentvalue)
       (gx-defaultvalue)
       ("")
     )
  )
  (setq gx-input (getstring (strcat "\n" gx-prompt " <" gx-currentvalue ">: ")))
  (cond
    ((= gx-input "") gx-currentvalue)
    ((= gx-input ".") "")
    (t gx-input)
  )
)

(defun turn-asin (x) (/ x (sqrt (- 1 (* x x)))))
(defun turn-tan (theta) (/ (sin theta) (cos theta)))

(defun
   wt-mkline (pt1 pt2)
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

;;Instructions on load-up added 2008-04-10 by Tom Haws
(princ
  (strcat
    "\nTURN.LSP version "
    (turn-getvar "General.Version")
    " loaded.  Type TURN to start."
  )
)
(princ)