;;; Turn 2.0 development
;;;
;;; Style Guide https://google.github.io/styleguide/lispguide.xml
;|
 Definitions:
 Course: An alignment that is followed by a steerable guide axle
 Path: The set of states and positions that result from following a course
 Step: The state and position at the end of a calculated interval
 Tblock: Turn block. Describes the plotted geometry of a vehicle segment.
 Also a reusable block that is drawn at each plotting step.
 While you can use drawing blocks instead of tblocks, tblocks let you assign
 meaning (point flags) to internal points.  Also, in the future, collision
 detection may be implemented in a way that works with tblocks, but not
 drawing blocks. Tblocks are also portable in the vehicle library XML format.

I am planning to export to LandXML and to possibly get the LandXML standard
expanded to specify what we need. That idea drives some of the data format
decisions.
				
 Data model with sample values:
 *WIKI-TURN-OBJECTS*
 '(("paths"
     ("path" ("id" PathId) path)
     ("path" ("id" PathId) path)
     .
     .
     .
     ("path" ("id" PathId) path)
   )
   ("vehicles"
     ("vehicle" ("id" VehicleId) vehicle)
     ("vehicle" ("id" VehicleId) vehicle)
     .
     .
     .
     ("vehicle" ("id" VehicleId) vehicle)
   )
   ("segments"
     ("segment" ("id" SegmentId) segment)
     ("segment" ("id" SegmentId) segment)
     .
     .
     .
     ("segment" ("id" SegmentId) segment)
   )
   ("tblocks"
     ("tblock" tblock)
     .
     .
     .
     
     ("tblock" tblock)
  )


 PATH
 '(PathId
   ("maxspeed" . 1000)
   ("maxaccel" . 32.2)
   ("vehicle" vehicle)
   ("course" x1 y1 x2 y2 ... xi yi)
   ("steps" ("step" step)("step" step))
  )

 VEHICLE
 '("vehicle"
    ("segments"
      ("segment" . Segment)
      ("segment" . Segment)
      ("segment" . Segment)
      ("tblocks"
        ("tblock" tblock)
        .
        .
        .
        ("tblock" tblock)
      )
    )




 SEGMENT
 '("segment"
    segmentid
    ("points" ("point" . point) ("point" . point))
    ("tblocks"
      ("tblock" tblock)
      .
      .
      .
      ("tblock" tblock)
    )
  )


 SEGMENT COORDINATE SYSTEM
 Origin point: Steering axle centroid
 Positive x (zero degree) axis: Segment "forward" direction
 Positive angle direction: Counter-clockwise
 Point coordinates: Polar (radius, theta)
 Notes: Vehicle blocks, when drawn in AutoCAD, should point right and have their
 insertion point as above.

 2015: I think that we should not allow the drawing of shapes in a segment
 directly.  All shapes should be drawn as tblocks and inserted into tblocks or
 segments.  It's not good to have two shape-drawing animals.
 
 SEGMENTPOINT
 '("point"
    ("position" r theta)
    ("flags" . pointflags)
    ("pathlayer" . pathlayer)
    ("blocklayer" . blocklayer) ; Layer (optional) to draw or insert block on
    ("blockname" . blockname) ; Name of block to be used at this point
  )
;;;

 TBLOCK COORDINATE SYSTEM
 Origin point: Tblock insertion point
 Positive x (zero degree) axis: Segment "forward" direction
 Positive angle direction: Counter-clockwise
 Point coordinates: Polar (radius, theta)
 Notes: For now, tblocks can't be scaled or rotated.

 TBLOCK
 For reuse in segments.  Initially intended for wheels. Initially can't be scaled
 or rotated. Defined very much like a segment.  If you have the guide point,
 traling point, or hitch point in a tblock, you can only use the tblock once per
 segment.
 '("tblock" ("name" tblockname) ("points" ("point" . point) ("point" . point)))

 STEP
 '("step" ("vehicle" vehicle)) 

 POINTFLAGS
|;
;;Global (for now) "constants"
;; Here is a question: Would we rather store these in XML as names or as integers?
;; If names, I think we need to use stings or symbols or a translation table.
;; And if names, the XML can't be a straight analog of an integer flag,
;; I think we need to choose integer or name
(setq
  ;; Guide point. This is the steering axle or trailer tongue point. There can only be one in each vehicle segment.
  *wt-point-guide*
   1
  ;; Trailing point. This is the back axle centroid point vehicle segment. There can only be one in each vehicle segment.
  *wt-point-trail*
   2
  ;; Hitch point.  This is where the guide point of the trailing vehicle segment connects to this vehicle segment. There can only be one in each vehicle segment.
  *wt-point-hitch*
   4
  ;; Path. Indicates that a path line should be plotted at this point. Layer required in point definition.
  *wt-point-path*
   8
  ;; Drawing block. Indicates that a drawing block should be inserted at this point. Name required.  Layer (optional) goes in point definition.
  *wt-point-dblock*
   16
  ;; Turn block. Indicates that a pre-defined turn block should be plotted at this point. Name required.  Layer (optional) goes in point definition.
  *wt-point-tblock*
   32
  ;; Shape start. For use only in tblock definitions.  Layer (optional) goes in point definition.
  *wt-point-shape-start*
   64
  ;; End shape open. (For use only in tblock definitions.
  *wt-point-shape-open*
   128
  ;; End shape closed. For use only in tblock definitions.
  *wt-point-shape-closed*
   256
)

;;;Data stub functions, mostly for testing
(defun
   wiki-turn-stub-path ()
  (list
    "path"
    (cons "maxspeed" 1000)
    (cons "maxaccel" 9.8)
    (wiki-turn-stub-vehicle)
    (wiki-turn-stub-steps)
  )
)
(defun
   wiki-turn-stub-vehicle ()
  (list
    "vehicle"
    (list
      "segments"
      (wiki-turn-stub-segment (list 1))
      (wiki-turn-stub-segment (list 2))
    )
  )
)
(defun
   wiki-turn-stub-segment (args)
  (setq index (car args))
  (list
    "segment"
    (cons "id" index)
    (list
      "point"
      (list "position" 0 0)
      (cons "flags" *wt-point-guide*)
    )
    (list
      "point"
      (list "position" 20.0 pi)
      (cons "flags" (+ *wt-point-path* *wt-point-trail*))
      (cons
        "pathlayer"
        (strcat "C-TURN-SEG" (itoa index) "-BACK-CNTR")
      )
    )
    (list
      "point"
      (list "position" 30.0 pi)
      (cons "flags" (+ *wt-point-path* *wt-point-hitch*))
      (cons
        "pathlayer"
        (strcat "C-TURN-SEG" (itoa index) "-HTCH")
      )
    )
    (list
      "point"
      (list "position" 5.0 (* pi 0.5))
      (cons "flags" *wt-point-tblock*)
      (cons
        "blocklayer"
        (strcat "C-TURN-SEG" (itoa index) "-BODY")
      )
      (cons "blockname" "stubwheel")
    )
    (list
      "point"
      (list "position" -5.0 (* pi 0.5))
      (cons "flags" *wt-point-tblock*)
      (cons
        "blocklayer"
        (strcat "C-TURN-SEG" (itoa index) "-BODY")
      )
      (cons "blockname" "stubwheel")
    )
  )
)
(defun
   wiki-turn-stub-tblock ()
  '("tblock"
    ("tblockname" "stubwheel")
    ("tblockpoint"
     (list "position" 1 (* pi 0.25))
     (cons "flags" *wt-point-shape-start*)
    )
    ("tblockpoint" (list "position" 1 (* pi 0.75)))
    ("tblockpoint" (list "position" 1 (* pi 1.25)))
    ("tblockpoint"
     (list "position" 1 (* pi 1.75))
     (cons "flags" *wt-point-shape-closed*)
    )
   )
)
(defun
   wiki-turn-stub-steps ()
  '("steps"
    ("step"
     ("id" . 0)
     ("seconds" . 0.0)
     ("position"
      (0 ("guide" 100.0 0.0) ("trail" 80.0 0.0))
      (1 ("guide" 70.0 0.0) ("trail" 50.0 0.0))
     )
    )
    ("step"
     ("id" . 0)
     ("seconds" . 1.0)
     ("position"
      (0 ("guide" 200.0 0.0) ("trail" 180.0 0.0))
      (1 ("guide" 170.0 0.0) ("trail" 150.0 0.0))
     )
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

(defun
   wiki-turn-put-path (args / pathid path paths)
  ;;Get the arguments
  (setq
    pathid
     (car args)
    path
     (cadr args)
     ;;Create the new path
  )
  (cond ((not path) (setq path (wiki-turn-stub-path))))
  ;;Get the id for the new path
  ;;All the paths are stored in the global variable *WIKI-TURN-OBJECTS*
  (cond
    ((not pathid)
     (cond
       ;;If there are already path objects
       ((setq paths (cdr (assoc "paths" (wiki-turn-get-objects nil))))
        ;;Then find a free id integer
        ;;Start at 0
        (setq pathid 0)
        ;;and increment until there is no such path in paths
        (while (assoc pathid paths) (setq pathid (1+ pathid)))
       )
       ;;Else PathId=0
       (t (setq pathid 0))
     )
    )
  )
  ;;Add the new path to paths
  (setq paths (cons (cons pathid path) paths))
  ;;Save the modified paths to the global variable
  (wiki-turn-put-objects
    (list
      (subst
        (cons "paths" paths)
        (cons "paths" (wiki-turn-get-paths nil))
        (wiki-turn-get-objects nil)
      )
    )
  )
  ;;Return the path ID
  pathid
)

;;;Puts a vehicle definition in a path
;;;Returns the VehicleId
;;;2009-09-26 TGH Maybe the vehicle definition shouldn't go in the "path:,
;;;but rather in the "vehicles" section and be referenced from the path.
(defun
   wiki-turn-put-vehicle (args / path)
  (setq
    ;;Integer PathId argument
    pathid
     (car args)
    ;;Vehicle definition list to add to path
    vehicle
     (cadr args)
    path
     (wiki-turn-get-path (list pathid))
  )
  (setq
    path
     (subst (cons "vehicle" vehicle) (assoc "vehicle" path) path)
  )
  (wiki-turn-put-path (list pathid path))
)

;;;Puts a vehicle segment in a vehicle
(defun
   wiki-turn-put-segment (args / path)
  (setq
    ;;Integer PathId argument
    pathid
     (car args)
    vehicle
     (cadr args)
    segment
     (caddr args)
    path
     (wiki-turn-get-path (list pathid))
  )
  (setq
    path
     (subst (cons "vehicle" vehicle) (assoc "vehicle" path) path)
  )
  (wiki-turn-put-path (list pathid path))
)

;;;Puts a vehicle segment in a vehicle
(defun
   wiki-turn-put-tblock (args / path)
  (setq
    ;;Integer TblockhId argument
    pathid
     (car args)
    vehicle
     (cadr args)
    segment
     (caddr args)
    path
     (wiki-turn-get-path (list pathid))
  )
  (setq
    path
     (subst (cons "vehicle" vehicle) (assoc "vehicle" path) path)
  )
  (wiki-turn-put-path (list pathid path))
)

;;; Gets the turn objects list from its global variable
;;; Mostly just a development utility
;;; 2009-07-13 TGH  Functional.  Displays list if run after WIKI-TURN-PATHS-ADD-PATH
(defun
   wiki-turn-get-objects (args)
  (cond
    (*wiki-turn-objects*)
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
(defun
   wt-invoke-method (args / obj method)
  (setq
    obj    (car args)
    method (cadr args)
  )
  ;;I guess this is just a wrapper function for all the
  ;;individual method functions for each object and method.
  ;;So
  (cond                                 ;    (= obj ' 
  )
)
;;;Puts the objects list in its global variable
;;; 2009-07-13 TGH  Functional.  Called by WIKI-TURN-PATHS-ADD-PATH
(defun
   wiki-turn-put-objects (args / allobjects)
  (setq
    allobjects
     (car args)
    *wiki-turn-objects* allobjects
  )
)

;;;Gets all the paths
;;; 2009-07-13 TGH  Functional.
(defun
   wiki-turn-get-paths (args)
  (cdr (assoc "paths" *wiki-turn-objects*))
)

;;;Gets a single path list
;;; 2009-07-13 TGH  Functional.
(defun
   wiki-turn-get-path (args / pathid)
  (setq pathid (car args))
  (cdr (assoc pathid (wiki-turn-get-paths nil)))
)

;;;Advances the path to a new point
(defun wiki-turn-path-advance (pathid newpoint) nil)

;;;Retracts one point from the path
(defun wiki-turn-path-retract (pathid) nil)

 ;|
(defun WIKI-TURN-PATH (PathId ))

(defun WIKI-TURN-PATH (PathId ))

(defun WIKI-TURN-PATH (PathId ))
|;
;;; Converts rectangular coordinates to AutoLISP polar coordinates
;;; Returns a two-element list of '(ang dist)
                                        ;
(defun
   wiki-turn-recttopolar (args / x y)
  ;;Get arguments
  (setq
    x (car args)
    y (cadr args)
  )
  ;;Calculate radius and theta
  ;;(list (sqrt(+ (exp (* 2 (log x)))(exp (* 2 (log y)))))(cond ((= x 0)(/ pi (cond((minusp y) -2)(T  2))))(T(+(atan (/ y x))(cond ((minusp x) pi)(T 0))))))
  ;; Why not just the following line?
  (list (angle '(0 0) args) (distance '(0 0) args))
)

(defun
   c:drawvehicle (/)
  (wiki-turn-draw-vehicle (c:convertvehicle))
)

(defun
   c:convertvehicle (/)
  (wiki-turn-vehicle-1-1-to-1-2
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
      (list "TRAILHAVE" "Y")
      (list "TRAILNAME" "TestTrailer")
      (list "TRAILUNITS" "M")
      (list "TRAILERHITCHTOWHEEL" 10000.0)
      (list "TRAILERWHEELWIDTH" 2000.0)
      (list "TRAILERFRONTHANG" 1000.0)
      (list "TRAILERBODYLENGTH" 12000.0)
      (list "TRAILERWIDTH" 2440.0)
    )
  )
)

;;; WIKI-TURN-DRAW-VEHICLE
;;; This function is to test the vehicle translation function.
;;; It doesn't yet plot drawing blocks. It just plots polylines.
(defun
   wiki-turn-draw-vehicle (vehicle /)
  ;;Draw each segment
  (foreach
     segment (cdr (assoc "segments" (cdr vehicle)))
    ;;Process sequentially each element of the segment
    (wiki-turn-draw-shape (cdr segment) vehicle '(0 0) 0 nil)
  )
)

(defun
   wiki-turn-lookup-tblock (referrer vehicle / return tblock)
  (setq tblockname (cdr (assoc "usetblock" (cdr referrer))))
  (foreach
     tblocktemp (cdr (assoc "tblocks" (cdr vehicle)))
    (if (= tblockname (cdr (assoc "tblockname" (cdr tblocktemp))))
      (setq tblock (assoc "tblockpoints" (cdr tblocktemp)))
    )
  )
  tblock
)
;;; WIKI-TURN-DRAW-SHAPE
;;; This function is to test the vehicle translation function.
;;; It doesn't yet plot blocks. It just plots polylines.
(defun
   wiki-turn-draw-shape (tblock vehicle insertion rotation parentlayer /
                         layerkey lwpoly points segmentpoly
                        )
  (foreach
     tblockpoint (cdr tblock)
    ;;Set the layer for the point
    (setq
      layerkey
       (cond
         ;;If the point has a layer key, use it
         ((cdr (assoc "blocklayer" (cdr tblockpoint))))
         ;;Else use the parent layer.
         (parentlayer)
       )
    )
    ;;Add the point to the front of the points list in case there is
    ;;a polyline to be drawn
    (setq
      points
       (cons
         (cons
           10
           (polar
             insertion
             (cadr (assoc "pointposition" (cdr tblockpoint)))
             (caddr (assoc "pointposition" (cdr tblockpoint)))
           )
         )
         points
       )
    )
    (cond
      ;;If it's a tblock, draw it
      ((= *wt-point-tblock*
          (logand
            (cdr (assoc "pointflags" (cdr tblockpoint)))
            *wt-point-tblock*
          )
       )
       (wiki-turn-draw-tblock
         (wiki-turn-lookup-tblock tblockpoint vehicle)
         vehicle
         (cdr (assoc "pointposition" (cdr tblockpoint)))
         0
         layerkey
       )
      )
      ;;If it's the start of a tblock
      ((= *wt-point-shape-start*
          (logand
            (cdr (assoc "pointflags" (cdr shapepoint)))
            *wt-point-shape-start*
          )
       )
       (setq
         ;;Clear the rest of the points list
         points
          (list (car points))
         ;; Start a polyline at the point
         lwpoly
          (list
            (cons 43 0.0)
            (cons 100 "AcDbPolyline")
            (cons 100 "AcDbEntity")
            (cons 0 "LWPOLYLINE")
          )
       )
      )
      ;;If it's the end of an open shape,
      ((= *wt-point-shape-open*
          (logand
            (cdr (assoc "pointflags" (cdr shapepoint)))
            *wt-point-shape-open*
          )
       )
       ;;Put the polyline together and entmake it.
       (setq
         lwpoly
          (append
            points
            (list
              ;; Number of polyline points
              (cons 90 (length points))
              (cons 8 (car (turn-getlayer layerkey)))
            )
            lwpoly
          )
       )
       (entmake (reverse lwpoly))
      )
      ;;If it's the end of a closed shape,
      ((= *wt-point-shape-closed*
          (logand
            (cdr (assoc "pointflags" (cdr shapepoint)))
            *wt-point-shape-closed*
          )
       )
       ;;Put the polyline together and entmake it.
       (setq
         lwpoly
          (append
            points
            (list
              ;; Closed pline if 1 is set.
              (cons 70 1)
              ;; Number of polyline points
              (cons 90 (length points))
              (cons 8 (car (turn-getlayer layerkey)))
            )
            lwpoly
          )
       )
       (entmake (reverse lwpoly))
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
(defun
   wiki-turn-vehicle-1-1-to-1-2 (args / backaxlecentroid trailer
                                 wheelhalflength wheelhalfwidth
                                )
  ;;Set variables
  (setq
    vd1-1 args
    wheelhalflength
     (/ (cadr (assoc "VEHBODYLENGTH" vd1-1)) 10)
    wheelhalfwidth
     (/ (cadr (assoc "VEHWIDTH" vd1-1)) 10)
  )
  (setq
    vd1-2
     (list
       "vehicle"
       (list
         "tblocks"
         (list
           "tblock"
           (cons "tblockname" "wheel")
           ;;Wheel tblock front left corner
           (list
             "tblockpoints"
             (list
               "tblockpoint"
               (cons
                 "pointposition"
                 (wiki-turn-recttopolar
                   (list wheelhalflength wheelhalfwidth)
                 )
               )
               (cons "pointflags" *wt-point-shape-start*)
             )
             ;;Wheel tblock front right corner
             (list
               "tblockpoint"
               (cons
                 "pointposition"
                 (wiki-turn-recttopolar
                   (list wheelhalflength (* -1 wheelhalfwidth))
                 )
               )
               (cons "pointflags" 0)
             )
             ;;Wheel tblock back right corner
             (list
               "tblockpoint"
               (cons
                 "pointposition"
                 (wiki-turn-recttopolar
                   (list
                     (* -1 wheelhalflength)
                     (* -1 wheelhalfwidth)
                   )
                 )
               )
               (cons "pointflags" 0)
             )
             ;;Wheel tblock back left corner
             (list
               "tblockpoint"
               (cons
                 "pointposition"
                 (wiki-turn-recttopolar
                   (list (* -1 wheelhalflength) wheelhalfwidth)
                 )
               )
               (cons "pointflags" *wt-point-shape-closed*)
             )
           )
         )
       )
       (list
         "segments"
         (list
           "segment"
           ;;Steering axle centroid
           (list
             "segmentpoint"
             (list "pointposition" 0 0)
             (cons "pointflags" *wt-point-steering*)
           )
           ;;Back axle centroid "VEHWHEELBASE" back from steering axle
           (list
             "segmentpoint"
             (list
               "pointposition"
               pi
               (cadr (assoc "VEHWHEELBASE" vd1-1))
             )
             (cons "pointflags" *wt-point-trail*)
           )
           ;;Hitch "VEHWHEELBASE" plus "VEHREARHITCH" back from steering axle
           (list
             "segmentpoint"
             (list
               "pointposition"
               pi
               (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                  (cadr (assoc "VEHREARHITCH" vd1-1))
               )
             )
             (cons "pointflags" *wt-point-hitch*)
           )
           ;;Body front left corner
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (list
                   (cadr (assoc "VEHFRONTHANG" vd1-1))
                   (/ (cadr (assoc "VEHWIDTH" vd1-1)) 2)
                 )
               )
             )
             ;;Start shape here
             (cons "pointflags" *wt-point-shape-start*)
           )
           ;;Body front right corner
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (list
                   (cadr (assoc "VEHFRONTHANG" vd1-1))
                   (/ (cadr (assoc "VEHWIDTH" vd1-1)) -2)
                 )
               )
             )
             ;;Just continue shape
             (cons "pointflags" 0)
           )
           ;;Body back right corner
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (list
                   (- (cadr (assoc "VEHFRONTHANG" vd1-1))
                      (cadr (assoc "VEHBODYLENGTH" vd1-1))
                   )
                   (/ (cadr (assoc "VEHWIDTH" vd1-1)) -2)
                 )
               )
             )
             ;;Plot shape
             (cons "pointflags" 2)
           )
           ;;Body back left corner
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (list
                   (- (cadr (assoc "VEHFRONTHANG" vd1-1))
                      (cadr (assoc "VEHBODYLENGTH" vd1-1))
                   )
                   (/ (cadr (assoc "VEHWIDTH" vd1-1)) 2)
                 )
               )
             )
             ;;End shape closed 
             (cons "pointflags" *wt-point-shape-closed*)
             (cons "shapelayer" "TruckBody")
           )
           ;;Front left wheel
           (list
             "segmentpoint"
             (list
               "pointposition"
               (/ pi 2)
               (* (cadr (assoc "VEHWIDTH" vd1-1)) 0.45)
             )
             ;;Use pre-defined tblock 
             (cons "pointflags" *wt-point-tblock*)
             (cons "usetblock" "wheel")
             (cons "shapelayer" "TruckBody")
           )
           ;;Front right wheel
           (list
             "segmentpoint"
             (list
               "pointposition"
               (/ pi -2)
               (* (cadr (assoc "VEHWIDTH" vd1-1)) 0.45)
             )
             ;;Use pre-defined shape 
             (cons "pointflags" *wt-point-tblock*)
             (cons "usetblock" "wheel")
             (cons "shapelayer" "TruckBody")
           )
           ;;Back right wheel
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (* -1 (cadr (assoc "VEHWHEELBASE" vd1-1)))
                 (* (cadr (assoc "VEHWIDTH" vd1-1)) -0.45)
               )
             )
             ;;Use pre-defined shape 
             (cons "pointflags" *wt-point-tblock*)
             (cons "usetblock" "wheel")
             (cons "shapelayer" "TruckBody")
           )
           ;;Back left wheel
           (list
             "segmentpoint"
             (cons
               "pointposition"
               (wiki-turn-recttopolar
                 (* -1 (cadr (assoc "VEHWHEELBASE" vd1-1)))
                 (* (cadr (assoc "VEHWIDTH" vd1-1)) 0.45)
               )
             )
             ;;Use pre-defined shape 
             (cons "pointflags" *wt-point-tblock*)
             (cons "usetblock" "wheel")
             (cons "shapelayer" "TruckBody")
           )
         )
       )
     )
  )
  (cond
    ((= (cadr (assoc "TRAILHAVE" vd1-1)) "Y")
     (setq
       trailer
        (list
          "segment"
          ;;Steering axle centroid (Tongue point)
          (list
            "segmentpoint"
            (list
              "pointposition"
              pi
              (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                 (cadr (assoc "VEHREARHITCH" vd1-1))
              )
            )
            (cons "pointflags" *wt-point-steering*)
          )
          ;;Back axle centroid "TRAILERHITCHTOWHEEL" back from steering axle
          (list
            "segmentpoint"
            (list
              "pointposition"
              pi
              (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                 (cadr (assoc "VEHREARHITCH" vd1-1))
                 (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
              )
            )
            (cons "pointflags" *wt-point-trail*)
          )
          ;;Body front left corner
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (- (cadr (assoc "TRAILERFRONTHANG" vd1-1))
                     (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                        (cadr (assoc "VEHREARHITCH" vd1-1))
                        (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                     )
                  )
                  (/ (cadr (assoc "TRAILERWIDTH" vd1-1)) 2)
                )
              )
            )
            ;;Start shape here
            (cons "pointflags" *wt-point-shape-start*)
          )
          ;;Body front right corner
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (- (cadr (assoc "TRAILERFRONTHANG" vd1-1))
                     (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                        (cadr (assoc "VEHREARHITCH" vd1-1))
                        (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                     )
                  )
                  (/ (cadr (assoc "TRAILERWIDTH" vd1-1)) -2)
                )
              )
            )
            ;;Just continue shape
            (cons "pointflags" 0)
          )
          ;;Body back right corner
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (- (cadr (assoc "TRAILERFRONTHANG" vd1-1))
                     (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                        (cadr (assoc "VEHREARHITCH" vd1-1))
                        (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                        (cadr (assoc "TRAILERBODYLENGTH" vd1-1))
                     )
                  )
                  (/ (cadr (assoc "TRAILERWIDTH" vd1-1)) -2)
                )
              )
            )
            ;;Plot shape
            (cons "pointflags" 2)
          )
          ;;Body back left corner
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (- (cadr (assoc "TRAILERFRONTHANG" vd1-1))
                     (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                        (cadr (assoc "VEHREARHITCH" vd1-1))
                        (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                        (cadr (assoc "TRAILERBODYLENGTH" vd1-1))
                     )
                  )
                  (/ (cadr (assoc "TRAILERWIDTH" vd1-1)) 2)
                )
              )
            )
            ;;End shape closed 
            (cons "pointflags" *wt-point-shape-closed*)
            (cons "shapelayer" "TrailerBody")
          )
          ;;Trailer left wheel
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                     (cadr (assoc "VEHREARHITCH" vd1-1))
                     (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                  )
                  (* (cadr (assoc "TRAILERWIDTH" vd1-1)) 0.45)
                )
              )
            )
            ;;Use pre-defined tblock 
            (cons "pointflags" *wt-point-tblock*)
            (cons "usetblock" "wheel")
            (cons "shapelayer" "TrailerBody")
          )
          ;;Trailer right wheel
          (list
            "segmentpoint"
            (cons
              "pointposition"
              (wiki-turn-recttopolar
                (list
                  (+ (cadr (assoc "VEHWHEELBASE" vd1-1))
                     (cadr (assoc "VEHREARHITCH" vd1-1))
                     (cadr (assoc "TRAILERHITCHTOWHEEL" vd1-1))
                  )
                  (* (cadr (assoc "TRAILERWIDTH" vd1-1)) -0.45)
                )
              )
            )
            ;;Use pre-defined shape 
            (cons "pointflags" *wt-point-tblock*)
            (cons "usetblock" "wheel")
            (cons "shapelayer" "TrailerBody")
          )
        )
     )
     (setq
       vd1-2
        (cons
          "vehicle"
          (subst
            (reverse
              (cons
                trailer
                (reverse (assoc "segments" (cdr vd1-2)))
              )
            )
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
(defun
   turn-initializesettings ()
  (turn-setvar "General.Version" "1.1.10")
;;; Layer settings.
  (turn-setlayer "TruckBody" "C-TURN-TRCK-BODY" "1" "")
  (turn-setlayer "TrailerBody" "C-TURN-TRAL-BODY" "2" "")
  (turn-setlayer "HitchPath" "C-TURN-HTCH-PATH" "3" "")
  (turn-setlayer
    "TruckBackLeftTirePath"
    "C-TURN-TRCK-RLTR-PATH"
    "3"
    "dashed"
  )
  (turn-setlayer
    "TruckBackRightTirePath"
    "C-TURN-TRCK-RRTR-PATH"
    "3"
    "dashed"
  )
  (turn-setlayer
    "TruckFrontRightTirePath"
    "C-TURN-TRCK-FRTR-PATH"
    "3"
    "dashed"
  )
  (turn-setlayer
    "TrailerBackRightTirePath"
    "C-TURN-TRAL-RLTR-PATH"
    "4"
    "dashed"
  )
  (turn-setlayer
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
           ".\nTurn can't continue."
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
   turn-setlayer (basename laname lacolor laltype)
  (turn-setvar (strcat "Layers." basename ".Name") laname)
  (turn-setvar (strcat "Layers." basename ".Color") lacolor)
  (turn-setvar
    (strcat "Layers." basename ".Linetype")
    laltype
  )
)
;;Gets a layer list from a layer base name string.
;;If no basename string, returns empty strings.
(defun
   turn-getlayer (basename)
  (cond
    (basename
     (list
       (turn-getvar (strcat "Layers." basename ".Name"))
       (turn-getvar (strcat "Layers." basename ".Color"))
       (turn-getvar (strcat "Layers." basename ".Linetype"))
     )
    )
    (t '("" "" ""))
  )
)
;;; Layer settings added by Tom Haws 2008-04-10
(defun
   turn-makelayers (/ layer)
  ;;Layer change 2008-02-22 Stephen Hitchcox
  (foreach
     basename '("TruckBody" "TrailerBody" "HitchPath"
                "TruckBackLeftTirePath" "TruckBackRightTirePath"
                "TruckFrontRightTirePath" "TrailerBackRightTirePath"
                "TrailerBackLeftTirePath"
               )
    (setq layer (turn-getlayer basename))
    (command
      "._layer"
      "t"
      (car layer)
      "on"
      (car layer)
      "un"
      (car layer)
      "m"
      (car layer)
      "c"
      (cadr layer)
      ""
      "lt"
      (caddr layer)
      ""
      ""
    )
  )
)

(turn-initializesettings)
(turn-makelayers)

;;; VEHICLEDATAGET gets the vehicle attributes from a BUILDVEHICLE
;;; defined block.
;;; Returns a list of vehicle properties.
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
                       (subst
                         newpair
                         oldpair
                         vehicledatalist
                       )
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

;;;
;;; XML functions
;;;
;;; LISP and XML are natural analogs of each other, so we are not shy to define our own
;;; rudimentary XML IO functions here.  These are not generic XML parsers, so they can be simple.
;;; XML has "nodes" called "element", "attribute", and "text"
;;;
;;; We only need to make arbitrary conventions about *attributes*, cons vs. list, and data types to keep things simple.
;;; The reason XML attributes were introduced is to curb XML's verbosity.
;;; <element attribute1="value" />
;;; is less verbose than
;;; <element><attribute1>value</attribute1></element>
;;; But attributes can only represent string data.  Or is that true?  Would LandXML let us use single quotes for attribute
;;; values so that we can indicate strings with double quotes?
;;; Or instead, would LandXML make us use a schema requirement to indicate the data type of the various types of attributes?
;;; So our convention will be that (cons) = attribute
;;; In other words:
;;; '("vehicle" ("name" . "WB-50") ("segments" ("segment" ("id" . 0) ("points" ("point" ("position" 0.0 0.0) ("flags" . 1))))))
;;; =
;;; <vehicle name="WB-50"><segments><segment id="0"><points><point flags="1"><position>0.0 0.0</position></point></points></segment></segments>
;|
XML thoughts
					<F n="3 0 701" z="3 0 701">386 5 385</F>'("F" ("n" . "3 0 701") ("z" . "3 0 701")386 5 385)
					<F><n>"5 0 3"</n>387 6 5</F>'("F" ("n" "503") 387 6 5)
          <><n>"5 0 3"</n>387 6 5</>'(("n" "503") 387 6 5) Illegal XML.  Need name on all lists.
					<F><n>"5 0 3"</n>387 6 5</F>'("F" 387 6 5 ("n" "503")) Illegal list. Not strict analog.
|;
(defun wiki-turn-list-element-to-xml-element-test ()
  (wiki-turn-list-element-to-xml-element
    '("vehicle" ("name" . "WB-50") ("segments" ("segment" ("id" . 0) ("points" ("point" ("position" 0.0 0.0) ("flags" . 1))))))
  )
)

;; An XML element list can have 
;; tag             Mandatory.  Must be a string and must be first element
;; attribute(s)    Optional. Must be strings (or manual casting when reading from XML) and must be indicated by cons
;; sub-element(s)  Optional. Must be tagged lists.
;; text            Optional. Can be numbers or strings.
;;
;; We detect each and treat appropriately
(defun
   wiki-turn-list-element-to-xml-element (list-1 / output-string tags-1)
  ;; Tag of the element.  Mandatory. Must be a string and must be first element.
  (setq 
    tags-1 (wiki-turn-list-first-element-to-xml-tags list-1)
    output-string (car tags-1)
  )
  (foreach
     child-1 (cdr list-1)
    (setq
      output-string
       (strcat
         output-string
         (cond
           ((= (type (cdr child-1)) 'list)
            (cond
              ((= (type (cadr child-1)) 'list)
               (wiki-turn-list-element-to-xml-element child-1)
              )
              (t (wiki-turn-list-leaf-to-xml-leaf child-1))
            )
           )
           ;; Attribute. Optional. Must be string (or manual casting when reading from XML) and must be indicated by cons.
           (t (wiki-turn-cons-to-xml-attribute child-1))
         )
       )
    )
  )
  
)


(defun wiki-turn-list-leaf-to-xml-leaf (leaf-1  / element-1 OUTPUT-STRING TAGS-1)
  (setq
    tags-1 (wiki-turn-list-first-element-to-xml-tags leaf-1)
    output-string (car tags-1)
  )
  (foreach text-1 leaf-1
    (setq output-string (strcat
         output-string " " (wiki-turn-list-value-to-xml-text text-1)))
  )
  (setq output-string (strcat output-string (cadr tags-1)))
)

(defun wiki-turn-cons-to-xml-attribute (cons-1)
  (strcat (car cons-1) "=\"" (cdr cons-1) "\"")
)

(defun
   wiki-turn-list-first-element-to-xml-tags (list-1)
  (cond
    ((/= (type (car list-1)) 'str)
     (alert
       (print "Fatal error: wiki-turn-list-first-element-to-xml-tags\nwas given a list destined for XML that was poorly formed.\nThe first element must be a string XML tag name.\nList shown on command line.")
       
     )
     (print list-1)
     (exit)
    )
  )
  (list
    (strcat "<" (car list-1) ">")
    (strcat "</" (car list-1) ">")
  )
)
(defun
   wiki-turn-list-value-to-xml-text (value-1)
  (cond
    ((= (type value-1) 'str) (strcat "\"" value-1 "\""))
    ((= (type value-1) 'int) (strcat "\"" (itoa value-1) "\""))
    ((= (type value-1) 'real)
     (strcat "\"" (rtos value-1 2 12) "\"")
    )
    (t
     (alert
       "Fatal error: wiki-turn-list-value-to-xml-text\nwas given something other than a 'STR, 'INT, or 'REAL.\nIt does not know how ot handle it.\nValue shown on command line."
     )
     (print value-1)
     (exit)
    )
  )
)


;;;
;;; The following can go in a separate file called turn-lang.lsp
;;;

 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 1 1 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
