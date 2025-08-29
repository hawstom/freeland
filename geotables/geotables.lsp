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
;;; http://autocad.wikia.com/wiki/Curve_table_creator_(AutoLISP_application)

;;; GEOTABLES.LSP
;;; Copyright 2008 Thomas Gail Haws
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
;;; CRVS-INITIALIZESETTINGS
(DEFUN
   CRVS-INITIALIZESETTINGS ()
;;; Revisions
  (CRVS-SETVAR "General.Version" "2.0.17")

;;; 20150605  Version 2.0.18 Made it possible to have different tables by layer in a single drawing
;;; 20150112  Version 2.0.17 Fixed extensive bugs in bearing and location duplicate combining
;;; 20150111  Version 2.0.16 Changed Help behavior and added help about scale.
;;; 20150106  Version 2.0.15 Removed references to WIKI-TIP
;;; 20110219  Version 2.0.14 Make angtos follow AutoCAD auprec
;;; 20110124  Version 2.0.13 Add "General.DistancePrecision" option
;;; 20100907  Version 2.0.12 Use 1/CANNOSCALEVALUE if DIMSCALE=0
;;; 20090201  Version 2.0.11 Improved point alerts further
;;; 20090129  Version 2.0.10 Improved point alerts and in process fixed bug in return value for CRVS-INSERTLABELBLOCK
;;; 20090122  Version 2.0.9 Fixed coding mistake in duplicate point alert.
;;; 20081215  Version 2.0.8 Clarified duplicate point alert.
;;; 20081202  Version 2.0.7 Added (getvar "ANGBASE") to label insertion angle in CRVS-INSERTLABELBLOCK.
;;; 20080811  Version 2.0.6 Bug fix.  Angtos extra argument removed
;;; 20080809  Version 2.0.5 Bug fix.  No bearing when IsBearingImportant = TRUE
;;; 20081103  Version 2.0.4 Bug fix.  Several local 2PI variables weren't defined.
;;; 20081029  Version 2.0.3 Bug fix: Added General.PointMatchTolerance and General.PointAlertTolerance settings because point labels were duplicating those from older version.
;;; 20080924  Version 2.0.2 Bug fix: added precision to ArcsLines coordinates to boost precision of line bearings.  Added azimuth bearing method.
;;; 20080801  Version 2.0.1 Fixed bug.  Northing and easting were switched in table.
;;; 20080729  Version 2.0.0 Major rework to do arcs, lines, and points.
;;; 20070921  Version 1.0.4 Fixed bug.  Northing and easting were switched in table.  
;;; 20070920  Version 1.0.3 Added location coordinate capabilities.  Made each column in block a separate layer, and their colors byblock.  
;;; 20070915  Version 1.0.2+Renamed command with CRVS prefix.  
;;; 20070718  Version 1.0.2 Replaced distppoint with distpoint so Quick table would work.
;;; 20061219  Version 1.0.1 Added distance suffix option.
;;; 20050815  Version 1.0 released.  Changed prompts and initial defaults.
;;; 20050308  Version 1.0PR released
;;; 20041110  Finished initial version for M2Group, Inc.
;;;
;;; Development Notes
;;; Format of GEOLIST and LABELBLOCKLIST returned by CRVS-MAKE_____.
;;; (Omit any groups that are nil.  tabletypes are "ARC", "LINE", "POINT")
;;; GEOLIST       '(handle (-1 . ename) (0 . tabletype)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
;;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
;;;                     (50 . str8angle1)(51 . str8angle2)(40 . str8radius)
;;; LABELBLOCKLIST'(targethandle (-1 . ename)(0 . tabletype)(1 . label)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
;;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
;;;                     (40 . str8radius)(50 . str8angle1)(51 . str8angle2)
;;;               )
;;;
;;;----------------------------------------------------------------------------
;;; Program settings users can edit--------------------------------------------
;;;----------------------------------------------------------------------------
;;;
;;; Label/Table types in the order of desired creation.
  (CRVS-SETVAR "General.TableTypes" "ARC,LINE,POINT")
;;; Layer name and color to use for label insertions.
;;; Out-of-the-box we are trying to follow the U.S. National CAD standard
  (CRVS-SETVAR "General.LabelLayerName" "R-ANNO-LABL-CRVS")
  (CRVS-SETVAR "General.LabelLayerColor" "y")
  (CRVS-SETVAR "General.LabelLayerLinetype" "")
;;; Layer names and colors to use for ARC, LINE, and POINT geo table insertions.
  (CRVS-SETVAR "Arc.TableLayerName" "R-ANNO-TABLE-CRVS-C")
  (CRVS-SETVAR "Arc.TableLayerColor" "c")
  (CRVS-SETVAR "Arc.TableLayerLinetype" "")
  (CRVS-SETVAR "Line.TableLayerName" "R-ANNO-TABLE-CRVS-L")
  (CRVS-SETVAR "Line.TableLayerColor" "c")
  (CRVS-SETVAR "Line.TableLayerLinetype" "")
  (CRVS-SETVAR "Point.TableLayerName" "R-ANNO-TABLE-CRVS-P")
  (CRVS-SETVAR "Point.TableLayerColor" "c")
  (CRVS-SETVAR "Point.TableLayerLinetype" "")
;;; Layers to allow in selection set of arcs and lines to label.  Put layer names between the quotes.
  (CRVS-SETVAR "General.ArcsLinesLayerWildcard" "*")
;;; Layers to allow in selection set of objects for points labelling.  Put layer names between the quotes.
  (CRVS-SETVAR "General.PointsLayerWildcard" "*")
;;; Label block name
  (CRVS-SETVAR "General.LabelBlockName" "GeotablesLabel")
;;;
;;; Table block name building blocks
;;; Each table block name = pre+base+post
;;;
;;; Block name prefix to use for table insertions.
  (CRVS-SETVAR "General.TableBlockPre" "Geotables")
;;; Block name base to use for curve insertions.
  (CRVS-SETVAR "General.ArcTableBlockBase" "C")
;;; Block name base to use for line insertions.
  (CRVS-SETVAR "General.LineTableBlockBase" "L")
;;; Block name base to use for point insertions.
  (CRVS-SETVAR "General.PointTableBlockBase" "P")
;;; Block name ending to use for table header insertions.
  (CRVS-SETVAR "General.TableHeaderBlockPost" "Header")
;;; Block name ending to use for table entry insertions.
  (CRVS-SETVAR "General.TableEntryBlockPost" "Table")
;;;
;;; An AutoCAD Wildcard list of objects whose points are to be labelled
;;; If ARC or LINE are in the list, their endpoints are labelled
;;; If CIRCLE is in the list, centers are labelled
;;; If POINT is in the list, nodes are labelled
;;; If any other object type is in the list, its start or insertion point is labelled.
  (CRVS-SETVAR "General.PointsObjectTypes" "ARC,LINE")
;;; An AutoCAD Wilcard list of legal ARCSLINES objects Geotables can process.
  (CRVS-SETVAR "General.ArcsLinesObjectTypes" "ARC,LINE")
;;;
;;; IsArcBearingImportant
;;; "TRUE" or "FALSE"
;;; True means arcs must have the same bearing to have the same label
;;; You are listing bearings in your table,
;;; so arcs that differ only by bearing are listed separately.
;;; FALSE means you aren't using bearings in your table,
;;; so arcs that differ only by bearing are given the same label.
;;; Note that Geotables does NOT remove duplicate labels once they
;;; have been added.  If you change this variable from TRUE to FALSE
;;; after adding labels, you need to erase labels yourself.
  (CRVS-SETVAR "General.IsArcBearingImportant" "FALSE")
;;;
;;; IsArcLineLocationImportant
;;; "TRUE" or "FALSE".
;;; TRUE means arcs or lines must have the same location to have the same label
;;; so arcs or lines that differ only by location are listed separately.
;;; FALSE means
;;; arcs or lines that differ only by location are given the same label.
;;; Obviously location is always important for point labels, regardless of this setting.
;;; Note that Geotables does NOT remove duplicate labels once they
;;; have been added.  If you change this variable from TRUE to FALSE
;;; after adding labels, you need to erase labels yourself.
  (CRVS-SETVAR "General.IsArcLineLocationImportant" "FALSE")
;;;
;;; BearingStyle
;;; "A" or "B".
;;; "A" means put azimuths in tables
;;; "B" means put bearings in tables
  (CRVS-SETVAR "General.BearingStyle" "B")
;;; Geotables gives a "close points" alert if two point labels are inserted
;;; within the PointProximityAlertDistance of each other.
;;; Must be greater than or equal to PointMergeDistance
;;; Example:
;;; If you want to be alerted if there are any points being inserted 
;;; within 0.1 meter of each other,
;;; you would set  to "0.1"
;;; Suggested values: 0.2 meter or 0.5 feet
  (CRVS-SETVAR "General.PointProximityAlertDistance" "0.5")
;;; Geotables merges any points that are
;;; within the PointMergeDistance of each other.
;;; Must be greater than or equal to PointGapAlertDistance
;;; Example:
;;; If you consider any endpoints within 0.002 meter of each other 
;;; to be at the same point,
;;; you would set PointMergeDistance to "0.002"
;;; Suggested values: 0.005 meter or 0.01 feet
  (CRVS-SETVAR "General.PointMergeDistance" "0.01")
;;; Geotables gives a "gap" alert if a merged point is more
;;; than the PointGapAlertDistance from one of the endpoints it labels.
;;; Example:
;;; If you want to be alerted if there is any gap at all in your geometry,
;;; you would set PointGapAlertDistance to "0"
;;; If you want to be alerted only if there are gaps greater than 0.001 units,
;;; you would set PointGapAlertDistance to "0.001"
;;; Suggested values: "0.000000005" or ("5e-9") meter or "0.00000001" (1e-8) feet
  (CRVS-SETVAR "General.PointGapAlertDistance" "0.00000001")
;;; Distance suffix (postfix).
  (CRVS-SETVAR "General.DistancePost" "'")
;;; Arc label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Arc.LabelPrefix" "C")
;;; Line label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Line.LabelPrefix" "L")
;;; Point label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Point.LabelPrefix" "P")
;;; This is the text height used for all calculated scales and distances.
;;; To hard code a text height, replace the dozen lines of code below with something like the following line:
;;; (CRVS-SETVAR "General.TextHeight" "100.0")
  (CRVS-SETVAR
    "General.TextHeight"
    (RTOS
      (* (COND
           ((> (GETVAR "dimscale") 0) (GETVAR "dimscale"))
           (T (/ 1 (GETVAR "CANNOSCALEVALUE")))
         )
         (GETVAR "dimtxt")
      )
      2
      8
    )
  )
;;; This only affects the placement of multiple columns.
  (CRVS-SETVAR "Arc.TableWidth" "118")
;;;
;;; This is the width of your geotablesltable.dwg block.
;;; This only affects the placement of multiple columns.
  (CRVS-SETVAR "Line.TableWidth" "64")
;;; This is the width of your geotablesptable.dwg block.
;;; This only affects the placement of multiple columns.
  (CRVS-SETVAR "Point.TableWidth" "26")
;;; Spacing of geo table blocks in text heights
  (CRVS-SETVAR "General.TableRowSpacing" "2")
;;; Display precision for coordinates in tables
  (CRVS-SETVAR "General.CoordinatePrecision" "2")
;;; Display precision for coordinates in tables
  (CRVS-SETVAR "General.DistancePrecision" "2")
;;; Displays extra help messages all the time
  (CRVS-SETVAR "General.HelpMode" "FALSE")
;;;
;;;----------------------------------------------------------------------------
;;; End of program settings users can edit-------------------------------------
;;;----------------------------------------------------------------------------
;;;
  (MAPCAR
    '(LAMBDA (TABLETYPE)
       ;;Create table header block name
       (CRVS-SETVAR
         (STRCAT TABLETYPE ".TableHeaderBlock")
         (STRCAT
           (CRVS-GETVAR "General.TableBlockPre")
           (CRVS-GETVAR (STRCAT "General." TABLETYPE "TableBlockBase"))
           (CRVS-GETVAR (STRCAT "General.TableHeaderBlockPost"))
         )
       )
       ;;Create table block name
       (CRVS-SETVAR
         (STRCAT TABLETYPE ".TableEntryBlock")
         (STRCAT
           (CRVS-GETVAR "General.TableBlockPre")
           (CRVS-GETVAR (STRCAT "General." TABLETYPE "TableBlockBase"))
           (CRVS-GETVAR (STRCAT "General.TableEntryBlockPost"))
         )
       )
     )
    (WIKI-STRTOLST
      (CRVS-GETVAR "General.TableTypes")
      "`,"
      "\""
      T
    )
  )
)
;;;
;;; Start program code-------------------------------------------------
;;;
;;;  Command functions ----------------------------------------------------------
(DEFUN C:GT () (C:CRVS-GT))
(DEFUN C:GTP () (C:CRVS-GTPOINTS))
(DEFUN C:GTA () (C:CRVS-GTARCSLINES))
(DEFUN C:GEOTABLES () (C:CRVS-GT))
(DEFUN C:CRVS-GTPOINTS () (CRVS-GEOTABLES "POINTS"))
(DEFUN C:CRVS-GTARCSLINES () (CRVS-GEOTABLES "ARCSLINES"))
(DEFUN C:GTT () (C:GTTABLES))
(DEFUN C:GTTABLES () (CRVS-MAKEGEOTABLES NIL))

;;;C:CRVS-GT
(DEFUN
   C:CRVS-GT (/ DATATYPE)
  (WHILE
    (= "?"
       (PROGN
         (INITGET "Arcslines Points ?")
         (SETQ DATATYPE (GETKWORD "\n[Arcs and lines/Points/?]: "))
       )
    )
     (CRVS-SETVAR "General.HelpMode" "TRUE")
     (CRVS-TIP
       6
       "GEOTABLES first needs to know whether to label the geometry of arcs and lines (not polylines) themselves or their end points."
     )
  )
  (COND (DATATYPE (CRVS-GEOTABLES (STRCASE DATATYPE))))
  (CRVS-SETVAR "General.HelpMode" "FALSE")
  (PRINC)
)
;;;CRVS-GEOTABLES
(DEFUN
   CRVS-GEOTABLES (DATATYPE / OPT SS)
  (SETQ *CRVS:VLST* (LIST (LIST "CLAYER" (GETVAR "CLAYER"))))
  (WHILE (= "?"
            (PROGN
              (INITGET "Quick Label Table Burst ?")
              (SETQ
                OPT
                 (GETKWORD
                   "\n[Quick label, table, and burst/Labels only/Tables from labels/Burst smart label blocks/?]: "
                 )
              )
            )
         )
    (CRVS-TIP
      0
      "Select from the following:\n\n-Quick label, table, and burst: make tables from selected objects in one step.\n\n-Labels only: add attributed block labels to selected objects, but no table yet.\n\n-Tables from labels: make a table from selected label blocks.  This might be useful to insert labels only into a drawing and make a table from there.\n\n-Burst smart label blocks: explode smart labels, turning label attributes into plain text.\n\nNote about scale:\nThe blocks provided with Geotables are UNITLESS, and Geotables inserts them by default at dimscale * dimtxt scale.  You must either set your default insertion units correctly or hard-code General.TextHeight in Geotables.lsp to a value that works for you."
    )
  )
  (COND
    ((= OPT "Quick")
     ;;Insert labels of the requested type
     (SETQ SS (CRVS-AUTOINSERTLABELS DATATYPE))
     ;;Make tables listing all the labels inserted
     (CRVS-MAKEGEOTABLES SS)
;;;     ;;Burst all the inserted labels
;;;     (CRVS-BURSTLABELS SS)
    )
    ((= OPT "Label") (CRVS-AUTOINSERTLABELS DATATYPE))
    ((= OPT "Table") (CRVS-MAKEGEOTABLES NIL))
    ((= OPT "Burst") (CRVS-BURSTLABELS NIL))
  )
  (FOREACH V *CRVS:VLST* (SETVAR (CAR V) (CADR V)))
  (CRVS-ERRRST)
  (PRINC)
)
;;;----------------------------------------------------------------------------
;;;  End command functions------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; CRVS-SETVAR
(DEFUN
   CRVS-SETVAR (VARNAME VALUE / NEWGROUP OLDGROUP)
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
    ((SETQ OLDGROUP (ASSOC VARNAME *CRVS:SETTINGS*))
     ;;Replace the old setting with the new setting.
     (SETQ *CRVS:SETTINGS* (SUBST NEWGROUP OLDGROUP *CRVS:SETTINGS*))
    )
    ;;Else,
    (T
     ;;Add the setting.
     (SETQ *CRVS:SETTINGS* (CONS NEWGROUP *CRVS:SETTINGS*))
    )
  )
)
;;;
;;; CRVS-GETVAR
(DEFUN
   CRVS-GETVAR (VARNAME / VARNAMEMIXED)
  (SETQ
    VARNAMEMIXED VARNAME
    VARNAME
     (STRCASE VARNAME)
  )
  (COND
    ;;If the setting is found, then return it
    ((CDR (ASSOC VARNAME *CRVS:SETTINGS*)))
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
     (ALERT (PRINC *CRVS:SETTINGS*))
     ;;2.  Exit
     (EXIT)
    )
  )
)

(DEFUN
   CRVS-TIP (ITIP TIPTEXT)
  (ALERT (PRINC (STRCAT "\n" TIPTEXT)))
)

;;;Curves error trapper
(DEFUN
   CRVS-ERRDEF ()
  (SETQ
    CRVS-ERROR *ERROR*
    *ERROR* CRVS-STPERR
  )
)

;;;Stperr replaces the standard error function.
;;;It sets everything back in case of an error.
(DEFUN
   CRVS-STPERR (S)
  (IF (OR (= MSG "Function cancelled")
          (= MSG "quit / exit abort")
      )
    (PRINC)
    (PRINC (STRCAT "\nError: " MSG))
  )
  (COMMAND)
  (IF CRVS:VLST
    (FOREACH V CRVS:VLST (SETVAR (CAR V) (CADR V)))
  )
  (IF (= (TYPE F1) (QUOTE FILE))
    (SETQ F1 (CLOSE F1))
  )
  ;; Close files
  (IF (= (TYPE F2) (QUOTE FILE))
    (SETQ F2 (CLOSE F2))
  )
  (IF (= (TYPE F3) (QUOTE FILE))
    (SETQ F3 (CLOSE F3))
  )
  (IF (= 8 (LOGAND (GETVAR "undoctl") 8))
    (COMMAND "._undo" "end")
  )
  ;; End undo group
  (IF CRVS-ERROR
    (SETQ
      *ERROR* CRVS-ERROR
      CRVS-ERROR NIL
    )
  )
  ;; Restore old *error* handler
  (PRINC)
)

;;;Restores old error function
(DEFUN
   CRVS-ERRRST ()
  (SETQ
    UCSP NIL
    UCSPP NIL
    ENM NIL
    F1 NIL
    F2 NIL
    *ERROR* OLDERR
    OLDERR NIL
  )
)
;;;END ERROR HANDLER

;;;CRVS-AUTOINSERTLABELS
;;;1.  Prompts user to select objects to label and labels to check for deletion.
;;;2.  Deletes any selected labels that are orphans.
;;;Returns the selection set of the labels for all the objects that were selected.
(DEFUN
   CRVS-AUTOINSERTLABELS (DATATYPE / ALLGEOLIST ALLLABELBLOCKLIST
                          ARCDELTA GEOENDANG GEOSTARTANG LABELBLOCK
                          NLABELBLOCKSDELETED LABELDELTA GEOENDANG
                          NLABELBLOCKSINSERTED GEOSTARTANG FREENUM I
                          LABELTEXT LABELTEXTCOUNTER LABELTEXTLIST
                          LABELTEXTPREFIX SSALL SSUSER
                          SSFINISHEDDLABELBLOCKS TXTHT USERGEOLIST
                          USERLABELBLOCKLIST OBJECT SELECTIONWC
                          TABLETYPE
                         )
;;;Inserts labels on selected objects
;;;Returns selection set of object label blocks for selected objects
  (COND
    ((= (CRVS-GETVAR "General.HelpMode") "TRUE")
     (CRVS-TIP
       2
       (STRCAT
         "You are about to select objects to label and labels to check for deletion.\n\n"
         "If you want to label all objects in all spaces (tabs), press enter instead of selecting objects.  "
         "Note that for curves and lines only ARC and LINE objects will work; please make an exploded copy of any polylines you wish to label.\n\n"
         "You can have GEOTABLES.LSP select only from layers you want to label. "
         "Just modify the settings near the top of GEOTABLES.LSP"
         " so that they have the names of the layers you want to label.\n\n"
         "For example:   (CRVS-SETVAR \"General.ArcLayerWildcard\" \"C-ROAD-CURB-BACK\")\n\n"
        )
     )
    )
  )
  (COMMAND "._undo" "group")
  ;;Build the selection set wildcard for allowable objects.
  ;;Includes geotables blocks, arcs, and lines on their respective legal layers
  (SETQ
    SELECTIONWC
     (LIST
       '(-4 . "<OR")
       '(-4 . "<AND")
       '(0 . "INSERT")
       (CONS 2 (CRVS-GETVAR "General.LabelBlockName"))
       (CONS 8 (CRVS-GETVAR "General.LabelLayerName"))
       '(-4 . "AND>")
       '(-4 . "<AND")
       (CONS 0 (CRVS-GETVAR "General.ArcsLinesObjectTypes"))
       (CONS
         8
         (CRVS-GETVAR "General.ArcsLinesLayerWildcard")
       )
       '(-4 . "AND>")
       '(-4 . "<AND")
       (CONS 0 (CRVS-GETVAR "General.PointsObjectTypes"))
       (CONS 8 (CRVS-GETVAR "General.PointsLayerWildcard"))
       '(-4 . "AND>")
       '(-4 . "OR>")
     )
    SSALL
     (SSGET "X" SELECTIONWC)
  )
  ;;Get the selection set from user, constrained by the wildcard
  (PROMPT
    "\nSelect objects to label and any labels to check for deletion/<return to select all objects and labels on all tabs>: "
  )
  (SETQ SSUSER (SSGET SELECTIONWC))
  ;;If user didn't select anything,
  (IF (NOT SSUSER)
    ;;then (as advertised in the preceding (prompt)) select all that meet the wildcard.
    (SETQ SSUSER SSALL)
  )
  (SETQ
    ;;Make a labelblocklist that includes all labels selected by user.
    USERLABELBLOCKLIST
     (CRVS-MAKELABELBLOCKLIST SSUSER)
    ;;Make a list of the geometries for all objects in the drawing.
    ALLGEOLIST
     (CRVS-SSTOGEOLIST SSALL DATATYPE)
    ;;Make a list of the geometries for all objects selected by user.
    USERGEOLIST
     (CRVS-SSTOGEOLIST SSUSER DATATYPE)
    ;;Check selected labels against all objects.  Delete orphan label blocks.
    ;;Save the number deleted.
    NLABELBLOCKSDELETED
     (CRVS-DELETEORPHANLABELBLOCKS
       USERLABELBLOCKLIST
       ALLGEOLIST
     )
    ;;Select all objects again now that orphan labels have been deleted.
    SSALL
     (SSGET "X" SELECTIONWC)
    ;;Make a labelblocklist that includes all labels in the drawing.
    ALLLABELBLOCKLIST
     (CRVS-MAKELABELBLOCKLIST SSALL)
    ;;Get association list of available labels for new label blocks
    LABELTEXTLIST
     (CRVS-AVAILABLENUMBERS
       ALLGEOLIST
       ALLLABELBLOCKLIST
       (WIKI-STRTOLST
         (CRVS-GETVAR "General.TableTypes")
         "`,"
         "\""
         T
       )
     )
  )
  ;;;CRVS-INSERTLABELS
  ;;Check selected objects against all labels to see if they need labels.
  ;;Insert labels if needed.
  ;;Also make a selection set of their finished label blocks.
  (SETQ
    ;;Start the selection set of inspected or inserted labelblocks.
    SSFINISHEDDLABELBLOCKS
     (SSADD)
    NLABELBLOCKSINSERTED 0
  )
  (FOREACH
     GEOMETRY USERGEOLIST
    (COND
      ;;If the geometry has a label, get it
      ((SETQ
         LABELBLOCK
          (CRVS-GEOMETRYLABEL
            GEOMETRY
            ALLLABELBLOCKLIST
            DATATYPE
          )
       )
      )
      (T
       ;;Else
       (COND
         ;;If we can find a similar label, use its number
         ((SETQ
            LABELTEXT
             (CRVS-SIMILARLABELNUMBER
               GEOMETRY
               ALLLABELBLOCKLIST
               DATATYPE
             )
          )
         )
         ;;Else get the next available number and remove that number from the list.
         (T
          (SETQ
            TABLETYPE
             (CDR (ASSOC 0 (CDR GEOMETRY)))
            LABELTEXT
             (CADR (ASSOC TABLETYPE LABELTEXTLIST))
            LABELTEXTLIST
             (SUBST
               (CONS
                 TABLETYPE
                 (CDDR (ASSOC TABLETYPE LABELTEXTLIST))
               )
               (ASSOC TABLETYPE LABELTEXTLIST)
               LABELTEXTLIST
             )
          )
         )
       )
       ;;Insert Label and add it to AllLabelBlockList.
       (SETQ
         ALLLABELBLOCKLIST
          (SUBST
            (REVERSE
              (CONS
                (SETQ
                  LABELBLOCK
                   (CRVS-INSERTLABELBLOCK
                     GEOMETRY
                     LABELTEXT
                   )
                )
                (REVERSE
                  (ASSOC TABLETYPE ALLLABELBLOCKLIST)
                )
              )
            )
            (ASSOC TABLETYPE ALLLABELBLOCKLIST)
            ALLLABELBLOCKLIST
          )
       )
       (SETQ NLABELBLOCKSINSERTED (1+ NLABELBLOCKSINSERTED))
      )
    )
    ;;Add the object's corresponding label block to the list of active label blocks
    (SETQ
      SSFINISHEDDLABELBLOCKS
       (SSADD
         (CDR (ASSOC -1 (CDR LABELBLOCK)))
         SSFINISHEDDLABELBLOCKS
       )
    )
  )
;;;End CRVS-INSERTLABELS
  (PROMPT
    (STRCAT
      "\n"
      (ITOA NLABELBLOCKSINSERTED)
      " object labels were inserted.\n"
      (ITOA NLABELBLOCKSDELETED)
      " object labels were deleted."
    )
  )
  (COMMAND "._undo" "end")
  SSFINISHEDDLABELBLOCKS
)
;;;CRVS-AVAILABLENUMBERS 
;;;Returns an ordered list of available label text for label blocks.
;|Test:
(setq datatype "ARCSLINES" ssall (ssget))
(CRVS-AVAILABLENUMBERS
  (CRVS-SSTOGEOLIST SSALL DATATYPE)
  (CRVS-MAKELABELBLOCKLIST SSALL)
  '("ARC" "LINE" "POINT")
)
|;
(DEFUN
   CRVS-AVAILABLENUMBERS (ALLGEOLIST ALLLABELBLOCKLIST TABLETYPES /
                          FREENUM I LABELTEXT LABELTEXTLIST N RETURNLIST
                         )
  (FOREACH
     TABLETYPE TABLETYPES
    (SETQ
      I             0
      N             (1+ (MAX (LENGTH ALLGEOLIST) (LENGTH ALLLABELBLOCKLIST)))
      LABELTEXTLIST NIL
    )
    (WHILE (<= (SETQ I (1+ I)) N)
      (SETQ
        FREENUM T
        LABELTEXT
         (STRCAT
           (CRVS-GETVAR (STRCAT TABLETYPE ".LabelPrefix"))
           (ITOA I)
         )
      )
      (IF ALLLABELBLOCKLIST
        (FOREACH
           LABELBLOCK (CDR (ASSOC TABLETYPE ALLLABELBLOCKLIST))
          (IF (= LABELTEXT (CDR (ASSOC 1 (CDR LABELBLOCK))))
            (SETQ FREENUM NIL)
          )
        )
      )
      (IF FREENUM
        (SETQ LABELTEXTLIST (CONS LABELTEXT LABELTEXTLIST))
      )
    )
    ;;The highest number ended up at the beginning, so reverse the list.
    (SETQ
      RETURNLIST
       (CONS
         (CONS TABLETYPE (REVERSE LABELTEXTLIST))
         RETURNLIST
       )
    )
  )
  RETURNLIST
)
;;;CRVS-DELETEORPHANLABELBLOCKS
;;;Checks selected labels against all objects.  Deletes orphan label blocks.
;;;Returns number of blocks deleted.
(DEFUN
   CRVS-DELETEORPHANLABELBLOCKS (USERLABELBLOCKLIST ALLGEOLIST /
                                 DATATYPE DELETETHISLABEL
                                 NLABELBLOCKSDELETED
                                )
  (SETQ NLABELBLOCKSDELETED 0)
  (IF USERLABELBLOCKLIST
    (FOREACH
       DATATYPE USERLABELBLOCKLIST
      (FOREACH
         LABELBLOCK (CDR DATATYPE)
        (SETQ DELETETHISLABEL T)
        ;;Point labels may apply to multiple touching object ends, 
        ;;so we have to check if any of them exist.
        (FOREACH
           TARGETHANDLE (WIKI-STRTOLST (CAR LABELBLOCK) "`," "\"" T)
          ;;If the target handle matches a found object anywhere, don't delete it.
          (COND
            ((ASSOC (CAR LABELBLOCK) ALLGEOLIST)
             (SETQ DELETETHISLABEL NIL)
            )
          )
        )
        ;;If no matching object for the label was found, delete it.
        (COND
          (DELETETHISLABEL
           (ENTDEL (CDR (ASSOC -1 (CDR LABELBLOCK))))
           (SETQ NLABELBLOCKSDELETED (1+ NLABELBLOCKSDELETED))
          )
        )
      )
    )
  )
  NLABELBLOCKSDELETED
)


;;; CRVS-GEOMETRYLABEL
;;; Looks for a label in LABELBLOCKLIST that fits the given geometry
;;; If datatype is POINTS, a match is at the same location.
;;; If datatype is ARCSLINES, a match points to the geometry's handle.
;;; If a matching label is found, returns it
(DEFUN
   CRVS-GEOMETRYLABEL (GEOMETRY LABELBLOCKLIST DATATYPE / GAPFLAG I
                       LABELBLOCK MATCHINGLABELBLOCK MERGEFLAG
                       PROXIMITYFLAG SEPARATION
                      )
  (COND
    ((= DATATYPE "ARCSLINES")
     (COND
       ((ASSOC (CAR GEOMETRY) (CDR (ASSOC "ARC" LABELBLOCKLIST))))
       ((ASSOC (CAR GEOMETRY) (CDR (ASSOC "LINE" LABELBLOCKLIST))))
     )
    )
    ((= DATATYPE "POINTS")
     (SETQ I -1)
     (WHILE (AND
              ;;There is a list of point labelblocks,
              (CDR (ASSOC "POINT" LABELBLOCKLIST))
              ;;And labelblock to merge with has not yet been found,
              (NOT MERGEFLAG)
              ;;And there is another labelblock to compare,
              (SETQ
                LABELBLOCK
                 (NTH
                   (SETQ I (1+ I))
                   (CDR (ASSOC "POINT" LABELBLOCKLIST))
                 )
              )
            )
       ;;Then get the distance between the geometry and the labelblock.
       (SETQ
         SEPARATION
          (DISTANCE
            (LIST
              (ATOF (CDR (ASSOC 10 (CDR LABELBLOCK))))
              (ATOF (CDR (ASSOC 20 (CDR LABELBLOCK))))
              (ATOF (CDR (ASSOC 30 (CDR LABELBLOCK))))
            )
            (LIST
              (ATOF (CDR (ASSOC 10 (CDR GEOMETRY))))
              (ATOF (CDR (ASSOC 20 (CDR GEOMETRY))))
              (ATOF (CDR (ASSOC 30 (CDR GEOMETRY))))
            )
          )
       )
       ;;Set proximity flags as required.
       (COND
         ;;If points are within merge distance,
         ((< SEPARATION
             (ATOF (CRVS-GETVAR "General.PointMergeDistance"))
          )
          ;;then set merge flag and save block
          (SETQ
            MERGEFLAG T
            MATCHINGLABELBLOCK LABELBLOCK
          )
          ;;and if points to be merged are outside of gap distance,
          (COND
            ((> SEPARATION
                (ATOF (CRVS-GETVAR "General.PointGapAlertDistance"))
             )
             ;;then set gap flag.
             (SETQ GAPFLAG T)
            )
          )
         )
         ;;else if points are within proximity alert distance,
         ((< SEPARATION
             (ATOF (CRVS-GETVAR "General.PointProximityAlertDistance"))
          )
          ;;then set proximity alert and save block.
          (SETQ
            PROXIMITYFLAG T
            MATCHINGLABELBLOCK LABELBLOCK
          )
         )
       )
     )
     ;;If point is being merged, don't give proximity alert.
     ;;(If point isn't being merged, there won't be a gap alert.
     ;;In either case, one of the alerts is excluded.
     ;;Therefore proximity and gap alerts are mutually exclusive.)
     (COND (MERGEFLAG (SETQ PROXIMITYFLAG NIL)))
     (COND
       (PROXIMITYFLAG
        (ALERT
          (STRCAT
            "Point Proximity Alert\n\nPoint "
            (CDR (ASSOC 1 (CDR MATCHINGLABELBLOCK)))
            " is "
            (RTOS SEPARATION)
            " away from another point.\n\nYou are receiving this alert based on these current settings:\n\nGeneral.PointProximityAlertDistance="
            (CRVS-GETVAR "General.PointProximityAlertDistance")
            "\nGeneral.PointMergeDistance="
            (CRVS-GETVAR "General.PointMergeDistance")
            ".\n\nTo resolve this alert, do one of the following:\n1. Decrease the PointProximityAlertDistance setting.\n2. Increase the PointMergeDistance setting.\n3. Manually erase the points that are triggering this alert."
          )
        )
       )
     )
     (COND
       (GAPFLAG
        (ALERT
          (STRCAT
            "Point Gap Alert\n\nPoint "
            (CDR (ASSOC 1 (CDR MATCHINGLABELBLOCK)))
            " is "
            ;;We are making the big assumption here that 
            ;;the units used are either feet or meters.
            ;;Based on that assumption, we are going to make
            ;;some presentation decisions about the gap distance
            (COND
              ;;If PointGapAlertDistance string length is 1 (Assume that means "0"?)
              ;;or greater than 7 (maximum the eyeball can process; 0.00001)
              ((OR (= (STRLEN
                        (CRVS-GETVAR "General.PointGapAlertDistance")
                      )
                      1
                   )
                   (> (STRLEN
                        (CRVS-GETVAR "General.PointGapAlertDistance")
                      )
                      7
                   )
               )
               ;;Then show the separation in scientific notation
               (RTOS SEPARATION 1 2)
              )
              ;;Else show the separation in fixed units 
              ;;with length to match PointGapAlertDistance string
              ;;plus an extra significant figure
              ((RTOS
                 SEPARATION
                 2
                 (- (STRLEN
                      (CRVS-GETVAR "General.PointGapAlertDistance")
                    )
                    1
                 )
               )
              )
            )
            " away from one of the endpoints it labels.\n\nYou are receiving this alert based on these current settings:\n\nGeneral.PointGapAlertDistance="
            (CRVS-GETVAR "General.PointGapAlertDistance")
            "\nGeneral.PointMergeDistance="
            (CRVS-GETVAR "General.PointMergeDistance")
            ".\n\nTo resolve this alert, do one of the following:\n1. Increase the PointGapAlertDistance setting.\n2. Decrease the PointMergeDistance setting.\n3. Manually close the gap that is triggering this alert."
          )
        )
       )
     )
     (COND (MERGEFLAG MATCHINGLABELBLOCK))
    )
  )
)


;;; CRVS-SIMILARLABELNUMBER 
;;; Looks for a label in ALLLABELBLOCKLIST that is similar in the required ways
;;; to the given geometry
;;; If a matching label is found, returns its text
(DEFUN
   CRVS-SIMILARLABELNUMBER (GEOMETRY ALLLABELBLOCKLIST DATATYPE / 2PI
                            ARCDELTA GEODATA GEOENDANG GEOENDPOINT
                            GEOSTARTANG GEOSTARTPOINT I ISLABELSIMILAR
                            LABELBLOCK LABELBLOCKI LABELTEXT TABLETYPE
                            TYPELABELBLOCKLIST
                           )
  (SETQ
    2PI
     (* 2 PI)
    TABLETYPE
     (CDR (ASSOC 0 (CDR GEOMETRY)))
    GEODATA
     (COND
       ((= TABLETYPE "ARC")
        (SETQ
          GEOENDANG
           (CRVS-GETREALFROMLIST 51 GEOMETRY)
          GEOSTARTANG
           (CRVS-GETREALFROMLIST 50 GEOMETRY)
        )
        (LIST
          (CONS
            "DELTA"
            (COND
              ((> GEOSTARTANG GEOENDANG)
               (- 2PI (- GEOSTARTANG GEOENDANG))
              )
              (T (- GEOENDANG GEOSTARTANG))
            )
          )
          (CONS "STARTANGLE" GEOSTARTANG)
          (CONS
            "STARTPOINT"
            (POLAR
              (LIST
                (CRVS-GETREALFROMLIST 10 GEOMETRY)
                (CRVS-GETREALFROMLIST 20 GEOMETRY)
                (CRVS-GETREALFROMLIST 30 GEOMETRY)
              )
              GEOSTARTANG
              (CRVS-GETREALFROMLIST 40 GEOMETRY)
            )
          )
        )
       )
       ((= TABLETYPE "LINE")
        (SETQ
          GEOSTARTPOINT
           (LIST
             (CRVS-GETREALFROMLIST 10 GEOMETRY)
             (CRVS-GETREALFROMLIST 20 GEOMETRY)
             (CRVS-GETREALFROMLIST 30 GEOMETRY)
           )
          GEOENDPOINT
           (LIST
             (CRVS-GETREALFROMLIST 11 GEOMETRY)
             (CRVS-GETREALFROMLIST 21 GEOMETRY)
             (CRVS-GETREALFROMLIST 31 GEOMETRY)
           )
        )
        (LIST
          (CONS "LENGTH" (DISTANCE GEOSTARTPOINT GEOENDPOINT))
          (CONS "BEARING" (ANGLE GEOSTARTPOINT GEOENDPOINT))
        )
       )
       ((= TABLETYPE "POINT")
        (LIST
          (CONS
            "STARTPOINT"
            (LIST
              (CRVS-GETREALFROMLIST 10 GEOMETRY)
              (CRVS-GETREALFROMLIST 20 GEOMETRY)
              (CRVS-GETREALFROMLIST 30 GEOMETRY)
            )
          )
          (CONS
            "ENDPOINT"
            (LIST
              (CRVS-GETREALFROMLIST 10 GEOMETRY)
              (CRVS-GETREALFROMLIST 20 GEOMETRY)
              (CRVS-GETREALFROMLIST 30 GEOMETRY)
            )
          )
        )
       )
     )
  )
  ;;Initialize labeltext for clarity.
  (SETQ LABELTEXT NIL)
  ;;Check through AllLabelBlockList (if it exists) for matches.
  (COND
    (ALLLABELBLOCKLIST
     (SETQ
       ;;Initialize the labelblock counter
       I
        -1
     )
     (WHILE
       ;;While
       (AND
         ;;There are labelblocks to examine
         (SETQ
           TYPELABELBLOCKLIST
            (CDR (ASSOC TABLETYPE ALLLABELBLOCKLIST))
         )
         (SETQ LABELBLOCKI (NTH (SETQ I (1+ I)) TYPELABELBLOCKLIST))
         ;;And
         ;;We haven't already got a label from a matching labelblock.
         (NOT LABELTEXT)
       );;If this labelblock matches this object in all the required ways,
        ;;use it instead of a new one.
        (COND
          ((= TABLETYPE (CDR (ASSOC 0 (CDR LABELBLOCKI))) "ARC")
           ;;Get comparison data from the LabelBlock
           (SETQ
             GEOENDANG
              (CRVS-GETREALFROMLIST 51 LABELBLOCKI)
             GEOSTARTANG
              (CRVS-GETREALFROMLIST 50 LABELBLOCKI)
             ARCDELTA
              (COND
                ((> GEOSTARTANG GEOENDANG)
                 (- 2PI (- GEOSTARTANG GEOENDANG))
                )
                (T (- GEOENDANG GEOSTARTANG))
              )
           )
           ;;If
           (IF
             (AND
               ;; Radius and delta match the object geometry
               ;; (The test most likely to fail is for same radius and delta.
               ;; We'll run it first.)
               (AND
                 ;;Radii are equal
                 (CRVS-COMPARE LABELBLOCKI GEOMETRY 40)
                 ;;and deltas are equal
                 (EQUAL
                   ARCDELTA
                   (CDR (ASSOC "DELTA" GEODATA))
                   0.00000002
                 )
               )
               ;; And
               (OR ;; we are ignoring bearings
                   (= (CRVS-GETVAR "General.IsArcBearingImportant")
                      "FALSE"
                   )
                   ;; or the angle matches the object
                   ;;(Deltas were already equal, so we can compare just start angles)
                   (CRVS-COMPARE LABELBLOCKI GEOMETRY 50)
               )
               ;; And
               (OR ;; we are ignoring location
                   (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                      "FALSE"
                   )
                   ;; or the label location and start angle match the object location (a strange situation!)
                   (AND
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 50)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 10)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 20)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 30)
                   )
               )
             );;Then
              ;;Use existing label
              (SETQ ISLABELSIMILAR T)
           )
          )
          ((= TABLETYPE (CDR (ASSOC 0 (CDR LABELBLOCKI))) "LINE")
           ;;Get comparison data from the LabelBlock
           (SETQ
             GEOSTARTPOINT
              (LIST
                (CRVS-GETREALFROMLIST 10 LABELBLOCKI)
                (CRVS-GETREALFROMLIST 20 LABELBLOCKI)
                (CRVS-GETREALFROMLIST 30 LABELBLOCKI)
              )
             GEOENDPOINT
              (LIST
                (CRVS-GETREALFROMLIST 11 LABELBLOCKI)
                (CRVS-GETREALFROMLIST 21 LABELBLOCKI)
                (CRVS-GETREALFROMLIST 31 LABELBLOCKI)
              )
           )
           ;;If
           (IF
             (AND
               ;; Length and Bearing match the object
               ;; (This test is most likely to fail is for same bearing and length.
               ;; We'll run it first.)
               (AND
                 ;;Lengths are equal
                 (EQUAL
                   (DISTANCE GEOSTARTPOINT GEOENDPOINT)
                   (CDR (ASSOC "LENGTH" GEODATA))
                   0.001
                 )
                 ;;and deltas are equal
                 (EQUAL
                   (ANGLE GEOSTARTPOINT GEOENDPOINT)
                   (CDR (ASSOC "BEARING" GEODATA))
                   0.00000002
                 )
               )
               ;; And
               (OR ;; we are ignoring location
                   (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                      "FALSE"
                   )
                   ;; or the label location matches the object location (a strange situation!)
                   (AND
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 10)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 20)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 30)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 11)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 21)
                     (CRVS-COMPARE LABELBLOCKI GEOMETRY 31)
                   )
               )
             );;Then
              ;;Use existing label
              (SETQ ISLABELSIMILAR T)
           )
          )
          ((= TABLETYPE (CDR (ASSOC 0 (CDR LABELBLOCKI))) "POINT")
           ;;If
           (IF (AND
                 (CRVS-COMPARE LABELBLOCK GEOMETRY 10)
                 (CRVS-COMPARE LABELBLOCK GEOMETRY 20)
                 (CRVS-COMPARE LABELBLOCK GEOMETRY 30)
               )
             ;;Then
             ;;Use existing label
             (SETQ ISLABELSIMILAR T)
           )
          )
        )
        (IF ISLABELSIMILAR
          (SETQ LABELTEXT (CDR (ASSOC 1 (CDR LABELBLOCKI))))
        )
     )
    )
  )
)




;;;CRVS-INSERTLABELBLOCK
;;Returns LABELBLOCKLIST for the inserted label
(DEFUN
   CRVS-INSERTLABELBLOCK (GEOMETRY LABELTEXT / 2PI ANG1 ATAG AVAL CENPT
                          EL EN ENBLK ENDANG INSPT LACOLOR LALTYPE
                          LANAME RAD ROT STARTANG TXTHT ENDPT LABEL
                          STARTPT TABLETYPE
                         )
  (SETQ
    TABLETYPE
     (CDR (ASSOC 0 (CDR GEOMETRY)))
    TXTHT
     (ATOF (CRVS-GETVAR "General.TextHeight"))
    LANAME
     (CRVS-GETVAR "General.LabelLayerName")
    LACOLOR
     (CRVS-GETVAR "General.LabelLayerColor")
    LALTYPE
     (CRVS-GETVAR "General.LabelLayerLinetype")
  )
  ;;Determine insertion point for label
  (COND
    ((= TABLETYPE "ARC")
     (SETQ
       2PI
        (* 2 PI)
       RAD
        (CRVS-GETREALFROMLIST 40 GEOMETRY)
       STARTANG
        (CRVS-GETREALFROMLIST 50 GEOMETRY)
       ENDANG
        (CRVS-GETREALFROMLIST 51 GEOMETRY)
       CENPT
        (LIST
          (CRVS-GETREALFROMLIST 10 GEOMETRY)
          (CRVS-GETREALFROMLIST 20 GEOMETRY)
          (CRVS-GETREALFROMLIST 30 GEOMETRY)
        )
       ANG1
        (IF (> STARTANG ENDANG)
          (REM (/ (+ STARTANG ENDANG 2PI) 2) 2PI)
          (/ (+ STARTANG ENDANG) 2)
        )
       INSPT
        (POLAR CENPT ANG1 (+ RAD TXTHT))
       ROT
        (IF (MINUSP (SIN (- ANG1 (/ PI 4))))
          (+ ANG1 (/ PI 2))
          (- ANG1 (/ PI 2))
        )
     )
    )
    ((= TABLETYPE "LINE")
     (SETQ
       STARTPT
        (LIST
          (CRVS-GETREALFROMLIST 10 GEOMETRY)
          (CRVS-GETREALFROMLIST 20 GEOMETRY)
          (CRVS-GETREALFROMLIST 30 GEOMETRY)
        )
       ENDPT
        (LIST
          (CRVS-GETREALFROMLIST 11 GEOMETRY)
          (CRVS-GETREALFROMLIST 21 GEOMETRY)
          (CRVS-GETREALFROMLIST 31 GEOMETRY)
        )
       ANG1
        (ANGLE STARTPT ENDPT)
       ROT
        (IF (MINUSP (SIN (- ANG1 (/ PI 4))))
          ANG1
          (+ ANG1 PI)
        )
       INSPT
        (POLAR
          (POLAR STARTPT ANG1 (/ (DISTANCE STARTPT ENDPT) 2.0))
          (+ ROT (/ PI 2))
          TXTHT
        )
     )
    )
    ((= TABLETYPE "POINT")
     (SETQ
       STARTPT
        (LIST
          (CRVS-GETREALFROMLIST 10 GEOMETRY)
          (CRVS-GETREALFROMLIST 20 GEOMETRY)
          (CRVS-GETREALFROMLIST 30 GEOMETRY)
        )
       ANG1
        (CRVS-GETREALFROMLIST 50 GEOMETRY)
       ROT
        (IF (MINUSP (SIN (- ANG1 (/ PI 4))))
          ANG1
          (+ ANG1 PI)
        )
       INSPT
        (POLAR STARTPT (+ ROT (/ PI 2)) TXTHT)
     )
    )
  )
  (COMMAND "._layer")
  (IF (NOT (TBLSEARCH "LAYER" LANAME))
    (COMMAND "m" LANAME)
  )
  (COMMAND "t" LANAME "on" LANAME "u" LANAME "s" LANAME)
  (IF (/= LACOLOR "")
    (COMMAND "c" LACOLOR "")
  )
  (IF (/= LALTYPE "")
    (COMMAND "lt" LALTYPE "")
  )
  (COMMAND "")
  (COMMAND
    "._insert"
    (CRVS-GETVAR "General.LabelBlockName")
    "non"
    INSPT
    TXTHT
    ""
    ;;AutoCAD adds ANGBASE to the zero direction of a block when inserting it.
    ;;A block inserted with 0 rotation will look the same regardless of ANGBASE.
    ;;But AutoLISP subtracts ANGBASE when it does an (ANGTOS) conversion.
    ;;So we add ANGBASE in before the conversion.
    ;;eg: If ANGBASE=pi and we want zero rotation, we need to (ANGTOS pi), so we add pi to rot.
    (ANGTOS (+ ROT (GETVAR "ANGBASE")))
  )
  ;;Change attribute values
  (CRVS-WRITEBLOCK
    (ENTLAST)
    (CONS
      (CONS "LABEL" LABELTEXT)
      (CRVS-GEOTABLESTOATTRIBUTES GEOMETRY)
    )
  )
  ;;Return the labelblock list (the geometry, but with the labelblock's entity name and handle and the label text).
  (CRVS-GEOGEOMETRYTOGEOTABLES
    TABLETYPE
    (CONS (CONS 1 LABELTEXT) (CDDDR GEOMETRY))
    (ENTGET (ENTLAST))
  )
)

;;; CRVS-MAKEGEOTABLES
(DEFUN
   CRVS-MAKEGEOTABLES (SSUSER / ATAG AVAL BEARING CENPT COL1X DELTA
                       DOVER2 DOWN EL EN ENDANG IROW ICOLUMN LABEL
                       MAKELABELBLOCKLIST NEWCOLUMN RAD ROW1Y SS1
                       STARTANG TABLEMAXROWS TABLEPT TABLETYPE
                       TABLETYPELIST TXTHT USERLABELLIST LACOLOR LALTYPE
                       LANAME
                      )
;;; Makes geometry tables for selected objects.
;;; Makes table for any data type encountered in label selection set.
;;; Gets data type from each object and makes a separate table for Arc, Line, and Point data.
  (COMMAND "._undo" "group")
  (COND
    ((NOT SSUSER)
     (COND
       ((= (CRVS-GETVAR "General.HelpMode") "TRUE")
        (CRVS-TIP
          3
          "Select now the object labels whose data you want to put into a table.\n\nAll other object labels will be ignored."
        )
       )
     )
     (PROMPT "\nSelect object labels to put in table: ")
     (SETQ
       SSUSER
        (SSGET
          (LIST
            '(0 . "INSERT")
            (CONS 2 (CRVS-GETVAR "General.LabelBlockName"))
            (CONS 8 (CRVS-GETVAR "General.LabelLayerName"))
          )
        )
     )
    )
  )
  (COND
    (SSUSER
     (SETQ
       ;;Get a list of the the tabletypes and the labels
       USERLABELLIST
        (CRVS-MAKELABELBLOCKLIST SSUSER)
       USERLABELLIST
        (CRVS-SORTLABELLIST USERLABELLIST)
       DOWN
        (/ PI -2)
     )
     (FOREACH
        TABLETYPELIST USERLABELLIST
       (COND
         ((CDR TABLETYPELIST)
          (SETQ
            TABLETYPE
             (CAR TABLETYPELIST)
            TABLEPT
             (COND
               ((SETQ
                  SS1
                   (SSGET
                     "X"
                     (LIST
                       (CONS 8 (CRVS-GETVAR (STRCAT (CAR TABLETYPELIST) ".TableLayerName")))
                     )
                   )
                )
                (CDR
                  (ASSOC
                    10
                    (ENTGET (SSNAME SS1 (1- (SSLENGTH SS1))))
                  )
                )
               )
               (T
                (GETPOINT
                  (STRCAT
                    "\nStart point for "
                    TABLETYPE
                    " table: "
                  )
                )
               )
             )
            COL1X
             (CAR TABLEPT)
            ROW1Y
             (CADR TABLEPT)
            IROW 0
            ICOLUMN 0
            TABLEMAXROWS
             (COND
               ((GETINT
                  (STRCAT
                    "\nMaximum number of rows for "
                    TABLETYPE
                    " table height <1000>:"
                  )
                )
               )
               (1000)
             )
            TXTHT
             (ATOF (CRVS-GETVAR "General.TextHeight"))
            NEWCOLUMN T
            LANAME
             (CRVS-GETVAR (STRCAT TABLETYPE ".TableLayerName"))
            LACOLOR
             (CRVS-GETVAR (STRCAT TABLETYPE ".TableLayerColor"))
            LALTYPE
             (CRVS-GETVAR
               (STRCAT TABLETYPE ".TableLayerLinetype")
             )
          )
          (COMMAND "._layer")
          (IF (NOT (TBLSEARCH "LAYER" LANAME))
            (COMMAND "m" LANAME)
          )
          (COMMAND "t" LANAME "on" LANAME "u" LANAME "s" LANAME)
          (IF (/= LACOLOR "")
            (COMMAND "c" LACOLOR "")
          )
          (IF (/= LALTYPE "")
            (COMMAND "lt" LALTYPE "")
          )
          (COMMAND "")
          (IF SS1
            (COMMAND "._ERASE" SS1 "")
          )
          (FOREACH
             LABEL (CDR TABLETYPELIST)
            ;;Bump to next column if the column is filled
            (IF (> (1+ IROW) TABLEMAXROWS)
              (SETQ
                IROW 0
                ICOLUMN
                 (1+ ICOLUMN)
                TABLEPT
                 (LIST
                   (+ COL1X
                      (* ICOLUMN
                         TXTHT
                         (ATOF
                           (CRVS-GETVAR
                             (STRCAT TABLETYPE ".TableWidth")
                           )
                         )
                      )
                   )
                   ROW1Y
                   0.0
                 )
              )
            )
            ;;Put a header before the row if it's a new column
            (COND
              ((= IROW 0)
               (COMMAND
                 "._insert"
                 (STRCAT
                   (CRVS-GETVAR "General.TableBlockPre")
                   (CRVS-GETVAR
                     (STRCAT "General." TABLETYPE "TableBlockBase")
                   )
                   (CRVS-GETVAR "General.TableHeaderBlockPost")
                 )
                 TABLEPT
                 TXTHT
                 ""
                 0
               )
               (SETQ
                 TABLEPT
                  (POLAR
                    TABLEPT
                    DOWN
                    (* TXTHT
                       (ATOF
                         (CRVS-GETVAR "General.TableRowSpacing")
                       )
                    )
                  )
                 IROW
                  (1+ IROW)
               )
              )
            )
            ;;Insert the row for the label
            (COMMAND
              "._insert"
              (STRCAT
                (CRVS-GETVAR "General.TableBlockPre")
                (CRVS-GETVAR
                  (STRCAT "General." TABLETYPE "TableBlockBase")
                )
                (CRVS-GETVAR "General.TableEntryBlockPost")
              )
              "non"
              TABLEPT
              TXTHT
              ""
              0
            )
            ;;Change attribute values
            (CRVS-WRITEBLOCK (ENTLAST) (CRVS-LABELTOTABLEENTRY LABEL))
            (SETQ
              TABLEPT
               (POLAR
                 TABLEPT
                 DOWN
                 (* TXTHT
                    (ATOF (CRVS-GETVAR "General.TableRowSpacing"))
                 )
               )
              IROW
               (1+ IROW)
            )
          )
          (COMMAND "._undo" "end")
         )
       )
     )
    )
    (COND
     ((= (CRVS-GETVAR "General.HelpMode") "TRUE")
       (CRVS-TIP
         4
         "GEOTABLES ships with unique layers for every table column.  You may thaw all layers to see all columns, freeze layers for columns you don't need, or modify the table blocks.\n\nYou may choose to list unique bearings or locations separately by changing the respective settings in GEOTABLES.LSP"
       )
     )
    )
    (T
     (ALERT
       (PRINC "No object labels selected.  Cannot create a table.")
     )
    )
  )
)




;;;CRVS-LABELTOTABLEENTRY
(DEFUN
   CRVS-LABELTOTABLEENTRY (LABEL / 2PI BEARING CENPT DELTA DOVER2 ENDANG
                           ENDPT GEONO TABLETYPE RAD STARTANG STARTPT
                          )
;;; LABELBLOCKLIST'(targethandle (-1 . ename)(0 . tabletype)(1 . label)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
;;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
;;;                     (40 . str8radius)(50 . str8angle1)(51 . str8angle2)
;;;               )
  (SETQ
    2PI
     (* 2 PI)
    LABEL
     (CDR LABEL)
    TABLETYPE
     (CDR (ASSOC 0 LABEL))
    GEONO
     (CDR (ASSOC 1 LABEL))
  )
  (COND
    ((= TABLETYPE "ARC")
     (SETQ
       RAD
        (ATOF (CDR (ASSOC 40 LABEL)))
       STARTANG
        (ATOF (CDR (ASSOC 50 LABEL)))
       ENDANG
        (ATOF (CDR (ASSOC 51 LABEL)))
       CENPT
        (LIST
          (ATOF (CDR (ASSOC 10 LABEL)))
          (ATOF (CDR (ASSOC 20 LABEL)))
          (ATOF (CDR (ASSOC 30 LABEL)))
        )
       BEARING
        (+ (/ PI 2)
           (IF (> STARTANG ENDANG)
             (REM (/ (+ STARTANG ENDANG 2PI) 2) 2PI)
             (/ (+ STARTANG ENDANG) 2)
           )
        )
       DELTA
        (COND
          ((> STARTANG ENDANG) (- 2PI (- STARTANG ENDANG)))
          (T (- ENDANG STARTANG))
        )
       DOVER2
        (/ DELTA 2)
     )
     (LIST
       (CONS "LABEL" GEONO)
       (CONS
         "RADIUS"
         (STRCAT
           (RTOS
             RAD
             2
             (ATOI (CRVS-GETVAR "General.DistancePrecision"))
           )
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "LENGTH"
         (STRCAT
           (RTOS
             (* RAD DELTA)
             2
             (ATOI (CRVS-GETVAR "General.DistancePrecision"))
           )
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "DELTA"
         (VL-STRING-SUBST
           "%%d"
           "d"
           (ANGTOS DELTA 1 (GETVAR "auprec"))
         )
       )
       (CONS
         "CHORD"
         (STRCAT
           (RTOS
             (* 2 RAD (SIN DOVER2))
             2
             (ATOI (CRVS-GETVAR "General.DistancePrecision"))
           )
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "TANGENT"
         (STRCAT
           (RTOS
             (* RAD (/ (SIN DOVER2) (COS DOVER2)))
             2
             (ATOI (CRVS-GETVAR "General.DistancePrecision"))
           )
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "BEARING"
         (IF (= (CRVS-GETVAR "General.IsArcBearingImportant") "FALSE")
           "-"
           (VL-STRING-SUBST
             "%%d"
             "d"
             (ANGTOS
               BEARING
               (COND
                 ((= (STRCASE (CRVS-GETVAR "General.BearingStyle")) "B")
                  4
                 )
                 (T 1)
               )
               (GETVAR "auprec")
             )
           )
         )
       )
       (CONS
         "STARTNORTHING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CADR (POLAR CENPT STARTANG RAD))
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "STARTEASTING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CAR (POLAR CENPT STARTANG RAD))
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "ENDNORTHING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CADR (POLAR CENPT ENDANG RAD))
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "ENDEASTING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CAR (POLAR CENPT ENDANG RAD))
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "CENTERNORTHING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CADR CENPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "CENTEREASTING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CAR CENPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
     )
    )
    ((= TABLETYPE "LINE")
     (SETQ
       STARTPT
        (LIST
          (ATOF (CDR (ASSOC 10 LABEL)))
          (ATOF (CDR (ASSOC 20 LABEL)))
          (ATOF (CDR (ASSOC 30 LABEL)))
        )
       ENDPT
        (LIST
          (ATOF (CDR (ASSOC 11 LABEL)))
          (ATOF (CDR (ASSOC 21 LABEL)))
          (ATOF (CDR (ASSOC 31 LABEL)))
        )
     )
     (LIST
       (CONS "LABEL" GEONO)
       (CONS
         "BEARING"
         (VL-STRING-SUBST
           "%%d"
           "d"
           (ANGTOS
             (ANGLE STARTPT ENDPT)
             (COND
               ((= (STRCASE (CRVS-GETVAR "General.BearingStyle")) "B")
                4
               )
               (T 1)
             )
             (GETVAR "auprec")
           )
         )
       )
       (CONS
         "DISTANCE"
         (STRCAT
           (RTOS
             (DISTANCE STARTPT ENDPT)
             2
             (ATOI (CRVS-GETVAR "General.DistancePrecision"))
           )
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "STARTNORTHING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CADR STARTPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "STARTEASTING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CAR STARTPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "ENDNORTHING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CADR ENDPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
       (CONS
         "ENDEASTING"
         (IF (= (CRVS-GETVAR "General.IsArcLineLocationImportant")
                "FALSE"
             )
           "-"
           (RTOS
             (CAR ENDPT)
             2
             (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
           )
         )
       )
     )
    )
    ((= TABLETYPE "POINT")
     (LIST
       (CONS "LABEL" GEONO)
       (CONS
         "NORTHING"
         (RTOS
           (ATOF (CDR (ASSOC 20 LABEL)))
           2
           (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
         )
       )
       (CONS
         "EASTING"
         (RTOS
           (ATOF (CDR (ASSOC 10 LABEL)))
           2
           (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
         )
       )
       (CONS
         "ELEVATION"
         (RTOS
           (ATOF (CDR (ASSOC 30 LABEL)))
           2
           (ATOI (CRVS-GETVAR "General.CoordinatePrecision"))
         )
       )
     )
    )
  )
)
;;;CRVS-BURSTLABELS
(DEFUN
   CRVS-BURSTLABELS (SSUSER / EN ENLABEL EL ENT I SELECTIONSETWC)
  (COMMAND "._undo" "g")
  (SETQ
    SELECTIONSETWC
     (LIST
       '(-4 . "<AND")
       '(0 . "INSERT")
       (CONS 2 (CRVS-GETVAR "General.LabelBlockName"))
       '(-4 . "AND>")
     )
  )
  ;;If there is nothing to burst, get a selection set from user.
  (IF (NOT SSUSER)
    (SETQ SSUSER (SSGET SELECTIONSETWC))
  )
  ;;If user didn't select anything, get all qualifying objects in drawing.
  (IF (NOT SSUSER)
    (SETQ SSUSER (SSGET "X" SELECTIONSETWC))
  )
  (COND
    (SSUSER
     (SETQ I -1)
     (WHILE (SETQ EN (SSNAME SSUSER (SETQ I (1+ I))))
       (SETQ
         EL      (ENTGET EN)
         ENLABEL EN
       )
       (COND
         ((= (CDR (ASSOC 0 EL)) "INSERT")
          ;;Make a text just like the label, but on the object label layer.
          (WHILE (AND
                   (SETQ EN (ENTNEXT EN))
                   (/= "SEQEND" (CDR (ASSOC 0 (SETQ EL (ENTGET EN)))))
                 )
            (COND
              ((AND
                 (= "ATTRIB" (CDR (ASSOC 0 EL)))
                 (= (CDR (ASSOC 2 EL)) "LABEL")
               )
               (ENTMAKE
                 (LIST
                   (CONS 0 "TEXT")
                   (ASSOC 67 EL)
                   (ASSOC 410 EL)
                   (CONS 8 (CRVS-GETVAR "General.LabelLayerName"))
                   (CONS 100 "AcDbText")
                   (ASSOC 10 EL)
                   (ASSOC 40 EL)
                   (ASSOC 1 EL)
                   (ASSOC 50 EL)
                   (ASSOC 41 EL)
                   (ASSOC 51 EL)
                   (ASSOC 7 EL)
                   (ASSOC 71 EL)
                   (ASSOC 72 EL)
                   (ASSOC 11 EL)
                   (ASSOC 73 EL)
                 )
               )
               (SETQ
                 ENT (ENTGET (ENTLAST))
                 ENT (SUBST (ASSOC 11 EL) (ASSOC 11 ENT) ENT)
               )
               (ENTMOD ENT)
              )
            )
          )
          ;;Explode the block
          (SETQ EN (ENTLAST))
          (COMMAND "._explode" ENLABEL)
          ;;Erase all the attdefs and change the rest to object label layer.
          (WHILE (SETQ EN (ENTNEXT EN))
            (IF (= "ATTDEF" (CDR (ASSOC 0 (ENTGET EN))))
              (ENTDEL EN)
              (ENTMOD
                (SUBST
                  (CONS 8 (CRVS-GETVAR "General.LabelLayerName"))
                  (ASSOC 8 (ENTGET EN))
                  (ENTGET EN)
                )
              )
            )
          )
         )
       )
     )
    )
  )
  (COMMAND "._undo" "e")
)

;;;CRVS-COMPARE
(DEFUN
   CRVS-COMPARE (LABELBLOCKLIST OBJECTBLOCKLIST ASSOCGROUP)
;;;Returns T if requested (string) elements are equal.
;;;Intended for use with this kind of list
;;;'(handle (0 . etype)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
;;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
;;;)
  (= (CDR (ASSOC ASSOCGROUP (CDR OBJECTBLOCKLIST)))
     (CDR (ASSOC ASSOCGROUP (CDR LABELBLOCKLIST)))
  )
)

;;;CRVS-GETREALFROMLIST
(DEFUN
   CRVS-GETREALFROMLIST (GROUPCODE GEOLIST)
  (ATOF (CDR (ASSOC GROUPCODE (CDR GEOLIST))))
)

;;;CRVS-GETRAWFROMLIST
(DEFUN
   CRVS-GETRAWFROMLIST (GROUPCODE GEOLIST)
  (CDR (ASSOC GROUPCODE (CDR GEOLIST)))
)

;;;CRVS-SORTLABELLIST
(DEFUN
   CRVS-SORTLABELLIST (LABELLIST / LABEL LABELBEFORE I NEWTABLETYPELIST
                       ISSORTED SORTEDLIST TABLETYPELIST
                      )
  (SETQ SORTEDLIST LABELLIST)
  (FOREACH
     TABLETYPELIST LABELLIST
    (SETQ
      ISSORTED NIL
      TABLETYPE
       (CAR TABLETYPELIST)
      TABLETYPELIST
       (CDR TABLETYPELIST)
    )
    (WHILE (NOT ISSORTED)
      (SETQ
        I 0
        ISSORTED T
      )
      (WHILE (> (LENGTH TABLETYPELIST) 1)
        (COND
          ;;If the first two entries are in order,
          ((< (ATOI (SUBSTR (CDR (ASSOC 1 (CDR (CAR TABLETYPELIST)))) 2))
              (ATOI
                (SUBSTR (CDR (ASSOC 1 (CDR (CADR TABLETYPELIST)))) 2)
              )
           )
           ;;Then put the first one in the new list.
           (SETQ
             NEWTABLETYPELIST
              (CONS
                (CAR TABLETYPELIST)
                NEWTABLETYPELIST
              )
             TABLETYPELIST
              (CDR TABLETYPELIST)
           )
          )
          ;;Else if the first two entries are equal,
          ((= (ATOI (SUBSTR (CDR (ASSOC 1 (CDR (CAR TABLETYPELIST)))) 2))
              (ATOI
                (SUBSTR (CDR (ASSOC 1 (CDR (CADR TABLETYPELIST)))) 2)
              )
           )
           ;;Then skip the first of the two.
           (SETQ TABLETYPELIST (CDR TABLETYPELIST))
          )
          ;;Else put the second entry into the new list and flag we aren't done yet.
          (T
           (SETQ
             NEWTABLETYPELIST
              (CONS
                (CADR TABLETYPELIST)
                NEWTABLETYPELIST
              )
             TABLETYPELIST
              (CONS
                (CAR TABLETYPELIST)
                (CDDR TABLETYPELIST)
              )
             ISSORTED NIL
           )
          )
        )
      )
      (COND
        (NEWTABLETYPELIST
         (SETQ
           TABLETYPELIST
            (REVERSE
              (CONS (CAR TABLETYPELIST) NEWTABLETYPELIST)
            )
           NEWTABLETYPELIST NIL
         )
        )
      )
    )
    (SETQ
      SORTEDLIST
       (SUBST
         (CONS TABLETYPE TABLETYPELIST)
         (ASSOC TABLETYPE LABELLIST)
         SORTEDLIST
       )
    )
  )
  SORTEDLIST
)


;;; CRVS-GEOTABLESTOATTRIBUTES
(DEFUN
   CRVS-GEOTABLESTOATTRIBUTES (GTLIST)
  (CONS
    ;;(handle
    (CONS "TARGETHANDLE" (CAR GTLIST))
    (MAPCAR
      '(LAMBDA (GROUP / GROUPCODE)
         (SETQ GROUPCODE (CAR GROUP))
         (CONS
           (COND
             ((= GROUPCODE 1) "LABEL")
             ((= GROUPCODE 0) "TABLETYPE")
             ((= GROUPCODE 10) "POINT1X")
             ((= GROUPCODE 20) "POINT1Y")
             ((= GROUPCODE 30) "POINT1Z")
             ((= GROUPCODE 11) "POINT2X")
             ((= GROUPCODE 21) "POINT2Y")
             ((= GROUPCODE 31) "POINT2Z")
             ((= GROUPCODE 40) "RADIUS")
             ((= GROUPCODE 50) "ANGLE1")
             ((= GROUPCODE 51) "ANGLE2")
           )
           (COND
             ((CDR GROUP))
             ("")
           )
         )
       )
      (CDR GTLIST)
    )
  )
)

;;; CRVS-ATTRIBUTESTOGEOTABLES
;;; Converts an attribute value list to a geotables data list
(DEFUN
   CRVS-ATTRIBUTESTOGEOTABLES (ATTLIST ENAME)
  (CONS
    ;;Put the targethandle attribute at the front of the list.
    (CDR (ASSOC "TARGETHANDLE" ATTLIST))
    (CONS
      ;;Put the supplied ename next
      (CONS -1 ENAME)
      ;;Then translate the group codes for the whole list.
      (MAPCAR
        '(LAMBDA (GROUP / GROUPCODE)
           (SETQ GROUPCODE (CAR GROUP))
           (CONS
             (COND
               ((= GROUPCODE "TARGETHANDLE") 5)
               ((= GROUPCODE "TABLETYPE") 0)
               ((= GROUPCODE "LABEL") 1)
               ((= GROUPCODE "POINT1X") 10)
               ((= GROUPCODE "POINT1Y") 20)
               ((= GROUPCODE "POINT1Z") 30)
               ((= GROUPCODE "POINT2X") 11)
               ((= GROUPCODE "POINT2Y") 21)
               ((= GROUPCODE "POINT2Z") 31)
               ((= GROUPCODE "RADIUS") 40)
               ((= GROUPCODE "ANGLE1") 50)
               ((= GROUPCODE "ANGLE2") 51)
             )
             (CDR GROUP)
           )
         )
        ATTLIST
      )
    )
  )
)

;;; CRVS-MAKELABELBLOCKLIST
(DEFUN
   CRVS-MAKELABELBLOCKLIST (SS / ATAG AVAL LABELPROPERTYI LABELBLOCKLIST
                            LABELBLOCKSLIST TABLETYPE TABLETYPES EL EN
                            ENDANG GROUPCODE I LABEL RAD STARTANG
                            TARGETHANDLE XCOORD YCOORD ZCOORD
                           )
;;; Returns a two-element list when given a single selection set of object labels.  List consists of 
;;; 1.  a list of the label types found, in the order found
;;; 2. a list of labels of the various types
;;; This list gets sorted by another function.
;;; This format is made to match the format returned by CRVS-SSTOGEOLIST
;;; LABELBLOCKLIST
;;;             '(targethandle (-1 . ename)(0 . tabletype)(1 . label)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
;;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
;;;                     (40 . str8radius)(50 . str8angle1)(51 . str8angle2)
;;;               )
;;;
  (COND
    (SS
     (SETQ
       I -1
       LABELBLOCKSLIST
        (MAPCAR
          'LIST
          (WIKI-STRTOLST
            (CRVS-GETVAR "General.TableTypes")
            "`,"
            "\""
            T
          )
        )
     )
     (WHILE (SETQ EN (SSNAME SS (SETQ I (1+ I))))
       (SETQ
         LABELBLOCKLIST NIL
         EL (ENTGET EN)
       )
       (COND
         ((= (CDR (ASSOC 0 EL)) "INSERT")
          (SETQ
            LABELBLOCKLIST
             (CRVS-ATTRIBUTESTOGEOTABLES
               (CRVS-READBLOCK EN)
               EN
             )
            TABLETYPE
             (CDR (ASSOC 0 (CDR LABELBLOCKLIST)))
            LABELBLOCKSLIST
             (SUBST
               (REVERSE
                 (CONS
                   LABELBLOCKLIST
                   (REVERSE
                     (ASSOC TABLETYPE LABELBLOCKSLIST)
                   )
                 )
               )
               (ASSOC TABLETYPE LABELBLOCKSLIST)
               LABELBLOCKSLIST
             )
          )
         )
       )
     )
     LABELBLOCKSLIST
    )
  )
)


;;; CRVS-SSTOGEOLIST
(DEFUN
;;; Builds list of geometries from selection set
;;; If doing point geometry, splits each arc and line into two point geometry entries.
;;; This format is made to match the format returned by CRVS-MAKELABELBLOCKLIST
   CRVS-SSTOGEOLIST (SS DATATYPE / GEOLIST CENPT EL EN ENDANG I RAD
                     STARTANG OBJECTTYPE TABLETYPE
                    )
  (SETQ I -1)
  (COND
    (SS
     (WHILE (SETQ EN (SSNAME SS (SETQ I (1+ I))))
       ;;Enter each entity in geolist.
       (SETQ EL (ENTGET EN))
       ;; Convert entget data list to a geotables data list
       ;; Geotables data list format is as follows:
       ;;      '(targethandle (0 . tabletype)(10 . str2point1x)(20 . str2point1y)(30 . str2point1z)
       ;;                     (11 . str2point2x)(21 . str2point2y)(31 . str2point2z)
       ;;                     (50 . str8angle1)(51 . str8angle2)(40 . str8radius)
       ;;       )
       (COND
         ;;If
         ((AND
            ;; data type is POINTS,
            (= DATATYPE "POINTS")
            ;; and we want to label this object type,
            (WCMATCH
              (SETQ OBJECTTYPE (CDR (ASSOC 0 EL)))
              (STRCASE (CRVS-GETVAR "General.PointsObjectTypes"))
            )
          )
          ;;Then
          (COND
            ;;If the entity is a line, put each endpoint in the list.
            ((= OBJECTTYPE "LINE")
             ;;First endpoint
             (SETQ
               GEOLIST
                (CRVS-ADDPOINTTOGEOLIST
                  (CDR (ASSOC 10 EL))
                  (ANGLE (CDR (ASSOC 10 EL)) (CDR (ASSOC 11 EL)))
                  EL
                  GEOLIST
                )
             )
             ;;Second endpoint
             (SETQ
               GEOLIST
                (CRVS-ADDPOINTTOGEOLIST
                  (CDR (ASSOC 11 EL))
                  (ANGLE (CDR (ASSOC 10 EL)) (CDR (ASSOC 11 EL)))
                  EL
                  GEOLIST
                )
             )
            )
            ;;If the entity is an arc, put each endpoint in the list.
            ((= OBJECTTYPE "ARC")
             ;;First endpoint
             (SETQ
               GEOLIST
                (CRVS-ADDPOINTTOGEOLIST
                  (POLAR
                    (CDR (ASSOC 10 EL))
                    (CDR (ASSOC 50 EL))
                    (CDR (ASSOC 40 EL))
                  )
                  (+ (CDR (ASSOC 50 EL)) (/ PI 2))
                  EL
                  GEOLIST
                )
             )
             ;;Second endpoint
             (SETQ
               GEOLIST
                (CRVS-ADDPOINTTOGEOLIST
                  (POLAR
                    (CDR (ASSOC 10 EL))
                    (CDR (ASSOC 51 EL))
                    (CDR (ASSOC 40 EL))
                  )
                  (+ (CDR (ASSOC 51 EL)) (/ PI 2))
                  EL
                  GEOLIST
                )
             )
            )
            ;;If the entity is another type, put main point in the list.
            (T
             (SETQ
               GEOLIST
                (CRVS-ADDPOINTTOGEOLIST
                  (CDR (ASSOC 10 EL))
                  ;;object rotation or zero rotation
                  (COND
                    ((CDR (ASSOC 50 EL)))
                    (0)
                  )
                  EL
                  GEOLIST
                )
             )
            )
          )
         )
         ;;Else if
         ((AND
            ;; data type is ARCSLINES
            (= DATATYPE "ARCSLINES")
            ;; and we know how to label this object type,
            (WCMATCH
              (SETQ OBJECTTYPE (CDR (ASSOC 0 EL)))
              (STRCASE (CRVS-GETVAR "General.ArcsLinesObjectTypes"))
            )
          )
          ;;Put all the base geometry data in the list
          (SETQ
            TABLETYPE OBJECTTYPE
            GEOLIST
             (CONS
               (CRVS-GEOGEOMETRYTOGEOTABLES
                 TABLETYPE
                 (CRVS-RTOSGEODATA
                   (LIST
                     ;;(10 . str2point1x)
                     (LIST 10 (CADR (ASSOC 10 EL)) 8)
                     ;;(20 . str2point1y)
                     (LIST 20 (CADDR (ASSOC 10 EL)) 8)
                     ;;(30 . str2point1z)
                     (LIST 30 (CADDDR (ASSOC 10 EL)) 8)
                     ;;(11 . str2point2x)
                     (LIST 11 (CADR (ASSOC 11 EL)) 8)
                     ;;(21 . str2point2y)
                     (LIST 21 (CADDR (ASSOC 11 EL)) 8)
                     ;;(31 . str2point2z)
                     (LIST 31 (CADDDR (ASSOC 11 EL)) 8)
                     ;;(40 . str8radius)
                     (LIST 40 (CDR (ASSOC 40 EL)) 8)
                     ;;(50 . str8angle1)
                     (LIST 50 (CDR (ASSOC 50 EL)) 8)
                     ;;(51 . str8angle2)
                     (LIST 51 (CDR (ASSOC 51 EL)) 8)
                   )
                 )
                 EL
               )
               GEOLIST
             )
          )
         )
       )
     )
     (REVERSE GEOLIST)
    )
  )
)


;;;CRVS-ADDPOINTTOGEOLIST
(DEFUN
   CRVS-ADDPOINTTOGEOLIST (3DPOINT ROT EL GEOLIST)
;;;Puts a point into GEOLIST
  (CONS
    (CRVS-GEOGEOMETRYTOGEOTABLES
      "POINT"
      (CRVS-RTOSGEODATA
        (LIST
          ;;(10 . str2point1x)
          (LIST 10 (CAR 3DPOINT) 8)
          ;;(20 . str2point1y)
          (LIST 20 (CADR 3DPOINT) 8)
          ;;(30 . str2point1z)
          (LIST 30 (CADDR 3DPOINT) 8)
          ;;(50 . str8angle1) angle at endpoint for label alignment
          (LIST 50 ROT 8)
        )
      )
      EL
    )
    GEOLIST
  )
)
;;;CRVS-RTOSGEOLIST
(DEFUN
   CRVS-RTOSGEODATA (GEODATA)
  (MAPCAR
    '(LAMBDA (GROUP / VAL)
       (SETQ VAL (CADR GROUP))
       (CONS
         (CAR GROUP)
         (IF VAL
           (RTOS VAL 2 (CADDR GROUP))
           NIL
         )
       )
     )
    GEODATA
  )
)

;;; CRVS-GEOGEOMETRYTOGEOTABLES
(DEFUN
   CRVS-GEOGEOMETRYTOGEOTABLES (TABLETYPE GEOGEOMETRY EL)
;;; Adds handle and entity name to the front of geotables formatted geometry 
;;; to make a complete geotables data list.
  (CONS
    ;;Put the handle in front as the object id
    (CDR (ASSOC 5 EL))
    (CONS
      ;;Put the entity (object) name verbatim in the list
      (ASSOC -1 EL)
      (CONS
        ;;Put the tabletype verbatim in the list
        (CONS 0 TABLETYPE)
        GEOGEOMETRY
      )
    )
  )
)


;;;  CRVS-MAKELAYER sub-function creates and makes current a layer for another routine.
(DEFUN
   CRVS-MAKELAYER (STRLAOPT / LAOPT LANAME LACOLR LALTYP LTFILE)
;;; Usage: (CRVS-MAKELAYER "'(\"laname\" \"lacolr\" \"laltyp\")")
;;; Use empty quotes for default color and linetype (eg. (CRVS-MAKELAYER "'(\"AZ\" \"\" \"\")")
  ;; Convert string to layer list.
  (SETQ LAOPT (READ STRLAOPT))
  (COND
    ;;If in ICAD mode, do nothing because we are getting an error trying to invoke the layer command.
    ((CRVS-ICAD-P))
    (T
     (SETQ
       LANAME
        (CAR LAOPT)
       LACOLR
        (CADR LAOPT)
       LALTYP
        (CADDR LAOPT)
       LTFILE "acad"
     )
     (IF (NOT (OR (= LALTYP "") (TBLSEARCH "LTYPE" LALTYP)))
       (PROGN (COMMAND "._linetype" "l" LALTYP "acad") (COMMAND))
     )
     (IF (NOT (OR (= LALTYP "") (TBLSEARCH "LTYPE" LALTYP)))
       (PROGN
         (ALERT
           (STRCAT
             "AutoCAD could not find "
             LALTYP
             " linetype.\n\nUsing default linetype."
           )
         )
         (SETQ LALTYP "")
       )
     )
     (COMMAND "._layer")
     (IF (NOT (TBLSEARCH "LAYER" LANAME))
       (COMMAND "m" LANAME)
       (COMMAND "t" LANAME "on" LANAME "u" LANAME "s" LANAME)
     )
     (IF (/= LACOLR "")
       (COMMAND "c" LACOLR "")
     )
     (IF (/= LALTYP "")
       (COMMAND "lt" LALTYP "")
     )
     (COMMAND "")
     LAOPT
    )
  )
)

;;;  CRVS-READBLOCK
(DEFUN
   CRVS-READBLOCK (EN / AT AV EG ET I J VALUES)
;;;Reads all values from attributes in the given block.
;;;Block is given as a entity name
;;;Returns list of tags and values '((tag . value))
  (WHILE (AND
           (SETQ EN (ENTNEXT EN))
           (/= "SEQEND"
               (SETQ ET (CDR (ASSOC 0 (SETQ EG (ENTGET EN)))))
           )
         )
    (COND
      ((= ET "ATTRIB")
       (SETQ
         AT (CDR (ASSOC 2 EG))
         AV (CDR (ASSOC 1 EG))
       )
       (SETQ VALUES (CONS (CONS AT AV) VALUES))
      )
    )
  )
  VALUES
)

;;;  CRVS-WRITEBLOCK
(DEFUN
   CRVS-WRITEBLOCK (EN VALUES / AT AV EG ET SUCCESS)
;;;Writes the given values to the given block.
;;;Values are in an association list '((tag . value))
;;;Block is given as a entity name
;;;No meaningful return value.  Could return list of attributes successfully written.
  ;;Fill in attributes
  (WHILE (AND
           (SETQ EN (ENTNEXT EN))
           (/= "SEQEND"
               (SETQ ET (CDR (ASSOC 0 (SETQ EG (ENTGET EN)))))
           )
         )
    (COND
      ((= ET "ATTRIB")
       (SETQ
         AT (CDR (ASSOC 2 EG))
         AV (CDR (ASSOC 1 EG))
       )
       (COND
         ((ASSOC AT VALUES)
          (ENTMOD
            (SUBST (CONS 1 (CDR (ASSOC AT VALUES))) (ASSOC 1 EG) EG)
          )
          (SETQ SUCCESS (CONS (ASSOC AT VALUES) SUCCESS))
         )
       )
       (ENTUPD EN)
      )
    )
  )
  (REVERSE SUCCESS)
)
;| Start AutoLISP comment mode to wiki transclude sub functions

;;;WIKI-STRTOLST
;;;Parses a string into a list of fields.
;;;Usage: (wiki-strtolst
;;;         [InputString containing fields]
;;;         [FieldSeparatorWC field delimiter wildcard string
;;;          Use "`," for comma and " ,\t" for white space
;;;         ]
;;;         [TextDelimiter text delimiter character.]
;;;         [EmptyFieldsDoCount flag.
;;;           If nil, consecutive field delimiters are ignored.
;;;           Nil is good for word (white space) delimited strings.
;;;         ]
;;;       )
;;; Examples:
;;; CSV            (wiki-strtolst string "`," "\"" T)
;;; Word delimited (wiki-strtolst string " ,\t,\n" "" nil)
;;; Revision history
;;; 2009-01-17 TGH     Replaced test for empty fieldseparatorwc with a simple '= function
;|
   Edit the source code for this function at 

  http://autocad.wikia.com/wiki/Strtolst_(AutoLISP_function)

|;
;;;Avoid cleverness.
;;;Human readability trumps elegance and economy and cleverness here.
;;;This should be readable to a programmer familiar with any language.
;;;In this function, I'm trying to honor readability in a new (2008) way.
;;;And I am trying a new commenting style.
;;;Tests
;;;(alert (apply 'strcat (mapcar '(lambda (x) (strcat "\n----\n" x)) (wiki-strtolst "1 John,\"2 2\"\" pipe,\nheated\",3 the end,,,,," "`," "\"" nil))))
;;;(alert (apply 'strcat (mapcar '(lambda (x) (strcat "\n----\n" x)) (wiki-strtolst "1 John,\"2 2\"\" pipe,\nheated\",3 the end,,,,," "`," "\"" T))))
(DEFUN
   WIKI-STRTOLST (INPUTSTRING FIELDSEPARATORWC TEXTDELIMITER
                  EMPTYFIELDSDOCOUNT / CHARACTERCOUNTER CONVERSIONISDONE
                  CURRENTCHARACTER CURRENTFIELD CURRENTFIELDISDONE
                  FIRSTCHARACTERINDEX PREVIOUSCHARACTER RETURNLIST
                  TEXTMODEISON
                 )
  ;;Initialize the variables for clarity's sake
  (SETQ
    ;;For the AutoLISP (substr string index length) function, the first character index is 1
    FIRSTCHARACTERINDEX
     1
    ;;We start the character counter one before the beginning
    CHARACTERCOUNTER
     (1- FIRSTCHARACTERINDEX)
    PREVIOUSCHARACTER ""
    CURRENTCHARACTER ""
    CURRENTFIELD ""
    CURRENTFIELDISDONE NIL
    TEXTMODEISON NIL
    CONVERSIONISDONE NIL
    RETURNLIST NIL
  )
  ;;Make sure that the FieldSeparatorWC is not empty.
  (COND
    ;;If the FieldSeparatorWC is an empty string,
    ((= FIELDSEPARATORWC "")
     ;;Then
     ;;1. Give an alert about the problem.
     (ALERT
       ;;Include princ to allow user to see and copy error
       ;;after dismissing alert box.
       (PRINC
         (STRCAT
           "\n\""
           FIELDSEPARATORWC
           "\" is not a valid field delimiter."
         )
       )
     )
     ;;2. Exit with error.
     (EXIT)
    )
  )
  ;;Start the main character-by-character InputString examination loop.
  (WHILE (NOT CONVERSIONISDONE)
    (SETQ
      ;;Save CurrentCharacter as PreviousCharacter.
      PREVIOUSCHARACTER
       CURRENTCHARACTER
      ;;CharacterCounter is initialized above to start 1 before first character.  Increment it.
      CHARACTERCOUNTER
       (1+ CHARACTERCOUNTER)
      ;;Get new CurrentCharacter from InputString.
      CURRENTCHARACTER
       (SUBSTR INPUTSTRING CHARACTERCOUNTER 1)
    )
    ;;Decide what to do with CurrentCharacter.
    (COND
      ;;If
      ((AND
         ;;there is a TextDelimiter,
         (/= TEXTDELIMITER "")
         ;;and CurrentCharacter is a TextDelimiter,
         (= CURRENTCHARACTER TEXTDELIMITER)
       )
       ;;then
       ;;1.  Toggle the TextModeIsOn flag
       (IF (NOT TEXTMODEISON)
         (SETQ TEXTMODEISON T)
         (SETQ TEXTMODEISON NIL)
       )
       ;;2.  If this is the second consecutive TextDelimiter character, then
       (IF (= PREVIOUSCHARACTER TEXTDELIMITER)
         ;;Output it to CurrentField.
         (SETQ CURRENTFIELD (STRCAT CURRENTFIELD CURRENTCHARACTER))
       )
      )
      ;;Else if CurrentCharacter is a FieldDelimiter wildcard match,
      ((WCMATCH CURRENTCHARACTER FIELDSEPARATORWC)
       ;;Then
       (COND
         ;;If TextModeIsOn = True, then 
         ((= TEXTMODEISON T)
          ;;Output CurrentCharacter to CurrentField.
          (SETQ CURRENTFIELD (STRCAT CURRENTFIELD CURRENTCHARACTER))
         )
         ;;Else if
         ((OR ;;EmptyFieldsDoCount, or
              (= EMPTYFIELDSDOCOUNT T)
              ;;the CurrentField isn't empty,
              (/= "" CURRENTFIELD)
          )
          ;;Then
          ;;Set the CurrentFieldIsDone flag to true.
          (SETQ CURRENTFIELDISDONE T)
         )
         (T
          ;;Else do nothing
          ;;Do not flag the CurrentFieldDone,
          ;;nor output the CurrentCharacter.
          NIL
         )
       )
      )
      ;;Else if CurrentCharacter is empty,
      ((= CURRENTCHARACTER "")
       ;;Then
       ;;We are at the end of the string.
       ;;1.  Flag ConversionIsDone.
       (SETQ CONVERSIONISDONE T)
       ;;2.  If
       (IF (OR ;;EmptyFieldsDoCount, or
               EMPTYFIELDSDOCOUNT
               ;;the PreviousCharacter wasn't a FieldSeparatorWC, or
               (NOT (WCMATCH PREVIOUSCHARACTER FIELDSEPARATORWC))
               ;;the ReturnList is still nil due to only empty non-counting fields in string,
               ;;(Added 2008-02-18 TGH. Bug fix.)
               (= RETURNLIST NIL)
           )
         ;;Then flag the CurrentFieldIsDone to wrap up the last field.
         (SETQ CURRENTFIELDISDONE T)
       )
      )
      ;;Else (CurrentCharacter is something else),
      (T
       ;;Output CurrentCharacter to CurrentField.
       (SETQ CURRENTFIELD (STRCAT CURRENTFIELD CURRENTCHARACTER))
      )
    )
    ;;If CurrentFieldIsDone,
    (IF CURRENTFIELDISDONE
      ;;Then
      ;;Output it to the front of ReturnList.
      (SETQ
        RETURNLIST
         (CONS CURRENTFIELD RETURNLIST)
        ;;Start a new CurrentField.
        CURRENTFIELD
         ""
        CURRENTFIELDISDONE NIL
      )
    )
    ;;End the main character-by-character InputString examination loop.
  )
  ;;Reverse the backwards return list and we are done.
  (REVERSE RETURNLIST)
)

(CRVS-INITIALIZESETTINGS)

(PRINC
  (STRCAT
    "\nGEOTABLES.LSP version "
    (CRVS-GETVAR "General.Version")
    " loaded.  Type GEOTABLES to start."
  )
)
(PRINC)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 2 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;