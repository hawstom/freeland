# Turning Path Tracker — Roadmap to 2.0

*Drafted 2026-09-08 from a survey of every snapshot in this folder, including the abandoned
1.2 / 2.0 rewrites and Piotr's 2011 Blender study.*

## The goal

A free, GPL, single-file AutoLISP tool that a working civil engineer would choose over
AutoTURN — not because it is cheaper, but because it answers the question they actually have:
**"can this vehicle make this move, and what does it sweep?"**

## What you already decided, years ago

Nothing here starts from zero. Reading the archive, the design is largely settled — it was
just never finished:

- **The kinematics are right.** The 2002 tracking equation (`turntheo1.png`,
  `turn-angle-turned`) is a proper bicycle model, exact for a two-wheeled vehicle, and it
  correlates well against published AASHTO templates even for articulated rigs. This is the
  hard part of a swept-path program and it is done.
- **The vocabulary is right.** Course / Path / Step / Segment / Tblock, from `turn-2-0-2015.lsp`.
- **The data model is right.** A vehicle is a *list of segments*; a segment has a guide point,
  a trailing point, and optionally a hitch point where the next segment's guide point attaches.
  Point flags (`*wt-point-guide*` / `-trail*` / `-hitch*` / `-path*` / `-tblock*`) already
  express everything needed. Piotr independently rigged exactly this as a Blender bone chain
  in 2011.
- **The ambition is already in the file format.** `VEHSTEERLOCK`, `VEHSTEERLOCKTIME`,
  `VEHARTANGLE` are collected by `BUILDVEHICLE` today and *never used by anything*. 2.0 added
  `maxspeed` and `maxaccel`, also unused. You have been writing down the inputs for the
  analysis features for twenty years without yet writing the analysis.

The gap between TURN and AutoTURN is not insight. It is unfinished work.

## What actually separates TURN from AutoTURN

Revised 2026-09-13. "TURN today" means the 2.0 trunk, `Turning_Path_Tracker/turn.lsp`; where that differs from
what a user can actually download, the row says so, because the published 1.1.17 still
has none of this.

| AutoTURN does | TURN today (2.0 trunk) | Gap |
|---|---|---|
| Arbitrary articulation — N trailers, dollies, B-doubles | **N trailers, done.** Chain walks until a segment tows nothing | *Unreleased* |
| Swept-path *envelope* (outer boundary of the body sweep) | **Done.** Body outline at every step, unioned by REGION/UNION, reported with its area | *Unreleased* |
| Steering-lock and articulation-angle limits; jackknife detection | **Built, and dark.** Enforced at every step and hitch, but every library vehicle's limits are the zeroed placeholder | **Missing data, not code** |
| Standard vehicle libraries (AASHTO, TAC, Austroads) as data | 17 vehicles in `turn-vehicles.dat`, extracted not typed | **More data** |
| Interactive drive mode (SmartPath) | Follow a course you drew | **Interaction** |
| Reverse driving | Forward only | Moderate |
| Speed / superelevation / lateral friction | `maxspeed`, `maxaccel` declared, unused | Low priority |
| 3D clearance and collision detection | None | Long term |

The shape of the table has changed. The top two gaps are closed and the third is closed
in code — what stands between TURN and its users now is **a release, not a feature**. The
remaining genuine gaps are data we do not have, and interaction we have not built.

## Phases

### Phase 0 — Get honest. Fix what is broken. — DONE (2026-09-13)

All three items closed, though not the way this phase expected:

- **The harness exists.** `devtools/turn-tests.bat` drives a `.scr` against Civil 3D 2026 or plain AutoCAD 2024
  unattended. 89 kernel checks and 40 end-to-end checks, all passing.
- **The user report is diagnosed, and it was not a bug.** Kenya Caldwell's rig plotted
  as one straight box because her course was 82 ft under a 73.5 ft WB-67 — articulation
  never had room to develop. Her earlier drawings did carry two real input errors, both
  caused by BUILDVEHICLE's prompt wording, not by the tracking code. See
  `CLAUDE.md`. TURN now reports course length against rig wheelbase and says so.
- **The website is fixed and pushed.** `gnu/turn.php` no longer tells users to follow
  the front left tire, `gnu/turn-instructions.php` is the new canonical page, and both
  library zips have been rebuilt with corrected instruction sheets (DWGs untouched,
  verified byte-identical). The zips await a manual upload.

**1.1.18 was never cut**, and should not be. Everything it would have carried is in the
2.0 trunk, which fixes all five 1.1.17 defects outright rather than patching them. What
remains is a release decision, below.

### Phase 0 as originally written

Before any new feature, we need to be able to *see* what the program does without a human
driving AutoCAD.

- Build the unattended test harness: `turn-tests.bat` / `.scr` / fixture `.dwg`, borrowed from
  the flagship's `cnm-unattended-tests.*` pattern. `turn-test.scr` is already a seed of this.
- Reproduce the current user report against **1.1.17**, which is what the site serves. No
  cause is confirmed yet; it may be a bug, or it may be the missing envelope (Phase 3)
  described as a bug. One clarifying question to the user resolves which.
- **Fix the website.** `turn.php` still tells users to draw the path along the *front left
  tire* and place the block by the *front left wheel*. The code moved to axle centroids in
  1.1.3 (2008). Anyone following the published instructions sets up wrong. This is a confirmed
  defect in the deliverable and costs nothing to fix.
- Ship 1.1.18 with whatever the harness finds.

**Why first:** every later phase is guesswork without a test loop, and we owe the user in the
inbox an answer this week.

### Phase 1 — The segment chain. N trailers. — DONE (verified 2026-09-13)

The architectural fight is over and the code is in `turn.lsp`:

- `turn-path` walks the chain, each segment's hitch path becoming the next
  segment's course, until a segment tows nothing (`turn.lsp:681`). It is the
  `foreach` this phase predicted, not new math.
- `BUILDVEHICLE` loops: *"Does &lt;name&gt; tow another trailer? [Yes/No]"*
  (`turn.lsp:1686`).
- Layer keys carry a segment stem, so `TRL2-REAR-LEFT` falls out of the scheme with no
  new entry per trailer.
- `turn-findings` enforces the articulation angle at every hitch and the steering
  lock on the powered unit — dark until someone supplies real limits, because every
  library vehicle's angles are the zeroed 0.5-radian placeholder.
- Covered both ways: `turn-test-kernel-chain` runs a tractor and two trailers and asserts each
  segment tracks inside the one ahead; the integration suite draws a three-segment rig
  end to end.

**This was the user's asked-for feature.** It is built and tested but unreleased — see
the release gate below.

### Phase 1 as originally written

Replace the truck-and-maybe-a-trailer special case with the segment list that
`turn-2-0-2015.lsp` already specifies.

- One tracking function, applied down a chain: each segment's hitch path becomes the next
  segment's course. `wiki-turn-track-step` already does exactly this — it is called once for
  the truck and once for the trailer today. The change is a `foreach`, not new math.
- `BUILDVEHICLE` asks "another trailer? [Yes/No]" and loops.
- Enforce and report the articulation angle limit while stepping. Jackknife is the first
  analysis result the program can offer, and it comes nearly free.

**This is the user's asked-for feature and the unlock for everything after it.** Getting from
one trailer to *N* is the whole architectural fight; getting from two to five is nothing.

### Phase 2 — Vehicles as data — PARTLY DONE

Done: `turn-vehicles.dat`, 17 vehicles, extracted from the library drawings rather
than typed, with provenance and the placeholder angles zeroed and explained. Optional —
its absence is a quiet fallback, proven by `turn-test-kernel-no-data-files`.
`turn-layers.dat` does the same for layer names, in the flagship's `Layers.dat`
format.

**QuickTurn is resolved: do not absorb the code.** Robert Livingston replied
(2026-09-12) that he cannot license it — he does not recall his sources, and the work
was done across several employers, so he does not know who owns it. His personal
goodwill is not a grant. But he also said where the vehicles came from: published
manuals and design standards, AASHTO, TAC-1999, Alberta Infrastructure. **Use his file
as an index of which standard holds which vehicle, and take the numbers from the
standards.** That yields better provenance than copying would, which is the standard
`turn-vehicles.dat` already holds itself to.

He confirmed two things worth recording. His multi-vehicle method is a hook point on
each unit becoming the path of the next — independently identical to Phase 1's design
and to Piotr's 2011 bone chain, which is three arrivals at the same architecture. And
he says the sweep envelope is the hardest part and his is brute force; Phase 3 handed
the union to AutoCAD's own REGION/UNION in C++ and does a three-segment rig over 190
steps in about five seconds. That is worth sending back to him.

Remaining: more vehicles, which needs external data, and the open questions in the
WANTED notice on turn.php.

### Phase 2 as originally written

- A plain-text vehicle library file, one entry per vehicle, human-readable and hand-editable.
  The 2.0 XML/LandXML work is the natural serialization; the LandXML ambition can wait, but
  the format should not fight it.
- Ship the AASHTO standard set (P, SU, BUS, WB-40/50/62/65/67, MH, and the rest of
  `Vehicle_Library/`) as data rather than as 2009 DWG blocks.
- `BUILDVEHICLE` becomes one way to author a vehicle, not the only source of truth.
- **Ask Robert Livingston about QuickTurn's library** (`..\QuickTurn`). His `QTMakeOUT.lsp` is
  50 curated standard vehicles in plain AutoLISP source — 21 AASHTO-2011, 11 TAC-1999,
  Alberta Infrastructure, plus rigs up to six segments. It is exactly this phase's content and
  it already exists. It carries no license header, so it cannot be absorbed without his
  explicit permission. See `../QuickTurn-NOTES.md`.

**Why:** it makes the library contributable. Someone in Australia can send a text file of
Austroads vehicles, and a user can diff it. Today they would have to send DWGs.

### Phase 3 — The envelope, and the answer — DONE (2026-09-10)

This is the phase where TURN stops being a drawing aid and becomes an analysis tool.

- **Swept path envelope** — done. `turn-draw-envelope` lays the body outline down at
  every step of every segment, regions them, unions them, and reduces the result to closed
  polylines on `C-TURN-ENVL`. It came out as one closed boundary of the whole swept area
  rather than "a polyline per side", which is the better deliverable: it is what gets
  hatched, offset and plotted. The union is AutoCAD's, in C++ — a polygon union written in
  AutoLISP over a few hundred bodies would be too slow to use. A three-segment rig over 190
  steps takes about five seconds end to end, so no chunking was needed.
- **Steering lock enforcement** — done. `turn-findings` compares the steer demanded at
  every step against `VEHSTEERLOCK`, and the articulation at every hitch against
  `VEHARTANGLE`. The inputs collected since 2006 are finally read by something.
- **A verdict** — done. `turn-report` prints the swept area, the tightest turn the
  vehicle is capable of, every finding, and then says plainly whether the manoeuvre is
  achievable as drawn.

Corner loci moved to their own role, `CRNR`, when `ENVL` was given to the real envelope. They
stay because they show *which* corner governs the boundary where.

### RELEASE — DONE (2026-09-13). 2.0.0 is published.

Decided and shipped: **both versions are served for now.** `turn-2.0.0.lsp` alongside
`turn-1.1.17.lsp`, with `turn-layers.dat` and `turn-vehicles.dat` as optional
companions. The User block method is gone from 2.0 and Tom accepted that; `turn.php`
says so and asks anyone relying on it to get in touch. The corrected library zips are
committed and uploaded.

Everything is on `hawsedc.com` master and pushed. The zips became tracked when Tom
changed `.gitignore` mid-session, so git now carries them.

**Phase 0's original aim is met by this, not by the 1.1.18 it imagined.** All five
1.1.17 defects are fixed outright in the 2.0 line rather than patched.

### Phase 4 — Drive it — KERNEL DONE (2026-09-13), command still to build

Interactive stepping — nudge the vehicle forward, steer, watch the rig follow — instead of
drawing a polyline and hoping. This is AutoTURN's SmartPath, and it is the feature users
describe when they say AutoTURN is easier. It is also the natural consumer of the Step model
already defined in 2.0.

**The kinematics half is done and tested**, in the pure kernel where it can be:
`turn-drive-step`, `turn-rest-states`, `turn-drive`,
`turn-drive-path`. It needed no new mathematics — only the next guide point, which
a steer angle and a travel distance determine. 35 checks.

The decision that made it cheap: **`turn-drive-path` returns the same shape as
`turn-path`**, so the envelope, the findings and the report work on a driven rig
unchanged. `turn-test-drive-equivalence` proves the two agree to 0.000000000000 over 482
states, which is what keeps drive mode from becoming a second, drifting tracking model.

Driving also reaches an analysis the drawn-course path cannot pose as naturally: a turn
that is impossible *without* exceeding the steering lock. 25° of steer on a WB-67 puts
the tractor's trailing axle inside the trailer's own wheelbase, so the trailer can never
settle and the rig folds — reported as a jackknife from the hitch.

**`c:drive` is built** (2026-09-14). The cursor is the driver's eyes: the rig steers
toward it as hard as the steering lock allows, one calculation step per cursor event,
and stops when you stop moving. ENTER or SPACE finishes and the collected inputs go
through the ordinary drawing, envelope and report.

One step per event is a correctness requirement: driving *until* the rig reaches the
cursor never terminates when the cursor is inside the minimum turning circle, and that
first version hung AutoCAD.

**What remains is judgement, not code.** Whether driving with the cursor feels right,
and whether accumulating `grdraw` outlines are what a user wants to see while steering,
are questions a test harness cannot answer — `grread` waits for a human. Tom's hands
are the next step.

### Phase 5 — Long tail

Reverse driving. Clearance offsets. Collision detection against selected geometry (the 2.0
notes say tblocks were chosen partly to make this possible). Speed / superelevation.
Reporting. 3D.

## Two decisions I would recommend now

**1. 1.1.17 is the trunk; 2.0 is the destination, not a restart.** The 1.2 and 2.0 files are
valuable as *specifications* — the segment model, the point flags, the XML convention — but
they are unfinished scaffolding, and 1.1.17 is working code with a correct tracking engine.
Refactor 1.1.17 toward the 2.0 data model in place, one phase at a time, with the test harness
proving each step. Two previous rewrites stalled; a third would too.

**2. Keep it one file.** FreeLand tools are downloaded and loaded individually by people who
know nothing but `APPLOAD`. A vehicle library data file is a reasonable second file. An
installer is not.

## Standing constraints, not phases

**AutoLISP provides no namespacing, so we provide it. One prefix: `turn-`.** There is
a single global namespace per AutoCAD session, shared with every other application the
user has loaded, so an unprefixed `tt-write` is a collision waiting for whoever else
defines one. Commands are `c:turn`, `c:drive`, `c:buildvehicle`, `c:bv`.

It binds test scaffolding as well as shipped code, because the harness loads into the
same session. The flagship names its test helpers `haws-assert-equal` for this reason.

Sub-namespacing goes *after* the prefix — `turn-test-`, `turn-test-drive-`,
`turn-tool-`, `turn-probe-` — which is still one prefix.

*Raised by Tom 2026-09-14 on finding unprefixed functions in `devtools/`, and
consolidated the same day from nineteen prefixes to one. `wiki-` is retired: it
recorded the AutoCAD Wiki origin and no longer earned its keep.*

**Keep it one file, loadable by APPLOAD.** FreeLand tools are downloaded and loaded
individually by people who know nothing but `APPLOAD`. A data file or two is
reasonable. An installer is not.

## What I would not chase

- **3D first.** The 2D envelope is the deliverable on 95% of plan sheets. 3D is Phase 5 for a
  reason.
- **A LandXML standards campaign.** The 2015 notes hoped to get the LandXML standard extended.
  Worth designing *toward*; not worth blocking on.
- **Harmonizing the User Block and Generated Vehicle methods early.** The 2.0 tblock model
  dissolves that distinction naturally once segments carry their own drawable geometry. Doing
  it before Phase 1 is wasted effort.
