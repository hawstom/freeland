;;; Civil 3D Subdivision Tools
;;; Version: 2025-08-28 TGH Not yet in Git version control
;;; Haws is a registered reserved symbol with Autodesk that will never conflict with other apps.
;;;
;;; Features:
;;; -Saves to (setcfg) to remember settings between sessions.  Saves to a single global variable during a session.
;;; -For programmers, demonstrates small functions with self-documenting names and variable names.  Also demonstrates settings management.

;; Customizable out-of-the-box defaults you can edit are at very end of file

;;; Specialized Move, Copy, and Rotate command
;;; Moves a selection set (A). Then puts a copy (B) at the original location. Then rotates the selection set (A).
;;; Prompts for selection set, base point and base rotation, and repetitive destination point and rotation.
(defun c:cccc () (c:haws-mocoro))
(defun
   c:haws-mocoro (/ basept baserot destpt destrot ss1)
  (setq
    ss1
     (ssget)
    basept
     (getpoint
       "\nSpecify base point (midpoint or endpoint of front of pad): "
     )
    baserot
     (getangle
       basept
       "\nSpecify base rotation (midpoint or endpoint of back of pad):"
     )
  )
  (while (setq destpt (getpoint "\nSpecify destination point: "))
    (setq destrot (getangle destpt "\nSpecify destination rotation:"))
    (command "._move" ss1 "" basept destpt)
    (command "._copy" ss1 "" destpt basept)
    (command
      "._rotate"
      ss1
      ""
      destpt
      (* 180 (/ (- destrot baserot) pi))
    )
    (setq
      basept destpt
      baserot destrot
    )
  )
  (princ)
)
;;; Pad Elevate (PE) application
;;; Command aliases:
;;; ppp = PadElevate Sets a running row of pads by selecting alternately curb, pad, curb, pad, curb.
;;; pppp = PadElevateOptions
(defun c:pppp () (c:haws-sdt:padelevateoptions))
(defun c:speo () (c:haws-sdt:padelevateoptions))
(defun
   c:haws-sdt:padelevateoptions ()
  (haws-sdt:pe-options-main)
)

(defun c:ppp () (c:haws-sdt:padelevate))
(defun c:spe () (c:haws-sdt:padelevate))
(defun
   c:haws-sdt:padelevate ()
  (haws-core-init 1000)
  (haws-vsave '("osmode"))
  (haws-sdt:pe_main)
  (haws-core-restore)
  (haws-vrstor)
  (princ)
)
(defun
   haws-sdt:pe_main (/ continue-p espad ptc1 ptc2 zpad)
  (haws-sdt:initialize-settings)
  (setq continue-p t)
  (while continue-p
    (command "._undo" "_group")
    (setq ptc1 (haws-sdt:gettcelev ptc1 "1"))
    (cond
      (ptc1 (setq espad (haws-sdt:getpad "")))
      (t (setq continue-p nil))
    )
    (if espad
      (setq ptc2 (haws-sdt:gettcelev nil "2"))
    )
    (if ptc2
      (setq continue-p (haws-sdt:elevatepad ptc1 espad ptc2))
    )
    (setq ptc1 ptc2)
    (command "._undo" "_end")
  )
)
(defun
   haws-sdt:gettcelev (ptc istring / es tcelev)
  (cond
    ((not ptc)
     (setvar "osmode" 64)
     (setq
       ptc
        (getpoint
          (strcat
            "\nSelect TC Surface Elevation Label "
            istring
            " insertion point: "
          )
        )
     )
    )
  )
  (cond
    (ptc
     (princ
       (strcat "\nTC Elevation " istring " = " (rtos (last ptc) 2))
     )
    )
  )
  ptc
)
(defun
   haws-sdt:getpad (padspec / espad zpad)
  (princ (strcat "\nSelect " padspec "pad: "))
  (setq espad (entsel))
  espad
)
(defun
   haws-sdt:elevatepad (ptc1 espad ptc2 / zpad zpadnew zpadold)
  (cond
    ((and
       espad
       (setq zpadold (caddr (osnap (cadr espad) "_endp")))
       (setq zpadnew (haws-sdt:calcpad ptc1 zpadold ptc2))
     )
     (princ (strcat "\nOld pad elevation = " (rtos zpadold 2)))
     (princ (strcat "\nNew pad elevation = " (rtos zpadnew 2)))
     (command
       "._move"
       (car espad)
       ""
       "_none"
       (list 0.0 0.0 zpadold)
       "_none"
       (list 0.0 0.0 zpadnew)
     )
     t
    )
    (t nil)
  )
)
(defun
   haws-sdt:calcpad (ptc1 zpadold ptc2 / limit-lower limit-upper tc-high
                     tc-low tcslope
                    )
  (cond
    ((> (last ptc1) (last ptc2))
     (setq
       tc-high ptc1
       tc-low ptc2
     )
    )
    (t
     (setq
       tc-high ptc2
       tc-low ptc1
     )
    )
  )
  (setq
    tcslope
     (/ (- (last tc-high) (last tc-low)) (distance ptc1 ptc2))
    ;; The high curb has our lower limit.  This limits street slope.
    limit-lower
     (+ (- (last tc-high)
           (* tcslope (haws-sdt:getvar "HighDriveDist"))
        )
        (haws-sdt:getvar "HighCurbMinDiff")
     )
    ;; The low curb has our upper limit. This limits street slope.                                        
    limit-upper
     (+ (last tc-low)
        (* tcslope (haws-sdt:getvar "LowDriveDist"))
        (haws-sdt:getvar "LowCurbMaxDiff")
     )
  )
  (cond
    ((> limit-lower limit-upper)
     (alert
       (princ
         (strcat
           "\nConstraint violation:\nLower limit: "
           (rtos limit-lower 2 2)
           "\nUpper limit: "
           (rtos limit-upper 2 2)
           "\nCan't satisfy both based on low TC. Is street too steep?\nCalculated slope: "
           (rtos (* tcslope 100.0) 2 2)
           "%"
         )
       )
     )
     nil
    )
    ((/ (+ limit-upper
           limit-lower
           (* (haws-sdt:getvar "Bias") (- limit-upper limit-lower))
        )
        2.0
     )
    )
  )
)
(defun
   haws-sdt:pe-options-main (/ input-main)
  (haws-sdt:initialize-settings)
  (while (setq input-main (haws-sdt:pe-options-get-input-main))
    (haws-sdt:pe-options-do-input-main input-main)
  )
  (princ)
)
(defun
   haws-sdt:pe-options-get-input-main (/ input-main current-elevation)
  (haws-sdt:print-settings
    (list
      "HighCurbMinDiff" "LowCurbMaxDiff" "HighDriveDist" "LowDriveDist"
      "Bias"
     )
  )
  (initget "HT LT HD LD Bias")
  (getkword
    "\nEnter an option [HT: high tc diff/LT: low tc diff/HD: high driveway edge distance/LD: low driveway edge distance/Bias]: "
  )
)
(defun
   haws-sdt:pe-options-do-input-main (input-main /)
  (cond
    ((= input-main "HT")
     (haws-sdt:get-input-generic
       "HighCurbMinDiff"
       'getreal
       "\nSpecify minimum pad elevation relative to high TC (for back yard drainage): "
     )
    )
    ((= input-main "LT")
     (haws-sdt:get-input-generic
       "LowCurbMaxDiff"
       'getreal
       "\nSpecify maximum pad elevation relative to low TC (for driveway slope)"
     )
    )
    ((= input-main "HD")
     (haws-sdt:get-input-generic
       "HighDriveDist"
       'getreal
       "\nSpecify distance of high edge of driveway from high property line (or 0 to drain to curb at PL)"
     )
    )
    ((= input-main "LD")
     (haws-sdt:get-input-generic
       "LowDriveDist"
       'getreal
       "\nSpecify distance of low edge of driveway from low property line (or 0 to calculate from PL curb elevation)"
     )
    )
    ((= input-main "Bias")
     (haws-sdt:get-input-generic
       "Bias"
       'getreal
       "\nSpecify pad elevation adjustment bias where -1.0 uses lowest limit, 0.0 uses average, and 1.0 uses highest limit. Values outside (violating) the -1.0 to 1.0 limits are accepted"
     )
    )
  )
)
;;; Elevate low back feature line points
;;; Command aliases:
;;; bbbl = Back Elevate Low
;;; bbbb = Back Elevate Options
(defun c:bbbl () (haws-sdt:be-low))
(defun c:sbel () (haws-sdt:be-low))
(defun
   haws-sdt:be-low ()
  (haws-core-init 1000)
  (haws-vsave '("osmode"))
  (haws-sdt:be-low-main)
  (haws-core-restore)
  (haws-vrstor)
)
(defun
   haws-sdt:be-low-main (/ ptcontrol-high ptcontrol-low objfeature)
  (haws-sdt:initialize-settings)
  (princ "\nSelect a low side back feature line. ")
  (setq objfeature (haws-sdt:be-get-feature))
  (while (and
           objfeature
           (setq
             ptcontrol-high
              (haws-sdt:be-get-endpoint
                "a controlling high side point or <next feature line>"
              )
           )
         )
    (while (setq
             ptcontrol-low
              (haws-sdt:be-get-endpoint "an affected low side controlling point or <next high side controlling point>")
           )
      (haws-sdt:be-low-elevate-points
        objfeature
        ptcontrol-high
        ptcontrol-low
      )
    )
  )
  (princ)
)
(defun
   haws-sdt:be-get-feature (/ obj ss1)
  (setq ss1 (ssget ":s+." '((0 . "AECC_FEATURE_LINE"))))
  (cond
    (ss1 (setq obj (vlax-ename->vla-object (ssname ss1 0))))
    (t (princ "\nNo feature line selected.") nil)
  )
)
(defun
   haws-sdt:be-low-elevate-points
   (objfeature ptcontrol-high ptcontrol-low / pt1)
  (while (setq pt1 (haws-sdt:be-get-endpoint "the low side back feature line or <next low side controlling point>"))
    (haws-sdt:be-low-elevate-feature-point
      objfeature
      ptcontrol-high
      ptcontrol-low
      pt1
    )
  )
)
(defun
   haws-sdt:be-low-elevate-feature-point
   (objfeature ptcontrol-high ptcontrol-low pt1 / elev1 obj)
  (setq
    elev1
     (min
       (+ (caddr ptcontrol-high) (haws-sdt:getvar "BackDiffMin"))
       (+ (caddr ptcontrol-low) (haws-sdt:getvar "BackDiffMax"))
     )
  )
  (haws-sdt:be-elevate-feature-point objfeature pt1 elev1)
)
;;; Elevate high back feature line points
;;; Command aliases:
;;; bbbh = Back Elevate High
;;; bbbb = Back Elevate Options

(defun c:bbbh (/) (haws-sdt:be-high))
(defun c:sbeh (/) (haws-sdt:be-high))
(defun
   haws-sdt:be-high ()
  (haws-core-init 1000)
  (haws-vsave '("osmode"))
  (haws-sdt:be-high-main)
  (haws-core-restore)
  (haws-vrstor)
)
(defun
   haws-sdt:be-high-main (/ ptcontrol objfeature)
  (haws-sdt:initialize-settings)
  (princ "\nSelect high side back feature line. ")
  (setq objfeature (haws-sdt:be-get-feature))
  (while (setq ptcontrol (haws-sdt:be-get-endpoint "the high side controlling point or <next feature line>"))
    (haws-sdt:be-high-elevate-points objfeature ptcontrol)
  )
  (princ)
)
(defun
   haws-sdt:be-high-elevate-points (objfeature ptcontrol-high / pt1)
  (while (setq pt1 (haws-sdt:be-get-endpoint "the high side back feature line or <next high side controlling point>"))
    (haws-sdt:be-high-elevate-feature-point
      objfeature
      ptcontrol-high
      pt1
    )
  )
)
(defun
   haws-sdt:be-get-endpoint (target / pt1)
  (setvar "osmode" 1)
  (setq pt1 (getpoint (strcat "\nSpecify endpoint on " target ": ")))
  (cond (pt1 (princ (strcat "\nElevation = " (rtos (caddr pt1) 2 2)))))
  pt1
)
(defun
   haws-sdt:be-high-elevate-feature-point
   (objfeature ptcontrol-high pt1 / elev1 obj)
  (setq elev1 (+ (caddr ptcontrol-high) (haws-sdt:getvar "BackDiffMin")))
  (haws-sdt:be-elevate-feature-point objfeature pt1 elev1)
)
(defun
   haws-sdt:be-elevate-feature-point (objfeature pt1 elev1)
  (vlax-invoke-method
    objfeature
    'setpointelevation
    (vlax-3d-point (list (car pt1) (cadr pt1) elev1))
  )
)
(defun c:bbbb () (haws-sdt:be-options-main))
(defun c:sbeo () (haws-sdt:be-options-main))
(defun
   haws-sdt:be-options-main (/ input-main)
  (haws-sdt:initialize-settings)
  (while (setq input-main (haws-sdt:be-options-get-input-main))
    (haws-sdt:be-options-do-input-main input-main)
  )
  (princ)
)
(defun
   haws-sdt:be-options-get-input-main (/ input-main current-elevation)
  (haws-sdt:print-settings (list "BackDiffMin" "BackDiffMax"))
  (initget "MInimum MAximum")
  (getkword
    "\nEnter an option [MInimum back PL elevation/MAximum back PL elevation]: "
  )
)
(defun
   haws-sdt:be-options-do-input-main (input-main /)
  (cond
    ((= input-main "MInimum")
     (haws-sdt:get-input-generic
       "BackDiffMin"
       'getreal
       "\nSpecify minimum back property line elevation relative to controlling point"
     )
    )
    ((= input-main "MAximum")
     (haws-sdt:get-input-generic
       "BackDiffMax"
       'getreal
       "\nSpecify maximum back property line elevation relative to controlling point"
     )
    )
  )
)
;;; ============================================================================
;;; Settings stuff.  Last part of code; not fun to read for new project member.
;;; ============================================================================
;; Start with default settings and supplement with stored settings.
(defun
   haws-sdt:get-input-generic (var function-symbol prompt1 / input1)
  (setq
    input1
     (apply
       function-symbol
       (list
         (strcat
           "\n"
           prompt1
           " <"
           (haws-sdt:getvar-string var)
           ">: "
         )
       )
     )
  )
  (cond ((and input1 (/= input1 "")) (haws-sdt:setvar var input1)))
)
(defun
   haws-sdt:print-settings (print-list / setting)
  (princ "\nCurrent settings: ")
  (foreach
     setting print-list
    (princ setting)
    (princ "=")
    (princ (haws-sdt:getvar-string setting))
    (princ " ")
  )
)

(defun
   haws-sdt:initialize-settings (/ setting)
  (cond ((not *haws-sdt:settings*) (haws-sdt:get-default-settings)))
  (haws-sdt:get-stored-settings)
)

;; Define-Settings is at bottom of code for customization convenience.
(defun
   haws-sdt:get-default-settings ()
  (setq *haws-sdt:settings* (haws-sdt:define-settings))
)

;; Get settings from AutoCAD's AutoLISP permananent storage system
;; The setcfg/getcfg functions might be removed in a future release.
(defun
   haws-sdt:get-stored-settings (/ settings-definition valuei)
  (setq settings-definition (haws-sdt:define-settings))
  (cond
    ;; If stored settings location exists
    ((getcfg (strcat (haws-sdt:storage-location) "Dummy"))
     (foreach
        setting settings-definition
       (cond
         ;; If setting exists (even missing settings return "")
         ((/= ""
              (setq
                valuei
                 (getcfg
                   (strcat
                     (haws-sdt:storage-location)
                     (car setting)
                   )
                 )
              )
          )
          (haws-sdt:save-to-settings-list (car setting) valuei)
         )
       )
     )
    )
  )
)

(defun haws-sdt:storage-location () "Appdata/Haws/SDT/")

(defun
   haws-sdt:save-to-settings-list (var val)
  (setq
    *haws-sdt:settings*
     (subst
       (list var val (haws-sdt:getvar-type var))
       (assoc var *haws-sdt:settings*)
       *haws-sdt:settings*
     )
  )
)

(defun
   haws-sdt:getvar-string (var / val-string)
  (cadr (assoc var *haws-sdt:settings*))
)

(defun
   haws-sdt:getvar (var / val val-string var-type)
  (setq
    val-string
     (haws-sdt:getvar-string var)
    var-type
     (caddr (assoc var *haws-sdt:settings*))
    val
     (cond
       ((= var-type 'real) (distof val-string)) ; Returns nil for ""
       ((= var-type 'int) (atoi val-string))
       ((= var-type 'str) val-string)
     )
  )
)

(defun
   haws-sdt:getvar-type (var / val-string)
  (caddr (assoc var *haws-sdt:settings*))
)

(defun
   haws-sdt:setvar (var val / var-type)
  (setq var-type (haws-sdt:getvar-type var))
  (cond
    ((/= (type val) var-type)
     (alert
       (strcat
         "Warning in haws-sdt:SETVAR.\n\nVariable: "
         var
         "\nType expected: "
         (vl-prin1-to-string var-type)
         "\nType provided: "
         (vl-prin1-to-string (type val))
       )
     )
     (exit)
    )
  )
  (cond ((/= (type val) 'str) (setq val (vl-prin1-to-string val))))
  (haws-sdt:save-to-settings-list var val)
  (haws-sdt:save-to-storage var val)
  val
)

(defun
   haws-sdt:save-to-storage (var val)
  (setcfg (strcat (haws-sdt:storage-location) var) val)
)

;; Customizable out-of-the-box defaults.  You can edit these.
(defun
   haws-sdt:define-settings (/)
  (list
    ;; At runtime retrieval, each setting is converted 
    ;; from its storage as a string to the given data type.
    ;;    Name             Value Data_type
    (list "HighCurbMinDiff" "1" 'real)
    (list "LowCurbMaxDiff" "2" 'real)
    (list "HighDriveDist" "7" 'real)
    (list "LowDriveDist" "7" 'real)
    (list "Bias" "0.0" 'real)
    (list "BackDiffMin" "-0.1" 'real)
    (list "BackDiffMax" "0.1" 'real)
  )
)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 1 1 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;