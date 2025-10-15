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
;;; Copyright 2015 Thomas Gail Haws
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
;;;
;;; USER BLOCK METHOD
;;;
;;; The User Block method doesn't keep track of as many vehicle dimensions and paths.
;;; It merely drags your block along a path.
;;; It also doesn't model hitches at this time, which limits its accuracy for trailers.
;;;
;;; GENERATED BLOCK METHOD
;;;
;;; The Generated Vehicle method doesn't show the nuances of a vehicle as well.
;;; It merely draws rectangles along with multiple calculated wheel paths.
;;; While we hope to harmonize the two methods, they are currently rather independent.
;;; If you choose the Generated vehicle method, TURN will ask you for all of the parameters
;;; for your vehicle, and draw a unique attributed block.  You can build a library
;;; of vehicles for future use. For any any group of multiple axles, use their "centroid"
;;; to model them as a single axle.
;;;
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
;;; Draw the path for the vehicle as the route taken by the middle of the front axle.  A future
;;; version of this program might allow you to provide the path of left of right side of vehicle.
;;;
;;; Move the BuildVehicle block of your choice to the beginning of the polyline path to tell TURN.LSP
;;; the initial heading angle of your vehicle.
;;;
;;; Then, run TURN.  When prompted, select the BuildVehicle block, and then
;;; select the front axle path near the starting end.
;;; Turn.lsp uses the dimensions of the vehicle block for calculations.
;;; Accept TURN.LSP's suggestions for a calculation step and plotting accuracy
;;; or enter your own.
;;;
;;; Note:  Place the vehicle at the start of the path using the centre of the
;;; front axle, which should be marked with a circle.  Rotate the
;;; vehicle to the approximate correct starting angle.
;;;
;;; Note:  Select the front axle centerline path.  The left and right
;;; sides are drawn off of this.
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

;; Tests on this code showed that setting a direct global symbol took 1/25 as long as providing the data in a function.
(setq
  *wiki-turn-settings*
   (list
;;;----------------------------------------------------------------------------
;;; Program settings users can edit -------------------------------------------
;;;----------------------------------------------------------------------------
;;;
     '("layer.truckbody"
       ("C-TURN-TRCK-BODY" "TURN.LSP rectangle representing a vehicle at a step along a path" "1" "")
       list
     )
     '("layer.truckfrontlefttirepath"
       ("C-TURN-TRCK-FRONT-LEFT-PATH" "TURN.LSP vehicle front left tire path" "1" "")
       list
     )
     '("layer.truckfrontrighttirepath"
       ("C-TURN-TRCK-FRONT-RGHT-PATH" "TURN.LSP vehicle front right tire path" "1" "")
       list
     )
     '("layer.truckrearlefttirepath"
       ("C-TURN-TRCK-REAR-LEFT-PATH" "TURN.LSP vehicle rear left tire path" "2" "")
       list
     )
     '("layer.truckrearrighttirepath"
       ("C-TURN-TRCK-REAR-RGHT-PATH" "TURN.LSP vehicle rear right tire path" "2" "")
       list
     )
     '("layer.hitchpath"
       ("C-TURN-HTCH-PATH" "TURN.LSP path of connection between trailer and the vehicle pulling it" "3" "")
       list
     )
     '("layer.trailerbody"
       ("C-TURN-TRAL-BODY" "TURN.LSP rectangle representing a trailer at a step along a path" "4" "")
       list
     )
     '("layer.trailerrearlefttirepath"
       ("C-TURN-TRAL-REAR-LEFT-PATH" "TURN.LSP trailer rear left tire path" "4" "")
       list
     )
     '("layer.trailerrearrighttirepath"
       ("C-TURN-TRAL-REAR-RGHT-PATH" "TURN.LSP trailer rear right tire path" "4" "")
       list
     )
     ;;----------------------------------------------------------------------------
     ;; End program settings users can edit ---------------------------------------
     ;;----------------------------------------------------------------------------
     ;;
     ;; At runtime retrieval, each setting is converted 
     ;; from its storage as a string to the given data type.
     ;; Good or bad, these have to be single case
     ;;    Name             Value Data_type
     ;; The vehicle list is not used much. I am struggling with an elegant way to do it short of my v2 work.
     (list "vehicle.vehentname" "" 'ename)
     (list "vehicle.vehname" "TestVehicle" 'str)
     (list "vehicle.vehunits" "M" 'str)
     (list "vehicle.vehsteerlock" "0.0" 'real)
     (list "vehicle.vehsteerlocktime" "0.0" 'real)
     (list "vehicle.vehartangle" "20.0" 'real)
     (list "vehicle.vehfronthang" "1220.0" 'real)
     (list "vehicle.vehwheelbase" "6100.0" 'real)
     (list "vehicle.vehwheelwidth" "2000.0" 'real)
     (list "vehicle.vehbodylength" "9150.0" 'real)
     (list "vehicle.vehwidth" "2440.0" 'real)
     (list "vehicle.vehrearhitch" "2100.0" 'real)
     (list "vehicle.trailhave" "No" 'str)
     (list "vehicle.trailname" "TestVehicle" 'str)
     (list "vehicle.trailunits" "M" 'str)
     (list "vehicle.trailerhitchtowheel" "10000.0" 'real)
     (list "vehicle.trailerwheelwidth" "2000.0" 'real)
     (list "vehicle.trailerfronthang" "1000.0" 'real)
     (list "vehicle.trailerbodylength" "12000.0" 'real)
     (list "vehicle.trailerwidth" "2440.0" 'real)
     (list "general.icadmode" "False" 'str)
     (list "general.version" "1.1.17" 'str)
     (list "general.countvehiclesettings" "0" 'int)
   )
)
(defun wiki-turn-initialize-settings ()
  (wiki-turn-setvar "general.countvehiclesettings" (wiki-turn-count-settings "vehicle*"))
)
(defun wiki-turn-count-settings (wc / count)
  (setq count 0)
  (foreach setting *wiki-turn-settings*
    (if (wcmatch (car setting) wc) (setq count (1+ count)))
  )
  count
)
(defun wiki-turn-setting-group-names (wc)
  (foreach setting *wiki-turn-settings*
    (if (wcmatch (car setting) wc) (setq group-names (cons (car setting) group-names)))
  )
  group-names
)

;;; REVISION HISTORY
;;; Date     Programmer   Revision
;;; 20230223 TGH          1.1.17 More refactoring.
;;; 20230219 TGH          1.1.16 Moved layer creation inside command.
;;; 201510   TGH          1.1.15 Major DRY refactoring. Fixed turned angle.  Changed layer settings. Fixed trailer plotting. Fixed/completed internationalization.
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
;;; 20080410 TGH          1.1.5  Simplified prompts, added layer defaults, and fixed a few errors.
;;; 20080206 SH           1.1.4  Fixed Imperial dimension storage, and made input consistent to type of data
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

;;; TURN-SETVAR

(defun
   wiki-turn-vehicle-setvar (var val)
  (wiki-turn-setvar (strcat "vehicle." var) val)
)

(defun
   wiki-turn-setvar (var val / var_type)
;;; For future compatibility with other storage options,
;;; We're keeping all values as strings (text).
  ;;Put Var and Val together into a setting group.
  (setq var_type (wiki-turn-getvar-type var))
  (cond ((/= (type val) 'str) (setq val (vl-prin1-to-string val))))
  (wiki-turn-save-to-settings-list var val)
  val
)

(defun
   wiki-turn-save-to-settings-list (var val / oldgroup)
;;; For future compatibility with other storage options,
;;; We're keeping all values as strings (text).
  ;;Put Var and Val together into a setting group.
  (setq var (strcase var T))
  (cond
    ;;If the variable is already set, then
    ((setq oldgroup (assoc var *wiki-turn-settings*))
     ;;Replace the old setting with the new setting.
     (setq *wiki-turn-settings*
     (subst
       (list var val (caddr oldgroup))
       (assoc var *wiki-turn-settings*)
       *wiki-turn-settings*
     )
    )
    )
    ;;Else,
    (t
     ;;Add the setting assuming it's a string
     (setq *wiki-turn-settings* (cons (list var val 'str) *wiki-turn-settings*))
    )
  )
)

(defun
   wiki-turn-vehicle-getvar (var / val val_string var_type)
  (wiki-turn-getvar (strcat "Vehicle." var))
)

(defun
   wiki-turn-getvar (var / val val_string var_type)
  (setq
    var (strcase var T)
    val_string
     (wiki-turn-getvar-string var)
    var_type
     (caddr
       (assoc var *wiki-turn-settings*))
    val
     (cond
       ;; Returns nil for ""
       ((= var_type 'real) (distof val_string)) 
       ((= var_type 'int) (atoi val_string))
       ((= var_type 'str) val_string)
       ((= var_type 'ename) (read val_string))
       ((= var_type (quote list)) val_string)
     )
  )
)

(defun
   wiki-turn-getvar-string (var / val-string)
  (setq var (strcase var T))
  (cadr (assoc var *wiki-turn-settings*))
)

(defun
   wiki-turn-getvar-type (var / val-string)
  (setq var (strcase var T))
  (caddr (assoc var *wiki-turn-settings*))
)

;;; Layer settings added by Tom Haws 2008-04-10
(defun
   wiki-turn-makelayers (/ setting)
  ;;Layer change 2008-02-22 Stephen Hitchcox
  (foreach
     setting *wiki-turn-settings*
    (if (wcmatch (car setting) "layer*")(wiki-turn-make-layer setting))
  )
)
(defun
   wiki-turn-make-layer (setting / existing-layer-list layer-list)
  ;;Layer change 2008-02-22 Stephen Hitchcox
  (setq
    layer-list
     (cadr setting)
    existing-layer-list
     (tblsearch "layer" (car layer-list))
  )
  (cond
    ((not existing-layer-list)
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
       "_description"
       (cadr layer-list)
       (car layer-list)
       "_color"
       (caddr layer-list)
       (car layer-list)
       "_ltype"
       (cadddr layer-list)
       (car layer-list)
       ""
     )
    )
  )
)

;;Gets a layer list from a layer base name string.
(defun
   wiki-turn-getlayer (basename)
  (wiki-turn-getvar (strcat "Layer." basename))
)

(defun
   c:turn (/ method vehname osmold)
  (wiki-turn-makelayers)
  (initget "User Generated ?")
  (setq
    method
     (getkword "\nTracking method [User block/Generated vehicle/?]: ")
    osmold
     (getvar "osmode")
  )
  (cond
    ((= method "User")
     (setq
       *wiki-turn-vehblk*
        (cdr
          (assoc
            2
            (tblsearch
              "BLOCK"
              (wiki-turn-getstringx
                "Block name to place along path, or . for none"
                *wiki-turn-vehblk*
                "TURNVEHICLE"
              )
            )
          )
        )
     )
     (wiki-turn-main-user-block-method)
    )
    ((= method "Generated")
     (setq vehname (getstring "\nName for new vehicle or <select previously generated vehicle>: "))
     (cond
       ((= vehname "") (wiki-turn-main-generated-block-method))
       (t (wiki-turn-buildvehicle vehname))
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
      (wiki-turn-getvar "General.Version")
      " , Copyright (C) 2015 Thomas Gail Haws and Stephen Hitchcox"
      "\nTURN comes with ABSOLUTELY NO WARRANTY."
      "\nThis is free software, and you are welcome to modify and"
      "\nredistribute it under the terms of the GNU General Public License."
      "\nThe latest version of TURN is always available at autocad.wikia.com"
    )
  )
  (princ)
)

;;;C:BV short form call for (wiki-turn-BUILDVEHICLE)
(defun c:bv () (wiki-turn-buildvehicle))
(defun
   wiki-turn-buildvehicle (vehname / layer-key circlelist heading-angle heading-length oldexpert point-rear-mid
                           startdrawpoint swath-width targetx targety trailerbodylength trailerfronthang
                           trailerhitchtowheel trailerwheelwidth trailerwidth TrailHave TrailerName TrailerUnits vehartangle
                           vehblocklist vehbodylength vehfronthang vehrearhitch vehsteerlock vehsteerlocktime vehunits
                           vehwheelbase vehwheelwidth vehwidth wheel-f-x wheel-l-y wheel-r-x wheel-r-y wheel-x
                           wheellength wheelwidth
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
  (setq startdrawpoint (getpoint "\nLocation to build vehicle (midpoint of front bumper):  "))
  ;;Prompt change 2008-04-10 Tom Haws
  (setq vehbodylength (getdist startdrawpoint "\nLength of vehicle body: "))
  ;;Prompt change 2008-04-10 Tom Haws
  (setq vehwidth (* 2 (getdist startdrawpoint "\nHalf width of vehicle body: ")))
  ;; Record VEHWIDTH
  ;; MAKEATTRIBUTE usage: (MakeAttribute InsPoint InsAngle Tag Value AttPrompt TextSize)
;;inspoint insangle tag value attriblayer attprompt textsize
  (wiki-turn-make-attribute
    (polar startdrawpoint pi (/ vehwidth 15))
    90.0
    "VEHWIDTH"
    (rtos vehwidth 2)
    "Vehicle width"
    (/ vehwidth 15)
  )
  (setq vehblocklist (ssadd (entlast)))
  ;; Record VEHBODYLENGTH
  (wiki-turn-make-attribute
    (polar (polar startdrawpoint (* 1.5 pi) (* vehwidth 0.55)) 0.0 (/ vehbodylength 2))
    0.0
    "VEHBODYLENGTH"
    (rtos vehbodylength 2)
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
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (ssadd (entlast) vehblocklist)
  ;;Prompt change 2008-04-11 Tom Haws
  (setq vehfronthang (getdist startdrawpoint "\nFront overhang (distance from bumper to axle): "))
  ;; Record front axle offset
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 (/ vehfronthang 2))
    0.0
    "VEHFRONTHANG"
    (rtos vehfronthang 2)
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
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase))
    90
    "VEHWHEELBASE"
    (rtos vehwheelbase 2)
    "Vehicle wheelbase"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  ;; Record name of vehicle
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 (+ vehfronthang (/ vehwheelbase 2)))
    0.0
    "VEHNAME"
    vehname
    "Vehicle name"
    (/ vehwidth 10)
  )
  (ssadd (entlast) vehblocklist)
  ;; Record units of vehicle
  (wiki-turn-make-attribute
    (polar (polar startdrawpoint (* 1.5 pi) (* vehwidth 0.25)) 0.0 (/ vehbodylength 2))
    0.0
    "VEHUNITS"
    vehunits
    "Vehicle units (Metric or Imperial)"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
;;; VehSteerLock isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
;;; Steering lock is the maximum angle that the wheels can be turned.
  (setq vehsteerlock 0.5)
  ;|
  (SETQ VEHSTEERLOCK (GETANGLE "\nEnter vehicle Steering Lock Angle:  (note that this is required but not used at this time)"))
  |;
  ;; Record vehicle Steering Lock Angle
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 (/ vehfronthang 3))
    90.0
    "VEHSTEERLOCK"
    (angtos vehsteerlock 0)
    "Vehicle steering lock angle"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
;;; VEHSTEERLOCKTIME isn't currently functional. Prompt hidden 2008-04-10 by Tom Haws
;;; Steering lock time is the fastest time that the wheels could be turned from straight to locked.
  (setq vehsteerlocktime 0.0)
  ;|
  (SETQ
    VEHSTEERLOCKTIME
     (GETREAL "\nEnter vehicle steering lock time:  (note that this is required but not used at this time)")
  )
  |;
  ;; Record vehicle steer lock time
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 (* 2 (/ vehfronthang 3)))
    90.0
    "VEHSTEERLOCKTIME"
    (rtos vehsteerlocktime)
    "Vehicle steer lock time"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  (setq
    vehwheelwidth
     ;;Prompt change 2008-04-11 Tom Haws
     (* 2 (getdist startdrawpoint "\nHalf of maximum axle width to middle of wheels: "))
  )
  ;; Record wheel width
  (wiki-turn-make-attribute
    (polar startdrawpoint 0.0 vehfronthang)
    90.0
    "VEHWHEELWIDTH"
    (rtos vehwheelwidth 2)
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
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (ssadd (entlast) vehblocklist)
  ;; Draw front right wheel
  (setq point-rear-mid (list wheel-f-x wheel-r-y))
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (ssadd (entlast) vehblocklist)
  ;; Draw rear left wheel
  (setq point-rear-mid (list wheel-r-x wheel-l-y))
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (ssadd (entlast) vehblocklist)
  ;; Draw rear right wheel
  (setq point-rear-mid (list wheel-r-x wheel-r-y))
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (ssadd (entlast) vehblocklist)
  ;; Draw front left target point
  (wiki-turn-drawtarget
    (list (+ (car startdrawpoint) vehfronthang) (cadr startdrawpoint))
    wheellength
    wheelwidth
    "C-TURN-TRCK-BODY"
  )
  (ssadd (entlast) vehblocklist)
  ;; End of main vehicle entry
  ;; Start trailer entry
  (initget 1 "Yes No")
  (setq TrailHave (getkword "\nDoes unit have a trailer? [Yes/No]:  "))
  (wiki-turn-make-attribute
    (polar
      startdrawpoint
      0.0
      (+ vehfronthang vehwheelbase)     ;(* VEHREARHITCH 0.5)) Edited 2008-04-10 to accomodate prompt order change
    )
    90.0
    "TrailHave"
    TrailHave
    "Does unit have a trailer"
    (/ vehwidth 15)
  )
  (ssadd (entlast) vehblocklist)
  (cond
    ((= TrailHave "Yes")
     ;;Moved hitch stuff 2008-04-10 by Tom Haws so non-trailer builds won't see it.
     (setq vehrearhitch (getdist "\nEnter distance from rear axle to hitch (forward is NEGATIVE):  "))
     ;;Draw hitch
     (setq
       circlelist
        (list
          (cons 0 "CIRCLE")             ;(CONS 100 "AcDbEntity")
          (cons 8 "C-TURN-TRCK-BODY")   ;(CONS 100 "AcDbCircle")
          (cons 40 (/ vehwidth 10))
          (cons 10 (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase vehrearhitch)))
        )
     )
     (entmake circlelist)
     (ssadd (entlast) vehblocklist)
     (wiki-turn-make-attribute
       (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase vehrearhitch))
       90.0
       "VEHREARHITCH"
       (rtos vehrearhitch 2)
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
     (wiki-turn-make-attribute
       (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase (* vehrearhitch 1.5)))
       90.0
       "VEHARTANGLE"
       (angtos vehartangle 0)
       "Vehicle articulation angle"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     (setq TrailerName (getstring "\nName for trailer:  "))
     ;| Code not used at this time.  Prompt hidden and default set by Tom Haws 2008-04-10
  ;;Input change 2008-04-10 Tom Haws
  (initget 1 "M I")
  (SETQ TrailerUnits (GETKWORD "\nMetric or Imperial units [M/I]:  "))
  |; (setq TrailerUnits "M")
     ;;Prompt change 2008-04-11 Tom Haws
     (setq trailerhitchtowheel (getdist "\nDistance from hitch to trailer axle:  "))
     ;;Prompt change 2008-04-11 Tom Haws
     (setq trailerwheelwidth (* 2 (getdist "\nHalf of maximum trailer axle width to middle of wheels:  ")))
     (setq trailerfronthang (getdist "\nDistance from hitch to front of trailer (forward is NEGATIVE):  "))
     (setq trailerbodylength (getdist "\nOverall trailer length:  "))
     (setq trailerwidth (* 2 (getdist "\nHalf of trailer width:  ")))
     ;; Record trailer Length
     (wiki-turn-make-attribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILERBODYLENGTH"
       (rtos trailerbodylength 2)
       "Trailer body length"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer name
     (wiki-turn-make-attribute
       (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2)))
       0.0
       "TrailerName"
       TrailerName
       "Trailer name"
       (/ vehwidth 10)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer units
     (wiki-turn-make-attribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.25))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TrailerUnits"
       TrailerUnits
       "Trailer units"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailerfronthang
     (wiki-turn-make-attribute
       (polar
         (polar startdrawpoint (* 1.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerfronthang 2))
       )
       0.0
       "TRAILERFRONTHANG"
       (rtos trailerfronthang 2)
       "Trailer front overhang"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer to wheel length
     (wiki-turn-make-attribute
       (polar
         (polar startdrawpoint (* 0.5 pi) (* trailerwidth 0.55))
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (/ trailerbodylength 2))
       )
       0.0
       "TRAILERHITCHTOWHEEL"
       (rtos trailerhitchtowheel 2)
       "Trailer hitch to wheel length"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer width
     (wiki-turn-make-attribute
       (polar
         startdrawpoint
         0.0
         (+ vehfronthang vehwheelbase vehrearhitch (- trailerbodylength trailerfronthang))
       )
       90.0
       "TRAILERWIDTH"
       (rtos trailerwidth 2)
       "Trailer width"
       (/ vehwidth 15)
     )
     (ssadd (entlast) vehblocklist)
     ;; Record trailer wheel width
     (wiki-turn-make-attribute
       (polar startdrawpoint 0.0 (+ vehfronthang vehwheelbase vehrearhitch trailerhitchtowheel))
       90.0
       "TRAILERWHEELWIDTH"
       (rtos trailerwheelwidth 2)
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
          (+ vehfronthang vehwheelbase vehrearhitch trailerfronthang trailerbodylength)
        )
       heading-angle pi
       heading-length trailerbodylength
       swath-width trailerwidth
       layer-key "TrailerBody"
     )
     (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
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
     (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
     (ssadd (entlast) vehblocklist)
     ;; Draw right wheel
     (setq point-rear-mid (list wheel-x wheel-r-y))
     (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
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
  (command "-block" (strcat "VEHICLELIB" vehname) startdrawpoint vehblocklist "")
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
(defun
   wiki-turn-main-generated-block-method ( / angle-turned dirtrailer en-guide-point-i
                                          es-guide-path frontlefttirepathlist frontrighttirepathlist heading-0 heading-1
                                          heading-angle heading-length hitchpath hitchpathlist i layer-key
                                          npathsegments point-calc-front-0 point-calc-front-1 point-calc-rear-0
                                          point-calc-rear-1 point-rear-mid rearlefttirepathlist rearrighttirepathlist
                                          ss-guide-points swath-width this-step 
                                         )
  (wiki-turn-get-vehicle-data-from-block)
  (setq
    es-guide-path
     (wiki-turn-get-es-guide-path)
    point-calc-front-0
     (osnap (cadr es-guide-path) "_end")
    heading-0
     (+ pi (cdr (assoc 50 (entget vehentname))))
    wheelbase vehwheelbase
    point-calc-rear-0
     (polar point-calc-front-0 heading-0 (* -1 wheelbase))
    ss-guide-points
     (wiki-turn-get-ss-guide-path es-guide-path point-calc-front-0 wheelbase)
    dirtrailer heading-0
    ;;  End 20020625 Revision
    ;;  Initial Travel Angle from Pick Points
    npathsegments
     (1- (sslength ss-guide-points))
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
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (setq i 0)
  ;; Initiate path pline plots
  (wiki-turn-initiate-path
    'frontlefttirepathlist
    npathsegments
    "TruckFrontLeftTirePath"
    (polar point-calc-front-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wiki-turn-initiate-path
    'frontrighttirepathlist
    npathsegments
    "TruckFrontRightTirePath"
    (polar point-calc-front-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wiki-turn-initiate-path
    'rearlefttirepathlist
    npathsegments
    "TruckRearLeftTirePath"
    (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (wiki-turn-initiate-path
    'rearrighttirepathlist
    npathsegments
    "TruckRearRightTirePath"
    (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
  )
  (cond
    ((= TrailHave "Yes")
     (wiki-turn-initiate-path
       'hitchpathlist
       npathsegments
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
      this-step
       (wiki-turn-track-step point-calc-front-0 heading-0 wheelbase point-calc-front-1)
      heading-1
       (cdr (assoc "heading-1" this-step))
      angle-turned
       (cdr (assoc "angle-turned" this-step))
      point-calc-rear-1
       (cdr (assoc "point-calc-rear-1" this-step))
      ;;Save this step's variables
      point-calc-front-0
       point-calc-front-1
      point-calc-rear-0 point-calc-rear-1
      heading-0 heading-1
    )
    (cond
      ((= (rem i *wiki-turn-plotfrequency*) 0)
       (setq
         point-rear-mid
          (polar point-calc-front-0 heading-0 (- vehfronthang vehbodylength))
         heading-angle
          (angle point-calc-rear-0 point-calc-front-0)
         heading-length vehbodylength
         swath-width vehwidth
         layer-key "TruckBody"
       )
       (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
      )
    )
    (wiki-turn-add-point-to-path
      'frontlefttirepathlist
      (polar point-calc-front-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wiki-turn-add-point-to-path
      'frontrighttirepathlist
      (polar point-calc-front-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wiki-turn-add-point-to-path
      'rearlefttirepathlist
      (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (wiki-turn-add-point-to-path
      'rearrighttirepathlist
      (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ vehwheelwidth 2))
    )
    (cond
      ((= TrailHave "Yes")
       (setq hitchpathlist (cons (cons 10 (polar point-calc-rear-0 heading-0 (* -1 vehrearhitch))) hitchpathlist))
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
  (if (= TrailHave "Yes")
    (wiki-turn-trailerpath)
    (princ "\nTrailer not Included, no trailer calculated.")
  )
  (setvar "osmode" osmold)
  (command "._erase" ss-guide-points "")
  (redraw)
  (princ)
)


;;; SETVEHICLEDIMS
(defun
   wiki-turn-setvehicledims ()
  (alert "wiki-turn-setvehicledims not used any more")
  ;|
vehsteerlock vehsteerlocktime vehartangle vehfronthang vehwheelbase vehwheelwidth vehbodylength vehwidth
           vehrearhitch trailerhitchtowheel trailerwheelwidth trailerfronthang trailerbodylength trailerwidth
  |;
;;;====================================================================
)

;; Function TrailerPath
;; Symbols that are global here should all be local to wiki-turn-main-generated-block-method,
;; which is the only function that calls this.
;; I've tried for years to think of a more elegant and readable way to do this. Maybe shorter names is the answer.
(defun
   wiki-turn-trailerpath (/ angle-turned heading-1 heading-angle heading-length
                          hitchpathlistcount layer-key point-calc-front-0 point-calc-front-1
                          point-calc-rear-0 point-calc-rear-1 point-rear-mid rearlefttrailertirepathlist
                          rearrighttrailertirepathlist swath-width this-step
                         )
  ;; strip header stuff from trailerpointslist
  (while (/= (car (car hitchpathlist)) 10) (setq hitchpathlist (cdr hitchpathlist)))
  (setq hitchpathlistcount 0)
  (setq point-calc-front-0 (cdr (nth 0 hitchpathlist)))
  ;; get first trailer point
  ;; Note that Dirtrailer was set at start of turn from direction of vehicle/trailer block
  (setq heading-0 dirtrailer)
  (setq point-calc-rear-0 (polar point-calc-front-0 heading-0 (* -1 trailerhitchtowheel)))
  ;; Draw initial position of trailer.
  (setq
    point-rear-mid
     (polar point-calc-rear-0 heading-0 (- trailerhitchtowheel (+ trailerfronthang trailerbodylength)))
    heading-angle heading-0
    heading-length trailerbodylength
    swath-width trailerwidth
    layer-key "TrailerBody"
  )
  (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
  (wiki-turn-initiate-path
    'rearlefttrailertirepathlist
    npathsegments
    "TrailerRearLeftTirePath"
    (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ trailerwheelwidth 2))
  )
  (wiki-turn-initiate-path
    'rearrighttrailertirepathlist
    npathsegments
    "TrailerRearRightTirePath"
    (polar point-calc-rear-0 (- heading-0 (/ pi 2)) (/ trailerwheelwidth 2))
  )
  (setq hitchpathlistcount (1+ hitchpathlistcount))
  (while (< hitchpathlistcount npathsegments)
    (setq
      point-calc-front-1
       (cdr (nth hitchpathlistcount hitchpathlist))
      this-step
       (wiki-turn-track-step point-calc-front-0 heading-0 trailerhitchtowheel point-calc-front-1)
      heading-1
       (cdr (assoc "heading-1" this-step))
      angle-turned
       (cdr (assoc "angle-turned" this-step))
      point-calc-rear-1
       (cdr (assoc "point-calc-rear-1" this-step))
      point-calc-front-0 point-calc-front-1
      point-calc-rear-0 point-calc-rear-1
      heading-0 heading-1
    )
    ;; Draw trailer
    (cond
      ((= (rem hitchpathlistcount *wiki-turn-plotfrequency*) 0)
       (setq
         point-rear-mid
          (polar
            point-calc-rear-0
            heading-0
            (- trailerhitchtowheel (+ trailerfronthang trailerbodylength))
          )
         heading-angle
          (angle point-calc-rear-0 point-calc-front-0)
         heading-length trailerbodylength
         swath-width trailerwidth
         layer-key "TrailerBody"
       )
       (wiki-turn-draw-box point-rear-mid heading-angle heading-length swath-width layer-key)
      )
    )
    (wiki-turn-add-point-to-path
      'rearlefttrailertirepathlist
      (polar point-calc-rear-0 (+ heading-0 (/ pi 2)) (/ trailerwheelwidth 2))
    )
    (wiki-turn-add-point-to-path
      'rearrighttrailertirepathlist
      (polar point-calc-rear-0 (- heading-1 (/ pi 2)) (/ trailerwheelwidth 2))
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
   wiki-turn-get-vehicle-data-from-block (/ changefromdefault en el et val var)
  ;;Prompt change 2008-04-10 Tom Haws
  (setq
    vehentname (car (entsel "\nSelect vehicle block: "))
    en vehentname
    changefromdefault 0
  )
  (wiki-turn-vehicle-setvar "vehentname" vehentname)
  ;;If a block was selected, get its data.  Otherwise alert and fail.
  (cond
    ((and
       en
       (setq el (entget en))
       (setq et (cdr (assoc 0 el)))
       (= et "INSERT")
     )
     (while (and
              (setq en (entnext en))
              (setq el (entget en))
              (setq et (cdr (assoc 0 el)))
              (/= et "SEQEND")
            )
       (setq var (cdr (assoc 2 el)))
       (wiki-turn-vehicle-setvar var (cdr (assoc 1 el)))
       (set (read var)(wiki-turn-vehicle-getvar var))
       (setq changefromdefault (1+ changefromdefault))
     )
    )
    (t
     (alert (princ "\n ENTITY SELECTED IS NOT A VALID BLOCK.\n\nRUN BUILDVEHICLE TO DEFINE A VEHICLE."))
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
    ((= changefromdefault (1- (wiki-turn-getvar "General.CountVehicleSettings")))
     (princ "\n ALL DIMENSIONS AND DATA FOUND, CUSTOMIZED VEHICLE HAS BEEN DEFINED")
    )
    ((= "Yes" (wiki-turn-getvar "Vehicle.TrailHave"))
     (alert
       (princ
         "\n SOME DIMENSIONS OR DATA FOUND.  PLEASE VERIFY THAT SOURCE BLOCK IS VALID.  SOME DEFAULT VALUES WILL BE USED"
       )
     )
    )
  )
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
   wiki-turn-main-user-block-method (/ angle-turned en-guide-point-i es-guide-path heading-0 heading-1 i pathlist
                                     point-calc-front-0 point-calc-front-1 point-calc-rear-0 point-calc-rear-1 rfront
                                     rrear ss-guide-points step this-step wheel-tilt wheelbase
                                    )
  (setq
    es-guide-path
     (wiki-turn-get-es-guide-path)
    point-calc-front-0
     (osnap (cadr es-guide-path) "_end")
    point-calc-rear-0
     (getpoint
       point-calc-front-0
       "\nEnter initial midpoint of rear axle (TURN.LSP calculates wheelbase length and starting vehicle orientation from point entered): "
     )
    wheelbase
     (distance point-calc-front-0 point-calc-rear-0)
    heading-0
     (angle point-calc-rear-0 point-calc-front-0)
    ss-guide-points
     (wiki-turn-get-ss-guide-path es-guide-path point-calc-front-0 wheelbase)
    ;;First element in pathlist doesn't have any radius info.
    i
     0
    pathlist
     (list (list (cons 22 point-calc-front-0) (cons 23 point-calc-rear-0) (cons 50 heading-0)))
  )
  ;; For every guide path step, calculate points and dimensions and add to pathlist
  ;; For now, only one vehicle is calculated.
  ;; To add more, change the initial prompts to keep asking for successive rear points.
  (while (setq en-guide-point-i (ssname ss-guide-points (setq i (1+ i))))
    (setq
      point-calc-front-1
       (trans (cdr (assoc 10 (entget en-guide-point-i))) en-guide-point-i 1)
      ;;Angle vehicle turned this step
      this-step
       (wiki-turn-track-step point-calc-front-0 heading-0 wheelbase point-calc-front-1)
      heading-1
       (cdr (assoc "heading-1" this-step))
      angle-turned
       (cdr (assoc "angle-turned" this-step))
      point-calc-rear-1
       (cdr (assoc "point-calc-rear-1" this-step))
      rfront
       (cdr (assoc "front-radius" this-step))
      rrear
       (cdr (assoc "rear-radius" this-step))
      ;; Average wheel tilt or articulation angle this step
      wheel-tilt
       (cdr (assoc "wheel-tilt" this-step))
      point-calc-front-0 point-calc-front-1
      point-calc-rear-0 point-calc-rear-1
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
           (cons 51 wheel-tilt)
         )
         pathlist
       )
    )
  )
  (setq pathlist (reverse pathlist))
  ;; Erase the ._MEASURE points.
  (command "._erase" ss-guide-points "")
  ;;Draw a polyline following one of the points in pathlist
  (command "._pline" (cdr (assoc 23 (car pathlist))) "_width" 0 "")
  (foreach step (cdr pathlist) (command (cdr (assoc 23 step))))
  (command "")
  ;; Loop insert a block representing one of the vehicles in pathlist.
  (cond
    (*wiki-turn-vehblk*
     (setq i (* -1 *wiki-turn-plotfrequency*))
     (while (setq step (nth (setq i (+ i *wiki-turn-plotfrequency*)) pathlist))
       (entmake
         (list
           (cons 0 "INSERT")
           (cons 2 *wiki-turn-vehblk*)
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
  (command "._undo" "_end")
  (redraw)
  (princ)
)
(defun
   wiki-turn-get-es-guide-path ()
  (entsel "\nSelect front axle path polyline at starting end: ")
  ;;TRACKLOCATION ("L")
  ;;(initget 1 "L M R")
  ;;(setq TRACKLOCATION (getkword "Is this track on the L eft, M iddle, or R ight of the front axle? (L or M or R) ")) 
)

(defun
   wiki-turn-get-ss-guide-path (es-guide-path point-calc-front-0 wheelbase / en-guide-point-i i ss-guide-points)
  (setq
    *wiki-turn-calculationstep*
     (wiki-turn-getdistx
       point-calc-front-0
       "\nCalculation step distance along front axle path"
       *wiki-turn-calculationstep*
       (/ wheelbase 10.0)
     )
    *wiki-turn-plotfrequency*
     (wiki-turn-getintx
       "\nNumber of calculation steps to skip between vehicle plots"
       *wiki-turn-plotfrequency*
       10
     )
    ss-guide-points
     (ssadd)
  )
  (setvar "osmode" 0)
  (command "._undo" "_begin" "._point" point-calc-front-0)
  (setq
    en-guide-point-i
     (entlast)
    ss-guide-points
     (ssadd en-guide-point-i ss-guide-points)
  )
  (command "._measure" es-guide-path *wiki-turn-calculationstep*)
  ;; MEASURE command in IntelliCAD places a point at beginning of polyline. 
  ;; If in IntelliCAD, skip that point.
  (if (= (wiki-turn-getvar "General.IcadMode") "TRUE")
    (setq en-guide-point-i (entnext en-guide-point-i))
  )
  (while (setq en-guide-point-i (entnext en-guide-point-i))
    (setq ss-guide-points (ssadd en-guide-point-i ss-guide-points))
  )
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
  ss-guide-points
)


;; Trying to use primary source input variables.
(defun
   wiki-turn-track-step (point-calc-front-0 heading-0 wheelbase point-calc-front-1 / angle-turned front-radius heading-1
                         point-calc-rear-0 point-calc-rear-1 rear-radius wheel-heading wheel-tilt
                        )
  (setq
    point-calc-rear-0
     (polar point-calc-front-0 heading-0 (* -1 wheelbase))
    angle-turned
     (wiki-turn-angle-turned point-calc-front-0 heading-0 wheelbase point-calc-front-1)
    ;;Direction of vehicle at end of this step
    heading-1
     (+ heading-0 angle-turned)
    ;;Location of rear wheel at end of this step
    point-calc-rear-1
     (polar point-calc-front-1 heading-1 (* -1 wheelbase))
    rear-radius
     (/ (distance point-calc-rear-0 point-calc-rear-1) 2 (sin (/ angle-turned 2)))
    front-radius
     (/ (distance point-calc-front-0 point-calc-front-1) 2 (sin (/ angle-turned 2)))
    wheel-tilt
     (wiki-turn-asin (/ wheelbase front-radius))
    wheel-heading
     (+ heading-1 wheel-tilt)
  )
  (list
    (cons "heading-1" heading-1)
    (cons "angle-turned" angle-turned)
    (cons "point-calc-rear-1" point-calc-rear-1)
    (cons "rear-radius" rear-radius)
    (cons "front-radius" front-radius)
    (cons "wheel-tilt" wheel-tilt)
    (cons "wheel-heading" wheel-heading)
  )
)

(defun
   wiki-turn-angle-turned (point-calc-front-0 heading-0 wheelbase point-calc-front-1 / angle-turned course-deviation-supplementary front-direction front-distance
                           course-deviation
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
        (if (minusp course-deviation)
          1
          -1
        )
        (atan
          (/ (sin course-deviation-supplementary)
             (- (/ (* 2 wheelbase) front-distance) (cos course-deviation-supplementary))
          )
        )
     )
  )
)

(defun
   wiki-turn-initiate-path (list-name npathsegments layer-key first-point)
  (set
    list-name
    (list
      (cons 43 0.0)
      ;; plinegen added 2008-04-10 by Tom Haws
      (cons 70 128)
      (cons 90 npathsegments)
      ;; polyline length
      (cons 100 "AcDbPolyline")
      (cons 8 (car (wiki-turn-getlayer layer-key)))
      (cons 100 "AcDbEntity")
      (cons 0 "LWPOLYLINE")
    )
  )
  (wiki-turn-add-point-to-path list-name first-point)
)
(defun
   wiki-turn-add-point-to-path (list-name add-point)
  (set list-name (cons (cons 10 add-point) (eval list-name)))
)

;; Added 2015-10-28 by Tom Haws to resolve trailer plotting bowtie and front offset issues.
(defun
   wiki-turn-draw-box (point-rear-mid heading-angle heading-length swath-width layer-key / box-pline-list
                       point-front-left point-front-right point-i point-rear-left point-rear-right
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
     (polar point-rear-mid (+ heading-angle (/ pi 2)) (/ swath-width 2))
    point-rear-right
     (polar point-rear-mid (- heading-angle (/ pi 2)) (/ swath-width 2))
    point-front-left
     (polar point-rear-left heading-angle heading-length)
    point-front-right
     (polar point-rear-right heading-angle heading-length)
  )
  (if layer-key
    (setq box-pline-list (cons (cons 8 (car (wiki-turn-getlayer layer-key))) box-pline-list))
  )
  (foreach
     point-i (list point-front-left point-rear-left point-rear-right point-front-right)
    (setq box-pline-list (cons (cons 10 point-i) box-pline-list))
  ) 
  (setq box-pline-list (reverse box-pline-list))
  (entmake box-pline-list)
)

(defun
   wiki-turn-drawtarget (startpoint xlength ylength targetlayer / circlelist)
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
(defun
   wiki-turn-make-attribute (inspoint insangle tag value attprompt textsize / attributelist)
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
       (cons 8 "0")
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
(defun
   wiki-turn-mkline (pt1 pt2)
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
  (entmake (list (cons 0 "LINE") (append '(10) (trans pt1 1 0)) (append '(11) (trans pt2 1 0))))
)

;;; GETDISTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (wiki-turn-getdistx startingpoint promptstring currentvalue vanilladefault)
(defun
   wiki-turn-getdistx (startingpoint promptstring currentvalue vanilladefault)
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
       ((getdist startingpoint (strcat promptstring " <" (rtos currentvalue) ">: ")))
       (t currentvalue)
     )
  )
)
;;; Added 2008-04-10 by Tom Haws for vehicle plotting frequency prompt.
;;; GETINTX
;;; Copyright Thomas Gail Haws 2006
;;; Get a distance providing the current value or a vanilla default.
;;; Usage: (wiki-turn-getdistx startingpoint promptstring currentvalue vanilladefault)
(defun
   wiki-turn-getintx (promptstring currentvalue vanilladefault)
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
       ((getint (strcat promptstring " <" (itoa currentvalue) ">: ")))
       (t currentvalue)
     )
  )
)

(defun
   wiki-turn-getstringx (gx-prompt gx-currentvalue gx-defaultvalue / gx-input)
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

(defun wiki-turn-asin (x) (/ x (sqrt (- 1 (* x x)))))
(defun wiki-turn-tan (theta) (/ (sin theta) (cos theta)))

;;;   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  Everything below here is Developmental Code, not ready for prime time, leave commented please  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Development code by Stephen Hitchcox.  Please keep.
;|
;; Indicate wheel turn angle on drawing
(defun wiki-turn-wheel-angles ()
;;(entmake ())
      (princ "\n  start>>>>>>")
    (princ (nth 0 point-calc-front-1))
    (princ "\n  middle>>>>>>")
    (princ (nth 1 point-calc-front-1))
        (SETQ
   ANGLETEXTLIST
    (LIST
      (CONS 0 "TEXT")  ; TEXT ENTITY
     ;(CONS 100 "AcDbEntity")
      (CONS 8 (cadr (wiki-turn-getlayer "TruckBody"))) ; TEXT LAYER
     ;(CONS 100 "AcDbCircle")

      (CONS
        10
        (nth 0 point-calc-front-1)
      )
      (CONS
        20
        (nth 1 point-calc-front-1)
      )
      (CONS 40 (/ VEHWIDTH 10)) ;TEXT HEIGHT
      (CONS 1 (ANGTOS angle-turned 0))
      (CONS 50 (RTOS DIRTRV 2))
    )
 )
 (ENTMAKE ANGLETEXTLIST)
      (princ "\n  end")
                                     ;;(SSADD (ENTLAST) VEHBLOCKLIST)
)
|;
 ;|
;;;  faster and neater than command -block, but needs fix
(defun makeblock (sset baspoint name / i e en blocktype)
(if (not sset) (setq sset (ssadd)))
(if (or (/= 'STR (type name)) (= "" name)) (setq name "*A"))
(if (= (substr name 1 1) "*")
        (setq blocktype 1 name "*A")
        (setq blocktype 0)
)
  (setq blocktype 2)  ;; added by srh
(entmake (append
        '((0 . "BLOCK"))
        (list (cons 2  name))
        (list (cons 70 blocktype))
        (list (cons 10 baspoint))
))
(setq i -1)
(while (setq e (ssname sset (setq i (1+ i))))
        (cond
                ((/= 1 (cdr (assoc 66 (entget e))))
                        (if (entget e) (progn
                                (entmake (entget e '("*")))
                                (entdel e)
                        ))
                )
                ((= 1 (cdr (assoc 66 (entget e))))
                        (if (entget e) (progn
                                (entmake (entget e '("*")))
                                (setq en e)
                                (while (/= "SEQEND" (cdr (assoc 0 (entget en))))
                                        (setq en (entnext en))
                                        (entmake (entget en '("*")))
                                )
                                (entdel e)
                        ))
                )
        )
)
(setq name (entmake '((0 . "ENDBLK"))))
(if name (progn
        (entmake (append
                '((0 . "INSERT"))
                (list (cons 2 name))
                (list (cons 10 baspoint))
        ))

))
(if name (entlast) nil)
)
(defun c:makeblock ()
  (makeblock (ssget) (getpoint "\nInsertionpoint: ") (getstring "\nName: "))
)
|;

 ;|
;;; Not yet used.
;;; See wiki-turn-MAIN-USER-BLOCK-METHOD for the working partial impementation of this.
;;; Function TRAILINGPATH
;;; Returns a list of points that define a wheel path
;;; that trails a given front wheel path
;;; with the initial point of the trailing path as given
;;; Usage:
;;;   (wiki-turn-trailingpath
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
(defun wiki-turn-trailingpath (frontpath rearstart / angle-turned heading-0
                               heading-1 i pathlistlength point-calc-front-0
                               point-calc-front-1 point-calc-rear-0
                               point-calc-rear-1 rearpath
                              )
  (setq i 0
        pathlistlength (length frontpath)
        point-calc-rear-0 rearstart
        rearpath (list rearstart)
  )
  ;; For every point on front wheel path,
  ;; calculate a point on rear wheel path
  (while (< (setq i (1+ i)) pathlistlength)
    (setq ;; Set initial point to the previous point
          point-calc-front-0 (nth (1- i) frontpath)
          ;; Set final point to current point
          point-calc-front-1 (nth i frontpath)
          ;; Initial direction of vehicle
          heading-0          (angle point-calc-rear-0 point-calc-front-0)
          ;;Angle vehicle turned this step
          angle-turned       (wiki-turn-angle-turned point-calc-front-0
                                                     heading-0
                                                     wheelbase
                                                     point-calc-front-1
                             )
          ;; Direction of vehicle at end of this step
          heading-1          (+ heading-0 angle-turned)
          ;; Location of rear wheel at end of this step
          point-calc-rear-1  (polar point-calc-front-1 heading-1 wheelbase)
          ;; Save this step's variables
          point-calc-front-0 point-calc-front-1
          point-calc-rear-0  point-calc-rear-1
          heading-0          heading-1
          rearpath           (cons point-calc-rear-1 rearpath)
                             ;;End saving
    )
  )
  (reverse rearpath)
)
|;

(wiki-turn-initialize-settings)
;;Instructions on load-up added 2008-04-10 by Tom Haws
(princ
  (strcat "\nTURN.LSP version " (wiki-turn-getvar "General.Version") " loaded.  Type TURN to start.")
)
(princ)
;|«Visual LISP© Format Options»
(200 2 40 2 nil "end of " 100 2 1 1 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
