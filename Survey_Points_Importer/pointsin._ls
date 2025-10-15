;;; This is the AutoLISP source file for
;;; ============
;;; POINTSIN.LSP
;;; ============
;;; Every line that begins with a semi-colon (;) is a comment,
;;; not part of the program.
;;; Read the comments below to learn how to enable, disable,
;;; and change parts of the program.
;;;
;;; HOW TO ADD, CHANGE, OR REMOVE ATTRIBUTES FROM BLOCK OR FILE
;;; 1. Edit the POINT.DWG block to meet your needs.
;;; 2. Edit the list of TAGNAMES in the PI:CONFIG-INITIALIZE function to include all the block attributes you want to fill from your file.
;;; 3. Make sure there is a format in the PI:GETFORMAT function that includes all the block attributes you want to import from your file.
;;;   a. Edit the menu to describe your format correctly.
;;;   b. Edit the list of tag/field names for the appropriate option for your format.
;;;
;;; Copyright 2015 Thomas Gail Haws
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
;;; POINTSIN is a civil engineering and survey tool that reads point data
;;; (ID, North, East, Elevation, Description) from a file
;;; and inserts a 2D attributed Softdesk-style POINT block
;;; and a 3d point in AutoCAD for every point in the file.
;;;
;;; You can change the POINT block if you prefer.  The order and graphical arrangement
;;; of the attributes doesn't matter. The default POINT block attributes are one unit high.
;;; POINTSIN scales the POINT block to the dimension text height
;;; (dimscale * dimtext), so the default POINT block will look as big as the current
;;; dimension text height.
;;;
;;; You can delete or comment out the lines that insert a 3d point or the POINT block.
;;; You can also comment out the lines that create and set layers.
;;;
;;; Revisions (latest first)
(SETQ *PI:VERSION* "1.1.00")
;;; 20201010  TGH  6.0 hr.  Version 1.1.00 Added block and layer options.
;;; 20170921  TGH  0.2 hr.  Version 1.0.16 Improved readability for users.
;;; 20160928  TGH  0.1 hr.  Version 1.0.15 Fixed PENZD file formats
;;; 20160609  TGH  0.2 hr.  Version 1.0.14 Fixed internationalization bug in point insertion osnap "none" to "_none"
;;; 20150629  TGH  0.2 hr.  Version 1.0.13 Fixed bug that obeys running osnaps.
;;; 20150415  TGH  2.0 hr.  Version 1.0.12 Fixed bug to allow block attributes that aren't in file.  Added commented out rounding of elevation attribute per drawing LUPREC.
;;; 20140920  TGH  0.5 hr.  Version 1.0.11 Implemented NCS layer names in source code and dwg.
;;; 20131010  TGH  0.5 hr.  Version 1.0.10 Deactivated description layers and added alerts about options for vanilla simplicity.
;;; 20121024  TGH  0.5 hr.  Version 1.0.9 Added in-code option to put blocks at 3D location.
;;; 20120912  TGH  5.0 hr.  Version 1.0.8 Added user point insertion function.
;;; 20120507  TGH  0.5 hr.  Version 1.0.7 Added white-space delimited formats to list.  Changed scale of point.dwg.  Added more sample files.
;;; 20120322  TGH  0.5 hr.  Version 1.0.6 Revised logic of layer name building to work with v1.0.4 format list.
;;; 20120211  TGH  0.5 hr.  Version 1.0.5 Added comments to clarify how to put blocks at their correct elevation and include NORTH and EAST in atributes.
;;; 20120122  TGH  2   hr.  Version 1.0.4 Modified some code to improve maintainability.  No functional change.
;;; 20120117  TGH  0.5 hr.  Version 1.0.3 Modified some code to clarify logic.  No functional change.
;;; 20101018  CAB  2.0 hr.  Added North and East to block and code, deleted point from block.
;;; 20100308  TGH  4   hr.  Version 1.0.2 Added ability to put points on layers by description.
;;; 20070126  TGH  0.2 hr.  Version 1.0.1 Fixed problem with empty fields.
;;; 20061017  TGH  0.2 hr.  Removed reference to HAWS-ENDSTR function.
;;; 20060928  TGH  0.5 hr.  Fixed problem with comment handling.
;;; 20060915  TGH  2   hr.  Version 1.0PR released.
;;; 20060915  TGH  1   hr.  Added error trapper and comment delimeters.
(ALERT
  "Please see the command line for notes about changing the behavior of POINTSIN."
)
(DEFUN
   PI:CONFIG-INITIALIZE ()
  ;; This function defines the rules for using file field values for point block 
  ;; coordinates (in the XYZNAMES list)
  ;; and attributes (in the TAGNAMES list).
  ;; Caution: The file format definitions in (PI:GETFILEFORMAT) use these same names to describe
  ;; the order of fields in the input file formats.
  ;; So you have to change both this function and that one when you change the attributes in POINT.DWG
  ;; ========================================================================
  ;; The XYZNAMES list names the file fields used for x, y, and z insertion point coordinates
  ;; They can have any names, but if you want to put them into an attribute of the block,
  ;; their names must match the attribute tag, which is given next in the attributes list.
  ;; If you don't want an insertion coordinate (like elevation/z) to come from the file,
  ;; just use nil, and a 0.0 value will be used.
  ;;(PI:SETVAR "XYZNAMES" '(xname yname zname))
  ;; Examples: 
  ;; This line tells POINTSIN to put all point objects (not 2D blocks) at their correct elevation.

  (PI:SETVAR "XYZNAMES" '("EAST" "NORTH" "ELEV"))

  ;; This line tells POINTSIN to put all point objects (not 2D blocks) at 0 elevation
  ;;(PI:SETVAR "XYZNAMES" '("EAST" "NORTH" nil))
  ;; ========================================================================
  ;; DESCNAME names the point description (for use in constructing description-specific layer names)
  ;; If you don't have a description attribute and aren't using description-specific layer names, this is ignored.  Just leave it alone.

  (PI:SETVAR "DESCNAME" "DESC")

  ;; ========================================================================
  ;; The TAGNAMES list tells POINTSIN which block attribute tags
  ;; need to receive the data in the file fields.
  ;; The order of the attribute fields in the list doesn't matter.
  ;; If any of the attributes are to receive coordinate values (x, y, or z),
  ;; the coordinate names in the XYZNAMES list must also match the attribute tag.
  ;; If any of the attributes are not in the block, they are skipped.
  ;; Examples:
  ;; This list tells POINTSIN to fill in the "POINT", "DESC", and "ELEV" attributes of each block insertion.
  ;;(PI:SETVAR "TAGNAMES" '("POINT" "DESC" "ELEV"))(PROMPT "\nOption to fill in NORTH and EAST attributes is not active.  Search this text in the source code to change behavior.")
  ;; This list tells POINTSIN to fill in the "NORTH", "EAST", "POINT", "DESC", and "ELEV" attributes of each block insertion.

  (PI:SETVAR "TAGNAMES" '("NORTH" "EAST" "POINT" "DESC" "ELEV")) (PROMPT "\nOption to fill in NORTH and EAST attributes is active.  Search this text in the source code to deactivate.")

  ;; ========================================================================
  ;; The BLOCKNAME* setting tells POINTSIN how to decide what block to insert at each point.
  ;; (You can insert multiple blocks at each point by checking/changing the code here and in the PI:POINTSIN and PI:GETVAR functions.)
  ;; Caution: A missing block will stop the program.
  ;; Three possibilities are shown, and you can use any of them.
  ;; Option 1. Use a single block name
  ;;(PI:SETVAR-BLOCKNAME-WITH-D-PARSE "BLOCKNAME1" "point")
  ;; Option 2. Build block name from each description
  ;; The line below adds the prefix "point-" to each description and tries to insert a block with that name.
  ;;(PI:SETVAR-BLOCKNAME-WITH-D-PARSE "BLOCKNAME1" "point-/d") (PROMPT "\nSearch this text in the source code to change the block name behavior.")
  ;; Option 3. Use a lookup table based on description
  ;; Any description not found in the table is skipped.
  ;;(PI:SETVAR-BLOCKNAME-WITH-D-PARSE
  ;;  "BLOCKNAME1"
  ;;  '(
  ;;    ("TREE6" "TREE")
  ;;    ("TREE4" "TREE")
  ;;    ("MH" "SEWER-MAHHOLE")
  ;;   )
  ;;)
  (PROMPT "\nSearch this text in the source code to change the block name behavior.")

  (PI:SETVAR-BLOCKNAME-WITH-D-PARSE "BLOCKNAME1" "point")
  (PI:SETVAR-BLOCKNAME-WITH-D-PARSE
    "BLOCKNAME2"
    '(
      ("TREE6" "TREE")
      ("TREE4" "TREE")
      ("MH" "SEWER-MANHOLE")
     )
  )

  ;; ========================================================================
  ;; The LAYER.* setting tells POINTSIN a layer scheme to use at each point.
  ;; (You can use multiple layer name schemes at each point by checking/changing the code here and in the PI:POINTSIN and PI:GETVAR functions.)
  ;; Option 1. If you want the current layer to be used at every point, use an empty string for the layer name and color.
  ;;(PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.BLOCK1" '("" ""))(PROMPT "\nOption to put all point blocks on current layer is active.  Search this text in the source code to change behavior.")
  ;; Option 2. If you want all point blocks to be put on the same layer, use this example.
  ;;(PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.BLOCK1" '("V-NODE-IMPT" "cyan")))  (PROMPT "\nOption to put all point blocks on same layer is active.  Search this text in the source code to change behavior." )
  ;; Option 3. If you want each block to go on a layer whose name includes the point description,
  ;; use the code "/d" where you want the point description included (NCS/AIA/US example on next line).
  ;;(PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.BLOCK1" '("V-NODE-/d" "cyan")))(PROMPT "\nBlock layer names by description is activated.  All descriptions must be legal layer names.  Search this text in the source code to deactivate.")
  ;; Option 4. Use a lookup table based on description
  ;; Any description not found in the table is put on current layer.
  ;;(PI:SETVAR-LAYER-WITH-D-PARSE
  ;;  "LAYER.BLOCK1"
  ;;  '(
  ;;    ("TREE6" ("V-NODE-TREE" "c"))
  ;;    ("TREE4" ("V-NODE-TREE" "c"))
  ;;    ("MH" ("V-SSWR-MHOL" "c"))
  ;;   )
  ;;)
  (PROMPT "\nSearch this text in the source code to change the block name behavior.")
 
  (PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.BLOCK1" '("V-NODE-IMPT" "cyan"))
  ;(PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.BLOCK2" '("V-NODE-/d" "m"))
  (PI:SETVAR-LAYER-WITH-D-PARSE
    "LAYER.BLOCK2"
    '(
      ("TREE6" ("V-NODE-TREE" "c"))
      ("TREE4" ("V-NODE-TREE" "c"))
      ("MH"    ("V-SSWR-MHOL" "c"))
     )
  )
  (PI:SETVAR-LAYER-WITH-D-PARSE "LAYER.NODE" '("V-NODE-IMPT-3D__" "cyan"))

)
;;; END CONFIG ===============================================================

(SETQ *PI:SETTINGS* nil) ; Clear on load for development convenience


(DEFUN C:POINTSIN () (PI:POINTSIN))

(DEFUN
   PI:POINTSIN (/ 3DPLAYERHASDESCRIPTION FILEFORMAT FNAME
                NODELAYER-SPECIFICATION PBLAYERHASDESCRIPTION
                POINTBLOCKLAYER-SPECIFICATION POINTFORMAT POINTSLIST
               )
  (PI:ERRORTRAP)
  (PI:SETVAR "SAVE-CLAYER" (GETVAR "CLAYER"))
  (PI:CONFIG-INITIALIZE)
  (PI:SETVAR "FILEFORMAT" (PI:GETFILEFORMAT))
  (SETQ FNAME (GETFILED "Points data file" (PI:GETDNPATH) "" 0))
  (SETQ POINTSLIST (PI:GETPOINTSLIST FNAME))
  ;; Insert blocks.  Comment out as needed.
  (PI:INSERTBLOCKS POINTSLIST "BLOCKNAME1" "LAYER.BLOCK1"); point.dwg with attributes
  (PI:INSERTBLOCKS POINTSLIST "BLOCKNAME2" "LAYER.BLOCK2"); description-based symbol blocks from table
  ;; Insert points.  Comment out the following line if you don't want 3d points.
  (PI:INSERTPOINTS POINTSLIST "LAYER.NODE")
  (PROMPT
    "\nSearch this text in the source code to choose what is inserted at each point."
  )
  (PI:ERRORRESTORE)
  (SETVAR "CLAYER" (PI:GETVAR "SAVE-CLAYER"))
  (PRINC)
)

;; Command for a user to insert points into a drawing manually.
(DEFUN C:INSPT () (PI:USERINSERTPOINT))
(DEFUN
   PI:USERINSERTPOINT (/ INSPT POINTBLOCKLAYER-SPECIFICATION POINTFORMAT POINTI PTDESC PTDESC-DEFAULT PTELEV PTELEV-DEFAULT PTNUM
                       PTNUM-DEFAULT
                      )
  (PI:ERRORTRAP)
  (PI:SETVAR "SAVE-CLAYER" (GETVAR "CLAYER"))
  (PI:CONFIG-INITIALIZE)
  (SETQ INSPT (GETPOINT "\nInsertion Point : "))
  ;; Get point number
  (SETQ PTNUM-DEFAULT (1+ (PI:GETVAR "NUMBER")))
  (SETQ PTNUM (GETINT (STRCAT "\nNode number <" (ITOA PTNUM-DEFAULT) ">: ")))
  (IF (NOT PTNUM)
    (SETQ PTNUM PTNUM-DEFAULT)
  )
  (PI:SETVAR "NUMBER" PTNUM)
  ;; Get point description
  (SETQ PTDESC-DEFAULT (PI:GETVAR "DESCRIPTION"))
  (SETQ PTDESC (GETSTRING (STRCAT "\nDescription <" PTDESC-DEFAULT ">: ")))
  (IF (=  PTDESC "")
    (SETQ PTDESC PTDESC-DEFAULT)
  )
  (PI:SETVAR "DESCRIPTION" PTDESC)
  ;; Get point elevation and store as a string
  (SETQ PTELEV-DEFAULT (RTOS (CADDR INSPT) 2))
  (SETQ PTELEV (GETREAL (STRCAT "\nElevation <" PTELEV-DEFAULT ">: ")))
  (IF (NOT PTELEV)
    (SETQ PTELEV PTELEV-DEFAULT)
    (SETQ PTELEV (RTOS PTELEV 2))
  )
  (PI:SETVAR "ELEVATION" PTELEV)
  ;; Insert a point block
  ;; The format of POINTI is defined in GETPOINTSLIST
  (SETQ
    POINTI
     (LIST
       ;; '(x y z)
       (LIST (CAR INSPT) (CADR INSPT) 0.0)
       ;;North string
       (RTOS (CADR INSPT) 2 2)
       ;;East string
       (RTOS (CAR INSPT) 2 2)
       (ITOA PTNUM)
       PTDESC
       PTELEV
     )
  )
  (SETQ BLOCK-SPECIFICATION (PI:GETVAR "BLOCKNAME1"))
  (SETQ LAYER-SPECIFICATION (PI:GETVAR "LAYER.BLOCK1"))
  (COND
    ((SETQ BLOCK (PI:BLOCK-GET-AT-POINT BLOCK-SPECIFICATION POINTI))
     (PI:INSERTBLOCK POINTI BLOCK LAYER-SPECIFICATION)
    )
  )
  (SETQ BLOCK-SPECIFICATION (PI:GETVAR "BLOCKNAME2"))
  (SETQ LAYER-SPECIFICATION (PI:GETVAR "LAYER.BLOCK2"))
  (COND
    ((SETQ BLOCK (PI:BLOCK-GET-AT-POINT BLOCK-SPECIFICATION POINTI))
     (PI:INSERTBLOCK POINTI BLOCK LAYER-SPECIFICATION)
    )
  )
  (SETQ BLOCK-SPECIFICATION (PI:GETVAR "BLOCKNAME2"))
  (SETQ LAYER-SPECIFICATION (PI:GETVAR "LAYER.BLOCK2"))
  (COND
    ((SETQ BLOCK (PI:BLOCK-GET-AT-POINT BLOCK-SPECIFICATION POINTI))
     (PI:INSERTBLOCK POINTI BLOCK LAYER-SPECIFICATION)
    )
  )
  (SETQ LAYER-SPECIFICATION (PI:GETVAR "LAYER.NODE"))
  (PI:LAYER-MAKE (PI:LAYER-GET-AT-POINT LAYER-SPECIFICATION POINTI))
  (COMMAND "._point" (CAR POINTI))
  (PI:ERRORRESTORE)
  (SETVAR "CLAYER" (PI:GETVAR "SAVE-CLAYER"))
  (PRINC)
)


;; Get a global setting for the current session
;; A common standard for global variables is encasement in *asterisks*
(DEFUN
   PI:GETVAR (VAR-NAME / PI:DEFAULTS)
  (SETQ
    VAR-NAME (STRCASE VAR-NAME) ; Names are case insensitive
    PI:DEFAULTS
     '(("NUMBER" 0) ; Lower case to work with prompts.
       ("ELEVATION" "0.00") ; Lower case to work with prompts.
       ("DESCRIPTION" "") ; Lower case to work with prompts.
       ("XYZNAMES" "")
       ("DESCNAME" "")
       ("TAGNAMES" "")
       ("BLOCKNAME1" "")
       ("BLOCKNAME2" "")
       ("LAYER.BLOCK1" "")
       ("LAYER.BLOCK2" "")
       ("LAYER.NODE" "")
       ("SAVE-CLAYER" "")
       ("FILEFORMAT" "")
      )
  )
  ;;If the settings don't exist, create them.
  ;;This statement is our official definition of our settings and defaults
  (IF (NOT *PI:SETTINGS*)
    (SETQ *PI:SETTINGS* PI:DEFAULTS)
  )
  ;; Now that we know the settings exist, return the requested setting's current value or an error message.
  (COND
    ((CADR (ASSOC VAR-NAME *PI:SETTINGS*)))
    ((CADR (ASSOC VAR-NAME PI:DEFAULTS)))
    (T
     (ALERT
       (PRINC
         (STRCAT
           "\n\""
           VAR-NAME
           "\" isn't a known setting for the points application."
         )
       )
     )
     ""
    )
  )
)

;; Set a global setting for the current session
(DEFUN
   PI:SETVAR (VAR-NAME VAR-VAL)
  (SETQ VAR-NAME (STRCASE VAR-NAME)) ; Names are case insensitive
  ;; Populate the settings list so it's complete and we know we are not setting an unknown (maverick) setting.
  (PI:GETVAR VAR-NAME)
  ;; Put the requested value in the settings list
  (SETQ
    *PI:SETTINGS*
     (SUBST
       (CONS VAR-NAME (LIST VAR-VAL))
       (ASSOC VAR-NAME *PI:SETTINGS*)
       *PI:SETTINGS*
     )
  )
)

(DEFUN PI:SETVAR-BLOCKNAME-WITH-D-PARSE (VAR-NAME VAR-VAL)
  (COND
    ((AND (= (TYPE VAR-VAL) 'STR) (WCMATCH (STRCASE VAR-VAL) "*/D*"))
     (SETQ VAR-VAL (PI:PARSE-DESCRIPTION-EMBEDMENT VAR-VAL))
    )
  )
  (PI:SETVAR VAR-NAME VAR-VAL)
)

(DEFUN PI:SETVAR-LAYER-WITH-D-PARSE (VAR-NAME VAR-VAL / LAYER-NAME)
  (COND
    ((AND (= (TYPE (CAR VAR-VAL)) 'STR) (WCMATCH (STRCASE (CAR VAR-VAL)) "*/D*"))
     (SETQ VAR-VAL (LIST (PI:PARSE-DESCRIPTION-EMBEDMENT (CAR VAR-VAL)) (CADR VAR-VAL)))
    )
  )
  (PI:SETVAR VAR-NAME VAR-VAL)
)

(DEFUN
   PI:ERRORTRAP ()
  (SETQ
    *PI:OLDERROR* *ERROR*
    *ERROR* *PI:ERROR*
  )
)

(DEFUN
   *PI:ERROR* (MESSAGE)
  (COND
    ((/= MESSAGE "Function cancelled")
     (PRINC (STRCAT "\nTrapped error: " MESSAGE))
    )
  )
  (COMMAND)
  (IF (= (TYPE F1) (QUOTE FILE))
    (SETQ F1 (CLOSE F1))
  )
  (SETVAR "CLAYER" (PI:GETVAR "SAVE-CLAYER"))
  (IF *PI:OLDERR*
    (SETQ
      *ERROR* *PI:OLDERR*
      *PI:OLDERR* NIL
    )
  )
  (PRINC)
)

(DEFUN
   PI:ERRORRESTORE ()
  (SETQ
    F1 NIL
    *ERROR* *PI:OLDERR*
    *PI:OLDERR* NIL
  )
)


(DEFUN
   PI:GETFILEFORMAT (/ STDCOMMENT OPTION)
  (TEXTPAGE)
  ;; Menu
  ;; Show the various formats
  (PROMPT
    "\nSelect a file format:
	1. PNEZD (comma delimited)
	2. PNEZD (tab delimited)
	3. PNEZD (white-space delimited)
	4. PENZD (comma delimited)
	5. PENZD (tab delimited)
	6. PENZD (white-space delimited)
" )
  ;;Set the allowed inputs and get one from user.
  (INITGET "1 2 3 4 5 6")
  (SETQ OPTION (GETKWORD "\n\n1/2/3/4/5/6: "))
  ;; Define the various formats by calling out the fields in order,
  ;; then specifying the field delimiter and the comment delimiter(s)
  ;; The field delimiter is a one-character string.
  ;; The comment delimiter is an AutoCAD style wild card string
  (SETQ STDCOMMENT ":,`#,;,'")
  (COND
    ((= OPTION "1")
     (LIST
       (LIST "POINT" "NORTH" "EAST" "ELEV" "DESC")
       ","
       STDCOMMENT
     )
    )
    ((= OPTION "2")
     (LIST
       (LIST "POINT" "NORTH" "EAST" "ELEV" "DESC")
       "\t"
       STDCOMMENT
     )
    )
    ((= OPTION "3")
     (LIST
       (LIST "POINT" "NORTH" "EAST" "ELEV" "DESC")
       "W"
       STDCOMMENT
     )
    )
    ((= OPTION "4")
     (LIST
       (LIST "POINT" "EAST" "NORTH" "ELEV" "DESC")
       ","
       STDCOMMENT
     )
    )
    ((= OPTION "5")
     (LIST
       (LIST "POINT" "EAST" "NORTH" "ELEV" "DESC")
       "\t"
       STDCOMMENT
     )
    )
    ((= OPTION "6")
     (LIST
       (LIST "POINT" "EAST" "NORTH" "ELEV" "DESC")
       "W"
       STDCOMMENT
     )
    )
  )
)

;;; PI:PARSE-DESCRIPTION-EMBEDMENT
;;; Returns a LAYERLIST with the name (first element) parsed into
;;; part before /d and part after /d.
(DEFUN
   PI:PARSE-DESCRIPTION-EMBEDMENT
   (NAMESTRING / NAMELIST NAMESTRING GROWINGSTRING COUNTER)
  (SETQ
    GROWINGSTRING ""
    COUNTER 0
  )
  (WHILE (< COUNTER (STRLEN NAMESTRING))
    (SETQ COUNTER (1+ COUNTER))
    (IF (= (STRCASE (SUBSTR NAMESTRING COUNTER 2)) "/D")
      (SETQ
        NAMELIST
         (CONS GROWINGSTRING NAMELIST)
        GROWINGSTRING ""
        COUNTER
         (1+ COUNTER)
      )
      (SETQ
        GROWINGSTRING
         (STRCAT
           GROWINGSTRING
           (SUBSTR NAMESTRING COUNTER 1)
         )
      )
    )
  )
  (REVERSE (CONS GROWINGSTRING NAMELIST))
)

;;; PI:LAYER-GET-AT-POINT
(DEFUN
   PI:LAYER-GET-AT-POINT (LAYER-SPECIFICATION POINTI)
  (COND
    ;;  '("" "")
    ((= (TYPE (CAR LAYER-SPECIFICATION)) 'STR) LAYER-SPECIFICATION)
    ;;  '(("" "") "")
    ((= (TYPE (CADR LAYER-SPECIFICATION)) 'STR) (PI:LAYER-GET-FROM-DESCRIPTION LAYER-SPECIFICATION POINTI))
    ;;  '(("" ("" ""))("" ("" "")))
    (T (PI:LAYER-GET-FROM-TABLE LAYER-SPECIFICATION POINTI))
  )
)

;;; PI:LAYER-GET-FROM-DESCRIPTION
(DEFUN
   PI:LAYER-GET-FROM-DESCRIPTION (LAYER-SPECIFICATION POINTI)
   (LIST (STRCAT (CAAR LAYER-SPECIFICATION) (PI:POINT-GET-DESCRIPTION POINTI) (CADAR LAYER-SPECIFICATION)) (CADR LAYER-SPECIFICATION))
)
  
;;; PI:LAYER-GET-FROM-TABLE
(DEFUN
   PI:LAYER-GET-FROM-TABLE (LAYER-SPECIFICATION POINTI)
  (COND
    ((CADR (ASSOC (PI:POINT-GET-DESCRIPTION POINTI) LAYER-SPECIFICATION)))
    ('("" ""))
  )
)

;;; PI:LAYER-GET-NAME
(DEFUN PI:LAYER-GET-NAME (LAYER) (CAR LAYER))

;;; PI:LAYER-GET-COLOR
(DEFUN PI:LAYER-GET-COLOR (LAYER) (CADR LAYER))

;;; PI:LAYER-MAKE
;;; Sets current layer.  Makes layer if required.
;;; The format of layerlist is '(([NAME BEFORE DESC] [NAME AFTER DESC OR NIL IF NOT USING DESC]) COLOR)
;;; The format of POINTI is '((XEAST YNORTH) POINT DESC ELEV)
(DEFUN
   PI:LAYER-MAKE (LAYERI / DWGLAYER LAYERNAME NAMELIST LAYERCOLOR)
  (SETQ
    LAYERNAME
     (PI:LAYER-GET-NAME LAYERI)
    LAYERCOLOR
     (PI:LAYER-GET-COLOR LAYERI)
  )
  (COND
    ((AND
       ;; Layer exists in drawing
       (SETQ DWGLAYER (TBLSEARCH "LAYER" LAYERNAME))
       ;; Layer is already proper color
       (= (CDR (ASSOC 62 DWGLAYER)) LAYERCOLOR)
       ;; Layer isn't frozen
       (/= 1 (LOGAND (CDR (ASSOC 70 DWGLAYER)) 1))
     )
     ;; Set that layer current without using command interpreter
     (SETVAR "CLAYER" LAYERNAME)
    )
    (T
     ;; Else make layer using (command)
     (COMMAND "._layer" "_thaw" LAYERNAME "_make" LAYERNAME "_on" "" "_color" LAYERCOLOR "" "")
    )
  )
)

;; Format of list for each point is:
;; The first member is the point list (list x y z)
;; The other members are attribute value strings as defined by the GETPOINTFORMAT function
(DEFUN
   PI:GETPOINTSLIST (FNAME / ATTVALUES COORD FIELDNAME FILEFORMAT I INSPOINT POINTI POINTSLIST RDLIN
                    )
  (SETQ
    FILEFORMAT (PI:GETVAR "FILEFORMAT")
    F1 (OPEN FNAME "r")
  )
  (WHILE (SETQ RDLIN (READ-LINE F1))
    (SETQ
      I 0
      POINTI NIL
    )
    ;;Create a point list for the line if it's not a comment.
    (COND
      ((NOT (WCMATCH (SUBSTR RDLIN 1 1) (CADDR FILEFORMAT)))
       ;; Read and label the fields in the order specified by FILEFORMAT
       (FOREACH
          FIELD (CAR FILEFORMAT)
         (SETQ I (1+ I))
         (SETQ
           POINTI
            (CONS
              (CONS
                FIELD
                (PI:RDFLD I RDLIN (CADR FILEFORMAT) 1)
              )
              POINTI
            )
         )
       )
       ;; Strip the labels from the fields and put them into internal order
       ;; specified by POINTFORMAT.
       (SETQ
         ;; Get insertion coordinates
         INSPOINT
          (MAPCAR
            '(LAMBDA (FIELDNAME / COORD)
               (COND
                 ((AND
                    ;; If the coordinate is defined
                    (SETQ
                      COORD
                       (CDR (ASSOC FIELDNAME POINTI))
                    )
                    ;; and if the file gave a value
                    (SETQ COORD (DISTOF COORD))
                  )
                  ;; use it.
                  COORD
                 )
                 ;; Use 0.0 for any missing or undefined coordinates.
                 (0.0)
               )
             )
            (PI:GETVAR "XYZNAMES")
          )
         ;; Get attribute values.
         ATTVALUES
          (MAPCAR
            '(LAMBDA (FIELDNAME / COORD)
               (CDR (ASSOC FIELDNAME POINTI))
             )
            (PI:GETVAR "TAGNAMES")
          )
       )
       ;; Add point to list.
       (SETQ POINTSLIST (CONS (CONS INSPOINT ATTVALUES) POINTSLIST))
      )
    )
  )
  (SETQ F1 (CLOSE F1))
  POINTSLIST
)

(DEFUN
   PI:POINT-GET-DESCRIPTION (POINTI)
  (NTH
    ;; Calculate the position of the description in POINTI
    (LENGTH
      (MEMBER
        ;; Name of point description
        (PI:GETVAR "DESCNAME")
        (REVERSE (PI:GETVAR "TAGNAMES"))
      )
    )
    POINTI
  )
)

;;; PI:BLOCK-GET-AT-POINT
(DEFUN
   PI:BLOCK-GET-AT-POINT (BLOCK-SPECIFICATION POINTI)
  (COND
    ;;  ""
    ((= (TYPE BLOCK-SPECIFICATION) 'STR) BLOCK-SPECIFICATION)
    ;;  '("" "")
    ((= (TYPE (CADR BLOCK-SPECIFICATION)) 'STR) (PI:BLOCK-GET-FROM-DESCRIPTION BLOCK-SPECIFICATION POINTI))
    ;;  '(("" "")("" ""))
    (T (PI:BLOCK-GET-FROM-TABLE BLOCK-SPECIFICATION POINTI))
  )
)

;;; PI:BLOCK-GET-FROM-DESCRIPTION
(DEFUN
   PI:BLOCK-GET-FROM-DESCRIPTION (BLOCK-SPECIFICATION POINTI)
   (STRCAT (CAR BLOCK-SPECIFICATION) (PI:POINT-GET-DESCRIPTION POINTI) (CADR BLOCK-SPECIFICATION))
)

;;; PI:BLOCK-GET-FROM-TABLE
(DEFUN
   PI:BLOCK-GET-FROM-TABLE (BLOCK-SPECIFICATION POINTI)
    (CADR (ASSOC (PI:POINT-GET-DESCRIPTION POINTI) BLOCK-SPECIFICATION))
)

(DEFUN
   PI:INSERTBLOCKS (POINTSLIST BLOCKNAMEKEY LAYERKEY / AROLD BLOCK-SPECIFICATION LAYER-SPECIFICATION)
  (COMMAND "._undo" "_group")
  (SETQ
    AROLD
     (GETVAR "attreq")
    BLOCK-SPECIFICATION
     (PI:GETVAR BLOCKNAMEKEY)
    LAYER-SPECIFICATION
     (PI:GETVAR LAYERKEY)
  )
  (SETVAR "attreq" 0)
  ;;Insert a Softdesk style block
  (FOREACH
     ;; The format of POINTI is defined in GETPOINTSLIST
     POINTI POINTSLIST
    (COND
      ((SETQ BLOCK (PI:BLOCK-GET-AT-POINT BLOCK-SPECIFICATION POINTI))
       (PI:INSERTBLOCK POINTI BLOCK LAYER-SPECIFICATION)
      )
    )
  )
  (SETVAR "attreq" AROLD)
  (COMMAND "._undo" "_end")
)

(DEFUN
   PI:INSERTBLOCK (POINTI BLOCK LAYER-SPECIFICATION / AT
                        AV EL EN ET N NEWVALUE SHORTLIST
                       )
  (PI:LAYER-MAKE (PI:LAYER-GET-AT-POINT LAYER-SPECIFICATION POINTI))
  (COMMAND
    "._insert"
    BLOCK
    "_none"
    ;; Chop off the z coordinate for 2D block insertion.
    (REVERSE (CDR (REVERSE (CAR POINTI))))
    ;; Or keep the z coordinate for 3D block insertion.
    ;;(CAR POINTI)
    (* (GETVAR "dimscale") (GETVAR "dimtxt"))
    ""
    0
  )
  (SETQ EN (ENTLAST))
  ;;Fill in attributes
  (WHILE (AND
           (SETQ EN (ENTNEXT EN))
           (/= "SEQEND"
               (SETQ ET (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
           ) ;_ end of /=
         ) ;_ end of and
    (COND
      ((= ET "ATTRIB")
       (SETQ
         AT (CDR (ASSOC 2 EL))
         AV (CDR (ASSOC 1 EL))
       ) ;_ end of setq
       (COND
         ((SETQ SHORTLIST (MEMBER AT (REVERSE (PI:GETVAR "TAGNAMES"))))
          (SETQ
            N        (LENGTH SHORTLIST)
            NEWVALUE (NTH N POINTI)
          )
          ;; Round elevation attribute to current drawing LUPREC value
          ;;(IF
          ;;  (= AT "ELEV")
          ;;  (SETQ NEWVALUE (RTOS (ATOF NEWVALUE) 2))
          ;;)
          (ENTMOD
            (SUBST (CONS 1 NEWVALUE) (ASSOC 1 EL) EL) ;_ end of SUBST
          ) ;_ end of ENTMOD
         )
       ) ;_ end of cond
       (ENTUPD EN)
      )
    ) ;_ end of cond
  ) ;_ end of while
)

(DEFUN
   PI:INSERTPOINTS
   (POINTSLIST LAYERKEY / NODELAYER-SPECIFICATION POINTI)
  (SETQ LAYER-SPECIFICATION (PI:GETVAR LAYERKEY))
  (COMMAND "._undo" "_group")
  (FOREACH
     POINTI POINTSLIST
    (PI:LAYER-MAKE (PI:LAYER-GET-AT-POINT LAYER-SPECIFICATION POINTI))
    (COMMAND "._point" (CAR POINTI))
  )
  (COMMAND "._undo" "_end")
)

;;Read fields from a text string delimited by a field width or a delimiter
;;character.
;;Usage: (PI:RDFLD
;;         [field number]
;;         [string containing fields]
;;         [uniform field width, field delimiter character, or "W" for words separated by one or more spaces]
;;         [sum of options: 1 (non-numerical character field)
;;                          2 (unlimited length field at end of string)
;;         ]
;;       )
(DEFUN
   PI:RDFLD (FLDNO STRING FLDWID OPT / ISCHR ISLONG I J ATOMX CHAR
             CHARPREV LITERAL FIRSTQUOTE
            )
  (SETQ
    ISCHR
     (= 1 (LOGAND 1 OPT))
    ISLONG
     (= 2 (LOGAND 2 OPT))
  ) ;_ end of setq
  (COND
    ((= FLDWID "W")
     (SETQ
       I 0
       J 0
       ATOMX ""
       CHAR " "
     ) ;_ end of setq
     (WHILE (AND (/= I FLDNO) (< J (STRLEN STRING))) ;_ end of and
       ;;Save previous character unless it was literal
       (SETQ
         CHARPREV
          (IF LITERAL
            ""
            CHAR
          ) ;_ end of IF
         ;;Get new character
         CHAR
          (SUBSTR STRING (SETQ J (1+ J)) 1)
       ) ;_ end of setq
       ;;Find if new character is literal or a doublequote
       (COND
         ((= CHAR (SUBSTR STRING J 1) "\"")
          (IF (NOT LITERAL)
            (SETQ LITERAL T)
            (SETQ LITERAL NIL)
          ) ;_ end of if
          (IF (NOT FIRSTQUOTE)
            (SETQ FIRSTQUOTE T)
            (SETQ FIRSTQUOTE NIL)
          ) ;_ end of if
         )
         (T (SETQ FIRSTQUOTE NIL))
       ) ;_ end of cond
       (IF (AND
             (WCMATCH CHARPREV " ,\t")
             (NOT (WCMATCH CHAR " ,\t,\n"))
           )
         (SETQ I (1+ I))
       ) ;_ end of if
     ) ;_ end of while
     (WHILE (AND
              (OR ISLONG LITERAL (NOT (WCMATCH CHAR " ,\t,\n"))) ;_ end of or
              (<= J (STRLEN STRING))
            ) ;_ end of and
       (IF (NOT FIRSTQUOTE)
         (SETQ ATOMX (STRCAT ATOMX CHAR))
       ) ;_ end of if
       (SETQ CHAR (SUBSTR STRING (SETQ J (1+ J)) 1))
       (COND
         ((= CHAR "\"")
          (IF (NOT LITERAL)
            (SETQ LITERAL T)
            (SETQ LITERAL NIL)
          ) ;_ end of if
          (IF (NOT FIRSTQUOTE)
            (SETQ FIRSTQUOTE T)
            (SETQ FIRSTQUOTE NIL)
          ) ;_ end of if
         )
         (T (SETQ FIRSTQUOTE NIL))
       ) ;_ end of cond
     ) ;_ end of while
    )
    ((= (TYPE FLDWID) 'STR)
     (SETQ
       I 1
       J 0
       ATOMX ""
     ) ;_ end of setq
     (WHILE (AND
              (/= I FLDNO)
              (IF (> (SETQ J (1+ J)) 1000)
                (PROMPT
                  (STRCAT
                    "\nFields or delimiters missing in this line?"
                    STRING
                  )
                )
                T
              ) ;_ end of if
            ) ;_ end of and
       (IF (= (SETQ CHAR (SUBSTR STRING J 1)) "\"")
         (IF (NOT LITERAL)
           (SETQ LITERAL T)
           (SETQ LITERAL NIL)
         ) ;_ end of if
       ) ;_ end of if
       (IF (AND (NOT LITERAL) (= (SUBSTR STRING J 1) FLDWID))
         (SETQ I (1+ I))
       ) ;_ end of if
     ) ;_ end of while
     (WHILE
       (AND
         (OR (/= (SETQ CHAR (SUBSTR STRING (SETQ J (1+ J)) 1)) FLDWID)
             LITERAL
         ) ;_ end of or
         (<= J (STRLEN STRING))
       ) ;_ end of and
        (COND
          ((= CHAR "\"")
           (IF (NOT LITERAL)
             (SETQ LITERAL T)
             (SETQ LITERAL NIL)
           ) ;_ end of if
           (IF (NOT FIRSTQUOTE)
             (SETQ FIRSTQUOTE T)
             (SETQ FIRSTQUOTE NIL)
           ) ;_ end of if
          )
          (T (SETQ FIRSTQUOTE NIL))
        ) ;_ end of cond
        (IF (NOT FIRSTQUOTE)
          (SETQ ATOMX (STRCAT ATOMX CHAR))
        ) ;_ end of if
     ) ;_ end of while
     (IF (AND ISCHR (NOT ISLONG))
       (SETQ ATOMX (PI:RDFLD-UNPAD ATOMX))
     )
    )
    (T
     (SETQ
       ATOMX
        (SUBSTR
          STRING
          (1+ (* (1- FLDNO) FLDWID))
          (IF ISLONG
            1000
            FLDWID
          ) ;_ end of if
        ) ;_ end of substr
     ) ;_ end of setq
     (IF (AND ISCHR (NOT ISLONG))
       (SETQ ATOMX (PI:RDFLD-UNPAD ATOMX))
     )
    )
  ) ;_ end of cond
  (SETQ
    ATOMX
     (IF ISCHR
       ATOMX
       (DISTOF ATOMX)
     ) ;_ end of if
  ) ;_ end of setq
) ;_ end of defun

;;Strip white space from beginning and end of a string
(DEFUN
   PI:RDFLD-UNPAD (STR)
  (WHILE (WCMATCH (SUBSTR STR 1 1) " ,\t")
    (SETQ STR (SUBSTR STR 2))
  ) ;_ end of while
  (IF (/= STR "")
    (WHILE (WCMATCH (SUBSTR STR (STRLEN STR)) " ,\t")
      (SETQ STR (SUBSTR STR 1 (1- (STRLEN STR))))
    ) ;_ end of while
  )
  STR
)


(DEFUN
   PI:GETDNPATH (/ DNPATH)
  (SETQ DNPATH (GETVAR "dwgname")) ;_ end of setq
  (IF (WCMATCH (STRCASE DNPATH) "*`.DWG")
    (SETQ
      DNPATH
       (STRCAT (GETVAR "dwgprefix") DNPATH)
      DNPATH
       (SUBSTR DNPATH 1 (- (STRLEN DNPATH) 4))
    ) ;_ end of setq
  ) ;_ end of if
  DNPATH
) ;_ end of defun

(PRINC
  (STRCAT "\nLoaded POINTSIN.LSP version " *PI:VERSION* ".")
)
;|«Visual LISP© Format Options»
(132 2 40 2 nil "end of " 100 2 2 2 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
