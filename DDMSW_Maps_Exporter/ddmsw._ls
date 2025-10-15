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
;;; Please AutoCAD:Be_bold in adding clarifying comments and improvements at
;;; https://autocad.wikia.com/wiki/Maricopa_County_DDMSW_GIS_Export_(AutoLISP_application)
;;; Copyleft 2018 Thomas Gail Haws licensed under the terms of the GNU GPL
;;; http://www.hawsedc.com tom.haws@gmail.com
;;; Version: 1.0.3
;;; Official Repository: http://autocad.wikia.com/wiki/Maricopa_County_DDMSW_GIS_Export_(AutoLISP_application)
;;; Haws is a registered reserved symbol with Autodesk that will never conflict with other apps.
;;;
;;; Features:


(defun c:ddmswcopy () (wiki-ddmsw-copy-main) (princ))
(defun c:ddmswexport () (wiki-ddmsw-export-main) (princ))

(defun
   wiki-ddmsw-copy-main (/ input-main)
  (cond
    ((> (getvar "expert") 0)
      (alert (princ "\nSorry. DDMSWCOPY currently needs you to set EXPERT to 0 before starting. Aborting."))
      (exit)
    )
  )
  (wiki-ddmsw-initialize-settings)
  (command "._undo" "_group")
  (wiki-ddmsw-adedefdata)
  (while (setq input-main (wiki-ddmsw-get-input-main)))
  (wiki-ddmsw-do-copy)
  ;; Needed a delay after defdata.  Moved defdata before user input
  (wiki-ddmsw-adeattachdata)
  (wiki-ddmsw-isolate-layers)
  (wiki-ddmsw-filter-layers)
  (command "._undo" "_end")
  (princ)
)

(defun
   wiki-ddmsw-get-input-main (/ input-main)
  (initget "Rainfall SUbbasin LandUse SOil Tc SEttings")
  (setq
    input-main
     (getkword
       (strcat
         "\nSpecify map to toggle [Rainfall ("
         (wiki-ddmsw-getvar "COPY-RAINFALL")
         ")/SUbbasin ("
         (wiki-ddmsw-getvar "COPY-SUBBASIN")
         ")/LandUse ("
         (wiki-ddmsw-getvar "COPY-LANDUSE")
         ")/SOil ("
         (wiki-ddmsw-getvar "COPY-SOIL")
         ")/Tc ("
         (wiki-ddmsw-getvar "COPY-TC")
         ")/SEttings] or <select objects>: "
       )
     )
  )
  (cond
    (input-main (wiki-ddmsw-process-input-main input-main))
    (t nil)
  )
)

(defun
   wiki-ddmsw-process-input-main (input-main)
  (cond
    ((= input-main "SEttings")
     (while (wiki-ddmsw-get-input-settings))
     t
    )
    (t (wiki-ddmsw-toggle-copy input-main))
  )
)

(defun
   wiki-ddmsw-get-input-settings (/ input-settings)
  (initget "Isolate Filter")
  (setq
    input-settings
     (getkword
       (strcat
         "\nSelect setting to change or enter to continue [Isolate layers ("
         (wiki-ddmsw-getvar "ISOLATE-LAYERS")
         ")/Filter layers ("
         (wiki-ddmsw-getvar "FILTER-LAYERS")
         ")] or <continue>: "
       )
     )
  )
  (cond
    ((= input-settings "Isolate")
     (wiki-ddmsw-toggle-yes-no "ISOLATE-LAYERS")
    )
    ((= input-settings "Filter")
     (wiki-ddmsw-toggle-yes-no "FILTER-LAYERS")
    )
    (t nil)
  )
)

(defun
   wiki-ddmsw-do-copy (/ map-set map-set-i)
  (setq
    map-sets
     '(("Tc" ("Tc"))
       ("area" ("Rainfall" "SubBasin" "LandUse" "Soil"))       
      )
  )
  (foreach
     map-set map-sets
    (wiki-ddmsw-do-copy-map-set map-set)
  )
)

(defun
   wiki-ddmsw-do-copy-map-set (map-set / layer-name map-copy-p map-list
                               map-prompt ss-source
                              )
  (setq
    map-prompt
     (car map-set)
    map-list
     (cadr map-set)
  )
  (foreach
     map map-list
    (cond
      ((= (wiki-ddmsw-getvar (strcat "COPY-" map)) "yes")
       (setq map-copy-p t)
      )
    )
  )
  (cond
    (map-copy-p
     (alert
       (princ (strcat "\nSelect " map-prompt " map polylines."))
     )
     (setq ss-source (ssget '((0 . "*POLYLINE"))))
     (cond
       (ss-source
        (foreach
           map map-list
          (setq layer-name (wiki-ddmsw-make-layer map))
          (cond
            ((= (wiki-ddmsw-getvar (strcat "Copy-" map)) "yes")
             (command "._copytolayer" ss-source "" layer-name "")
            )
          )
        )
       )
     )
    )
  )
)


(defun
   wiki-ddmsw-toggle-copy (input-main / var)
  (setq var (strcat "Copy-" input-main))
  (wiki-ddmsw-toggle-yes-no var)
)

(defun
   wiki-ddmsw-toggle-yes-no (var)
  (wiki-ddmsw-setvar
    var
    (cond
      ((= (wiki-ddmsw-getvar var) "yes") "no")
      (t "yes")
    )
  )
)

(defun
   wiki-ddmsw-make-layer (map / layer-color layer-ltype layer-name)
  (setq
    layer-name
     (wiki-ddmsw-getvar (strcat "Layer-" map "-Name"))
    layer-color
     (wiki-ddmsw-getvar (strcat "Layer-" map "-Color"))
    layer-ltype
     (wiki-ddmsw-getvar (strcat "Layer-" map "-Ltype"))
  )
  (command "._layer")
  ;; If exists, leaves color and ltype alone.
  (cond
    ((tblsearch "LAYER" layer-name)
     (command
       "_t" layer-name "_on" layer-name "_unlock" layer-name
      )
    )
    (t
     (command "_new" layer-name)
     (if (/= layer-color "")
       (command "_color" layer-color layer-name)
     )
     (if (/= layer-ltype "")
       (command "_ltype" layer-ltype layer-name)
     )
    )
  )
  (command "")
  layer-name
)

;; If filtering, leaves everything off but rainfall.
(defun
   wiki-ddmsw-isolate-layers ()
  (cond
    ((= (wiki-ddmsw-getvar "ISOLATE-LAYERS") "yes")
     (command
       "._layer"
       "_off"
       "*"
       "y"
       "_on"
       (cond
         ((= (wiki-ddmsw-getvar "FILTER-LAYERS") "yes")
          (wiki-ddmsw-getvar (strcat "Layer-Rainfall-Name"))
         )
         (t (wiki-ddmsw-layers-wildcard))
       )
       ""
     )
    )
  )
)

(defun
   wiki-ddmsw-filter-layers ()
  (cond
    ((= (wiki-ddmsw-getvar "FILTER-LAYERS") "yes")
     (command
       "._LAYER" "_FILTER" "_DELETE" "HAWS-DDMSW" "" "._LAYER" "_FILTER"
       "_NEW" "_GROUP" "" (wiki-ddmsw-layers-wildcard) "HAWS-DDMSW" "_EXIT" ""
       "LAYERPALETTE"
      )
    )
  )
)

(defun
   wiki-ddmsw-layers-wildcard ( / ade-data layers-wildcard)
  (setq layers-wildcard "" ade-data (wiki-ddmsw-define-ade-data))
  (foreach
     map ade-data
    (setq layers-wildcard (strcat layers-wildcard "," (wiki-ddmsw-getvar (strcat "Layer-" (car map) "-Name"))))
  )
  (substr layers-wildcard 2)
)

;; I hope to structure this better.  For now just a script
(defun
   wiki-ddmsw-adedefdata ()
  (princ "\nDefining DDMSW data...")
  (command
    "cmddia" "0"
    "adedefdata"
    "new" "dummy" "dummy1" "No description" "character" "01" "no"
    "delete" "Rainfall" "new" "Rainfall"
    "BASINID" "Major Basin getting the Rainfall" "character" "01" "yes"
    "RAINID" "Major Basin Rainfall data set" "character" "DEFAULT" "no"
    "delete" "SubBasin" "new" "SubBasin"
    "AREAID" "6-character-max name" "character" "999999" "yes"
    "BASINID" "Parent Major Basin" "character" "01" "yes"
    "AREASF" "Size of the Sub Basin" "real" "0" "no"
    "delete" "LandUse" "new" "LandUse"
    "LUCODE" "DDMSW LandUse Use code" "character" "999" "no"
    "delete" "Soil" "new" "Soil"
    "SOIL_LID" "DDMSW Soil ID" "integer" "999" "no"
    "delete" "TC" "new" "TC"
    "AREAID" "Determined by DDMSW" "character" "999999" "yes"
    "BASINID" "Determined by DDMSW" "character" "01" "yes"
    "LENGTH" "Determined by DDMSW" "real" "0.0" "yes"
    "USGE" "Upstream ground elevation" "real" "0.0" "yes"
    "DSGE" "Downsream ground elevation" "real" "0.0" "no"
    "delete" "dummy"
    "exit"
    "cmddia" "1"
  )
  (princ "\nDone defining DDMSW data.")
)

(defun
   wiki-ddmsw-adeattachdata (/ adeattachdata-script f1 file-name maps)
  (princ "\nAttaching DDMSW data to maps...")
  (setq
    adeattachdata-script
     (wiki-ddmsw-adeattachdata-script)
    file-name
     (strcat (getvar "dwgprefix") "DDMSW-adeattachdata.scr")
    f1 (open file-name "w")
  )
  (princ adeattachdata-script f1)
  (setq f1 (close f1))
  (alert (princ "\nCopied polylines to requested layers.  Now running script to attach DDMSW map data tables. Use Properties to enter required information for each polyline.  Then use DDMSWExport to create MapExport shape files."))
  (command "._script" file-name)
)

(defun
   wiki-ddmsw-adeattachdata-script (/ adeattachdata-script maps)
  (setq
    maps
     (wiki-ddmsw-define-ade-data)
    adeattachdata-script "cmddia\n0\n"
  )
  (foreach
     map maps
    (cond
      ((ssget
         "X"
         (list
           (cons
             8
             (wiki-ddmsw-getvar
               (strcase (strcat "Layer-" (car map) "-Name"))
             )
           )
         )
       )
       (setq
         adeattachdata-script
          (strcat
            adeattachdata-script
            "._adeattachdata\n"
            (car map)
            "\n"
            "_attach\n"
            "_no\n"
            "(ssget \"X\" (list (cons 8 (wiki-ddmsw-getvar \""
            (strcase
              (strcat "Layer-" (car map) "-Name")
            )
            "\"))))\n"
            "\n"
            "_exit\n"
          )
       )
      )
    )
  )
  (setq
    adeattachdata-script
     (strcat adeattachdata-script "cmddia\n1\n")
  )
)


(defun
   wiki-ddmsw-export-main (/ export-path shape-file maps)
  (setq maps (wiki-ddmsw-define-ade-data))
  (cond
    ((setq
       export-path
        (getfiled "Select directory and add an arbitrary filename" "Select.Directory" "" 1)
     )
     (setq export-path (vl-filename-directory export-path))
    )
  )
  (foreach map maps (wiki-ddmsw-export-map map export-path))
)

(defun
   wiki-ddmsw-export-map (map export-path / profile-file-name)
  (setq shape-file (strcat export-path "\\" (car map) ".shp"))
  (cond
    ((findfile shape-file)
     (alert
       (princ
         (strcat
           shape-file
           " already exists.  Please delete files or change export location."
         )
       )
     )
    )
    (t
     (setq
       profile-file-name
        (wiki-ddmsw-make-mapexport-profile
          map
          export-path
        )
     )
     (command
       "._-mapexport"
       "shp"
       shape-file
       "_yes"
       profile-file-name
       "_selection"
       (cond
         ((= (car map) "TC") "_Line")
         (t "_Polygon")
       )
       "_All"
       (wiki-ddmsw-getvar (strcat "Layer-" (car map) "-Name"))
       "*"
       "_no"
       "_options"
       "_no"
       "_yes"
       "_proceed"
     )
    )
  )
)

(defun
   wiki-ddmsw-make-mapexport-profile
   (map export-path / f1 file-name map-name profile-string)
  (setq
    map-name
     (car map)
    file-name
     (strcat
       export-path
       "\\DDMSW-mapexport-profile-"
       map-name
       ".epf"
     )
  )
  (cond
    ((not (findfile file-name))
     (setq
       profile-string
        (strcat
          "<AdMapExportProfile version=\"2.1.3\">"
          "<LoadedProfileName/>"
          "<StorageOptions>"
          "<StorageType>FileOneEntityType</StorageType>"
          "<GeometryType>Polygon</GeometryType>"
          "<FilePrefix/>"
          "</StorageOptions>"
          "<SelectionOptions>"
          "<UseSelectionSet>1</UseSelectionSet>"
          "<UseAutoSelection>0</UseAutoSelection>"
          "</SelectionOptions>"
          "<TranslationOptions>"
          "<TreatClosedPolylinesAsPolygons>1</TreatClosedPolylinesAsPolygons>"
          "<ExplodeBlocks>1</ExplodeBlocks>"
          "<LayersToLevels>"
          "<MapLayersToLevels>0</MapLayersToLevels>"
          "<LayerToLevelMapping/>"
          "</LayersToLevels>"
          "</TranslationOptions>"
          "<TopologyOptions>"
          "<GroupComplexPolygons>0</GroupComplexPolygons>"
          "<TopologyName/>"
          "</TopologyOptions>"
          "<LayerOptions>"
          "<DoFilterByLayer>0</DoFilterByLayer>"
          "<LayerList/>"
          "</LayerOptions>"
          "<FeatureClassOptions>"
          "<DoFilterByFeatureClass>0</DoFilterByFeatureClass>"
          "<FeatureClassList/>"
          "</FeatureClassOptions>"
          "<TableDataOptions>"
          "<TableDataType>None</TableDataType>"
          "<Name/>"
          "<SQLKeyOnly>0</SQLKeyOnly>"
          "</TableDataOptions>"
          "<CoordSysOptions>"
          "<DoCoordinateConversion>0</DoCoordinateConversion>"
          "<CoordSysName/>"
          "</CoordSysOptions>"
          "<TargetNameOptions>"
          "<FormatName>SHP</FormatName>"
          "</TargetNameOptions>"
          "<DriverOptions/>"
          "<UseUniqueKeyField>0</UseUniqueKeyField>"
          "<UseUniqueKeyFieldName>AdMapKey</UseUniqueKeyFieldName>"
          "<ExpressionFieldMappings>"
          (cond
            ((= map-name "Rainfall")
             (strcat
               "<NameValuePair><Name>BASINID</Name><Value>:BASINID@Rainfall</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>RAINID</Name><Value>:RAINID@Rainfall</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
             )
            )
            ((= map-name "SubBasin")
             (strcat
               "<NameValuePair><Name>AREAID</Name><Value>:AREAID@SubBasin</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>BASINID</Name><Value>:BASINID@SubBasin</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>AREASF</Name><Value>:AREASF@SubBasin</Value><Datatype>DoubleDataType</Datatype></NameValuePair>"
             )
            )
            ((= map-name "TC")
             (strcat
               "<NameValuePair><Name>AREAID</Name><Value>:AREAID@TC</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>BASINID</Name><Value>:BASINID@TC</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>LENGTH</Name><Value>:LENGTH@TC</Value><Datatype>DoubleDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>USGE</Name><Value>:USGE@TC</Value><Datatype>DoubleDataType</Datatype></NameValuePair>"
               "<NameValuePair><Name>DSGE</Name><Value>:DSGE@TC</Value><Datatype>DoubleDataType</Datatype></NameValuePair>"
              )
            )
            ((= map-name "LandUse")
             "<NameValuePair><Name>LUCODE</Name><Value>:LUCODE@LandUse</Value><Datatype>CharacterDataType</Datatype></NameValuePair>"
            )
            ((= map-name "Soil")
             "<NameValuePair><Name>SOIL_LID</Name><Value>:SOIL_LID@Soil</Value><Datatype>IntegerDataType</Datatype></NameValuePair>"
            )
          )
          "</ExpressionFieldMappings>"
          "</AdMapExportProfile>"
        )
       f1 (open file-name "w")
     )
     (princ profile-string f1)
     (setq f1 (close f1))
    )
  )
  file-name
)

;;; ============================================================================
;;; Settings stuff.  Last part of code; not fun to read for new project member.
;;; ============================================================================
;; Start with default settings and supplement with stored settings.
(defun
   wiki-ddmsw-initialize-settings (/ luprec setting)
  (cond
    ((not *wiki-ddmsw-settings*)
     (wiki-ddmsw-get-default-settings)
    )
  )
  (wiki-ddmsw-get-stored-settings)
)


;; Define-Settings is at top of file for customization convenience.
(defun
   wiki-ddmsw-get-default-settings ()
  (setq *wiki-ddmsw-settings* (wiki-ddmsw-define-settings))
)

;; Get settings from AutoCAD's AutoLISP permananent storage system
;; The setcfg/getcfg functions might be removed in a future release.
(defun
   wiki-ddmsw-get-stored-settings (/ settings-definition valuei)
  (setq settings-definition (wiki-ddmsw-define-settings))
  (cond
    ;; If stored settings location exists
    ((getcfg (strcat (wiki-ddmsw-storage-location) "Dummy"))
     (foreach
        setting settings-definition
       (cond
         ;; If setting exists (even missing settings return "")
         ((/= ""
              (setq
                valuei
                 (getcfg
                   (strcat
                     (wiki-ddmsw-storage-location)
                     (car setting)
                   )
                 )
              )
          )
          (wiki-ddmsw-save-to-settings-list (car setting) valuei)
         )
       )
     )
    )
  )
)

(defun wiki-ddmsw-storage-location () "Appdata/Haws/DDMSW/")

(defun
   wiki-ddmsw-save-to-settings-list (var val)
  (setq
    *wiki-ddmsw-settings*
     (subst
       (list var val (wiki-ddmsw-getvar-type var))
       (assoc var *wiki-ddmsw-settings*)
       *wiki-ddmsw-settings*
     )
  )
)

(defun
   wiki-ddmsw-getvar-string (var / val-string)
  (cadr (assoc var *wiki-ddmsw-settings*))
)

(defun
   wiki-ddmsw-getvar (var / val val-string var-type var-upper)
  (setq
    var-upper (strcase var)
    val-string
     (wiki-ddmsw-getvar-string var-upper)
    var-type
     (caddr (assoc var-upper *wiki-ddmsw-settings*))
    val
     (cond
       ((= var-type 'real) (distof val-string)) ; Returns nil for ""
       ((= var-type 'int) (atoi val-string))
       ((= var-type 'str) val-string)
     )
  )
)

(defun
   wiki-ddmsw-getvar-type (var / val-string)
  (caddr (assoc var *wiki-ddmsw-settings*))
)

(defun
   wiki-ddmsw-setvar (var val / var-type)
  (setq var-upper (strcase var) var-type (wiki-ddmsw-getvar-type var-upper))
  (cond
    ((/= (type val) var-type)
     (alert
       (princ
         (strcat
           "Warning in wiki-ddmsw-setvar.\n\nVariable: "
           var-upper
           "\nType expected: "
           (vl-prin1-to-string var-type)
           "\nType provided: "
           (vl-prin1-to-string (type val))
         )
       )
     )
     (exit)
    )
  )
  (cond ((/= (type val) 'str) (setq val (vl-prin1-to-string val))))
  (wiki-ddmsw-save-to-settings-list var-upper val)
  (wiki-ddmsw-save-to-storage var-upper val)
  val
)

(defun
   wiki-ddmsw-save-to-storage (var val)
  (setcfg (strcat (wiki-ddmsw-storage-location) var) val)
)


;; This will later have all the adedefdata data
(defun
   wiki-ddmsw-define-ade-data ()
  '(("Rainfall") ("SubBasin") ("LandUse") ("Soil") ("TC"))
)

;; Customizable out-of-the-box defaults are at the end of the file.
(defun
   wiki-ddmsw-define-settings (/ luprec)
  (list
    ;; At runtime retrieval, each setting is converted 
    ;; from its storage as a string to the given data type.
    ;;    Name             Value Data_type
    (list "ISOLATE-LAYERS" "yes" 'str)
    (list "FILTER-LAYERS" "yes" 'str)
    (list "COPY-RAINFALL" "yes" 'str)
    (list "COPY-SUBBASIN" "yes" 'str)
    (list "COPY-LANDUSE" "yes" 'str)
    (list "COPY-SOIL" "yes" 'str)
    (list "COPY-TC" "yes" 'str)
    (list "LAYER-RAINFALL-NAME" "C-STRM-DDMS-RAIN" 'str)
    (list "LAYER-RAINFALL-COLOR" "cyan" 'str)
    (list "LAYER-RAINFALL-LTYPE" "" 'str)
    (list "LAYER-SUBBASIN-NAME" "C-STRM-DDMS-SBAS" 'str)
    (list "LAYER-SUBBASIN-COLOR" "white" 'str)
    (list "LAYER-SUBBASIN-LTYPE" "" 'str)
    (list "LAYER-LANDUSE-NAME" "C-STRM-DDMS-LAND" 'str)
    (list "LAYER-LANDUSE-COLOR" "green" 'str)
    (list "LAYER-LANDUSE-LTYPE" "" 'str)
    (list "LAYER-SOIL-NAME" "C-STRM-DDMS-SOIL" 'str)
    (list "LAYER-SOIL-COLOR" "red" 'str)
    (list "LAYER-SOIL-LTYPE" "" 'str)
    (list "LAYER-TC-NAME" "C-STRM-DDMS-TCON" 'str)
    (list "LAYER-TC-COLOR" "blue" 'str)
    (list "LAYER-TC-LTYPE" "" 'str)
  )
)

;; Reset settings on load
(wiki-ddmsw-get-default-settings)
(alert (princ "\nYou must understand the export process before using this helper.  Follow the process at http://tomsthird.blogspot.com/2016/08/making-gis-shape-files-with-data-from.html at least once before using this tool."))
(princ
  "\nHAWS-DDMSW loaded.  1. Use DDMSWCopy to make map layers in AutoCAD.  2. Edit data using Properties palette.  3. Use DDMWSExport to export maps."
)

 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 1 1 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;