;;; AutoCAD Wiki AutoLISP code header. Start highlighting at the beginning of this line to copy program code.

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
;;; http://autocad.wikia.com/wiki/Curve_table_creator_%28AutoLISP_application%29

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
;;; Revisions
;;; 20080924 Version 2.0.2 Fixed bug.  Added precision to ArcsLines coordinates to boost precision of line bearings.
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
;|
Philosophy and questions:
Q: Do users want to automatically update and delete label blocks?
A: Yes.  And GT can update labels for selected objects.  
But deleting orphan labels is more tricky.

Q: Do users want to have to pick labels to delete?
A: No.  But they need to pick candidates for deletion

Q: How does GT know whether to label point or arc/line data?
A: Separate commands for point labelling and arc/line labelling.
Such as GT and GTP.
|;
;;; CRVS-INITIALIZESETTINGS
(DEFUN
   CRVS-INITIALIZESETTINGS ()
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
;;; An AutoCAD Wilcard list of objects whose points are to be labelled
;;; If ARC or LINE are in the list, their endpoints are labelled
;;; If CIRCLE is in the list, centers are labelled
;;; If POINT is in the list, nodes are labelled
;;; If any other object type is in the list, its start or insertion point is labelled.
  (CRVS-SETVAR "General.PointsObjectTypes" "ARC,LINE")
;;; An AutoCAD Wilcard list of legal ARCSLINES objects Geotables can process.
  (CRVS-SETVAR "General.ArcsLinesObjectTypes" "ARC,LINE")
;;; ArcBearingIsImportant
;;; "TRUE" or "FALSE"
;;; True means arcs must have the same bearing to have the same label
;;; You are listing bearings in your table,
;;; so arcs that differ only by bearing are listed separately.
;;; FALSE means you aren't using bearings in your table,
;;; so arcs that differ only by bearing are given the same label.
  (CRVS-SETVAR "General.IsArcBearingUnique" "FALSE")
;;; LocationIsImportant
;;; "TRUE" or "FALSE".
;;; TRUE means arcs or lines must have the same location to have the same label
;;; so arcs or lines that differ only by location are listed separately.
;;; FALSE means
;;; arcs or lines that differ only by location are given the same label.
;;; Obviously location is always important for point labels, regardless of this setting.
  (CRVS-SETVAR "General.IsLocationUnique" "FALSE")
;;; Distance suffix (postfix).
  (CRVS-SETVAR "General.DistancePost" "'")
;;; Arc label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Arc.LabelPrefix" "C")
;;; Line label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Line.LabelPrefix" "L")
;;; Point label prefix. This must be exactly 1 letter long.
  (CRVS-SETVAR "Point.LabelPrefix" "P")
;;; This is the width of your geotablesctable.dwg block.
;;; This only affects the placement of multiple columns.
  (CRVS-SETVAR "Arc.TableWidth" "118")
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
   (WIKI-TIP
     6
     "GEOTABLES first needs to know whether to label the geometry of arcs and lines themselves or their end points.\n\nAt the follwoing prompt, select Arcs and lines mode or Points mode."
   )
  (INITGET "Arcslines Points")
  (SETQ DATATYPE (GETKWORD "[Arcs and lines/Points]: "))
  (COND (DATATYPE (CRVS-GEOTABLES (STRCASE DATATYPE))))
)
;;;CRVS-GEOTABLES
(DEFUN
   CRVS-GEOTABLES (DATATYPE / OPT SS)
  (SETQ *CRVS:VLST* (LIST (LIST "CLAYER" (GETVAR "CLAYER"))))
  (WIKI-TIP
    0
    "Select from the following at the next prompt:\n\n-Quick label, table, and burst: make tables from selected objects in one step.\n\n-Labels only: add attributed block labels to selected objects, but no table yet.\n\n-Tables from labels: make a table from selected label blocks.  This might be useful to insert labels only into a drawing and make a table from there.\n\n-Burst smart label blocks: explode smart labels, turning label attributes into plain text."
  )
  (INITGET "Quick Label Table Burst")
  (SETQ
    OPT
     (GETKWORD
       "\n[Quick label, table, and burst/Labels only/Tables from labels/Burst smart label blocks]: "
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
  (WIKI-TIP
    1
    "Thank you for using GeoTables, the Open Source geometry table generator\n\n\n-Labels curves, lines, and points globally.\n\n-Combines duplicate entries.\n\n-Allows multi-column tables.\n\nLimitations:\n\n-World UCS only.  No UCS translations are done at this time.  Curves labels must be added with world UCS current.\n\n-Xrefs.  You can't select objects within xrefs at this time, but you can copy object labels from one drawing to another and use the 'Table from selected objects' option to make a table in a plan sheet.\n\nCustomization:\n\nUse refedit or your own methods to edit the two blocks that are used.  If you make the table blocks shorter or narrower, you need to tell GeoTables.  Modify the lines near the top of GEOTABLES.LSP that say   (CRVS-SETVAR \"Arc.TableWidth\")  (CRVS-SETVAR \"Line.TableWidth\")  (CRVS-SETVAR \"Point.TableWidth\")  (CRVS-SETVAR \"General.TableRowSpacing\").\n\nYou can remove any attributes from the table and header blocks, but don't remove any from the GEOTABLESNO block.\n\nThe order of the attributes in the blocks is flexible."
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
    varname (strcase varname)
    NEWGROUP (CONS VARNAME VALUE))
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
   CRVS-GETVAR (VARNAME / varnamemixed)
  (setq
    varnamemixed varname
    varname (strcase varname)
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
           VARNAMEmixed
           ".\nGeotables can't continue."
         )
       )
     )
     ;;2.  Exit
     (EXIT)
    )
  )
)

(VL-LOAD-COM)
(IF (NOT (LOAD "tip" NIL))
  (DEFUN
     WIKI-TIP (ITIP TIPTEXT)
    (PROMPT (STRCAT "\n" TIPTEXT))
  )
)

;;;Curves error trapper
(DEFUN
   CRVS-ERRDEF ()
  (SETQ
    CRVS-ERROR *ERROR*
    *ERROR* CRVS-STPERR
  ) ;_ end of setq
) ;_ end of defun

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
  ) ;_ end of IF
  (IF (= (TYPE F1) (QUOTE FILE))
    (SETQ F1 (CLOSE F1))
  ) ;_ end of IF
  ;; Close files
  (IF (= (TYPE F2) (QUOTE FILE))
    (SETQ F2 (CLOSE F2))
  ) ;_ end of if
  (IF (= (TYPE F3) (QUOTE FILE))
    (SETQ F3 (CLOSE F3))
  ) ;_ end of if
  (IF (= 8 (LOGAND (GETVAR "undoctl") 8))
    (COMMAND "._undo" "end")
  ) ;_ end of IF
  ;; End undo group
  (IF CRVS-ERROR
    (SETQ
      *ERROR* CRVS-ERROR
      CRVS-ERROR NIL
    ) ;_ end of setq
  ) ;_ end of IF
  ;; Restore old *error* handler
  (PRINC)
) ;_ end of defun

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
  ) ;_ end of setq
) ;_ end of defun
;;;END ERROR HANDLER

;;;CRVS-AUTOINSERTLABELS
;;;1.  Prompts user to select objects to label and labels to check for deletion.
;;;2.  Deletes any selected labels that are orphans.
;;;Returns the selection set of the labels for all the objects that were selected.
(DEFUN
   CRVS-AUTOINSERTLABELS (DATATYPE / 2PI ALLGEOLIST ALLLABELBLOCKLIST
                          ARCDELTA GEOENDANG GEOSTARTANG LABELBLOCK
                          NLABELBLOCKSDELETED LABELDELTA GEOENDANG
                          NLABELBLOCKSINSERTED GEOSTARTANG FREENUM I
                          LABELTEXT LABELTEXTCOUNTER LABELTEXTLIST
                          LABELTEXTPREFIX SSALL SSUSER
                          SSFINISHEDDLABELBLOCKS TXTHT USERGEOLIST
                          USERLABELBLOCKLIST OBJECT SELECTIONWC TABLETYPE
                         )
;;;Inserts labels on selected objects
;;;Returns selection set of object label blocks for selected objects
  (WIKI-TIP
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
      ((setq LABELBLOCK (CRVS-GEOMETRYLABEL GEOMETRY ALLLABELBLOCKLIST DATATYPE)))
      (T
       ;;Else
       (COND
         ;;If we can find a similar label, use it's number
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
             (CDR (ASSOC 0 (cdr GEOMETRY)))
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
                          FREENUM I LABELTEXT LABELTEXTLIST RETURNLIST
                         )
  (FOREACH
     TABLETYPE TABLETYPES
    (SETQ
      I 0
      LABELTEXTLIST NIL
    )
    (WHILE (<= (SETQ I (1+ I)) (LENGTH ALLGEOLIST))
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
           LABELBLOCK (cdr (assoc TABLETYPE ALLLABELBLOCKLIST))
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
         LABELBLOCK (cdr DATATYPE)
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
   CRVS-GEOMETRYLABEL (GEOMETRY LABELBLOCKLIST DATATYPE /
                       MATCHINGLABELBLOCK I LABELBLOCK
                      )
  (COND
    ((= DATATYPE "ARCSLINES")
     (cond
       ((ASSOC (CAR GEOMETRY) (cdr (assoc "ARC" LABELBLOCKLIST))))
       ((ASSOC (CAR GEOMETRY) (cdr (assoc "LINE" LABELBLOCKLIST))))
     )
    )
    ((= DATATYPE "POINTS")
     (SETQ I -1)
     (WHILE (AND
              (cdr(assoc "POINT" LABELBLOCKLIST))
              (NOT MATCHINGLABELBLOCK)
              (SETQ LABELBLOCK (NTH (SETQ I (1+ I)) (cdr (assoc "POINT" LABELBLOCKLIST))))
            )
       (COND
         ;;If all coordinates match
         ((AND
            (equal (CDR (ASSOC 10 (cdr LABELBLOCK))) (CDR (ASSOC 10 (cdr GEOMETRY))) 0.001)
            (equal (CDR (ASSOC 20 (cdr LABELBLOCK))) (CDR (ASSOC 20 (cdr GEOMETRY))) 0.001)
            (equal (CDR (ASSOC 30 (cdr LABELBLOCK))) (CDR (ASSOC 30 (cdr GEOMETRY))) 0.001)
          )
          ;;Then declare a match.
          (SETQ MATCHINGLABELBLOCK LABELBLOCK)
         )
       )
     )
     MATCHINGLABELBLOCK
    )
  )
)


;;; CRVS-SIMILARLABELNUMBER 
;;; Looks for a label in ALLLABELBLOCKLIST that is similar in the required ways
;;; to the given geometry
;;; If a matching label is found, returns its text
(DEFUN
   CRVS-SIMILARLABELNUMBER (GEOMETRY ALLLABELBLOCKLIST DATATYPE /
                            GEOENDANG GEOSTARTANG LABELBLOCKI LABELTEXT
                            TABLETYPE ISLABELSIMILAR GEOSTARTPOINT
                            GEOENDPOINT 2PI ARCDELTA GEODATA I LABELBLOCK
                           )
  (SETQ
    TABLETYPE
     (CDR (ASSOC 0 (cdr GEOMETRY)))
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
       ((= TABLETYPE "POINT") NIL)
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
         (SETQ LABELBLOCKI (NTH (SETQ I (1+ I)) ALLLABELBLOCKLIST))
         ;;And
         ;;We haven't already got a label from a matching labelblock.
         (NOT LABELTEXT)
       );;If this labelblock matches this object in all the required ways,
        ;;use it instead of a new one.
        (COND
          ((= TABLETYPE (CDR (ASSOC 0 (cdr LABELBLOCKI))) "ARC")
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
               ;; (This test is most likely to fail is for same radius and delta.
               ;; We'll run it first.)
               (AND
                 ;;Radii are equal
                 (CRVS-COMPARE LABELBLOCK GEOMETRY 40)
                 ;;and deltas are equal
                 (EQUAL
                   ARCDELTA
                   (CDR (ASSOC "DELTA" GEODATA))
                   0.00000002
                 )
               )
               ;; And
               (OR ;; we are ignoring bearings
                   (= (CRVS-GETVAR "General.IsArcBearingUnique") "FALSE")
                   ;; or the angle matches the object
                   ;;(Deltas were already equal, so we can compare just start angles)
                   (CRVS-COMPARE LABELBLOCK GEOMETRY 50)
               )
               ;; And
               (OR ;; we are ignoring location
                   (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
                   ;; or the label location and start angle match the object location (a strange situation!)
                   (AND
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 50)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 10)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 20)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 30)
                   )
               )
             );;Then
              ;;Use existing label
              (SETQ ISLABELSIMILAR T)
           )
          )
          ((= TABLETYPE (CDR (ASSOC 0 (cdr LABELBLOCKI))) "LINE")
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
                   (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
                   ;; or the label location matches the object location (a strange situation!)
                   (AND
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 10)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 20)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 30)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 11)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 21)
                     (CRVS-COMPARE LABELBLOCK GEOMETRY 31)
                   )
               )
             );;Then
              ;;Use existing label
              (SETQ ISLABELSIMILAR T)
           )
          )
          ((= TABLETYPE (CDR (ASSOC 0 (cdr LABELBLOCKI))) "POINT")
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
          (SETQ LABELTEXT (CDR (ASSOC 1 (CDR LABELBLOCK))))
        )
     )
    )
  )
)


;;;CRVS-INSERTLABELBLOCK
(DEFUN
   CRVS-INSERTLABELBLOCK (GEOMETRY LABELTEXT / 2PI ANG1 ATAG AVAL CENPT
                          EL EN ENBLK ENDANG INSPT LACOLOR LALTYPE
                          LANAME RAD ROT STARTANG TXTHT ENDPT LABEL STARTPT TABLETYPE
                         )
  (SETQ
    TABLETYPE
     (CDR (ASSOC 0 (CDR GEOMETRY)))
    TXTHT
     (* (GETVAR "dimscale") (GETVAR "dimtxt"))
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
       ANG1  (CRVS-GETREALFROMLIST 50 GEOMETRY)
       ROT   (IF (MINUSP (SIN (- ANG1 (/ PI 4))))
               ANG1
               (+ ANG1 PI)
             )
       INSPT (POLAR
               STARTPT
               (+ ROT (/ PI 2))
               TXTHT
             )
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
  ) ;_ end of if
  (IF (/= LALTYPE "")
    (COMMAND "lt" LALTYPE "")
  ) ;_ end of if
  (COMMAND "")
  (COMMAND
    "._insert"
    (CRVS-GETVAR "General.LabelBlockName")
    "non"
    INSPT
    TXTHT
    ""
    (ANGTOS ROT)
  )
  ;;Change attribute values
  (CRVS-WRITEBLOCK
    (ENTLAST)
    (CONS
      (CONS "LABEL" LABELTEXT)
      (CRVS-GEOTABLESTOATTRIBUTES GEOMETRY)
    )
  )
  ;;Return the geometry, but with the labelblock's entity name.
  (cons (cadr geometry) (subst (assoc -1 (entget (entlast))) (assoc -1 (cdr geometry)) (cdr GEOMETRY)))
)

;;; CRVS-MAKEGEOTABLES
(DEFUN
   CRVS-MAKEGEOTABLES (SSUSER / 2PI ATAG AVAL BEARING CENPT COL1X DELTA
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
     (WIKI-TIP
       3
       "Select now the object labels whose data you want to put into a table.\n\nAll other object labels will be ignored."
     )
     (PROMPT "\nSelect object labels to put in table: ")
     (SETQ
       SSUSER
        (SSGET
          (LIST
            '(0 . "INSERT")
            (CONS 2 (CRVS-GETVAR "General.LabelBlockName"))
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
       2PI
        (* 2 PI)
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
                       (CONS
                         2
                         (STRCAT
                           (CRVS-GETVAR
                             "General.TableBlockPre"
                           )
                           (CRVS-GETVAR
                             (STRCAT
                               "General."
                               TABLETYPE
                               "TableBlockBase"
                             )
                           )
                           (CRVS-GETVAR
                             "General.TableHeaderBlockPost"
                           )
                         )
                       )
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
             (* (GETVAR "dimscale") (GETVAR "dimtxt"))
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
          ) ;_ end of if
          (IF (/= LALTYPE "")
            (COMMAND "lt" LALTYPE "")
          ) ;_ end of if
          (COMMAND "")
          (IF (SETQ
                SS1
                 (SSGET
                   "X"
                   (LIST
                     (CONS
                       2
                       (STRCAT
                         (CRVS-GETVAR "General.TableBlockPre")
                         (CRVS-GETVAR
                           (STRCAT
                             "General."
                             TABLETYPE
                             "TableBlockBase"
                           )
                         )
                         (CRVS-GETVAR "General.TableHeaderBlockPost")
                         ","
                         (CRVS-GETVAR "General.TableBlockPre")
                         (CRVS-GETVAR
                           (STRCAT
                             "General."
                             TABLETYPE
                             "TableBlockBase"
                           )
                         )
                         (CRVS-GETVAR "General.TableEntryBlockPost")
                       )
                     )
                   )
                 )
              )
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
                         (atof(CRVS-GETVAR
                           (STRCAT TABLETYPE ".TableWidth")
                         ))
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
                       (ATOf
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
                    (ATOf (CRVS-GETVAR "General.TableRowSpacing"))
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
     (WIKI-TIP
       4
       "GEOTABLES ships with unique layers for every table column.  You may thaw all layers to see all columns, freeze layers for columns you don't need, or modify the table blocks.\n\nYou may choose to list unique bearings or locations separately by changing the respective settings in GEOTABLES.LSP"
     )
    )
    (T
     (WIKI-TIP
       5
       "You must select object labels to make a table."
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
         (STRCAT (RTOS RAD 2 2) (CRVS-GETVAR "General.DistancePost"))
       )
       (CONS
         "LENGTH"
         (STRCAT
           (RTOS (* RAD DELTA) 2 2)
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "DELTA"
         (VL-STRING-SUBST "%%d" "d" (ANGTOS DELTA 1 4))
       )
       (CONS
         "CHORD"
         (STRCAT
           (RTOS (* 2 RAD (SIN DOVER2)) 2 2)
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "TANGENT"
         (STRCAT
           (RTOS (* RAD (/ (SIN DOVER2) (COS DOVER2))) 2 2)
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "BEARING"
         (IF (= (CRVS-GETVAR "General.IsArcBearingUnique") "FALSE")
           "-"
           (VL-STRING-SUBST "%%d" "d" (ANGTOS BEARING 4 4))
         )
       )
       (CONS
         "STARTNORTHING"
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (VL-STRING-SUBST "%%d" "d" (ANGTOS (angle STARTPT ENDPT) 4 4))
       )
       (CONS
         "DISTANCE"
         (STRCAT
           (RTOS (DISTANCE STARTPT ENDPT) 2 2)
           (CRVS-GETVAR "General.DistancePost")
         )
       )
       (CONS
         "STARTNORTHING"
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
         (IF (= (CRVS-GETVAR "General.IsLocationUnique") "FALSE")
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
       (cons 2 (CRVS-GETVAR "General.LabelBlockName"))
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
               ) ;_ end of setq
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
   CRVS-COMPARE (LABELBLOCKLIST OBJECTBLOCKLIST ASSOCGROUP )
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
   CRVS-SORTLABELLIST (LABELLIST / LABEL LABELBEFORE I newtabletypelist
                       isSORTED sortedlist TABLETYPELIST
                      )
  (setq sortedlist LABELLIST)
  (FOREACH
     TABLETYPELIST LABELLIST
    (SETQ
      isSORTED NIL
      TABLETYPE
       (CAR TABLETYPELIST)
      TABLETYPELIST
       (CDR TABLETYPELIST)
    )
    (WHILE (NOT isSORTED)
      (SETQ
        I 0
        isSORTED T
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
             newtabletypelist
              (CONS (CAR TABLETYPELIST) newtabletypelist)
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
           (SETQ tabletypeLIST (CDR tabletypelist))
          )
          ;;Else put the second entry into the new list and flag we aren't done yet.
          (T
           (SETQ
             newtabletypelist
              (CONS (CADR TABLETYPELIST) newtabletypelist)
             TABLETYPELIST
              (CONS (CAR TABLETYPELIST) (CDDR TABLETYPELIST))
             isSORTED NIL
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
      sortedlist
       (SUBST
         (CONS TABLETYPE TABLETYPELIST)
         (ASSOC TABLETYPE LABELLIST)
         sortedlist
       )
    )
  )
  sortedlist
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
          ))
          ;;Else if
          ((AND
             ;; data type is ARCSLINES
             (= DATATYPE "ARCSLINES")
             ;; and we know how to label this object type,
             (WCMATCH
               (SETQ OBJECTTYPE (CDR (ASSOC 0 EL)))
               (STRCASE (CRVS-GETVAR "General.ArcsLinesObjectTypes"))
             )
           );;Put all the base geometry data in the list
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
           ) ;_ end of /=
         ) ;_ end of and
    (COND
      ((= ET "ATTRIB")
       (SETQ
         AT (CDR (ASSOC 2 EG))
         AV (CDR (ASSOC 1 EG))
       ) ;_ end of setq
       (SETQ
         VALUES
          (CONS (CONS AT AV) VALUES) ;_ end of SUBST
       )
      )
    ) ;_ end of cond
  ) ;_ end of while
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
           ) ;_ end of /=
         ) ;_ end of and
    (COND
      ((= ET "ATTRIB")
       (SETQ
         AT (CDR (ASSOC 2 EG))
         AV (CDR (ASSOC 1 EG))
       ) ;_ end of setq
       (COND
         ((ASSOC AT VALUES)
          (ENTMOD
            (SUBST (CONS 1 (CDR (ASSOC AT VALUES))) (ASSOC 1 EG) EG) ;_ end of SUBST
          ) ;_ end of ENTMOD
          (SETQ SUCCESS (CONS (ASSOC AT VALUES) SUCCESS))
         )
       ) ;_ end of cond
       (ENTUPD EN)
      )
    ) ;_ end of cond
  ) ;_ end of while
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
;|
   Edit the source code for this function at 

  strtolst (AutoLISP function)

|;
;;;Avoid cleverness.
;;;Human readability trumps elegance and economy and cleverness here.
;;;This should be readable to a programmer familiar with any language.
;;;In this function, I'm trying to honor readability in a new (2008) way.
;;;And I am trying a new commenting style.
;;;Tests
;;;(alert (apply 'strcat (mapcar '(lambda (x) (strcat "\n----\n" x)) (wiki-strtolst "1 John,\"2 2\"\" pipe,\nheated\",3 the end,,,,," "," "\"" nil))))
;;;(alert (apply 'strcat (mapcar '(lambda (x) (strcat "\n----\n" x)) (wiki-strtolst "1 John,\"2 2\"\" pipe,\nheated\",3 the end,,,,," "," "\"" T))))
(DEFUN
   WIKI-STRTOLST (INPUTSTRING FIELDSEPARATORWC TEXTDELIMITER
                  EMPTYFIELDSDOCOUNT / CHARACTERCOUNTER CONVERSIONISDONE
                  CURRENTCHARACTER CURRENTFIELD CURRENTFIELDISDONE
                  FIRSTCHARACTERINDEX PREVIOUSCHARACTER RETURNLIST
                  TEXTMODEISON
                 )
  ;;Initialize the variables for clarity's sake
  (SETQ
    FIRSTCHARACTERINDEX 1
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
    ;;If an empty string matches the FieldSeparatorWC,
    ((WCMATCH "" FIELDSEPARATORWC)
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
;;; Usage notes:
;;; This source code relies on the existence of the TIP.LSP file (itself), and writes
;;; tip dismissals to it.
;|
   This code also relies on the tip.dvb vba form available at AutoCAD Wiki as 

  Media:Tip.dwg (disguised for security purposes as a dwg file).

   Edit the source code for this function at 

  Tipvba (AutoLISP function)

|;
;;; 
;;;
(DEFUN
   C:TIP
	()
  (WIKI-TIP
    0
    "Use TIP.LSP and TIP.DVB to show your users a tip until they uncheck the box below."
  )
  (WIKI-TIP
    1
    "TIP.LSP stores the list of unchecked tips at the top of the file TIPS.LSP."
  )
  (WIKI-TIP
    2
    "Use VBAMAN and VBAIDE to adjust the size of this form as required."
  )
)
(DEFUN
   WIKI-TIP
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

; End AutoLISP comment mode if on |;

(CRVS-INITIALIZESETTINGS)

(PRINC "\nGEOTABLES.LSP version 2.0.2 loaded.  Type GEOTABLES to start.")
(PRINC)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 2 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
