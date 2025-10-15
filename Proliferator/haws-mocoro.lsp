;;; Specialized Move, Copy, and Rotate command
;;; Good for proliferating a selection set throughout a population of variously rotated blocks or locations.
;;;
;;; Moves a selection set (A). Then puts a copy (B) at the original location. Then rotates the selection set (A).
;;; Prompts for selection set, base point and base rotation, and repetitive destination point and rotation.
(princ "\nhaws-mocoro proliferator loaded. Type haws-mocoro or cccc to run it.")
(defun c:cccc () (c:haws-mocoro))
(defun
   c:haws-mocoro (/)
  (princ "\nHaws-MoCoRo: assumes current rotation input units are in degrees")
  (vl-cmdf "._undo" "_g")
  (haws-mocoro-main)
  (vl-cmdf "._undo" "_e")
  (princ)
)

(defun
   haws-mocoro-main (/ source-data)
  (setq source-data (haws-mocoro-get-source-data))
  (while (setq source-data (haws-mocoro-do-destination source-data)))
)
(defun
   haws-mocoro-get-source-data
   (/ basept baserot source-data ss-source)
  (princ "\nSelect source objects...")
  (setq
    ss-source
     (ssget)
    basept
     (getpoint "\nSpecify base point: ")
    baserot
     (getangle basept "\nSpecify base rotation:")
    source-data
     (list ss-source basept baserot)
  )
)
(defun
   haws-mocoro-do-destination (source-data / destpt destrot input1)
  (initget "Selection")
  (setq
    input1
     (getpoint
       "\nSpecify destination point or [Selection set]: "
     )
  )
  (cond
    ((not input1) nil)
    ((= input1 "Selection")
     (haws-mocoro-do-selection source-data)
    )
    (t
     (setq
       source-data
        (haws-mocoro-do-point source-data input1)
     )
    )
  )
)
(defun
   haws-mocoro-do-selection
   (source-data / eg en destpt destrot i ss-dest)
  (princ "\nSelect target objects: ")
  (setq
    ss-dest
     (ssget)
    i -1
    j 0
  )
  (while (setq en (ssname ss-dest (setq i (1+ i))))
    (setq
      eg (entget en)
      destpt
       (cond
         ;; Justification point
         ((wcmatch (cdr (assoc 0 eg)) "*TEXT")
          (cdr (assoc 11 eg))
         )
         ((= (cdr (assoc 0 eg)) "POLYLINE")
          (cdr (assoc 10 (entget (entnext en))))
         )
         ;; Start/insertion point
         (t (cdr (assoc 10 eg)))
       )
      destrot
       (cond
         ((not destpt) nil)
         ;; For blocks, arcs, etc.
         ((cdr (assoc 50 eg)))
         ;; For lines.
         ((assoc 11 eg) (angle destpt (cdr (assoc 11 eg))))
         ((= (cdr (assoc 0 eg)) "POLYLINE")
          (angle
            destpt
            (cdr (assoc 10 (entget (entnext (entnext en)))))
          )
         )
         ;; For lwplines.
         ((= (cdr (assoc 0 eg)) "LWPOLYLINE")
          (angle
            destpt
            (cdr (assoc 10 (cdr (member (assoc 10 eg) eg))))
          )
         )
       )
    )
    (cond
      ((and destpt destrot)
       (setq
         source-data (haws-mocoro-core source-data destpt destrot)
         j (1+ j)
       )
      )
    )
  )
  (princ (strcat "\nCopied to " (itoa j) " objects. " (itoa (- (sslength ss-dest) j)) " objects were ignored."))
  source-data
)
(defun
   haws-mocoro-do-point
   (source-data input1 / basept baserot destpt destrot)
  (setq
    destpt input1
    destrot
     (getangle destpt "\nSpecify destination rotation:")
  )
  (setq source-data (haws-mocoro-core source-data destpt destrot))
)
(defun
   haws-mocoro-core
   (source-data destpt destrot / basept baserot ss-source)
  (setq
    ss-source
     (car source-data)
    basept
     (cadr source-data)
    baserot
     (caddr source-data)
  )
  (vl-cmdf "._move" ss-source "" basept destpt)
  (vl-cmdf "._copy" ss-source "" destpt basept)
  (vl-cmdf
    "._rotate"
    ss-source
    ""
    destpt
    (* 180 (/ (- destrot baserot) pi))
  )
  (setq source-data (list ss-source destpt destrot))
)

 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 1 1 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;