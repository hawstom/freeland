;;; turn-probe-pedit-close.lsp - does PEDIT Join close a loop, and what does
;;; PEDIT Close leave behind?
;;;
;;; turn.lsp once rebuilt each joined loop with entmake instead of using PEDIT
;;; Close, on the unmeasured claim that Close over coincident ends leaves a
;;; zero-length segment. Tom asked why not just Join then Close. This measured
;;; it: Join closed every loop by itself, so the rebuild was removed.
;;;
;;; Run:  devtools\turn-tests.bat turn-probe-pedit-close
;;;
;;; A probe. Never ships.

(defun turn-probe-pc-describe (label en / el pts shortest)
  (setq
    el (entget en)
    pts (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= 10 (car x))) el))
  )
  (foreach seg (mapcar 'list pts (append (cdr pts) (list (car pts))))
    (if (or (null shortest) (< (distance (car seg) (cadr seg)) shortest))
      (setq shortest (distance (car seg) (cadr seg)))
    )
  )
  (turn-test-write
    (strcat "- " label ": " (cdr (assoc 0 el))
            ", closed flag " (if (= 1 (logand 1 (cdr (assoc 70 el)))) "ON" "off")
            ", " (itoa (length pts)) " vertices"
            ", first-to-last " (rtos (distance (car pts) (last pts)) 2 6)
            ", shortest segment (closure included) " (rtos shortest 2 6)))
)

(defun turn-probe-pc-case (label points / en marker ss)
  (turn-test-section label)
  (if (setq ss (ssget "_X" '((8 . "C-TURN-*")))) (command "._erase" ss ""))
  (setvar "clayer" (turn-layer nil "ENVL"))
  (setq marker (entlast))
  (turn-draw-region points (turn-layer nil "ENVL"))
  (foreach en (turn-entities-after marker) (command "._explode" en))
  (turn-test-write (strcat "- exploded into " (itoa (length (turn-entities-after marker))) " pieces"))
  (command "._pedit" "_multiple" (turn-selection (turn-entities-after marker)) "" "_join" 0.0 "")
  (setq en (car (turn-entities-after marker)))
  (turn-test-write (strcat "- join gave " (itoa (length (turn-entities-after marker))) " object(s)"))
  (turn-probe-pc-describe "after Join" en)
  ;; On a closed polyline the option is Open, not Close, so ask only when open.
  (if (zerop (logand 1 (cdr (assoc 70 (entget en)))))
    (progn
      (command "._pedit" en "_close" "")
      (turn-probe-pc-describe "after Close" en)
    )
  )
)

(defun turn-probe-pc-run ()
  (turn-make-vehicle-layers)
  (setvar "peditaccept" 1)
  (turn-probe-pc-case "Square" '((0.0 0.0) (10.0 0.0) (10.0 10.0) (0.0 10.0)))
  (turn-probe-pc-case "Seven-sided, uneven"
    '((0.0 0.0) (13.0 1.0) (17.0 6.0) (14.0 12.0) (6.0 14.0) (-2.0 9.0) (-3.0 4.0)))
)

;; On real envelopes: does every joined loop come back closed? (It did, on
;; 2026-09-26, which is why turn.lsp stopped rebuilding loops itself.)
(defun turn-probe-pc-envelopes ()
  (turn-test-section "Real envelopes")
  (foreach step '(2.4 1.2 0.6)
    (turn-test-envelope-clear)
    (turn-test-write (strcat "- WB-67 corner, step " (rtos step 2 1)))
    (turn-draw-envelope (turn-test-envelope-rig)
                        (turn-path (turn-test-envelope-rig)
                                   (turn-course-from-curve (turn-test-envelope-corner-course) '(0.0 0.0) step) pi))
    (foreach en (turn-test-envelope-loops) (turn-probe-pc-describe "  loop" en))
  )
  (turn-test-envelope-clear)
  (turn-test-write "- flatbed, starting backwards")
  (turn-draw-envelope (turn-test-envelope-narrow-rig)
                      (turn-path (turn-test-envelope-narrow-rig)
                                 (turn-course-from-curve (turn-test-envelope-corner-course) '(0.0 0.0) 2.2) 0.0))
  (foreach en (turn-test-envelope-loops) (turn-probe-pc-describe "  loop" en))
)
