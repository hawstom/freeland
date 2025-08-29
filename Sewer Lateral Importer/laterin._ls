;;; Sewer Laterals Importer
;;; LATERIN.LSP
;;;
;;; Imports video observations from a comma-separated values (csv) text file.
;;; Inserts blocks indicating the observations.
;;;
;;; Copyright 2010 Thomas Gail Haws
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
;;; LATERIN is a tool that reads attribute data from a file
;;; and interprets each line in the file as specified in the settings at the top
;;; of the source code.
;;;
;;; The order and graphical arrangement of the block attributes doesn't matter.
;;;
;;; Revisions
;;; Revisions
;;; 20090306  TGH     hr.  Made it create layers if not exist
;;; 20100812  TGH     hr.  Created based on AutoCAD Wiki ATTRIBSIN.
(DEFUN
   WIKI-LI:CONFIG ()
  ;;Start user editable settings
  (SETQ
    *WIKI-LI:SETTINGS*
     '(;;The layers don't do anything.
       ("LateralLayerName" . "C-SSWR-LATL")
       ("LateralLayerColor" . "")
       ("LateralLayerLinetype" . "")
       ("File.Input.Extension" . "csv")
       ;;Comma is a special character for AutoCAD wildcards, so a ` (`,) is needed to make a comma literal
       ("File.Input.FieldDelimiterWC" . "`,")
       ("File.Input.TextDelimiter" . "\"")
       ("File.Input.CommentPrefix" . ":,`#,;,'")
       ;;Does the text file have a first line header with all the field names?
       ;;T (True/yes) or nil (False/no)
       ("File.Input.HasFieldsHeader" . T)
       ;;Field names if there is a header
       ;;or field numbers starting at ZERO if there is no header or if header is to be ignored
       ("Fields"
        ("Code" . "Code")
        ("SegmentID" . "SegmentID")
        ("UManholeID" . 2)
        ("DManholeID" . "DManhole.ManholeID")
        ("Distance" . "Distance")
        ("Clock" . "ClockFrom")
        ("Severity" . "Severity")
        ("Direction" . "Reversed")
        ("Distance" . "Distance")
        ("Description" . "WinCanDescription")
       )
       ;;Reversal (camera travel direction) values used in file
       ("Field.Direction.Up" . "TRUE")
       ("Field.Direction.Down" . "FALSE")
       ;;Attribute tags in blocks to be inserted
       ("AttributeTag.Description" . "DESC")
       ("AttributeTag.ActiveStatus" . "ACTIVE")
       ("BlockNames"
        ;; A list of observation codes and the name of the block
        ;; to be inserted.
        ("START US" . "OBSERVATION-START")
        ("START DS" . "OBSERVATION-START")
        ("STOP" . "OBSERVATION-STOP")
        ("LAT" . "OBSERVATION-LATERAL")
       )
      )
  )
  (SETQ
    *WIKI-LI:SETTINGS*
     (CONS
       ;; Actions to take for each code encountered.
       (LIST
         "CodeActions"
         (CONS
           "START US"
           (+ FLAGENDBLOCK FLAGSTARTBLOCK FLAGSETCOORDSYS)
         )
         (CONS
           "START DS"
           (+ FLAGENDBLOCK FLAGSTARTBLOCK FLAGSETCOORDSYS)
         )
         (CONS
           "LAT"
           (+ FLAGENDBLOCK FLAGSTARTBLOCK FLAGSETLATDIR)
         )
         (CONS "TSA" (+ FLAGSETACTIVE FLAGADDDESCRIPTION))
         (CONS "TSNA" (+ FLAGSETINACTIVE FLAGADDDESCRIPTION))
         (CONS "TFA" (+ FLAGSETACTIVE FLAGADDDESCRIPTION))
         (CONS "TFNA" (+ FLAGSETINACTIVE FLAGADDDESCRIPTION))
         ;;Do nothing for this code.
         (CONS "AMH" 0)
         (CONS
           "STOP"
           (+ FLAGSTARTBLOCK FLAGENDBLOCK FLAGADDDESCRIPTION)
         )
         ;;Do this for all other codes
         (CONS
           "DEFAULT"
           (+ FLAGADDDESCRIPTION FLAGADDSEVERITY)
         )
       )
       *WIKI-LI:SETTINGS*
     )
  )
  ;;End user editable settings
)


(DEFUN C:LATERIN () (WIKI-LI:LATERIN))

(DEFUN
   WIKI-LI:LATERIN (/ ACADVARS FLAGENDBLOCK FLAGADDDESCRIPTION FLAGADDSEVERITY
                    FLAGSETACTIVE FLAGSETCOORDSYS FLAGSETINACTIVE FLAGSETLATDIR
                    FLAGSTARTBLOCK FNAME OBSERVATIONS
                   )
  ;;Set some constants
  (SETQ
    ;;Insert any pending old block and reset all block values to start a new one
    FLAGSTARTBLOCK
     1
    ;;Insert any pending block without starting a new one.
    FLAGENDBLOCK
     2
    FLAGSETCOORDSYS 4
    FLAGSETLATDIR 8
    FLAGSETACTIVE 16
    FLAGSETINACTIVE 32
    FLAGADDDESCRIPTION 64
    FLAGADDSEVERITY 128
  )
  (WIKI-LI:ERRORTRAP)
  (WIKI-LI:CONFIG)
  (WIKI-LI:GETFILENAMES)
  (SETQ OBSERVATIONS (WIKI-LI:GETOBSERVATIONS))
  ;;Make new layers
  ;;(WIKI-LI:MAKELAYERS OBSERVATIONS)
  ;;Insert blocks.
  (WIKI-LI:PROCESSOBSERVATIONS OBSERVATIONS)
  (WIKI-LI:ERRORRESTORE)
  (PRINC)
)


(DEFUN
   WIKI-LI:ERRORTRAP ()
  (SETQ
    *WIKI-LI:OLDERROR* *ERROR*
    *ERROR* *WIKI-LI:ERROR*
  )
)

(DEFUN
   *WIKI-LI:ERROR* (MESSAGE)
  (COMMAND)
  (IF (= 8 (LOGAND (GETVAR "undoctl") 8))
    (COMMAND "._undo" "end")
  )
  (WIKI-LI:VRSTOR)
  (IF (= (TYPE F1) (QUOTE FILE))
    (SETQ F1 (CLOSE F1))
  )
  (IF (= (TYPE F2) (QUOTE FILE))
    (SETQ F2 (CLOSE F2))
  )
  (IF *WIKI-LI:OLDERR*
    (SETQ
      *ERROR* *WIKI-LI:OLDERR*
      *WIKI-LI:OLDERR* NIL
    )
  )
  (IF (OR (= MESSAGE "Function cancelled")
          (= MESSAGE "quit / exit abort")
      )
    (PRINC)
    (PRINC (STRCAT "\nError: " MESSAGE))
  )
)

(DEFUN
   WIKI-LI:ERRORRESTORE ()
  (SETQ
    F1 NIL
    *ERROR* *WIKI-LI:OLDERR*
    *WIKI-LI:OLDERR* NIL
  )
)

(DEFUN
   WIKI-LI:VSAVE (VLST)
  (SETQ ACADVARS (MAPCAR '(LAMBDA (V) (LIST V (GETVAR V))) VLST))
)

(DEFUN
   WIKI-LI:VRSTOR ()
  (MAPCAR '(LAMBDA (V) (SETVAR (CAR V) (CADR V))) ACADVARS)
)

(DEFUN
   WIKI-LI:GETVAR (VAR)
  (CDR (ASSOC VAR *WIKI-LI:SETTINGS*))
)

(DEFUN
   WIKI-LI:SETVAR (VAR VAL)
  (SETQ
    *WIKI-LI:SETTINGS*
     (IF (ASSOC VAR *WIKI-LI:SETTINGS*)
       (SUBST
         (CONS VAR VAL)
         (ASSOC VAR *WIKI-LI:SETTINGS*)
         *WIKI-LI:SETTINGS*
       )
       (CONS (CONS VAR VAL) *WIKI-LI:SETTINGS*)
     )
  )
)

(DEFUN
   WIKI-LI:GETFILENAMES (/ FNAMEIN)
  (WIKI-LI:SETVAR
    "File.Input.Name"
    (SETQ
      FNAMEIN
       (GETFILED
         "Laterals csv text file"
         ""
         (WIKI-LI:GETVAR "File.Input.Extension")
         0
       )
    )
  )
  (WIKI-LI:SETVAR
    "File.Output.Name"
    (STRCAT
      (VL-FILENAME-DIRECTORY FNAMEIN)
      "\\"
      (VL-FILENAME-BASE FNAMEIN)
      "-coordinates"
      (VL-FILENAME-EXTENSION FNAMEIN)
    )
  )
)
;;; Usage:
;;;   FNAME is the complete path of an existing file.  Will not be checked.
;;; Returns a list of observations with a fields key list as the first member.
(DEFUN
   WIKI-LI:GETOBSERVATIONS ( / COMMENTPREFIX FIELD FIELDDELIMITER FIELDMEM
                            FIELDNAMESAREDONE FIELDS MISSINGFIELDS OBSERVATIONS
                            RDLIN TEXTDELIMITER THISOBSERVATION
                           )
  (SETQ
    ;;Initialize variable for readability.
    FIELDDELIMITER
     (WIKI-LI:GETVAR "File.Input.FieldDelimiterWC")
    TEXTDELIMITER
     (WIKI-LI:GETVAR "File.Input.TextDelimiter")
    COMMENTPREFIX
     (WIKI-LI:GETVAR "File.Input.CommentPrefix")
    FIELDNAMESAREDONE NIL
    F1 (OPEN (WIKI-LI:gETVAR "File.Input.Name") "r")
  )
  ;;Check that if there's no header, all field numbers are given.
  ;;If all good, use the field numbers as the header
  ;;Else abort.
  (COND
    ((NOT (WIKI-LI:GETVAR "File.Input.HasFieldsHeader"))
     (FOREACH
        FIELD (WIKI-LI:GETVAR "Fields")
       (IF (/= (TYPE (CADR FIELD)) 'INT)
         (SETQ
           MISSINGFIELDS
            (STRCAT
              MISSINGFIELDS
              (STRCAT "\n" (CAR FIELD) ": " (CADR FIELD))
            )
         )
       )
     )
     (COND
       (MISSINGFIELDS
        (ALERT
          (PRINC
            (STRCAT
              "\nFatal error: field numbers not assigned\n"
              MISSINGFIELDS
            )
          )
        )
        (EXIT)
       )
       ;;All good.  Add field key to front of observation list
       (T
        (SETQ
          OBSERVATIONS
           (CONS (WIKI-LI:GETVAR "Fields") OBSERVATIONS)
          FIELDNAMESAREDONE T
        )
       )
     )
    )
  )
  (WHILE (SETQ RDLIN (READ-LINE F1))
    (COND
      ;;If it's a comment,
      ((WCMATCH
         (SUBSTR RDLIN 1 1)
         (WIKI-LI:GETVAR "File.Input.CommentPrefix")
       )
       ;;then do nothing.
       NIL
      )
      ;;Else if field names aren't done, we need to process a header.
      ;;Read all the field names.
      ((AND (NOT FIELDNAMESAREDONE))
       ;;Parse the line
       (SETQ
         THISOBSERVATION
          ;;Parse the line into fields
          (WIKI-STRTOLST
            RDLIN
            FIELDDELIMITER
            TEXTDELIMITER
            ;;Empty fields do count.  We aren't allowing white-space delimited files.
            T
          )
       )
       ;;Check that we have all the fields we want.
       (SETQ
         FIELDS
          (MAPCAR
            '(LAMBDA (FIELD / FIELDMEM)
               (COND
                 ;;If it has a field number use it straight
                 ((= (TYPE (CDR FIELD)) 'INT) FIELD)
                 ;;Else if the the field name it has is found in the header
                 ((SETQ FIELDMEM (MEMBER (CDR FIELD) THISOBSERVATION))
                  ;;then add it to the field list with it's numeric position in the header
                  (CONS
                    (CAR FIELD)
                    (- (LENGTH THISOBSERVATION) (LENGTH FIELDMEM))
                  )
                 )
                 ;;Otherwise exit with a message.
                 (T
                  (ALERT
                    (PRINC
                      (STRCAT
                        "\nFatal error: Missing field\n"
                        (CAR FIELD)
                        ": "
                        (CDR FIELD)
                      )
                    )
                  )
                  (EXIT)
                 )
               )
             )
            (WIKI-LI:GETVAR "Fields")
          )
       )
       ;;Add field names to front of observation list
       (SETQ OBSERVATIONS (CONS FIELDS OBSERVATIONS))
       (SETQ FIELDNAMESAREDONE T)
       (PRINC "\nReading data file...")
       (PRINC)
      )
      ;;Else for all other lines
      (T
       ;;(SETQ PARSINGTIMER (GETVAR "date"))
       (SETQ
         THISOBSERVATION
          ;;Parse the line into fields
          (WIKI-STRTOLST
            RDLIN
            FIELDDELIMITER
            TEXTDELIMITER
            ;;Empty fields do count.  We aren't allowing white-space delimited files.
            T
          )
       )
       ;|
       (SETQ
         PARSINGTIME
          (+ (COND
               (PARSINGTIME)
               (0)
             )
             (- (GETVAR "date") PARSINGTIMER)
          )
       )|;
       ;;Add block to list
       (SETQ
         OBSERVATIONS
          (CONS THISOBSERVATION OBSERVATIONS)
         THISOBSERVATION NIL
       )
      )
    )
  )
  (SETQ F1 (CLOSE F1))
  ;|
  (PRINC
    (STRCAT
      "\nTime spent parsing = "
      (RTOS (* 86400 parsingtime) 2 2)
      " seconds"
    )
  )
  (setq parsingtime nil)
  |;
  (REVERSE OBSERVATIONS)
)


(DEFUN
   WIKI-LI:MAKELAYER (LAYERLIST)
  (IF LAYERLIST
    (COMMAND
      "._layer"
      "_thaw"
      (CAR LAYERLIST)
      "_make"
      (CAR LAYERLIST)
      "_on"
      ""
      "_color"
      (CADR LAYERLIST)
      ""
      ""
    )
  )
)

(DEFUN
   WIKI-LI:PROCESSOBSERVATIONS (OBSERVATIONS / ACTIONS BLOCKLIST
                                CODE COORDSYS FIELDNAMES LASTLIN MODELSPACEOBJECT n OBSERVATION RDLIN
                               )
  (SETQ
    ;;Initialize variable for readability.
    FIELDDELIMITER
     (WIKI-LI:GETVAR "File.Input.FieldDelimiterWC")
    TEXTDELIMITER
     (WIKI-LI:GETVAR "File.Input.TextDelimiter")
    COMMENTPREFIX
     (WIKI-LI:GETVAR "File.Input.CommentPrefix")
	MODELSPACEOBJECT
	 (VLA-GET-MODELSPACE
	   (VLA-GET-ACTIVEDOCUMENT (VLAX-GET-ACAD-OBJECT))
	 )
	
    F1
     (OPEN (WIKI-LI:GETVAR "File.Output.Name") "r")
  )
  ;;Read through output file looking for last segment entry.
  (WHILE (AND F1 (SETQ RDLIN (READ-LINE F1)))
    (COND
      ((AND
         (NOT
           (WCMATCH
             (SUBSTR RDLIN 1 1)
             (WIKI-LI:GETVAR "File.Input.CommentPrefix")
           )
         )
         (/= RDLIN "")
       )
       (SETQ LASTLIN RDLIN)
      )
    )
  )
  (if f1 (SETQ F1 (CLOSE F1)))
  ;;Get last segment name from last file entry.
  (COND
    (LASTLIN
     (SETQ
       LASTSEGMENT
        (CAR
          (WIKI-STRTOLST
            LASTLIN
            FIELDDELIMITER
            TEXTDELIMITER
            ;;Empty fields do count.  We aren't allowing white-space delimited files.
            T
          )
        )
     )
    )
  )
  (SETQ FIELDNAMES (CAR OBSERVATIONS) observations (cdr observations) n (CDR (ASSOC "SegmentID" FIELDNAMES)))
  (COND
    (LASTSEGMENT
     ;;Skip to last segment in observation file
     (WHILE (/= LASTSEGMENT (NTH N (CAR OBSERVATIONS)))
       (SETQ OBSERVATIONS (CDR OBSERVATIONS))
     )
     ;;Skip to next segment in observation file
     (WHILE (= LASTSEGMENT (NTH N (CAR OBSERVATIONS)))
       (SETQ OBSERVATIONS (CDR OBSERVATIONS))
     )
    )
  )
  (SETQ F2 (OPEN (WIKI-LI:GETVAR "File.Output.Name") "a"))
  (WRITE-LINE
    (STRCAT
      "# The following coordinates were added starting at "
      (RTOS (GETVAR "cdate") 2 6)
    )
    F2
  )
  (COMMAND "._undo" "_group")
  (WIKI-LI:VSAVE '("attreq" "cmdecho"))
  (SETVAR "attreq" 0)
  (SETVAR "cmdecho" 1)
  (FOREACH
     OBSERVATION OBSERVATIONS
    (SETQ CODE (NTH (CDR (ASSOC "Code" FIELDNAMES)) OBSERVATION))
    (SETQ
      ACTIONS
       (COND
         ((CDR (ASSOC CODE (WIKI-LI:GETVAR "CodeActions"))))
         ((CDR (ASSOC "DEFAULT" (WIKI-LI:GETVAR "CodeActions"))))
       )
    )
    ;;The order of these actions is important
    ;;Finish up any old block first
    (COND
      ((= FLAGENDBLOCK (LOGAND FLAGENDBLOCK ACTIONS))
       (WIKI-LI:ENDBLOCK)
      )
    )
    ;;Then set up a coordinate system
    (COND
      ((= FLAGSETCOORDSYS (LOGAND FLAGSETCOORDSYS ACTIONS))
       (WIKI-LI:SETCOORDSYS)
      )
    )
    ;;Start new pending block before adding any values
    (COND
      ((= FLAGSTARTBLOCK (LOGAND FLAGSTARTBLOCK ACTIONS))
       (WIKI-LI:STARTBLOCK)
      )
    )
    ;;Then add any values to the pending block
    (COND
      ((= FLAGSETLATDIR (LOGAND FLAGSETLATDIR ACTIONS))
       (WIKI-LI:SETLATDIR)
      )
    )
    (COND
      ((= FLAGSETACTIVE (LOGAND FLAGSETACTIVE ACTIONS))
       (WIKI-LI:SETACTIVE)
      )
    )
    (COND
      ((= FLAGSETINACTIVE (LOGAND FLAGSETINACTIVE ACTIONS))
       (WIKI-LI:SETINACTIVE)
      )
    )
    (COND
      ((= FLAGADDDESCRIPTION (LOGAND FLAGADDDESCRIPTION ACTIONS))
       (WIKI-LI:ADDDESCRIPTION)
      )
    )
    (COND
      ((= FLAGADDSEVERITY (LOGAND FLAGADDSEVERITY ACTIONS))
       (WIKI-LI:ADDSEVERITY)
      )
    )
  )
  ;;Finish up any remaining block
  (WIKI-LI:ENDBLOCK)
  (SETQ F2 (CLOSE F2))
  (WIKI-LI:VRSTOR)
  (COMMAND "._undo" "_end")
)


;;Insert any pending old block.  Reset all block values.
(DEFUN
   WIKI-LI:ENDBLOCK ()
  (IF BLOCKLIST
    (WIKI-LI:INSERTBLOCK)
  )
  (SETQ BLOCKLIST NIL)
)
;;Reset all block values to start a new one.
(DEFUN WIKI-LI:STARTBLOCK () (WIKI-LI:FRESHBLOCK))
(DEFUN
   WIKI-LI:SETCOORDSYS (/ PTDOWN PTUP SEGMENTID DMANHOLEID UMANHOLEID)
  (SETQ
    SEGMENTID
     (NTH (CDR (ASSOC "SegmentID" FIELDNAMES)) OBSERVATION)
    DMANHOLEID
     (NTH (CDR (ASSOC "DManholeID" FIELDNAMES)) OBSERVATION)
    UMANHOLEID
     (NTH (CDR (ASSOC "UManholeID" FIELDNAMES)) OBSERVATION)
    PTDOWN
     (GETPOINT
       (STRCAT
         "\nFor segment " SEGMENTID " inspection, specify downstream point at "
         DMANHOLEID ": "
        )
     )
  )
  (COND
    (PTDOWN
     (SETQ
       PTUP
        (GETPOINT
          PTDOWN
          (STRCAT " Specify upstream point at " UMANHOLEID ": ")
        )
     )
    )
    (T
     (EXIT)
    )
  )
  (SETQ
    COORDSYS
     (IF (= (NTH (CDR (ASSOC "Direction" FIELDNAMES)) OBSERVATION)
            (WIKI-LI:GETVAR "Field.Direction.Up")
         )
       (LIST PTDOWN (ANGLE PTDOWN PTUP) (DISTANCE PTDOWN PTUP))
       (LIST PTUP (ANGLE PTUP PTDOWN) (DISTANCE PTUP PTDOWN))
     )
  )
  ;;Log points to file
  (IF F2
    (WRITE-LINE
      (STRCAT
        "\""
        SEGMENTID
        "\",\""
        DMANHOLEID
        "\","
        (RTOS (CAR PTDOWN) 2 3)
        ","
        (RTOS (CADR PTDOWN) 2 3)
        ",\""
        UMANHOLEID
        "\","
        (RTOS (CAR PTUP) 2 3)
        ","
        (RTOS (CADR PTUP) 2 3)
      )
      F2
    )
  )
)
(DEFUN
   WIKI-LI:SETLATDIR (/ CLOCK)
  (SETQ CLOCK (ATOF (NTH (CDR (ASSOC "Clock" FIELDNAMES)) OBSERVATION)))
  (COND
    ((< 6 CLOCK 12)
     (WIKI-LI:SETBLOCKVALUE "Scale" '(1.0 -1.0 1.0))
    )
  )
)
(DEFUN
   WIKI-LI:SETACTIVE ()
  (WIKI-LI:SETBLOCKVALUE "ActiveStatus" "Active")
)
(DEFUN
   WIKI-LI:SETINACTIVE ()
  (WIKI-LI:SETBLOCKVALUE "ActiveStatus" "Not active")
)
(DEFUN
   WIKI-LI:ADDDESCRIPTION (/ KEY)
  (SETQ KEY "Description")
  (WIKI-LI:SETBLOCKVALUE
    KEY
    (STRCAT
      (CDR (ASSOC KEY BLOCKLIST))
      (NTH (CDR (ASSOC KEY FIELDNAMES)) OBSERVATION)
      " "
    )
  )
)
;;Adds value in the Severity field to the block's Description attribute
(DEFUN
   WIKI-LI:ADDSEVERITY (/ KEY SEVERITY)
  (SETQ
    KEY      "Description"
    SEVERITY (NTH (CDR (ASSOC "Severity" FIELDNAMES)) OBSERVATION)
  )
  (COND
    ((/= SEVERITY "")
     (WIKI-LI:SETBLOCKVALUE
       KEY
       (STRCAT (CDR (ASSOC KEY BLOCKLIST)) "(" SEVERITY ")" " ")
     )
    )
  )
)


(DEFUN
   WIKI-LI:FRESHBLOCK (/ OBSERVDIST)
  (SETQ
    BLOCKLIST
     (LIST
       (CONS
         "Name"
         (CDR (ASSOC CODE (WIKI-LI:GETVAR "BlockNames")))
       )
       (CONS
         "Distance"
         (ATOF (NTH (CDR (ASSOC "Distance" FIELDNAMES)) OBSERVATION))
       )
       (CONS "Description" "")
       (CONS "ActiveStatus" "")
       (LIST "Scale" 1.0 1.0 1.0)
     )
  )
)
(DEFUN
   WIKI-LI:SETBLOCKVALUE (KEY VALUE /)
  (SETQ BLOCKLIST (SUBST (CONS KEY VALUE) (ASSOC KEY BLOCKLIST) BLOCKLIST))
)


;;Uses semi-global variables BLOCKLIST, FIELDNAMES, OBSERVATION, COORDSYS
(DEFUN
   WIKI-LI:INSERTBLOCK (/ AT AV EL EN ET I N NLAYER TIMEMARKER TIMEINSERTING
                        TIMEENTMODING
                       )
  ;;Insert the block
  (VL-LOAD-COM)
  (IF (VL-CATCH-ALL-ERROR-P
        (VL-CATCH-ALL-APPLY
          (FUNCTION
            (LAMBDA ()
              (SETQ
                BLK
                 (VLA-INSERTBLOCK
				   MODELSPACEOBJECT
                   (VLAX-3D-POINT
                     (POLAR
                       (CAR COORDSYS)
                       (CADR COORDSYS)
                       (CDR (ASSOC "Distance" BLOCKLIST))
                     )
                   )
                   (CDR (ASSOC "Name" BLOCKLIST))
                   (CADR (ASSOC "Scale" BLOCKLIST))
                   (CADDR (ASSOC "Scale" BLOCKLIST))
                   (CADDDR (ASSOC "Scale" BLOCKLIST))
                   (CADR COORDSYS)
                 )
              )
            )
          )
        )
      )
    NIL
    (IF (EQ :VLAX-TRUE (VLA-GET-HASATTRIBUTES BLK))
      (FOREACH
         ATT (VLAX-SAFEARRAY->LIST
               (VLAX-VARIANT-VALUE (VLA-GETATTRIBUTES BLK))
             )
        (SETQ AT (VLA-GET-TAGSTRING ATT))
        (COND
          ((OR (AND
                 (= AT (WIKI-LI:GETVAR "AttributeTag.Description"))
                 (SETQ AV (CDR (ASSOC "Description" BLOCKLIST)))
               )
               (AND
                 (= AT (WIKI-LI:GETVAR "AttributeTag.ActiveStatus"))
                 (SETQ AV (CDR (ASSOC "ActiveStatus" BLOCKLIST)))
               )
           )
           ;;Then modify the attribute.
           (VLA-PUT-TEXTSTRING ATT AV)
          )
        )
      )
    )
  )
)

(DEFUN
   WIKI-LI:GETDNPATH (/ DNPATH)
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

;;;
;;; Include wiki functions
;;;
;| Start AutoLISP comment mode to wiki transclude sub functions

;| WIKI-GETSTRINGX
   Extended (getstring) with default value and drawing text selection
   Three modes:
   1. If a default or initial value is supplied, GETSTRINGX prompts with it
   2. If no default is supplied and MODE is 0, the first prompt is for standard input, with fallback to selecting value from drawing text.
   3. If no default is supplied and MODE is 1, the first prompt is for drawing text selection, with fallback to standard input.
   Returns a STR, empty if drawing text selection fails.
   Returns the arc sine of a number
   Edit the source code for this function at 

  Getstringx (AutoLISP function)

|;

(DEFUN
   WIKI-GETSTRINGX (GX-CR GX-PROMPT GX-DEFAULTVALUE GX-INITIALVALUE
                    GX-PROMPTMODE / GX-RESPONSE
                   )
  (SETQ
    GX-DEFAULTVALUE
     (COND
       (GX-DEFAULTVALUE)
       (GX-INITIALVALUE)
     )
  )
  ;;First prompt
  (COND
    ;;If a non-empty default value was supplied, prompt with it.
    ((/= GX-DEFAULTVALUE "")
     (SETQ
       GX-RESPONSE
        (GETSTRING
          GX-CR
          (STRCAT "\n" GX-PROMPT " <" GX-DEFAULTVALUE ">: ")
        )
     )
    )
    ;;Else if mode is 0, prompt for standard input
    ((= GX-PROMPTMODE 0)
     (SETQ
       GX-RESPONSE
        (GETSTRING
          GX-CR
          (STRCAT "\n" GX-PROMPT " or <Select from drawing>: ")
        )
     )
    )
    ;;Else if mode is 1, prompt for object select
    ((= GX-PROMPTMODE 1)
     (SETQ
       GX-RESPONSE
        (NENTSEL
          (STRCAT
            "\nSelect object with "
            GX-PROMPT
            " or <enter manually>: "
          )
        )
     )
    )
  )
  ;;Second prompt if necessary
  (COND
    ;;If
    ((AND
       ;;no response
       (= GX-RESPONSE "")
       ;;and there's a default value,
       GX-DEFAULTVALUE
     )
     ;;No second prompt
     NIL
    )
    ;;Else if
    ((AND
       ;;no response
       (= GX-RESPONSE "")
       ;;and mode is 0,
       (= GX-PROMPTMODE 0)
     )
     ;;Prompt for object select
     (SETQ
       GX-RESPONSE
        (NENTSEL (STRCAT "\nSelect object with " GX-PROMPT ": "))
     )
    )
    ;;Else if
    ((AND
       ;; no response
       (= GX-RESPONSE "")
       ;;and mode is 1,
       (= GX-PROMPTMODE 1)
     )
     ;;Prompt for standard input
     (SETQ GX-RESPONSE (GETSTRING GX-CR (STRCAT "\n" GX-PROMPT ": ")))
    )
  )
  ;;Return the string if provided
  (COND
    ;;If there was a (nentsel) prompt that failed (probably because user picked empty space)
    ((NOT GX-RESPONSE)
     ;;Print a warning and exit/abort
     (PRINC
       "\nError: No text object was selected.  Can't continue."
     )
     (EXIT)
    )
    ;;Else if the user hit return,
    ((= GX-RESPONSE "")
     ;;then return the default
     GX-DEFAULTVALUE
    )
    ;;Else if response isn't empty (the user didnt hit return)
    ((/= GX-RESPONSE "")
     ;;Then return the response
     GX-RESPONSE
    )
    ;;Else if there is a response, it is an (nentsel).  Convert to string
    (GX-RESPONSE (CDR (ASSOC 1 (ENTGET (CAR GX-RESPONSE)))))
  )
)

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
   WIKI-STRTOLST (INPUTSTRING FIELDSEPARATORWC TEXTDELIMITER EMPTYFIELDSDOCOUNT
                  / CHARACTERCOUNTER CONVERSIONISDONE CURRENTCHARACTER
                  CURRENTFIELD CURRENTFIELDISDONE FIRSTCHARACTERINDEX
                  PREVIOUSCHARACTER RETURNLIST TEXTMODEISON
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
      ((wcmatch CURRENTCHARACTER FIELDSEPARATORWC)
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
               (not (wcmatch PREVIOUSCHARACTER FIELDSEPARATORWC))
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

;; End AutoLISP comment mode if on |;

(PRINC "Laterals importer loaded.  Type LATERIN to run.")
(PRINC)
 ;|«Visual LISP© Format Options»
(80 2 40 2 nil "end of " 60 2 2 2 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;


