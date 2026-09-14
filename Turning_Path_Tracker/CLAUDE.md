# CLAUDE.md — Turning Path Tracker (TURN.LSP)

Draws vehicle turning paths: you give it a front-axle path polyline and a vehicle block, it
plots wheel paths and vehicle/trailer body rectangles along the path.
Public page: https://hawsedc.com/gnu/turn.php · Video: https://youtu.be/DmHMUyquoSI
Origin: AutoCAD Wiki (autocad.fandom.com). Co-authored by Thomas Gail Haws and Stephen Hitchcox.

## Which file is which
This folder is a source tree. It was an archive of twenty-two concurrent snapshots until
2026-09-13, when they were deleted in favour of git — One True Copy.

| File | Notes |
|---|---|
| `turn.lsp` | **The program. 2.0.0. The only editable copy.** |
| `turn-layers.dat`, `turn-vehicles.dat` | Optional data files, found by `(findfile)` |
| `devtools/` | Test harness and probes. Never ships. |
| `Vehicle_Library/turn-*.dwg` | 1.1.7.1 AASHTO-ish vehicle blocks (P, SU, BUS, WB-40/50/62/65/67, MH…) |
| `hawsedc.com/` | Clone of the website repo. Gitignored here; own history, own remote. |
| `user_help/` | **Users' own drawings and correspondence. Gitignored. Never commit.** |
| `turntest.dwg`, `turndev.dwg`, `turndev2.dwg` | Development drawings (2015) |
| `Civil3D.xml` | LandXML sample, from the 2.0 export idea |
| `turn-test.scr` | Published alongside the program; canned keystrokes driving TURN twice |
| `Piotr/` | 2011 Blender bone-chain study, cited by ROADMAP Phase 1 |

### Reading a deleted snapshot
All twenty-two are in commit `cafd98a` and come back by name:

    git show cafd98a:Turning_Path_Tracker/turn-1.1.17.lsp > /tmp/turn-1.1.17.lsp
    git show cafd98a:Turning_Path_Tracker/turn-2-0-2015.lsp   # the segment/tblock design
    git show cafd98a:Turning_Path_Tracker/turn1-2.lsp         # the other abandoned rewrite

The two that still matter: **`turn-2-0-2015.lsp` and `turn1-2*.lsp` are where the
multi-trailer segment model was designed** — read them before redesigning anything in
that area. `turn-1.1.17.lsp` is the modernization baseline, and is also still served
live at `hawsedc.com/gnu/turn-1.1.17.lsp`, which is the copy the harness loads.

## Two operating methods
- **User block method** — drags a user's block along the path. Doesn't model hitches.
- **Generated vehicle method** — `BUILDVEHICLE` (`BV`) prompts for dimensions, draws an
  attributed block; `TURN` then reads those attributes and plots boxes + tire paths.
The two are largely independent code paths.

The published AASHTO vehicle libraries are **not** the user block method, despite being
somebody else's blocks. They carry the full attribute set and go through the generated
vehicle path, so they articulate. See "What the published vehicle libraries contain" below.

## What hawsedc.com/gnu/turn.php actually serves
Verified 2026-09-08 by reading the page's links:
- `turn-1.1.17.lsp` — the program
- `turn-test.scr` — the test script
- `Turn.lsp_Turn_Radius_Modeling_AASHTO_2004_Edition.zip` and `..._2011_Edition.zip` — vehicle
  block libraries, "version 1.1.13"
- `turntest.dwg` / `turntestr12.dxf` (+ zips)

**Assume a user reporting a problem is on 1.1.17 unless they say otherwise.**

## Confirmed defect: the website instructions contradict the code
The turn.php page still carries pre-1.1.3 instructions:
> "Draw the path for the vehicle as the route taken by the **front left tire**."
> "Place the vehicle at the start of the path using the centre of the **FRONT LEFT WHEEL**,
> which should be marked with an 'x' type figure."

1.1.17's own header says the opposite:
> "Select the front axle **centerline** path. The left and right sides are drawn off of this."
> "Place the vehicle at the start of the path using the centre of the **front axle**, which
> should be marked with a circle."

The code moved to axle centroids in 1.1.3 (2008-01-20); the web page never followed. A user
following the website places the vehicle wrong and draws the wrong guide path.

**The two library zips carry the same stale instructions, and their blocks physically encode
them.** Verified 2026-09-11 by reading the blocks with ObjectDBX
(`devtools/turn-probe-aashto.lsp`, results in `devtools/turn-probe-aashto-log.md`). Each zip
contains `*_Turn_Radius_Instructions.pdf`, which repeats the pre-1.1.3 convention — draw "the
path of the left front wheel", sit "the little circle in the center of the left front tire" on
its start, layer `C-TURN-TRCK-FLTR-PATH` — and the blocks were built to match. In every
drawing the front axle is at x = `VEHFRONTHANG` and the rear axle at
x = `VEHFRONTHANG` + `VEHWHEELBASE`, so **+x runs rearward, the vehicle faces −x, and −y is
its left side.** The small marker circle sits at:

| Block | Marker circle | Half axle width |
|---|---|---|
| `2004_AASHTO_WB-67` | (4.00, −4.00) r 0.20 | 8.00 / 2 |
| `2011_AASHTO_WB-67` | (4.00, −4.25) r 0.2125 | 8.50 / 2 |

That is the front **left wheel**, half an axle width off the centreline. (The larger circle at
(23.50, 0.00) is the fifth wheel; it is absent from SU, which has no hitch.)

The offset is not cosmetic, because `c:turn` never reads the block's insertion point for
position — only its rotation (`turn-1.1.17.lsp:937-940`):

    point-calc-front-0  (osnap (cadr es-guide-path) "_end")
    heading-0           (+ pi (cdr (assoc 50 (entget vehentname))))

TURN takes the guide polyline's endpoint to **be** the front axle centreline. Follow the PDF
and the whole rig plots half an axle width — 4.00 ft on a WB-67 — to the right of where the
user meant it, with both swept edges off by that much.

**When advising a user: keep the PDF's steps 1, 3 and 6–11; discard 2, 4 and 5.** Draw the
guide polyline as the front axle centreline, starting where the axle centre starts. The layer
name is irrelevant — TURN does not care what layer the course is on.

## What the published vehicle libraries contain
Both zips downloaded from hawsedc.com and read with ObjectDBX, 2026-09-11
(`devtools/turn-probe-aashto.lsp` → `devtools/turn-probe-aashto-log.md`).

| | 2004 Edition | 2011 Edition |
|---|---|---|
| Size | 1,019,431 bytes, 18 files | 2,077,048 bytes, 17 files |
| Vehicles | 17 | 16 |
| Naming | `2004_AASHTO_<KEY>.dwg` | `2011_AASHTO_<KEY>.dwg` |

2004: `A-BUS BUS-40 BUS-45 CITY-BUS MH MHB P PB PT S-BUS-36 S-BUS-40 SU WB-40 WB-50 WB-62
WB-65 WB-67`. 2011 is the same list minus WB-50 and WB-65, with `SU` split into `SU-30` and
`SU-40`. **WB-67 is in both.**

**The 2004 zip is byte-identical to this repo's `Vehicle_Library/`** — md5 matched on all
eight sampled, e.g. `2004_AASHTO_WB-67.dwg` = `turn-wb-67.dwg`. So the "2004 Edition" download
is the 1.1.7.1 set renamed, and `turn-vehicles.dat` is already a faithful record of it.
The 2011 drawings are genuinely different files (~168 KB, dated 2013).

### The blocks do satisfy 1.1.17's reader
WB-67 carries 19 attributes, as loose ATTDEFs in `*Model_Space` — the drawings never got as
far as BLOCK, which is why `turn-extract-vehicles.lsp` scans block definitions and not just
inserts. Nineteen is exactly the 20 `vehicle.*` settings minus `vehentname`, which is the
equality tested at `turn-1.1.17.lsp:1229`, so TURN reports "ALL DIMENSIONS AND DATA FOUND"
with no warning.

`TrailHave` is **`Yes`** on WB-67 in both editions. That is the sole gate on drawing a trailer
(lines 991, 1053, 1069), set only from an attribute of that name by
`wiki-turn-get-vehicle-data-from-block` (line 1186). **A vehicle that plots as one monolithic
box with no articulation is a missing or `No` `TrailHave`.** SU / SU-30 are the control: 10
attributes, `TrailHave` `No`, legitimately one box.

| | 2004 WB-67 | 2011 WB-67 |
|---|---|---|
| VEHWHEELBASE | 19.50 | 19.50 |
| VEHFRONTHANG | 4.00 | 4.00 |
| VEHWIDTH / VEHWHEELWIDTH | 8.00 | 8.50 |
| VEHBODYLENGTH | 27.92 | 27.90 |
| VEHREARHITCH | 0.00 | 0.00 |
| TRAILERHITCHTOWHEEL | 45.50 | 45.50 |
| TRAILERBODYLENGTH | 53.00 | 53.00 |
| TRAILERWIDTH / WHEELWIDTH | 8.50 | 8.50 |
| TRAILERFRONTHANG | −3.00 | −3.00 |

Two harmless oddities: `VEHUNITS` is `"M"` on plainly-foot dimensions (inert — set at lines
506 and 588, never read by any calculation), and `VEHSTEERLOCK` and `VEHARTANGLE` are both
28.6479°, the hardcoded 0.5-radian placeholder that `turn-vehicles.dat` documents and zeroes.

Tag names drifted between 1.1.7.1 and 1.1.17: the libraries and the settings list use
`TrailName` / `TrailUnits`, while `BUILDVEHICLE` 1.1.17 writes `TrailerName` / `TrailerUnits`
(lines 780, 794). Cosmetic only — neither is used in any calculation, and an unrecognized tag
is simply added as a new setting at line 324.

## The website lives here now: `hawsedc.com/`
A clone of https://github.com/hawstom/hawsedc.com.git sits at
`Turning_Path_Tracker/hawsedc.com/`. It is a nested git repo — add it to freeland's
`.gitignore` or leave it untracked, but do not commit it into freeland.

The TURN pages are `gnu/turn.php`, `gnu/turn-instructions.php` (new, 2026-09-12) and
`gnu/turntheo.php`. Page format: PHP calling `echoHawsEDCHeader()` /
`echoHawsEDCFooter()` from `../hawsedc.lib.php`, plain HTML in between, Bootstrap and
`/hawsedc.css` loaded by the header. Files are **CRLF** — normalise before doing
multi-line string surgery or nothing will match.

**The two library zips are NOT in the repo**: `.gitignore` carries `*.zip`, so they
exist only on the server. Rebuilt copies are staged in `gnu/` (where git ignores them)
for upload. Generators: `devtools/make-turn-instruction-pdf.py` and
`devtools/make-turn-zips.py`. PyMuPDF and pypdf are installed for this user; PyMuPDF's
bold Helvetica is `hebo`, not `helvB`.

## Confirmed: Kenya Caldwell's real problem was course length
Resolved 2026-09-12 from `user_help/Kenya_Caldwell/Kenya-Caldwell-test-4.dwg`.

By test-4 she was using `2004_AASHTO_WB-67` and **the block was perfect** —
`TrailHave` Yes, `VEHREARHITCH` 0.00, `TRAILERFRONTHANG` −3.00, all 19 attributes.
TURN ran correctly and drew everything it owes: 5 tractor bodies, 5 trailer bodies,
the hitch path, and all six tire paths, with both body perimeters exact (71.84 and
123.00).

**Her course was a 3-vertex polyline 82.10 ft long, for a rig 73.5 ft long with a
65 ft wheelbase.** A trailer is still responding to where the tractor was a full
wheelbase ago, and articulation needs several vehicle lengths to develop. In 82 ft it
never does, and the rig plots as one straight box — which is what "a monolith" was.
Nothing was wrong with TURN or with her vehicle.

Her earlier drawings show where the prompts mislead. In test-2, `VEHREARHITCH` was
**45.50** — she answered the tractor's rear-axle-to-hitch question with the trailer's
kingpin-to-axle distance, and asked outright "why are there two of the same
questions?" A hitch 45 ft behind the drive axle is genuinely unstable, which is the
spiral in her first screenshot. She also gave `TRAILERFRONTHANG` as +3.00 where
1.1.17's prompt wants forward-is-NEGATIVE.

**Proposed feature, cheap and high value:** at startup, compare course length to the
rig's wheelbase and say something. "Course is 82 ft, 1.3 × the 65 ft wheelbase — the
trailer will not reach steady-state articulation. Recommend at least 5 ×." That would
have answered this without either of us opening a drawing.

## 2.0.0 is released (2026-09-13)
`hawsedc.com/gnu/` serves **both** `turn-2.0.0.lsp` and `turn-1.1.17.lsp`, plus the two
optional data files. 2.0 has no User block method — Tom accepted the regression, and the
page asks anyone who relies on it to say so. `turn.lsp` is canon; `gnu/turn-2.0.0.lsp` is a release artifact produced by
`devtools/turn-release.py --publish` and never hand-edited.

Decisions made this session, so they are not relitigated:

- **Follow INSUNITS. Do not second-guess an AutoCAD setting.** A library vehicle recorded
  in feet, in a drawing whose INSUNITS says inches, is correctly scaled by 12. Stock
  `acad.dwt` declares inches, so this bites civil users who never set it. A units *prompt*
  was written and then **reverted** — TURN states what it read and what it is doing
  (`wiki-turn-report-units`) and leaves the setting alone. An architect legitimately works
  in inches.
- **Steering lock 30 degrees, articulation 70 degrees** are BUILDVEHICLE's defaults, and
  are real enough to drive a verdict. Accepted deliberately.
- **The remembered calculation step is offered only while it suits the rig.** It used to
  win unconditionally, so a WB-67 sized in inches left 23.4 sitting there for a rig whose
  own default was 1.2. A step at or beyond the shortest body length guarantees envelope
  gaps, so that is the test; otherwise the computed default is offered and TURN says why.
  Two unit systems in one session is not rare — Tom hit it in a single drawing.

### Envelope: three distinct failure modes, all handled
Found by measuring Tom's drawings with `devtools/turn-inspect-envl`, not by eye:

1. **Holes** — real, and not a union bug. The body outline is laid down once per
   calculation step, so a step longer than the body means consecutive placements never
   touch. Left in place and reported; hiding them would make TURN quietly wrong.
2. **Slivers** — near-zero-area loops where two boundaries almost coincide. Arithmetic
   litter. Dropped below 1e-4 of the smallest body area, and counted.
3. **Not closed** — see the AutoCAD note above. Ends coincident, flag off. Rebuilt as a
   genuinely closed polyline with the duplicate vertex dropped. A loop with a *real* gap
   is left open and reported, because that is missing geometry rather than a missing flag.

Unexplained and deliberately not chased: a 2-segment run's envelope came back closed from
the same pipeline that left a 3-segment run's open. We close it ourselves either way.

## Phase 4: drive mode (2.1.0-dev, unreleased)
The kernel can now be **driven** — a steer angle and a travel distance per step —
instead of only following a course drawn first. `wiki-turn-drive-step`,
`wiki-turn-rest-states`, `wiki-turn-drive` and `wiki-turn-drive-path` are in
SECTION 3 and are pure.

**`wiki-turn-drive-path` returns the same shape as `wiki-turn-path`** — one list of
states per segment — so the envelope, the findings and the report all work on a driven
rig with no change. That equivalence is checked, not assumed: `tdv-test-equivalence`
drives a rig, takes the course its guide axle actually traced, follows that course with
`wiki-turn-path`, and compares every state. **Worst disagreement across 482 states:
0.000000000000.** Keep that test passing; it is what stops drive mode becoming a second
tracking model that drifts.

Facts worth keeping from building it:

- **The instantaneous turn centre is square to the TRAILING axle, not the guide axle.**
  The guide axle rides `wheelbase/sin(steer)`, the trailing axle `wheelbase/tan(steer)`.
  Getting that wrong made the first circle test fail by 20 ft.
- **The integrator is first order**, because each step moves the guide along a straight
  chord. Rather than pick a tolerance, `tdv-test-convergence` asserts that halving the
  step halves the error; it measures **1.989 against a predicted 2.0**.
- **Offtracking is inward only once the turn has developed.** A rig that starts straight
  is stretched along the tangent, so its hindmost axle begins *outside* the tractor's
  guide radius. Same fact the short-course advisory exists to explain.
- **A turn can be impossible without exceeding the steering lock.** On a WB-67, 25° of
  steer puts the tractor's trailing axle on a 41.8 radius, inside the trailer's own 45.5
  wheelbase, so the trailer can never settle: articulation grows without limit and the
  rig folds. TURN reports *"Jackknife: articulation behind Tractor reaches 93.6, limit is
  70.0"* — from the hitch, with the lock never exceeded.

Still to build: the interactive `c:drive` command — a `grread` loop over this kernel.

**The trunk carries `-dev` in its version and `turn-release.py` refuses to publish while
it does**, so the shipped 2.0.0 cannot be overwritten by work in progress. Drop the
suffix from both the `;;; VERSION` banner and `general.version` to release.

## The trunk is `Turning_Path_Tracker/turn.lsp` — One True Copy
Flat at the folder top, like every other FreeLand tool (`Grading_Designer/gdd.lsp`,
`Profile_Labeler/proflbl.lsp`). Ships with two optional data files, both found by
`(findfile)`: `turn-layers.dat` (layer names, NCS-compliant, with a legacy block) and
`turn-vehicles.dat` (17 vehicles, extracted not typed).

**There is exactly one editable copy of the program.** `hawsedc.com/gnu/turn-2.0.0.lsp`
is a release artifact, not a second source: produced by `devtools/turn-release.py`,
named from the version inside the file, never hand-edited.

    python devtools/turn-release.py             # check; changes nothing
    python devtools/turn-release.py --publish   # copy trunk -> gnu/turn-<version>.lsp

It detects a drifted artifact, which the old copy-by-hand ritual could not. Its first
run found `turn-layers.dat` already out of sync — line endings only, now normalised.

The 22 historical snapshots that used to sit here were removed 2026-09-13. They are in
git, in commit `cafd98a`:

    git show cafd98a:Turning_Path_Tracker/turn-1.1.17.lsp

1.1.17 is still *served*, from `hawsedc.com/gnu/turn-1.1.17.lsp`, which is where the
harness now loads it from when a probe needs the old version.

Test harness lives in `devtools/`. Run it with:

    devtools\turn-tests.bat turn-core-tests               # kernel, 106 checks
    devtools\turn-tests.bat turn-integration-tests        # end to end, 44 checks
    devtools\turn-tests.bat turn-punch-tests              # the punch list, 53 checks
    devtools\turn-tests.bat turn-curve-tests c3d c3d      # any curve type, 30 checks
    devtools\turn-tests.bat turn-core-tests acad          # same, on plain AutoCAD 2027

Second argument is the product: `c3d` (Civil 3D 2026, the default), `acad` (plain
AutoCAD 2027) or `2024` (plain AutoCAD 2024). Third is the template, and the only
value is `c3d`, which starts from `_Autodesk Civil 3D (Imperial) NCS.dwt`.

**Pass the template only when creating Civil 3D objects.** A drawing from `acad.dwt`
has one alignment style and no label sets, and every Aecc COM call fails with "the
parameter is incorrect"; from the C3D template there are six styles and the same call
is accepted. The other suites deliberately pass no template — no drawing and no `/t`
is the arrangement they were proven on.

Results land in `devtools/turn-test-log.md`. **All pass as of 2026-09-13: 106 kernel,
44 end to end, 53 punch list, 30 curve, 7 release smoke — on Civil 3D 2026, AutoCAD
2027 and AutoCAD 2024.**

### How a `.scr` must end
Two lines, always:

    (tt-safe-quit)
    quit

**The "Save changes?" prompt on QUIT is a modal task dialog, not a command line
prompt, and FILEDIA does not change that.** No script line can answer it: `quit`
followed by `y` *or* by `n` both leave AutoCAD sitting there forever holding the
process. Tom found a session parked exactly there. `y` is the worse of the two — it
also wants a filename.

The only reliable exit is to leave the drawing **saved**, so QUIT has nothing to ask
about. `tt-safe-quit` (in `turn-dev-paths.lsp`) does that: if DBMOD says the drawing
is dirty it SAVEAS-es to `turn-scratch.dwg`, otherwise it does nothing. `tt-finish`
always saves too, even when the caller wants no output file.

**The `quit` is a script line, not part of the LISP.** `(command "._quit")` inside a
function tears the interpreter down mid-call and logs a spurious `**ERROR**: Function
cancelled` on every run — noise that had been in every log since the harness was
built, and exactly the kind that hides a real error.

**The symptom to check for is a leftover `acad.exe`.** A run that leaves one behind
did not exit; it is waiting on a dialog nobody can see.

### TRUSTEDPATHS is saved in the profile, not the session
Appending to it unconditionally adds entries on **every run**. That is how the Civil 3D
trusted locations became a mess Tom had to clean by hand, and how the old release-smoke
`.scr` accumulated seven copies of a path ending in a literal `...`. `turn-dev-paths.lsp`
now normalises each path — backslashes, `..` resolved, no trailing slash — and adds one
only when genuinely absent. Verified convergent: three consecutive runs, five entries,
unchanged.

**No paths are hardcoded.** `turn-tests.bat` sets `TURNDEV` from its own location
(`%~dp0`); `devtools/turn-dev-paths.lsp`, loaded on the first line of every `.scr`,
derives everything else and exposes `(tt-dev "x")`, `(tt-src "x")` and `(tt-gnu "x")`.
Clone the tree anywhere and the tests run. AutoLISP `getenv` reads the environment the
`.bat` hands to `acad.exe` — verified on both products, not assumed.

Other scripts in `devtools/`, all run the same way (`turn-tests.bat <name>`):

| script | what it is for |
|---|---|
| `turn-release-smoke` | loads the SHIPPED `gnu/turn-2.0.0.lsp`, not the source. Run after every change. |
| `turn-inspect-dwg` | everything in a user's drawing that bears on a support question |
| `turn-inspect-plines` | polyline census by layer and vertex count — tells a drawn course from a computed path |
| `turn-inspect-envl` | envelope loops with area, closure and end gap — the tool that found all three envelope defects |
| `turn-probe-aashto` | reads the published AASHTO blocks |
| `turn-probe-initget` | proved `initget` accepts hyphenated keywords like `WB-67` |
| `turn-curve-tests` | punch item 7: LINE, ARC, SPLINE, ELLIPSE and a real Civil 3D alignment |
| `turn-punch-tests` | punch items 1, 4, 5, 6, 8, 9, 10, 11 — what TURN draws, reports and refuses |

Python helpers (PyMuPDF and pypdf are installed for this user):
`devtools/make-turn-instruction-pdf.py` and `devtools/make-turn-zips.py` regenerate the
vehicle-library instruction sheets and rebuild both zips, re-verifying every DWG round
trip. PyMuPDF's bold Helvetica is `hebo`, not `helvB`.

`turn-tests.bat` runs any `.scr` in `devtools/` by name, so it doubles as the way to run a
one-off probe — `devtools\turn-tests.bat turn-probe-aashto` reads the published AASHTO blocks
and writes `turn-probe-aashto-log.md`.

### Harness facts worth remembering
- **Redefining `alert` is the key to unattended testing.** BUILDVEHICLE ends in a modal
  `(alert ...)` that hangs a `/b` script forever. `turn-tests.lsp` redefines `alert` to write
  to the log instead. AutoLISP permits redefining a built-in subr.
- **`TRUSTEDPATHS` is set once, in `turn-dev-paths.lsp`**, because script lines run before the LISP
  security check. Without it, loading from an untrusted folder raises a modal dialog.
- Launch with `/p "AutoCAD"` or AutoCAD inherits the last-used profile and starts as Civil 3D.
- **AutoLISP scopes arguments DYNAMICALLY, so a parameter named after a built-in shadows
  it inside every function you call, not just your own.** `wiki-turn-drive-step` was first
  written with an argument called `distance`; it does not call `distance` itself, but
  `wiki-turn-step` does, and that died with `bad function: 5.0` — 5.0 being the travel
  distance evaluated in function position. The breakage surfaces far from the name that
  caused it. Same family as `last` below, and harder to see.
- **AutoLISP has `last`.** Declaring a local named `last` shadows it and turns `(last x)` into
  a call to nil. The harness caught exactly this.
- **AutoLISP `and` returns T, not its last value.** `(and file (findfile file))` yields `T`,
  so `(open T)` dies with `bad argument type: stringp T`. Use `if` or `cond` when you want
  the value. Common Lisp habits do not transfer; the harness caught this one too.
- Do NOT write .lsp with a bash heredoc in this shell: it eats backslashes, so
  "C:\path" silently becomes "C:\path" and every escape breaks. Use the Write tool.
- A space in a .scr line is the same as pressing Enter, which is why the folder
  "Vehicle Library" could not be handed to a script prompt (it is `Vehicle_Library` now).
  Read drawings with ObjectDBX
  instead of opening them: no SDI, no drawing swaps, no save prompts, one session.

## Confirmed defects in 1.1.17, found by running it
1. **`entsel` on the course grabs the vehicle block.** The block sits on the start of the
   path, which is exactly where the user is told to pick. MEASURE then fails with
   `Cannot measure that object` and TURN carries on and draws nothing useful.
   **This is the most likely cause of the current user report.**
2. **`(osnap pick "_end")` made correctness depend on zoom level and APERTURE.**
3. **`wiki-turn-asin` was not arcsine.** It returned `x/sqrt(1-x^2)`, which is *tan* of the
   arcsine; the `atan` was missing.
4. **DXF group 90 was set one short** of the vertices actually written.
5. MEASURE littered and erased dozens of POINT entities per run.

2.0 removes all five: `vlax-curve-*` samples the course from the object itself, which also
means TURN now follows lines, arcs, splines and Civil 3D alignments, not just polylines.

## Older snapshots, for reference only

1. **1.1.9 creates layers at LOAD time** (`turn.lsp` line 357, top-level `TURN-MAKELAYERS`).
   `entmake` fails silently on a nonexistent layer. 1.1.16 moved creation inside `c:turn`.
2. **1.1.9 asks for the `dashed` linetype**, which desynchronizes `-LAYER` if not loaded.
   1.1.17 uses `""` (Continuous) everywhere.
3. **1.1.9 offsets both "right" tire paths the same way** and uses full `VEHWHEELWIDTH`
   instead of half. No front-left path at all.

Structural gap in every 1.1.x version, including 1.1.17: **there is no swept-path envelope.**
The body is drawn as discrete rectangles at intervals; the outer boundary of the sweep — the
"lines for the left and right side of the vehicle" — was never drawn by any 1.1.x version.

2.0 draws it. `wiki-turn-draw-envelope` puts the body outline down at every step of every
segment, and hands the polygon union to AutoCAD's own REGION / UNION rather than writing a
polygon union in AutoLISP. The result is exploded and rejoined into closed polylines on
`C-TURN-ENVL`, and its area is reported. Two things bit on the way in and are worth
remembering:

- **REGION, UNION and EXPLODE put their output on the CURRENT layer**, not on the layer of
  the objects they consume. `entmake` honours the layer you give it; these commands do not.
  The first run put the whole envelope on layer 0. Set CLAYER around the operation.
- **PEDIT prompts "convert to polyline?" unless PEDITACCEPT is 1**, which would hang a `/b`
  script the same way a modal alert does.
- **Nothing closes in AutoCAD unless you tell it to.** PEDIT Join joins; it does not
  close. A joined loop comes back with its first and last vertices coincident and its
  Closed flag off — it looks shut and is not, and hatching, offset, AREA and booleans
  all refuse it. Do not treat that as a defect to be discovered; close it yourself,
  every time. `wiki-turn-close-loops` does it by rebuilding with `entmake` rather than
  with PEDIT Close, so the duplicated last vertex goes too instead of leaving a
  zero-length segment.

Corner loci now live on their own role, `CRNR` (`C-TURN-TRCK-CRNR`), because `ENVL` belongs to
the real envelope. `ENVL` is the one role with no segment stem: one rig sweeps one envelope.

## Vocabulary (from the 2.0 work — worth keeping)
- **Course** — alignment followed by a steerable guide axle
- **Path** — the states/positions resulting from following a course
- **Step** — state and position at the end of one calculation interval
- **Tblock** — turn block; plotted geometry of one vehicle segment
