;;; Turn 1.2 development
;|
 Definitions:
 Course: An alignment that is followed by a steerable axle
 Path: The set of states and positions that result from following a course
 Step: The state and position at the end of a calculated interval 

 Data model with sample values:
 *WIKI-TURN-OBJECTS*
 '(("paths"
     (PathId . path)
     (PathId . path)
     .
     .
     .
     (PathId . path)
   )
   ("vehicles"
     (VehicleId . vehicle)
     (VehicleId . vehicle)
     .
     .
     .
     (VehicleId . vehicle)
   )
  )


 PATH
 '(("maxspeed" . 1000)
   ("maxaccel" . 32.2)
   ("vehicle" . vehicle)
   ("steps" (stepid . step)(stepid .  step)(stepid .  step)(stepid .  step))
  )

 VEHICLE
 '("vehicle"
    ("segments"
      (segmentid . segment)
      (segmentid . segment)
      (segmentid . segment)
    )
  )


 SEGMENT
 '(segmentid ("points" (pointid . point) (pointid . point)))


 SEGMENT COORDINATE SYSTEM
 Origin point: Steering axle centroid
 Positive x (zero degree) axis: Segment "forward" direction
 Positive angle direction: Counter-clockwise
 Point coordinates: Polar (radius, theta)
 Notes: Vehicle blocks, when drawn in AutoCAD, should point right and have their insertion point as above.

 SEGMENTPOINT
 '(pointid
    ("pointposition" r theta)
    ("pointflags" . pointflags)
    ("pathlayer" . pathlayer)
    ("shapelayer" . shapelayer)
    ("usename" . usename)
  )
;;;

 SHAPE (For reuse in segments.  Initially intended for wheels. Initially can't be scaled or rotated.)
 '("shape" ("shapename" shapename) ("shapepoint" ("pointposition" r theta)("pointflags" . pointflags)))

 STEP
 '(stepid ("seconds" ) ("position" (0 ("guide" . segment 1 guide point) ("direction" . segment 1 heading angle (future use)) ("trail" . segment 1 trail point))))
 2015: For initial balance between speed and memory, we put only the guide and trail points into the step position.  Later we can add angles, then other points if we want to if it helps performance. Points are in world UCS.
 point0 is a point on the course (the first guide point) There should be function to check a step and a function to check a path against constraints.

 POINTFLAGS
 |;
(SETQ
  *PointFlagGuide*             1; Steering axle or trailer tongue point.  This is the steering guide point of this vehicle segment.
  *PointFlagTrail*             2; Back axle centroid point.  This is the tracking point of this vehicle segment.
  *PointFlagHitch*             4; Hitch point.  This is where the steering axle or tongue of the trailing vehicle connects to this vehicle segment.
  *PointFlagPlotPath*          8; Plot path (layer required in point definition). Plot a path at this point.
  *PointFlagUseBlock*         16; Use block (name required in point definition).  Use an AutoCAD block at this point.
  *PointFlagUseShape*         32; Use predefined shape (name required in point definition).  Use a predefined shape at this point.
  *PointFlagEndShapeOpen*     64; End shape open (layer required in point definition).
  *PointFlagEndShapeClosed*  128; End shape closed (layer required in point definition).
)
;|

I want to try to act like an object-oriented application.  
What that means is the various functions
will allow programmers to act (methods) on a list object, 
put information (put properties) in the list object, 
and get information (get properties) about the list object.

Hmmm.
The VLAX model has the following three basic GET, PUT and INVOKE functions
(vlax-get-property object property)
(vlax-put-property obj property arg)
(vlax-invoke-method obj method arg [arg...])

And the following object creation functions
(vlax-get-object prog-id)
(vlax-get-or-create-object prog-id)
(vlax-create-object prog-id)

Not a bad strategy.

I am also following the following style rules:
1.  All functions have one and only one argument, a list called args.
    This enables us to have optional arguments if we want.
2.  All global symbols (variables) enclosed in asterisks like *MyGlobal*

|;

;;; Creates an empty path.
;;; This is the "new object" function
;;; Arguments:
;;; Returns the PathId for the path.
;| Development notes:
This function should really require the minimum arguments for
creating a valid path that can be added to.
I think the minimum stuff that's needed are
A complete vehicle
2015: Doesn't a path need a course?  And isn't that the minimum valid path, an empty course?
|;

(DEFUN
   WIKI-TURN-PATHS-ADD-PATH (args / PathId path paths)
  ;;Get the arguments
  ;;None for now
  ;;Create the new path
  (SETQ
    path
   '(
      ("maxspeed" 1000)
      ("maxaccel" 9.8)
      ("vehicle"
        ("segments"
          ("segment"
            ("id" 0)
            ("point" 
              ("position" 0 0) 
              ("flags" *PointFlagGuide*)
            )
            ("point"
             ("position" 20.0 PI)
             ("flags" (+ *PointFlagTrail* *PointFlagPlotPath*))
             ("pathlayer" "C-TURN-SEG1-BACK-CNTR")
            )
            ("point"
             ("position" 18.0 PI)
             ("flags" (+ *PointFlagHitch* *PointFlagPlotPath*))
             ("pathlayer" "C-TURN-SEG1-HTCH")
            )
          )
          ("segment"
            ("id" 1)
            ("point" 
              ("position" 0 0) 
              ("flags" *PointFlagGuide*)
            )
            ("point"
              ("position" 20.0 PI)
              ("flags" (+ *PointFlagTrail* *PointFlagPlotPath*))
              ("pathlayer" "C-TURN-SEG2-BACK-CNTR")
            )
            ("point"
              ("position" 18.0 PI)
              ("flags" (+ *PointFlagHitch* *PointFlagPlotPath*))
              ("pathlayer" "C-TURN-SEG2-HTCH")
            )
          )
        )
      )
      ("steps" 
        ("step"
          ("id" 0)
          ("seconds" 0.0)
          ("position" 
            (0 ("guide" 100.0 0.0)("trail" 80.0 0.0)) 
            (1 ("guide" 70.0 0.0)("trail" 50.0 0.0)) 
          )
        )
        ("step"
          ("id" 0)
          ("seconds" 1.0)
          ("position" 
            (0 ("guide" 200.0 0.0)("trail" 180.0 0.0)) 
            (1 ("guide" 170.0 0.0)("trail" 150.0 0.0)) 
          )
        )
      )
    )
  )
  ;;Get the id for the new path
  ;;All the paths are stored in the global variable *WIKI-TURN-OBJECTS*
  (COND
    ;;If there are already path objects
    ((SETQ paths (CDR (ASSOC "paths" (WIKI-TURN-GET-OBJECTS nil))))
     ;;Then find a free id integer
     ;;Start at 0
     (SETQ PathId 0)
     ;;and increment until there is no such path in paths
     (WHILE (ASSOC PathId paths) (SETQ PathId (1+ PathId)))
    )
    ;;Else PathId=0
    (T (SETQ PathId 0))
  )
  ;;Add the new path to paths
  (SETQ paths (CONS (CONS PathId path) paths))
  ;;Save the modified paths to the global variable
  (WIKI-TURN-PUT-OBJECTS
    (LIST
      (SUBST
        (CONS "paths" paths)
        (CONS "paths" (WIKI-TURN-GET-PATHS nil))
        (WIKI-TURN-GET-OBJECTS nil)
      )
    )
  )
  ;;Return the path ID
  PathId
)

;;; Gets the turn objects list from its global variable
;;; Mostly just a development utility
(DEFUN
   WIKI-TURN-GET-OBJECTS (args)
  (COND
    (*WIKI-TURN-OBJECTS*)
    ('(("paths")))
  )
)

;;; Trying out this object oriented approach a la
;;; (vlax-invoke-method obj method arg [arg...])
;;; I'm also abbreviating WIKI-TURN- as wt-
;;; Usage:
;;; (wt-invoke-method
;;;   (list
;;;     obj {string}
;;;     method {string}
;;;     arg
;;;     [arg...]
;;;   )
;;; )
(defun wt-invoke-method (args / obj method)
  (setq
    obj (car args)
    method (cadr args)
  )
  ;;I guess this is just a wrapper function for all the
  ;;individual method functions for each object and method.
  ;;So
  (cond
    (= obj '
  )
)
;;;Puts the objects list in its global variable
(DEFUN
   WIKI-TURN-PUT-OBJECTS (args / AllObjects)
  (SETQ
    AllObjects
     (CAR args)
    *WIKI-TURN-OBJECTS* AllObjects
  )
)

;;;Gets all the paths
(DEFUN
   WIKI-TURN-GET-PATHS (args)
  (CDR (ASSOC "paths" *WIKI-TURN-OBJECTS*))
)

;;;Gets a single path list
;;;Obj
(DEFUN
   WIKI-TURN-GET-PATH (args / PathId)
  (SETQ PathId (CAR args))
  (CDR (ASSOC PathId (WIKI-GET-PATHS)))
)

;;;Puts a vehicle definition in a path
(DEFUN WIKI-TURN-PUT-VEHICLE (args / )
  (setq
    PathId (car args)
    Path (WIKI-TURN-GET-PATH (list PathId))
    Vehicle (cadr args)
  )
  (setq
  (subst
    (assoc PathId 
  )
)

;;;Advances the path to a new point
(DEFUN WIKI-TURN-PATH-ADVANCE (PathId NewPoint) nil)

;;;Retracts one point from the path
(DEFUN WIKI-TURN-PATH-RETRACT (PathId) nil)

 ;|
(defun WIKI-TURN-PATH (PathId ))

(defun WIKI-TURN-PATH (PathId ))

(defun WIKI-TURN-PATH (PathId ))
|;
;;; Converts rectangular coordinates to polar coordinates
;;; Returns a two-element list of '(radius theta)
;
(defun wiki-turn-recttopolar (args / x y)
  ;;Get arguments
  (setq x (car args) y (cadr args))
  ;;Calculate radius (sqrt(x^2 + y^2)) and theta (atan(y/x))
  (list (sqrt(+ (exp (* 2 (ln x)))(exp (* 2 (ln y)))))(cond ((= x 0)(/ pi (cond((minusp y) -2)(T  2))))(T(+(atan (/ y x))(cond ((minusp x) pi)(T 0))))))
  ;; How about (list (distance '(0 0) args)(angle '(0 0) args)) ?
)

;;; Translates version 1.1 vehicle data to 1.2 format
;;; Returns a version 1.2 vehicle
(DEFUN
   WIKI-TURN-VEHICLE-1.1-TO-1.2
   (args / backaxlecentroid wheelhalflength wheelhalfwidth)
  ;;Set variables
  (SETQ
    VD1.1 args
    wheelhalflength
     (/ (CDR (ASSOC "VEHBODYLENGTH" VD1.1)) 10)
    wheelhalfwidth
     (/ (CDR (ASSOC "VEHWIDTH" VD1.1)) 10)
  )
  (LIST
    "vehicle"
    (LIST
      "shapes"
      (LIST
        "shape"
        (CONS "shapename" "wheel")
        ;;Front left corner
        (LIST
          "shapepoints"
          (LIST
            "shapepoint"
            (CONS
              "pointposition"
              (wiki-turn-recttopolar
                (LIST wheelhalfwidth wheelhalflength)
              )
            )
            (CONS "pointflags" 2)
          )
          ;;Front right corner
          (LIST
            "shapepoint"
            (CONS
              "pointposition"
              (wiki-turn-recttopolar
                (LIST wheelhalfwidth (* -1 wheelhalflength))
              )
            )
            (CONS "pointflags" 2)
          )
          ;;Back right corner
          (LIST
            "shapepoint"
            (CONS
              "pointposition"
              (wiki-turn-recttopolar
                (LIST (* -1 wheelhalfwidth) (* -1 wheelhalflength))
              )
            )
            (CONS "pointflags" 2)
          )
          ;;Back left corner
          (LIST
            "shapepoint"
            (CONS
              "pointposition"
              (wiki-turn-recttopolar
                (LIST (* -1 wheelhalfwidth) wheelhalflength)
              )
            )
            (CONS "pointflags" 8)
          )
        )
      )
    )
    (LIST
      "segments"
      (LIST
        "segment"
        ;;Steering axle centroid
        (LIST
          "segmentpoint"
          (CONS "pointposition" 0 0)
          (CONS "pointflags" 16)
        )
        ;;Back axle centroid "VEHWHEELBASE" back from steering axle
        (LIST
          "segmentpoint"
          (CONS "pointposition" (CDR (ASSOC "VEHWHEELBASE" VD1.1)) PI)
          (CONS "pointflags" 32)
        )
        ;;Hitch "VEHWHEELBASE" plus "VEHREARHITCH" back from steering axle
        (LIST
          "segmentpoint"
          (CONS
            "pointposition"
            (+ (CDR (ASSOC "VEHWHEELBASE" VD1.1))
               (CDR (ASSOC "VEHREARHITCH" VD1.1))
            )
            PI
          )
          (CONS "pointflags" 64)
        )
        ;;Body front left corner
        (LIST
          "segmentpoint"
          (CONS
            "pointposition"
            (wiki-turn-recttopolar
              (LIST
                (CDR (ASSOC "VEHFRONTHANG" VD1.1))
                (/ (CDR (ASSOC "VEHWIDTH" VD1.1)) 2)
              )
            )
          )
          ;;Plot shape
          (CONS "pointflags" 2)
        )
        ;;Body front right corner
        (LIST
          "segmentpoint"
          (CONS
            "pointposition"
            (wiki-turn-recttopolar
              (LIST
                (CDR (ASSOC "VEHFRONTHANG" VD1.1))
                (/ (CDR (ASSOC "VEHWIDTH" VD1.1)) -2)
              )
            )
          )
          ;;Plot shape
          (CONS "pointflags" 2)
        )
        ;;Body back right corner
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (wiki-turn-recttopolar
              (LIST
                (- (CDR (ASSOC "VEHFRONTHANG" VD1.1))
                   (CDR (ASSOC "VEHBODYLENGTH" VD1.1))
                )
                (/ (CDR (ASSOC "VEHWIDTH" VD1.1)) 2)
              )
            )
          )
          ;;Plot shape
          (CONS "pointflags" 2)
        )
        ;;Body back left corner
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (wiki-turn-recttopolar
              (LIST
                (- (CDR (ASSOC "VEHFRONTHANG" VD1.1))
                   (CDR (ASSOC "VEHBODYLENGTH" VD1.1))
                )
                (/ (CDR (ASSOC "VEHWIDTH" VD1.1)) 2)
              )
            )
          )
          ;;End shape closed 
          (CONS "pointflags" 8)
          (CONS "shapelayer" "TruckBody")
        )
        ;;Front left wheel
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (* (CDR (ASSOC "VEHWIDTH" VD1.1)) 0.45)
            (/ PI 2)
          )
          ;;Use pre-defined shape 
          (CONS "pointflags" 128)
          (CONS "useshape" "wheel")
          (CONS "shapelayer" "TruckBody")
        )
        ;;Front right wheel
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (* (CDR (ASSOC "VEHWIDTH" VD1.1)) 0.45)
            (/ PI -2)
          )
          ;;Use pre-defined shape 
          (CONS "pointflags" 128)
          (CONS "useshape" "wheel")
          (CONS "shapelayer" "TruckBody")
        )
        ;;Back right wheel
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (wiki-turn-recttopolar
              (POLAR
                (POLAR (CDR (ASSOC "VEHWHEELBASE" VD1.1)) PI)
                (* (CDR (ASSOC "VEHWIDTH" VD1.1)) 0.45)
                (/ PI -2)
              )
            )
          )
          ;;Use pre-defined shape 
          (CONS "pointflags" 128)
          (CONS "useshape" "wheel")
          (CONS "shapelayer" "TruckBody")
        )
        ;;Back left wheel
        (LIST
          "segmentpoint"
          (LIST
            "pointposition"
            (wiki-turn-recttopolar
              (POLAR
                (POLAR (CDR (ASSOC "VEHWHEELBASE" VD1.1)) PI)
                (* (CDR (ASSOC "VEHWIDTH" VD1.1)) 0.45)
                (/ PI 2)
              )
            )
          )
          ;;Use pre-defined shape 
          (CONS "pointflags" 128)
          (CONS "useshape" "wheel")
          (CONS "shapelayer" "TruckBody")
        )
      )
      (COND
        ((= (CDR (ASSOC "TRAILHAVE" VD1.1)) "Y")
         ;;Extract the trailer too like above.
        )
      )
    )
  )
)
;|
(CDR
 (ASSOC
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
|;
;;; VEHICLE
;;; '("vehicle"("segments" ("segment" . segment)("segment" . segment)("segment" . segment)))
;;;
;;; SEGMENT
;;; '("segment" ("segmentpoint" . segmentpoint)("segmentpoint" . segmentpoint)("segmentpoint" . segmentpoint))
;;;
;;; SEGMENT COORDINATE SYSTEM
;;; Origin point: Steering axle centroid
;;; Positive x (zero degree) axis: Segment "forward" direction
;;; Positive angle direction: Counter-clockwise
;;; Point coordinates: Polar (radius, theta)
;;; Notes: Vehicle blocks, when drawn in AutoCAD, should point right and have their insertion point as above.
;;;
;;; SEGMENTPOINT
;;; '("segmentpoint" ("pointposition" r theta)("pointflags" . pointflags)("pathlayer" . pathlayer)("shapelayer" . shapelayer))
;;;
;;; Legacy code
;;;
(DEFUN
   TURN-INITIALIZESETTINGS ()
  (TURN-SETVAR "General.Version" "1.1.10")
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

;;; VEHICLEDATAGET gets the vehicle attributes from a BUILDVEHICLE
;;; defined block.
;;; Returns a list of vehicle properties.
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


;;;
;;; The following can go in a separate file called turn-lang.lsp
;;;

 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 0 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
