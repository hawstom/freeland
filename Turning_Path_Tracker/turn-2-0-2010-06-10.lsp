;;; Turn 1.2 development
;|
 Definitions:
 Course: An alignment that is followed by a steerable axle
 Path: The set of states and positions that result from following a course
 Step: The state and position at the end of a calculated interval 

 2009-09-26 TGH I am having a hard time structuring this data
 I'd like to have the paths, the vehicles, the segments, and the tblocks as associative lists.
 But in XML, each element is named, not grouped, right?
 
 Data model with sample values:
 *WIKI-TURN-OBJECTS*
 '(("path"
     (PathId path)
     (PathId path)
     .
     .
     .
     (PathId path)
   )
   ("vehicle"
     (VehicleId vehicle)
     (VehicleId vehicle)
     .
     .
     .
     (VehicleId vehicle)
   )
   ("segment"
     (SegmentId segment)
     (SegmentId segment)
     .
     .
     .
     (SegmentId segment)
   )
   ("tblock"
     (TblockId tblock)
     (TblockId tblock)
     .
     .
     .
     
     (TblockId tblock)
  )


 PATH
 '(PathId
   ("maxspeed" . 1000)
   ("maxaccel" . 32.2)
   ("vehicle" . VehicleId)
   ("step" (StepId . step)(StepId .  step)(StepId .  step)(StepId .  step))
  )

 VEHICLE
 '("vehicle"
    ("segments"
      ("segment" . Segment)
      ("segment" . Segment)
      ("segment" . Segment)
    )
  )


 SEGMENT
 '("segment" segmentid ("points" ("point" . point) ("point" . point)))

 TBLOCK
 '(TblockName ("points" ("point" . point) ("point" . point)))


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
    ("usename" . usename) ;Name of block or segment to be used at this point
  )
;;;

 tblock (For reuse in segments.  Initially intended for wheels. For now, can't be scaled or rotated.)
 '("tblock" ("tblockname" tblockname) ("tblockpoint" ("pointposition" r theta)("pointflags" . pointflags)))

 STEP
 '("step" ("vehicle" vehicle)) 

 POINTFLAGS
|;
;;Global "constants" (for now)
(SETQ
  *WT-POINT-PATH*
   1                                    ; Path (indicates that a path line should be plotted at this point)
  *WT-POINT-DBLOCK*
   2                                    ; Drawing block (Indicates that a drawing block should be inserted at this point. Name required)
  *WT-POINT-TBLOCK*
   4                                    ; Turn block (Indicates that a pre-defined turn block should be plotted at this point. Name required.)
  *WT-POINT-STEERING*
   8                                    ; Steering axle or trailer tongue point (identifies this as that point)
  *WT-POINT-BACK-AXLE*
   16                                   ; Back axle centroid point (identifies this as that point)
  *WT-POINT-HITCH*
   32                                   ; Hitch point (identifies this as that point)
  *WT-POINT-SHAPE-START*
   64                                   ; Shape start (For use in vehicle or tblock definitions.  Layer follows vehicle segment.) 
  *WT-POINT-SHAPE-OPEN*
   128                                  ; End shape open (For use in vehicle or tblock definitions.  Layer follows vehicle segment.) 
  *WT-POINT-SHAPE-CLOSED*
   256                                  ; End shape closed (For use in vehicle or tblock definitions.  Layer follows vehicle segment.)
)

;;;Data stub functions, mostly for testing
(DEFUN
   WIKI-TURN-STUB-PATH ()
  '(("maxspeed" 1000)
    ("maxaccel" 32.2)
    ("vehicle" (WIKI-TURN-STUB-VEHICLE))
   )
)
(DEFUN
   WIKI-TURN-STUB-VEHICLE ()
  '(("maxspeed" 1000)
    ("maxaccel" 32.2)
    ("vehicle"
     ("segments"
      ("segment"
       ("id" 1)
       ("point" ("position" 0 0) ("flags" 16))
       ("point"
        ("position" 20.0 PI)
        ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-BACK-AXLE*))
        ("pathlayer" "C-TURN-SEG1-BACK-CNTR")
       )
       ("point"
        ("position" 18.0 PI)
        ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-HITCH*))
        ("pathlayer" "C-TURN-SEG1-HTCH")
       )
      )
     )
    )
   )
)
(DEFUN
   WIKI-TURN-STUB-SEGMENT ()
  '("segmentstub"
    ("point" ("position" 0 0) ("flags" 16))
    ("point"
     ("position" 20.0 PI)
     ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-BACK-AXLE*))
     ("pathlayer" "C-TURN-SEG1-BACK-CNTR")
    )
    ("point"
     ("position" 18.0 PI)
     ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-HITCH*))
     ("pathlayer" "C-TURN-SEG1-HTCH")
    )
   )
)
(DEFUN
   WIKI-TURN-STUB-TBLOCK ()
  '("tblockstub"
    ("point" ("position" 0 0) ("flags" 16))
    ("point"
     ("position" 20.0 PI)
     ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-BACK-AXLE*))
     ("pathlayer" "C-TURN-SEG1-BACK-CNTR")
    )
    ("point"
     ("position" 18.0 PI)
     ("flags" (+ *WT-POINT-PLOT-PATH* *WT-POINT-HITCH*))
     ("pathlayer" "C-TURN-SEG1-HTCH")
    )
   )
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

;;; WIKI-TURN-PUT-PATH
;;; Puts a path in *WIKI-TURN-OBJECTS*
;;; If no path is supplied, creates an empty path suitable for testing purposes.
;;; Returns the PathId for the path.
;| Development notes:
This function should really require the minimum arguments for
creating a valid path that can be added to.
I think the minimum stuff that's needed are
A complete vehicle.  Hopefully that is already there.
2009-07-13 TGH  Functional.  Creates a list. Test with WIKI-TURN-GET-OBJECTS
|;

(DEFUN
   WIKI-TURN-PUT-PATH (args / PathId path paths)
  ;;Get the arguments
  (setq
    pathId (car args)
    path (cadr args)
  ;;Create the new path
  )
  (cond ((not path)
  (SETQ
    path
     (WIKI-TURN-STUB-PATH)
       )
      )
  )
  ;;Get the id for the new path
  ;;All the paths are stored in the global variable *WIKI-TURN-OBJECTS*
  (cond
    ((not PathId)
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
  )))
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

;;;Puts a vehicle definition in a path
;;;Returns the VehicleId
;;;2009-09-26 TGH Maybe the vehicle definition shouldn't go in the "path:,
;;;but rather in the "vehicles" section and be referenced from the path.
(DEFUN
   WIKI-TURN-PUT-VEHICLE (args / path)
  (SETQ
    ;;Integer PathId argument
    PathId
     (CAR args)
    ;;Vehicle definition list to add to path
    Vehicle
     (CADR args)
    Path
     (WIKI-TURN-GET-PATH (LIST PathId))
  )
  (SETQ
    path
       (SUBST (CONS "vehicle" Vehicle) (ASSOC "vehicle" Path) Path)
  )
  (WIKI-TURN-PUT-PATH (list PathId path))
)

;;;Puts a vehicle segment in a vehicle
(DEFUN
   WIKI-TURN-PUT-SEGMENT (args / path)
  (SETQ
    ;;Integer PathId argument
    PathId
     (CAR args)
    Vehicle
     (CADR args)
    Segment
     (CADDR args)
    Path
     (WIKI-TURN-GET-PATH (LIST PathId))
  )
  (SETQ
    path
       (SUBST (CONS "vehicle" Vehicle) (ASSOC "vehicle" Path) Path)
  )
  (WIKI-TURN-PUT-PATH (list PathId path))
)

;;;Puts a vehicle segment in a vehicle
(DEFUN
   WIKI-TURN-PUT-TBLOCK (args / path)
  (SETQ
    ;;Integer TblockhId argument
    PathId
     (CAR args)
    Vehicle
     (CADR args)
    Segment
     (CADDR args)
    Path
     (WIKI-TURN-GET-PATH (LIST PathId))
  )
  (SETQ
    path
       (SUBST (CONS "vehicle" Vehicle) (ASSOC "vehicle" Path) Path)
  )
  (WIKI-TURN-PUT-PATH (list PathId path))
)

;;; Gets the turn objects list from its global variable
;;; Mostly just a development utility
;;; 2009-07-13 TGH  Functional.  Displays list if run after WIKI-TURN-PATHS-ADD-PATH
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
;;; 2009-07-13 TGH  Useless?
;;; 2009-09-26 TGH  Yeah.  Useless?
(defun wt-invoke-method (args / obj method)
  (setq
    obj (car args)
    method (cadr args)
  )
  ;;I guess this is just a wrapper function for all the
  ;;individual method functions for each object and method.
  ;;So
  (cond
;    (= obj ' 
  )
)
;;;Puts the objects list in its global variable
;;; 2009-07-13 TGH  Functional.  Called by WIKI-TURN-PATHS-ADD-PATH
(DEFUN
   WIKI-TURN-PUT-OBJECTS (args / AllObjects)
  (SETQ
    AllObjects
     (CAR args)
    *WIKI-TURN-OBJECTS* AllObjects
  )
)

;;;Gets all the paths
;;; 2009-07-13 TGH  Functional.
(DEFUN
   WIKI-TURN-GET-PATHS (args)
  (CDR (ASSOC "paths" *WIKI-TURN-OBJECTS*))
)

;;;Gets a single path list
;;; 2009-07-13 TGH  Functional.
(DEFUN
   WIKI-TURN-GET-PATH (args / PathId)
  (SETQ PathId (CAR args))
  (CDR (ASSOC PathId (WIKI-TURN-GET-PATHS nil)))
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
;;; Converts rectangular coordinates to AutoLISP polar coordinates
;;; Returns a two-element list of '(ang dist)
;
(defun wiki-turn-recttopolar (args / x y)
  ;;Get arguments
  (setq x (car args) y (cadr args))
  ;;Calculate radius and theta
  ;;(list (sqrt(+ (exp (* 2 (log x)))(exp (* 2 (log y)))))(cond ((= x 0)(/ pi (cond((minusp y) -2)(T  2))))(T(+(atan (/ y x))(cond ((minusp x) pi)(T 0))))))
  ;; Why not just the following line?
  (list (angle '(0 0) args)(distance '(0 0) args))
)

(DEFUN
   c:drawvehicle (/)
  (WIKI-TURN-DRAW-VEHICLE
    (c:convertvehicle)
  )
)

(DEFUN
   c:convertvehicle (/)
  (WIKI-TURN-VEHICLE-1-1-TO-1-2
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
      (LIST "TRAILHAVE" "Y")
      (LIST "TRAILNAME" "TestTrailer")
      (LIST "TRAILUNITS" "M")
      (LIST "TRAILERHITCHTOWHEEL" 10000.0)
      (LIST "TRAILERWHEELWIDTH" 2000.0)
      (LIST "TRAILERFRONTHANG" 1000.0)
      (LIST "TRAILERBODYLENGTH" 12000.0)
      (LIST "TRAILERWIDTH" 2440.0)
    )
  )
)

;;; WIKI-TURN-DRAW-VEHICLE
;;; This function is to test the vehicle translation function.
;;; It doesn't yet plot blocks. It just plots polylines.
(DEFUN
   WIKI-TURN-DRAW-VEHICLE (vehicle / )
  ;;Draw each segment
  (FOREACH
     segment (CDR (ASSOC "segments" (cdr vehicle)))
    ;;Process sequentially each element of the segment
    (WIKI-TURN-DRAW-SHAPE (CDR SEGMENT) vehicle '(0 0) 0 nil)
  )
)

(DEFUN
   WIKI-TURN-LOOKUP-TBLOCK (REFERRER VEHICLE / RETURN TBLOCK)
  (SETQ TBLOCKNAME (CDR (ASSOC "usetblock" (CDR referrer))))
  (FOREACH
     TBLOCKTEMP (CDR (ASSOC "tblocks" (CDR vehicle)))
    (IF (= tblockname (CDR (ASSOC "tblockname" (CDR tblocktemp))))
      (SETQ tblock (assoc "tblockpoints" (cdr tblocktemp)))
    )
  )
  tblock
)
;;; WIKI-TURN-DRAW-SHAPE
;;; This function is to test the vehicle translation function.
;;; It doesn't yet plot blocks. It just plots polylines.
(DEFUN
   WIKI-TURN-DRAW-SHAPE (shape vehicle insertion rotation parentlayer / layerkey lwpoly points SEGMENTPOLY)
  (FOREACH
     shapepoint (CDR shape)
    ;;Set the layer for the point
    (SETQ
      layerkey
       (COND
         ;;If the point has a layer key, use it
         ((CDR (ASSOC "shapelayer" (CDR shapepoint))))
         ;;Else use the parent layer.
         (parentlayer)
       )
    )
    ;;Add the point to the front of the points list in case there is
    ;;a polyline to be drawn
    (SETQ
      points
       (CONS
         (CONS
           10
           (polar
               insertion
               (CaDR (ASSOC "pointposition" (CDR shapepoint)))
               (CaDdR (ASSOC "pointposition" (CDR shapepoint)))
           )
         )
         points
       )
    )
    (COND
      ;;If it's a tblock, draw it
      ((= *WT-POINT-TBLOCK*
          (LOGAND
            (CDR (ASSOC "pointflags" (CDR shapepoint)))
            *WT-POINT-TBLOCK*
          )
       )
       (WIKI-TURN-DRAW-SHAPE
         (WIKI-TURN-LOOKUP-TBLOCK shapepoint vehicle)
         vehicle
         (CDR (ASSOC "pointposition" (CDR shapepoint)))
         0
         layerkey
       )
      )
      ;;If it's the start of a shape
      ((= *WT-POINT-SHAPE-START*
          (LOGAND
            (CDR (ASSOC "pointflags" (CDR shapepoint)))
            *WT-POINT-SHAPE-START*
          )
       )
       (SETQ
         ;;Clear the rest of the points list
         points
          (LIST (CAR points))
         ;; Start a polyline at the point
         LWPOLY
          (LIST
            (CONS 43 0.0)
            (CONS 100 "AcDbPolyline")
            (CONS 100 "AcDbEntity")
            (CONS 0 "LWPOLYLINE")
          )
       )
      )
      ;;If it's the end of an open shape,
      ((= *WT-POINT-SHAPE-OPEN*
          (LOGAND
            (CDR (ASSOC "pointflags" (CDR shapepoint)))
            *WT-POINT-SHAPE-OPEN*
          )
       )
       ;;Put the polyline together and entmake it.
       (SETQ
         lwpoly
          (APPEND
            points
            (LIST
              ;; Number of polyline points
              (CONS 90 (LENGTH points))
              (CONS
                8
                (CAR
                  (TURN-GETLAYER
                    layerkey
                  )
                )
              )
            )
            lwpoly
          )
       )
       (ENTMAKE (REVERSE lwpoly))
      )
      ;;If it's the end of a closed shape,
      ((= *WT-POINT-SHAPE-CLOSED*
          (LOGAND
            (CDR (ASSOC "pointflags" (CDR shapepoint)))
            *WT-POINT-SHAPE-CLOSED*
          )
       )
       ;;Put the polyline together and entmake it.
       (SETQ
         lwpoly
          (APPEND
            points
            (LIST
              ;; Closed pline if 1 is set.
              (CONS 70 1)
              ;; Number of polyline points
              (CONS 90 (LENGTH points))
              (CONS
                8
                (CAR
                  (TURN-GETLAYER
                    layerkey
                  )
                )
              )
            )
            lwpoly
          )
       )
       (ENTMAKE (REVERSE lwpoly))
      )
    )
  )
)

;;; Translates version 1.1 vehicle data to 1.2 format
;;; Usage:
;;; (WIKI-TURN-VEHICLE-1-1-TO-1-2
;;;   Version 1.1 VEHDATA list
;;; )
;;; Returns a version 1.2 vehicle
(DEFUN
   WIKI-TURN-VEHICLE-1-1-TO-1-2
   (args / backaxlecentroid trailer wheelhalflength wheelhalfwidth)
  ;;Set variables
  (SETQ
    VD1-1 args
    wheelhalflength
     (/ (CADR (ASSOC "VEHBODYLENGTH" VD1-1)) 10)
    wheelhalfwidth
     (/ (CADR (ASSOC "VEHWIDTH" VD1-1)) 10)
  )
  (SETQ
    VD1-2
     (LIST
       "vehicle"
       (LIST
         "tblocks"
         (LIST
           "tblock"
           (CONS "tblockname" "wheel")
           ;;Wheel tblock front left corner
           (LIST
             "tblockpoints"
             (LIST
               "tblockpoint"
               (CONS
                 "pointposition"
                 (wiki-turn-recttopolar
                   (LIST wheelhalflength wheelhalfwidth)
                 )
               )
               (CONS "pointflags" *WT-POINT-SHAPE-START*)
             )
             ;;Wheel tblock front right corner
             (LIST
               "tblockpoint"
               (CONS
                 "pointposition"
                 (wiki-turn-recttopolar
                   (LIST wheelhalflength (* -1 wheelhalfwidth))
                 )
               )
               (CONS "pointflags" 0)
             )
             ;;Wheel tblock back right corner
             (LIST
               "tblockpoint"
               (CONS
                 "pointposition"
                 (wiki-turn-recttopolar
                   (LIST
                     (* -1 wheelhalflength)
                     (* -1 wheelhalfwidth)
                   )
                 )
               )
               (CONS "pointflags" 0)
             )
             ;;Wheel tblock back left corner
             (LIST
               "tblockpoint"
               (CONS
                 "pointposition"
                 (wiki-turn-recttopolar
                   (LIST (* -1 wheelhalflength) wheelhalfwidth)
                 )
               )
               (CONS "pointflags" *WT-POINT-SHAPE-CLOSED*)
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
             (LIST "pointposition" 0 0)
             (CONS "pointflags" *WT-POINT-STEERING*)
           )
           ;;Back axle centroid "VEHWHEELBASE" back from steering axle
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               PI
               (CADR (ASSOC "VEHWHEELBASE" VD1-1))
             )
             (CONS "pointflags" *WT-POINT-BACK-AXLE*)
           )
           ;;Hitch "VEHWHEELBASE" plus "VEHREARHITCH" back from steering axle
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               PI
               (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                  (CADR (ASSOC "VEHREARHITCH" VD1-1))
               )
             )
             (CONS "pointflags" *WT-POINT-HITCH*)
           )
           ;;Body front left corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (CADR (ASSOC "VEHFRONTHANG" VD1-1))
                   (/ (CADR (ASSOC "VEHWIDTH" VD1-1)) 2)
                 )
               )
             )
             ;;Start shape here
             (CONS "pointflags" *WT-POINT-SHAPE-START*)
           )
           ;;Body front right corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (CADR (ASSOC "VEHFRONTHANG" VD1-1))
                   (/ (CADR (ASSOC "VEHWIDTH" VD1-1)) -2)
                 )
               )
             )
             ;;Just continue shape
             (CONS "pointflags" 0)
           )
           ;;Body back right corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (- (CADR (ASSOC "VEHFRONTHANG" VD1-1))
                      (CADR (ASSOC "VEHBODYLENGTH" VD1-1))
                   )
                   (/ (CADR (ASSOC "VEHWIDTH" VD1-1)) -2)
                 )
               )
             )
             ;;Plot shape
             (CONS "pointflags" 2)
           )
           ;;Body back left corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (- (CADR (ASSOC "VEHFRONTHANG" VD1-1))
                      (CADR (ASSOC "VEHBODYLENGTH" VD1-1))
                   )
                   (/ (CADR (ASSOC "VEHWIDTH" VD1-1)) 2)
                 )
               )
             )
             ;;End shape closed 
             (CONS "pointflags" *WT-POINT-SHAPE-CLOSED*)
             (CONS "shapelayer" "TruckBody")
           )
           ;;Front left wheel
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               (/ PI 2)
               (* (CADR (ASSOC "VEHWIDTH" VD1-1)) 0.45)
             )
             ;;Use pre-defined tblock 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TruckBody")
           )
           ;;Front right wheel
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               (/ PI -2)
               (* (CADR (ASSOC "VEHWIDTH" VD1-1)) 0.45)
             )
             ;;Use pre-defined shape 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TruckBody")
           )
           ;;Back right wheel
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                   (* -1 (CADR (ASSOC "VEHWHEELBASE" VD1-1)))
                   (* (CADR (ASSOC "VEHWIDTH" VD1-1)) -0.45)
               )
             )
             ;;Use pre-defined shape 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TruckBody")
           )
           ;;Back left wheel
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                   (* -1 (CADR (ASSOC "VEHWHEELBASE" VD1-1)))
                   (* (CADR (ASSOC "VEHWIDTH" VD1-1)) 0.45)
               )
             )
             ;;Use pre-defined shape 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TruckBody")
           )
         )
       )
     )
  )
  (COND
    ((= (CADR (ASSOC "TRAILHAVE" VD1-1)) "Y")
     (setq trailer
         (LIST
           "segment"
           ;;Steering axle centroid (Tongue point)
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               pi
               (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                  (CADR (ASSOC "VEHREARHITCH" VD1-1))
               )
             )
             (CONS "pointflags" *WT-POINT-STEERING*)
           )
           ;;Back axle centroid "TRAILERHITCHTOWHEEL" back from steering axle
           (LIST
             "segmentpoint"
             (LIST
               "pointposition"
               PI
               (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                  (CADR (ASSOC "VEHREARHITCH" VD1-1))
                  (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
               )
             )
             (CONS "pointflags" *WT-POINT-BACK-AXLE*)
           )
           ;;Body front left corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (-
                     (CADR (ASSOC "TRAILERFRONTHANG" VD1-1))
                     (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                         (CADR (ASSOC "VEHREARHITCH" VD1-1))
                         (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                      )
                   )
                   (/ (CADR (ASSOC "TRAILERWIDTH" VD1-1)) 2)
                 )
               )
             )
             ;;Start shape here
             (CONS "pointflags" *WT-POINT-SHAPE-START*)
           )
           ;;Body front right corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (-
                     (CADR (ASSOC "TRAILERFRONTHANG" VD1-1))
                     (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                         (CADR (ASSOC "VEHREARHITCH" VD1-1))
                         (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                      )
                   )
                   (/ (CADR (ASSOC "TRAILERWIDTH" VD1-1)) -2)
                 )
               )
             )
             ;;Just continue shape
             (CONS "pointflags" 0)
           )
           ;;Body back right corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (-
                     (CADR (ASSOC "TRAILERFRONTHANG" VD1-1))
                     (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                         (CADR (ASSOC "VEHREARHITCH" VD1-1))
                         (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                         (CADR (ASSOC "TRAILERBODYLENGTH" VD1-1))
                      )
                   )
                   (/ (CADR (ASSOC "TRAILERWIDTH" VD1-1)) -2)
                 )
               )
             )
             ;;Plot shape
             (CONS "pointflags" 2)
           )
           ;;Body back left corner
           (LIST
             "segmentpoint"
             (CONS
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (-
                     (CADR (ASSOC "TRAILERFRONTHANG" VD1-1))
                     (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                         (CADR (ASSOC "VEHREARHITCH" VD1-1))
                         (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                         (CADR (ASSOC "TRAILERBODYLENGTH" VD1-1))
                      )
                   )
                   (/ (CADR (ASSOC "TRAILERWIDTH" VD1-1)) 2)
                 )
               )
             )
             ;;End shape closed 
             (CONS "pointflags" *WT-POINT-SHAPE-CLOSED*)
             (CONS "shapelayer" "TrailerBody")
           )
           ;;Trailer left wheel
           (LIST
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                      (CADR (ASSOC "VEHREARHITCH" VD1-1))
                      (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                   )
                   (* (CADR (ASSOC "TRAILERWIDTH" VD1-1)) 0.45)
                 )
               )
             )
             ;;Use pre-defined tblock 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TrailerBody")
           )
           ;;Trailer right wheel
           (LIST
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (LIST
                   (+ (CADR (ASSOC "VEHWHEELBASE" VD1-1))
                      (CADR (ASSOC "VEHREARHITCH" VD1-1))
                      (CADR (ASSOC "TRAILERHITCHTOWHEEL" VD1-1))
                   )
                   (* (CADR (ASSOC "TRAILERWIDTH" VD1-1)) -0.45)
                 )
               )
             )
             ;;Use pre-defined shape 
             (CONS "pointflags" *WT-POINT-TBLOCK*)
             (CONS "usetblock" "wheel")
             (CONS "shapelayer" "TrailerBody")
           )
         )
       )
       (setq vd1-2
          (cons "vehicle"
          (subst
            (reverse (cons trailer (reverse(assoc "segments" (cdr vd1-2)))))
            (assoc "segments" (cdr vd1-2))
            (cdr vd1-2)
          )
            )
       )
    )
  )
  vd1-2
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
           ".\nTurn can't continue."
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
;;If no basename string, returns empty strings.
(DEFUN
   TURN-GETLAYER (BASENAME)
  (COND
    (basename
     (LIST
       (TURN-GETVAR (STRCAT "Layers." BASENAME ".Name"))
       (TURN-GETVAR (STRCAT "Layers." BASENAME ".Color"))
       (TURN-GETVAR (STRCAT "Layers." BASENAME ".Linetype"))
     )
    )
    (T '("" "" ""))
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
