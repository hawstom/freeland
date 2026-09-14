;;; turn-tests.lsp - Unattended test harness for Turning Path Tracker
;;; Loaded by turn-tests.scr BEFORE turn itself, so that the alert override below
;;; is in place before any TURN code can raise a modal dialog.
;;;
;;; Everything here is test scaffolding. None of it ships to users.
(vl-load-com)
(setq
  ;; *tt-dir* is already set by turn-dev-paths.lsp, which every .scr loads first.
  *tt-log* (strcat *tt-dir* "turn-test-log.md")
  *tt-pass* 0
  *tt-fail* 0
)
;;; ---------------------------------------------------------------------------
;;; Logging
;;; ---------------------------------------------------------------------------
(defun tt-write (s / f)
  (setq f (open *tt-log* "a"))
  (write-line s f)
  (close f)
  (princ)
)
(defun tt-start (title / f)
  (setq f (open *tt-log* "w"))
  (close f)
  (setq *tt-pass* 0 *tt-fail* 0)
  (tt-write (strcat "# " title))
  (tt-write "")
  (tt-write (strcat "Run at CDATE " (rtos (getvar "cdate") 2 6)))
  (tt-write (strcat "AutoCAD " (getvar "acadver") " product " (getvar "product")))
  (tt-write "")
)
(defun tt-section (title)
  (tt-write "")
  (tt-write (strcat "## " title))
  (tt-write "")
)
;; A timestamped checkpoint. Every tt-write opens, appends and closes, so the
;; log is on disk before the next line of script runs. If AutoCAD hangs, the
;; last mark says exactly how far it got and how long it took to get there.
(defun tt-mark (label)
  (tt-write
    (strcat "- [" (menucmd "M=$(edtime,$(getvar,date),HH:MM:SS)") "] " label)
  )
)
;;; ---------------------------------------------------------------------------
;;; Modal-dialog suppression. THIS IS THE KEY TO UNATTENDED TESTING.
;;; A modal dialog hangs a /b script forever, and 1.1.x raises three of them.
;;;
;;; Two mechanisms, and the difference matters:
;;;
;;; tt-capture-alerts sets TURN 2.0's own handler hook. That is the supported
;;; way: 2.0 calls wiki-turn-alert, never the built-in, so nothing outside TURN
;;; is affected. Use this for anything testing src/turn.lsp.
;;;
;;; tt-clobber-builtin-alert redefines the built-in subr outright. AutoLISP
;;; allows it, but it changes alert for every application sharing the session.
;;; It is only here because 1.1.x calls (alert) directly and cannot be asked
;;; nicely. Use it ONLY when driving a legacy snapshot.
;;; ---------------------------------------------------------------------------
(defun tt-log-alert (msg)
  (tt-write (strcat "- ALERT (captured): " (vl-princ-to-string msg)))
  (princ)
)
(defun tt-capture-alerts ()
  (setq *wiki-turn-alert-handler* 'tt-log-alert)
  (princ)
)
(defun tt-clobber-builtin-alert ()
  (eval '(defun alert (msg) (tt-log-alert msg)))
  (princ)
)
(defun *error* (msg)
  (setq *tt-fail* (1+ *tt-fail*))
  (tt-write (strcat "- **ERROR**: " (vl-princ-to-string msg)))
  (princ)
)
;;; ---------------------------------------------------------------------------
;;; Assertions
;;; ---------------------------------------------------------------------------
(defun tt-check (label ok)
  (if ok
    (setq *tt-pass* (1+ *tt-pass*))
    (setq *tt-fail* (1+ *tt-fail*))
  )
  (tt-write (strcat (if ok "- PASS " "- **FAIL** ") label))
  ok
)
(defun tt-equal (label expected actual)
  (tt-check
    (strcat label " (expected " (vl-princ-to-string expected) ", got " (vl-princ-to-string actual) ")")
    (equal expected actual)
  )
)
;;; ---------------------------------------------------------------------------
;;; Drawing inspection
;;; ---------------------------------------------------------------------------
;; All model-space entities, tallied by layer and entity type.
(defun tt-census (/ en el i key out rec ss)
  (setq
    ss (ssget "_X" '((410 . "Model")))
    i -1
  )
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (setq
        el (entget en)
        key (strcat (cdr (assoc 8 el)) " | " (cdr (assoc 0 el)))
        rec (assoc key out)
        out (if rec
              (subst (cons key (1+ (cdr rec))) rec out)
              (cons (cons key 1) out)
            )
      )
    )
  )
  (vl-sort out '(lambda (a b) (< (car a) (car b))))
)
(defun tt-report-census (/ r)
  (tt-section "Model space census")
  (tt-write "| Layer | Type | Count |")
  (tt-write "|---|---|---|")
  (foreach r (tt-census)
    (tt-write (strcat "| " (car r) " | " (itoa (cdr r)) " |"))
  )
)
;; Does the DXF group 90 vertex count match the number of group 10 points
;; actually written? wiki-turn-initiate-path sets 90 to npathsegments but then
;; adds npathsegments+1 points. This audit settles whether AutoCAD cares.
(defun tt-report-plines (/ el en i lay n10 n90 rec ss out)
  (tt-section "LWPOLYLINE vertex audit (DXF 90 vs. actual group 10 count)")
  (setq
    ss (ssget "_X" '((0 . "LWPOLYLINE") (410 . "Model")))
    i -1
  )
  (if ss
    (while (setq en (ssname ss (setq i (1+ i))))
      (setq
        el (entget en)
        lay (cdr (assoc 8 el))
        n90 (cdr (assoc 90 el))
        n10 (length (vl-remove-if-not '(lambda (x) (= 10 (car x))) el))
        rec (assoc lay out)
      )
      (setq
        out (if rec
              (subst (list lay (1+ (cadr rec)) (cons (cons n90 n10) (caddr rec))) rec out)
              (cons (list lay 1 (list (cons n90 n10))) out)
            )
      )
    )
  )
  (tt-write "| Layer | Plines | (DXF 90 . actual) pairs seen |")
  (tt-write "|---|---|---|")
  (foreach rec (vl-sort out '(lambda (a b) (< (car a) (car b))))
    (tt-write
      (strcat
        "| " (car rec)
        " | " (itoa (cadr rec))
        " | " (vl-princ-to-string (tt-unique (caddr rec)))
        " |"
      )
    )
  )
)
(defun tt-unique (lst / out)
  (foreach x lst (if (not (member x out)) (setq out (cons x out))))
  (reverse out)
)
;; How many entities sit on a given layer.
(defun tt-count-on-layer (lay / ss)
  (setq ss (ssget "_X" (list (cons 8 lay) '(410 . "Model"))))
  (if ss (sslength ss) 0)
)
;;; ---------------------------------------------------------------------------
;;; The expectations TURN should meet
;;; ---------------------------------------------------------------------------
(setq
  *tt-path-layers*
   '("C-TURN-TRCK-FRONT-LEFT-PATH" "C-TURN-TRCK-FRONT-RGHT-PATH"
     "C-TURN-TRCK-REAR-LEFT-PATH" "C-TURN-TRCK-REAR-RGHT-PATH"
    )
  *tt-trailer-layers*
   '("C-TURN-HTCH-PATH" "C-TURN-TRAL-REAR-LEFT-PATH" "C-TURN-TRAL-REAR-RGHT-PATH")
)
(defun tt-report-layers (/ lay)
  (tt-section "Layer creation")
  (foreach lay (append *tt-path-layers* *tt-trailer-layers* '("C-TURN-TRCK-BODY" "C-TURN-TRAL-BODY"))
    (tt-check (strcat "layer exists: " lay) (if (tblsearch "layer" lay) T nil))
  )
)
(defun tt-report-paths (trailer-p / lay)
  (tt-section "Tire path polylines drawn")
  (foreach lay *tt-path-layers*
    (tt-equal (strcat "plines on " lay) 1 (tt-count-on-layer lay))
  )
  (if trailer-p
    (foreach lay *tt-trailer-layers*
      (tt-equal (strcat "plines on " lay) 1 (tt-count-on-layer lay))
    )
  )
  (tt-check
    "vehicle body boxes were drawn"
    (< 0 (tt-count-on-layer "C-TURN-TRCK-BODY"))
  )
)
;;; ---------------------------------------------------------------------------
;;; Run control
;;; ---------------------------------------------------------------------------
(defun tt-finish (dwg-out)
  (tt-section "Summary")
  (tt-write (strcat "- passed: " (itoa *tt-pass*)))
  (tt-write (strcat "- failed: " (itoa *tt-fail*)))
  (tt-write "")
  (tt-write (if (zerop *tt-fail*) "**ALL CHECKS PASSED**" "**THERE ARE FAILURES**"))
  ;; ALWAYS leave the drawing saved, even when the caller wants no output file.
  ;;
  ;; A modified drawing makes QUIT ask "Save changes?", and with FILEDIA 0 that
  ;; is a command line prompt the script has to answer. Answering it is the
  ;; fragile part: "y" then wants a filename and parks there forever, which is
  ;; exactly how a run was found still sitting at an unanswered quit. A saved
  ;; drawing makes QUIT exit silently, so there is no prompt to get wrong.
  ;;
  ;; The trailing "quit / n" in each .scr is now only a backstop for the case
  ;; where a LISP error aborts the script before this runs.
  (setq dwg-out (if dwg-out dwg-out (strcat *tt-dir* "turn-scratch.dwg")))
  (vl-file-delete dwg-out)
  (command "._qsave" dwg-out)
  (princ)
)
(princ "\nturn-tests.lsp loaded.")
(princ)
