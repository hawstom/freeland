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
| `../hawsedc.com/` | Clone of the website repo, at the freeland root — see the root `CLAUDE.md`. |
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

**Audit of the whole TURN offering, 2026-09-26** (live site vs this clone vs the wiki):
- **The live `turn-2.0.0.lsp` is NOT the clone's `gnu/turn-2.0.0.lsp`.** Later fixes were
  republished locally under the same number and never uploaded, so two different files are
  both "2.0.0". Never republish changed code under a released number.
- The site's license text said GPL v2; the code has always said v3 or later. Page fixed
  locally; the freeland repo still has no LICENSE file.
- **Collaboration lives on GitHub now** (`github.com/hawstom/freeland`, public, issues on).
  The AutoCAD Wiki page holds 1.1.17 inline, was last edited by Tom 2023-02-24, its Talk page
  last used 2017, and Fandom blocks scripted reads (the MediaWiki `api.php` still works). Do
  not put new code there: a second editable copy breaks One True Copy.
- The library zips were already reissued with corrected sheets (2 pages, pointing at
  `turn-instructions.php`), so page text calling their PDFs out of date was itself stale.
- `turnpoll.php` is an orphan feedback form, linked from nowhere, mailing Stephen Hitchcox.

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

## TURN on the website
The clone is at `freeland/hawsedc.com/` (root `CLAUDE.md` has the general notes). The TURN
pages are `gnu/turn.php`, `gnu/turn-instructions.php` and `gnu/turntheo.php`. The library
zips' instruction sheets are generated by `devtools/make-turn-instruction-pdf.py` and the
zips rebuilt by `devtools/make-turn-zips.py`, which takes its output folder as an argument.
PyMuPDF and pypdf are installed for this user; PyMuPDF's bold Helvetica is `hebo`, not
`helvB`.

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

## 2.1.0 is published locally, not yet uploaded (2026-09-26)
`gnu/turn-2.1.0.lsp` is produced and smoke-tested (7/7); Tom uploads. It carries the
six-point envelope, protruding axles, no trailer front paths, the start-direction warning,
and the INSUNITS / remembered-step work that had been republished as a second "2.0.0".
The clone's `gnu/turn-2.0.0.lsp` was restored to the bytes the live site serves.

**A released version names one file forever.** `turn-release.py --publish` now refuses
to overwrite a released `turn-<version>.lsp` with different contents (proved by trying).
After a release, the next edit to `turn.lsp` gives it a new version with a `-dev` suffix.

**DRIVE ships in 2.1.0 but is EXPERIMENTAL and unannounced** (Tom has not hand-tested
it): the load banner says "Type TURN or BV", the punch suite asserts DRIVE is *not* in the
banner, and `c:drive` warns when run. Name it in the banner when it is released.

Website, 2026-09-26 (clone only, Tom uploads): TURN's contact links fixed, `turnpoll.php`
removed, 2.1.0 on the download list. Stephen Hitchcox is not currently involved; Tom
intends to tell him about 2.x.

Licensing is per tool; see the root `CLAUDE.md`. TURN's GPL v3 text is the root `LICENSE`.

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
  (`turn-report-units`) and leaves the setting alone. An architect legitimately works
  in inches.
- **Steering lock 30 degrees, articulation 70 degrees** are BUILDVEHICLE's defaults, and
  are real enough to drive a verdict. Accepted deliberately.
- **The remembered calculation step is offered only while it suits the rig.** It used to
  win unconditionally, so a WB-67 sized in inches left 23.4 sitting there for a rig whose
  own default was 1.2. A step at or beyond the shortest body length guarantees envelope
  gaps, so that is the test; otherwise the computed default is offered and TURN says why.
  Two unit systems in one session is not rare — Tom hit it in a single drawing.

### Envelope: built from the paths of six fixed points (Tom's design, 2026-09-26)
**Do not state an accuracy property of the envelope without running
`turn-envelope-tests`.** The first envelope's comment claimed "the only error is the
chord-versus-arc sagitta"; it was reasoned, never measured, and wrong, and Tom was about to
repeat it to Robert Livingston.

**The construction.** The kernel never lets the trailing axle slip, so a segment always
turns about a centre on its trailing axle's line. Along any body edge, distance from that
centre then changes one way only between the edge's ends — once each side is cut abeam the
trailing axle. So six fixed points per segment trace the whole boundary: the four corners,
and the two side points abeam the trailing axle. Each edge piece sweeps exactly the strip
between its two end points' paths (`turn-edge-sweep`), and the segment's swept ground is
those six strips plus its first and last placement (`turn-segment-sweep`). The strips go to
REGION/UNION because which point forms the outside changes along the way and segments
overlap; that merge is polygon clipping, which we leave to AutoCAD.

**The inside of a turn is traced by a FIXED point** — the side point abeam the trailing
axle. I (Claude) twice told Tom it was a point "sliding along the side" and that bodies
therefore could not be done from point paths. Wrong for this kinematic model; Tom's
instinct to connect the body's points was right.

**Measured** (WB-67, 90° on radius 50): escape 0.0155 / 0.0039 / 0.0022 at steps 2.4 / 1.2 /
0.6 — second order, then the floor. Overreach 0.0017 at 64 reference placements per step:
the inner chord overstating by its sagitta. 16 polygons for the whole rig. Tom's turntest
case, 8 s.

**Robustness, because one bad polygon stalls everything.** A self-crossing polygon makes
UNION fail, and a failed UNION merges *nothing*: Tom's turntest.dwg (block rotated against
the course, rig folds round) left **1387 regions**. So `turn-edge-sweep` merges step quads
into strips only while they turn the same way and for at most 90°, turns a bowtie quad (an
edge pivoting on itself) into its two triangles, drops quads thinner than 1e-4 of the body
(a side sliding along itself on a straight — the documented floor, 0.0053 ft on a 53 ft
trailer), and `turn-strip-pieces` halves any strip that still fails
`turn-simple-polygon-p`. The report now warns when the vehicle starts facing more than 90°
from the course.

**Protruding axles** are edges like any other: an axle's wheels are its extremes by the same
argument, so where a wheel stands outside the body its strip lies between the two tire
paths. Real axles only — a trailer's guide point is a kingpin or drawbar eye. Found by Tom:
a 4 ft trailer on a 6 ft track, tire path 1.03 outside; now 0.0013.

What the old design taught, still true:
- **Explode regions one at a time.** `(command "._explode" ss)` from LISP explodes only the
  first object of a selection set.
- **The REGION command is slow on many curves** — it searches every selected curve for
  loops with every other (73 of 84 s once). `turn-draw-region` uses `vla-AddRegion` on each
  closed polyline alone.
- **Never index lists with `nth` inside a double loop.** `turn-simple-polygon-p` was cubic
  that way and a 600-vertex strip took most of a minute; it walks the lists now.
- Slivers (near-zero-area loops) are dropped below 1e-4 of the smallest body area.
- **PEDIT Join does close a loop, as measured 2026-09-26** (`turn-probe-pedit-close`): on
  exploded regions and on every envelope the six-point code draws, Join returned the loop
  with its Closed flag ON and no duplicate vertex, and `turn-close-loops` found nothing to
  do. The flag-off loops of 2026-09-13 came from the old placement envelope, cause never
  found. `turn-close-loops` was therefore removed (Tom, 2026-09-26); `turn-count-open`
  only reports a loop that is not closed, as a gap in the boundary.
- **A coarse step no longer opens holes** — a strip covers the ground between two positions
  of an edge however far apart. The report still warns when the step exceeds the shortest
  body, now because the tracking itself is too coarse to trust.
- **Holes** in the old envelope (Tom's 17-loop drawing, 2026-09-13) were placements that
  never touched. Before-fix sawtooth numbers: `devtools/turn-envelope-baseline-log.md`.

**Trailers have no front tire paths** (2026-09-26, Tom's decision). 2.0.0 drew
`C-TURN-TRL1-FRNT-*` at the kingpin, axle-width apart, where there are no wheels; 1.1.17
never drew them. A towed segment's guide point is its kingpin or drawbar eye (its path is
the towing segment's `HTCH`), and a dolly is a segment of its own with its wheels on its
trailing axle. `turn-role-applies-p` now keeps both the paths and their layers off trailers.

**`turn-segment` takes front-hang FORWARD-positive.** Only block attributes use the
trailer's backward convention (`turn-segment-from-attributes` negates it). The punch
suite's `turn-test-punch-rig` passed −3.0 for the WB-67 trailer until 2026-09-26, which put
its deck 3 ft *behind* the kingpin. Corrected to +3.0.

`turn.lsp` also never called `(vl-load-com)` while using `vlax-curve-*`. The harness calls
it before loading TURN, which is exactly why no test could see the omission. Added.

## Phase 4: drive mode (in 2.1.0, experimental, unannounced)
The kernel can now be **driven** — a steer angle and a travel distance per step —
instead of only following a course drawn first. `turn-drive-step`,
`turn-rest-states`, `turn-drive` and `turn-drive-path` are in
SECTION 3 and are pure.

**`turn-drive-path` returns the same shape as `turn-path`** — one list of
states per segment — so the envelope, the findings and the report all work on a driven
rig with no change. That equivalence is checked, not assumed: `turn-test-drive-equivalence`
drives a rig, takes the course its guide axle actually traced, follows that course with
`turn-path`, and compares every state. **Worst disagreement across 482 states:
0.000000000000.** Keep that test passing; it is what stops drive mode becoming a second
tracking model that drifts.

Facts worth keeping from building it:

- **The instantaneous turn centre is square to the TRAILING axle, not the guide axle.**
  The guide axle rides `wheelbase/sin(steer)`, the trailing axle `wheelbase/tan(steer)`.
  Getting that wrong made the first circle test fail by 20 ft.
- **The integrator is first order**, because each step moves the guide along a straight
  chord. Rather than pick a tolerance, `turn-test-drive-convergence` asserts that halving the
  step halves the error; it measures **1.989 against a predicted 2.0**.
- **Offtracking is inward only once the turn has developed.** A rig that starts straight
  is stretched along the tangent, so its hindmost axle begins *outside* the tractor's
  guide radius. Same fact the short-course advisory exists to explain.
- **A turn can be impossible without exceeding the steering lock.** On a WB-67, 25° of
  steer puts the tractor's trailing axle on a 41.8 radius, inside the trailer's own 45.5
  wheelbase, so the trailer can never settle: articulation grows without limit and the
  rig folds. TURN reports *"Jackknife: articulation behind Tractor reaches 93.6, limit is
  70.0"* — from the hitch, with the lock never exceeded.

### `c:drive` — steering with the cursor
Built 2026-09-14. The cursor is the driver's eyes: the rig steers toward it, as hard as
the steering lock allows, and takes **one calculation step per cursor event**, only once
the cursor is a full step ahead of the guide axle. Stop moving and the rig stops. ENTER
or SPACE finishes; the collected inputs then go through `turn-drive-path` and the
ordinary drawing, envelope and report.

**One step per event is a correctness requirement, not a feel choice.** The first
version drove *until* the rig reached the cursor, which never terminates when the
cursor sits inside the minimum turning circle — a point the vehicle cannot reach
however long it drives. A 20 ft wheelbase on a 30° lock cannot reach a spot 40 ft
abeam, and that loop hung AutoCAD. Termination is now structural.

`turn-steer-toward` is where the **steering lock clamps**, and the only place it
does: a driver cannot haul the wheel past the stops, so an intention the vehicle cannot
carry out is simply unavailable. The stepping functions still never clamp — they report
what the geometry does and let `turn-findings` judge it. A vehicle with no lock
recorded (every library vehicle's angle is the zeroed placeholder) is not clamped at
all; we do not invent a limit.

The `grread` loop itself cannot be tested unattended — it waits for a human. So it is
kept as thin as possible, and the rule it implements is restated in
`turn-test-drive-cursor-rule` and run headless, including the unreachable-cursor case.

**Still to hand-test:** the feel of it, and whether the accumulating `grdraw` outlines
are the right thing to see while driving.

**Between releases the trunk carries a `-dev` suffix and `turn-release.py` refuses to
publish it; it also refuses to republish a released version with different contents.**
Drop the suffix from both the `;;; VERSION` banner and `general.version` to release.

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

    devtools\turn-tests.bat turn-core-tests               # kernel, 154 checks
    devtools\turn-tests.bat turn-integration-tests        # end to end, 44 checks
    devtools\turn-tests.bat turn-punch-tests              # the punch list, 55 checks
    devtools\turn-tests.bat turn-envelope-tests           # envelope fidelity, 13 checks, ~5 min
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

Results land in `devtools/turn-test-log.md`. **All pass as of 2026-09-23: 154 kernel,
44 end to end, 55 punch list, 13 envelope — on Civil 3D 2026, AutoCAD 2027 and AutoCAD
2024 — plus 30 curve and 7 release smoke on Civil 3D 2026.** The release smoke writes
its own log, `devtools/turn-release-smoke.md`; `turn-test-log.md` will still hold the
previous suite's results, which is how 30 was once misreported as the smoke count.

### How a `.scr` must end
Two lines, always:

    (turn-test-safe-quit)
    quit

**QUIT on a dirty drawing asks whether to save, at the command line**, and in an
unattended `/b` run nothing we have tried answers it. Measured, with FILEDIA 0 and
DBMOD 5:

| ending | result |
|---|---|
| `quit` then `y` | parks forever — `y` then wants a *filename* |
| `quit` then `n` | parks forever |
| `(command "._quit" "_N")` from LISP | parks forever |
| drawing already saved | **exits cleanly, every time** |

Tom found a session sitting at exactly that prompt. Do not theorise about why the
scripted answers do not take — the useful fact is the last row.

The reliable exit is to leave the drawing **saved**, so the question is never asked.
`turn-test-safe-quit` (in `turn-dev-paths.lsp`) does that: if DBMOD says the drawing is dirty
it SAVEAS-es to `turn-scratch.dwg`, otherwise it does nothing. `turn-test-finish` always saves
too, even when the caller wants no output file.

**The `quit` is a script line, not part of the LISP.** `(command "._quit")` inside a
function tears the interpreter down mid-call and logs a spurious `**ERROR**: Function
cancelled` on every run — noise that had been in every log since the harness was
built, and exactly the kind that hides a real error.

**The symptom to check for is a leftover `acad.exe`.** A run that leaves one behind
did not exit; it is waiting on a dialog nobody can see. When that happens, read the
window title before assuming a hang:

    Get-Process acad | Select-Object Id, MainWindowTitle

It will not always say what you expect. A curve-test run that passed all 30 checks sat
for 19 minutes titled **"AutoCAD Error Aborting"** — a *crash* on shutdown, not a
prompt. Civil 3D crashes tearing down a drawing that holds a COM-created
`AECC_ALIGNMENT`, so `turn-test-curve-drop-alignments` erases them once the assertions are done.
A crash dialog and a wait-for-input dialog look identical from outside.

### TRUSTEDPATHS is saved in the profile, not the session
Appending to it unconditionally adds entries on **every run**. That is how the Civil 3D
trusted locations became a mess Tom had to clean by hand, and how the old release-smoke
`.scr` accumulated seven copies of a path ending in a literal `...`. `turn-dev-paths.lsp`
now normalises each path — backslashes, `..` resolved, no trailing slash — and adds one
only when genuinely absent. Verified convergent: three consecutive runs, five entries,
unchanged.

**No paths are hardcoded.** `turn-tests.bat` sets `TURNDEV` from its own location
(`%~dp0`); `devtools/turn-dev-paths.lsp`, loaded on the first line of every `.scr`,
derives everything else and exposes `(turn-test-dev "x")`, `(turn-test-src "x")` and `(turn-test-gnu "x")`.
Clone the tree anywhere and the tests run. AutoLISP `getenv` reads the environment the
`.bat` hands to `acad.exe` — verified on both products, not assumed.

Other scripts in `devtools/`, all run the same way (`turn-tests.bat <name>`):

| script | what it is for |
|---|---|
| `turn-release-smoke` | loads the newest SHIPPED `gnu/turn-<version>.lsp`, not the source. Finds it by name, reads the version out of it, and calls it through whichever prefix that file uses — so it keeps working across a release and a rename. Run after every change. |
| `turn-inspect-dwg` | everything in a user's drawing that bears on a support question |
| `turn-inspect-plines` | polyline census by layer and vertex count — tells a drawn course from a computed path |
| `turn-inspect-envl` | envelope loops with area, closure and end gap — the tool that found all three envelope defects |
| `turn-probe-aashto` | reads the published AASHTO blocks |
| `turn-probe-initget` | proved `initget` accepts hyphenated keywords like `WB-67` |
| `turn-curve-tests` | punch item 7: LINE, ARC, SPLINE, ELLIPSE and a real Civil 3D alignment |
| `turn-punch-tests` | punch items 1, 4, 5, 6, 8, 9, 10, 11 — what TURN draws, reports and refuses |
| `turn-envelope-tests` | how far the envelope misses the ground swept between steps, and whether that error is first or second order. The verdict is the order, not an invented threshold |
| `turn-probe-turntest` | copies Tom's course and `tom5` block out of `turntest.dwg` with ObjectDBX and reruns the envelope, as he ran it and with the heading along the course |
| `turn-tool-trust-prune` | removes TRUSTEDPATHS entries inside the freeland tree that no longer exist (run per product); keeps `\...` wildcards and anything outside the tree |
| `turn-probe-pedit-close` | whether PEDIT Join closes a loop, on exploded regions and on real envelopes. It does |
| `turn-inspect-layer-census` | every object on every C-TURN-* layer by type, plus every other curve in the drawing with its handle — how the 1387 leftover regions were found |
| `turn-inspect-outside` | every C-TURN-* polyline in a drawing measured against the envelope; edit the `.scr` for the drawing. Found the protruding-axle gap |

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
  it inside every function you call, not just your own.** `turn-drive-step` was first
  written with an argument called `distance`; it does not call `distance` itself, but
  `turn-step` does, and that died with `bad function: 5.0` — 5.0 being the travel
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

2.0 draws it, and hands the polygon union to AutoCAD's own REGION / UNION rather than
writing one in AutoLISP. (How the polygons are built is in "Envelope: built from the paths
of six fixed points" above; 2.0.0 as shipped lays the body down at every step instead, and
has the sawtooth.) The result is exploded and rejoined into closed polylines on
`C-TURN-ENVL`, and its area is reported. Things that bit on the way in:

- **REGION, UNION and EXPLODE put their output on the CURRENT layer**, not on the layer of
  the objects they consume. `entmake` honours the layer you give it; these commands do not.
  The first run put the whole envelope on layer 0. Set CLAYER around the operation.
- **PEDIT prompts "convert to polyline?" unless PEDITACCEPT is 1**, which would hang a `/b`
  script the same way a modal alert does.
- **A joined loop once came back with its ends coincident and its Closed flag off**
  (Tom's 1284-vertex envelope, 2026-09-13, old placement pipeline) — it looks shut and is
  not, and hatching, offset, AREA and booleans refuse it. It was rebuilt closed with
  `entmake` then; measured 2026-09-26, Join closes every loop the current envelope
  produces, so that code is gone. If it ever recurs, PEDIT Close is the fix — a
  zero-length closing segment is possible, and harmless (Tom).

Corner loci now live on their own role, `CRNR` (`C-TURN-TRCK-CRNR`), because `ENVL` belongs to
the real envelope. `ENVL` is the one role with no segment stem: one rig sweeps one envelope.

## Namespacing: there is none, so we provide it
**AutoLISP has one global namespace.** Every symbol a file defines — function or
variable — is visible to, and collides with, every other LISP loaded in the same
AutoCAD session. Users load TURN alongside whatever else they have. A short, generic
name is therefore not a style preference; it is a defect waiting for someone else's
`turn-test-write`.

**There is ONE prefix: `turn-`.** Every function and every global we define carries
it — shipped code and test scaffolding alike. Commands are `c:turn`, `c:drive`,
`c:buildvehicle`, `c:bv`, and `*error*` is AutoLISP's own.

    313 turn-*        every function in turn.lsp and every one in devtools/
      5 c:*           the commands
      1 *error*

**Test scaffolding is not exempt.** It loads into the same session and collides just
as hard; the flagship names its helpers `haws-assert-equal` for exactly this reason.

Sub-namespacing lives *after* the prefix, which is still one prefix:

| | |
|---|---|
| `turn-` | the program |
| `turn-test-` | the harness itself |
| `turn-test-kernel-`, `turn-test-drive-`, `turn-test-integration-`, `turn-test-punch-`, `turn-test-curve-`, `turn-test-smoke-` | the suites |
| `turn-tool-` | one-off tools over a user's drawing |
| `turn-probe-` | one-off probes that answer a question about AutoCAD |

**History:** this was consolidated 2026-09-14 on Tom's instruction, from **nineteen**
prefixes — `wiki-turn-`, `tt-`, `ttc-`, `tti-`, `tdv-`, `tpn-`, `tcv-`, `tx-`, `ti-`,
`tp-`, `to-`, `ev-`, `ky-`, `kr-`, `pb-`, `pi-`, `gp-`, `rs-`, `sci-`. The shipped
file was already clean under `wiki-turn-`; `devtools/` was the mess. **`wiki-` is
retired** — it recorded the AutoCAD Wiki origin and no longer earns its keep.
2,304 replacements, no collisions, whole matrix green afterwards.

## Vocabulary (from the 2.0 work — worth keeping)
- **Course** — alignment followed by a steerable guide axle
- **Path** — the states/positions resulting from following a course
- **Step** — state and position at the end of one calculation interval
- **Tblock** — turn block; plotted geometry of one vehicle segment
