# Handoff — Turning Path Tracker, 2026-09-14

`CLAUDE.md` holds the durable facts. This file is the perishable part: what just
happened, and what Tom is about to test.

## State in one paragraph

**The trunk is 2.1.0-dev and it is NOT published.** `hawsedc.com/gnu/` still serves
2.0.0, untouched, and `turn-release.py` refuses to publish anything whose version
carries a `-suffix`, so a work in progress cannot overwrite a good release. Everything
is committed and pushed on `main`. The punch list is closed. The whole test matrix is
green: **154 kernel, 55 punch list, 44 end to end, 30 curve, 7 release smoke**, on
Civil 3D 2026 and AutoCAD 2027, no errors, no leftover processes.

**What is waiting for you is hands on the wheel: `DRIVE`.**

---

## Testing DRIVE

Load the **trunk**, not the shipped copy:

    (load "C:/TGHFiles/programming/misclisp/freeland/Turning_Path_Tracker/turn.lsp")

Expect: `TURN 2.1.0-dev loaded. Type TURN, DRIVE or BV.`

Then:

1. **`BV`** — build a vehicle. A WB-67: body 27.92, width 8, overhang 4, wheelbase
   19.5, track 8, steering lock 30. Trailer: **Yes**, hitch 0, articulation 70,
   wheelbase 45.5, track 8.5, nose forward 3, body 53, width 8.5. Then **No**.
   (Or insert `Vehicle_Library/turn-wb-67.dwg` and use that.)
2. **`DRIVE`** — pick the block. It asks for the **start point of the front axle
   centre**, then the calculation step, then plot frequency.
3. **Move the cursor.** The rig steers toward it, as hard as the steering lock allows,
   and takes one step forward each time the cursor gets a step ahead of the front axle.
   Stop moving and it stops. Outlines accumulate as you go, so you watch the swept path
   build up.
4. **ENTER or SPACE** to finish. It then draws properly — tire paths, bodies, envelope —
   and reports, exactly as `TURN` does.

**What only you can judge**, because `grread` waits for a human and a harness is not one:

- Does steering with the cursor feel right, or should the cursor set a *heading* the
  rig holds rather than a point it chases?
- Are accumulating `grdraw` outlines what you want to see while driving, or would one
  rig plus a trailing centreline be better?
- Is one step per cursor event the right rate?
- The rig will not reverse. Acceptable for a first cut?

**Escape is safe.** The undo group opens only after the loop ends, so Esc aborts before
anything reaches the drawing. Leftover outlines clear with `REGEN`.

**Known and deliberate:** the cursor can be somewhere the rig cannot reach — inside its
own minimum turning circle — and it will then orbit rather than arrive. A WB-67 cannot
reach a point 40 ft abeam of itself. Driving *until* it arrives was the first version,
and it hung AutoCAD; one step per event makes termination structural.

---

## What changed since the last handoff

1. **One namespace prefix, `turn-`.** AutoLISP has a single global namespace and
   provides no namespacing, so we must. Nineteen prefixes became one; 313 functions.
   Test scaffolding is bound by the rule too — it loads into the same session. `wiki-`
   is retired except where a doc names a 1.1.17 function.
2. **`c:drive` and the drive kernel.** `turn-drive-path` returns the same shape as
   `turn-path`, so the envelope, findings and report work on a driven rig unchanged —
   proven, not assumed: **0.000000000000 disagreement across 482 states**.
3. **The punch list is closed**, ten items by automation and items 2 and 3 by your
   review. Prompts stand; 30/70 defaults stay.
4. **A release guard.** `-dev` in the version means `turn-release.py` publishes
   nothing, even with `--publish`.

## Defects found and fixed along the way

- **The harness leaked an AutoCAD process on every run** whose script reached `quit`
  with a dirty drawing. `quit`+`y` asked for a filename and parked; `quit`+`n` parked
  too. Leaving the drawing saved is what works.
- **Every log ended with a spurious `ERROR: Function cancelled`** — from
  `(command "._quit")` inside LISP. Gone; the `quit` is a script line now.
- **`TRUSTEDPATHS` grew by three entries every run**, which is what turned your Civil
  3D trusted locations into a mess. Paths are normalised and added only if absent.
- **Civil 3D crashes tearing down a COM-created `AECC_ALIGNMENT`.** The curve suite
  passed all 30 checks, then sat 19 minutes behind a window titled "AutoCAD Error
  Aborting". Alignments are erased once the assertions are done.
- **The rename silently broke the release smoke test**, which still printed PASS —
  once — with its summary line simply absent. It now resolves function names at run
  time and finds the published file by name.

## Still open, and on whom

### Tom
- **Drive it.** Above.
- **Kenya has not been replied to.** Draft ready and approved in substance:
  `user_help/Kenya_Caldwell/draft-reply-4.md`.
- **Rob Livingston** was emailed the REGION/UNION envelope approach. No reply yet.
- **Download counts.** Your host has a stats page. It answers which of the 15 FreeLand
  tools humans actually fetch, and whether anyone still takes 1.1.17 — the input to two
  open decisions: when to stop serving 1.1.17, and whether the User block method
  dropped in 2.0 was load-bearing for anyone.

### Waiting on the world
The WANTED notice on `turn.php`: articulation angles for standard vehicles, the WB1/WB2
split, non-US standard vehicles, and where AASHTO measures minimum turning radius from.

### When 2.1.0 is ready to ship
Drop `-dev` from **both** the `;;; VERSION` banner and `general.version`, run the full
matrix, then:

    python devtools/turn-release.py --publish
    devtools\turn-tests.bat turn-release-smoke
    # then commit in hawsedc.com/

## Traps, still true

- **This shell eats backslashes, even inside a quoted heredoc**, and backticks in a
  double-quoted `-c` string get command-substituted. Use the Write and Edit tools for
  any content with a backslash or a backtick. This bit four times in one session.
- **AutoLISP scopes arguments dynamically**, so a parameter named after a built-in
  shadows it inside every function you call. An argument called `distance` killed
  `turn-step`, which is not even the function that declared it.
- **Read the window title before assuming a hang**: `Get-Process acad | Select Id,
  MainWindowTitle`. A crash dialog and a waiting prompt look identical from outside.
- **Verify AutoLISP assumptions, do not reason about them.** The probes in `devtools/`
  exist because guessing was wrong every time.
- **Measure drawings, do not look at them.**

## Style notes worth carrying

- Be brief. *"Don't overwhelm 20 years of parsimony in a week."*
- Do not assume one user's mistake is common.
- Follow AutoCAD's settings rather than second-guessing them.
- **Ask, or clean up — do not route around a mess.** And when Tom says something is
  wrong, it is: he has watched this program run for twenty years. The "modal dialog"
  claim about QUIT was mine and it was wrong.
