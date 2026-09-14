# TURN 2.0.0 — punch list for hand testing in AutoCAD

For Tom, 2026-09-13. Work top to bottom; each item says what to do and what should
happen. Note anything that differs.

## First, what this is built out of

You asked. Verified by grep against `src/turn.lsp`, not from memory:

| | |
|---|---|
| Language | **AutoLISP only.** One file, 1,765 lines. |
| DCL | **None.** Zero `load_dialog` / `new_dialog` / `action_tile` / `.dcl`. |
| .NET | **None.** |
| ActiveX | 7 calls, all `vlax-curve-*`, to sample the course off the curve object. That is Visual LISP, same as 1.1.x already used. |
| User interface | Command line only. 15 `getdist`/`getint`/`getkword` prompts and 2 `entsel`. |
| Ships as | `turn-2.0.0.lsp`, plus optional `turn-layers.dat` and `turn-vehicles.dat`. |

Nothing to install, nothing compiled, still APPLOAD-and-go. If you want a dialog
later, that is a deliberate decision to take, not something that has crept in.

## Setup

Open a blank drawing. If AutoCAD complains about loading from an untrusted folder,
either put the folder on TRUSTEDPATHS or drag the file in and accept the prompt.
**Please note whether you hit that** — it bit the automated smoke test, and it will
bite users who unzip to a random folder.

---

## 1. Load

**Do:** APPLOAD or drag `turn-2.0.0.lsp` in.

**Expect:** `TURN 2.0.0 loaded. Type TURN or BV.`

- [ ] Banner says 2.0.0

---

## 2. BUILDVEHICLE — single unit, and a look at the prompts

**Do:** `BV`. Answer for an SU: name `SU`, body 30, width 8, front overhang 4,
wheelbase 20, track 8, steering lock — take the default.

**This is the prompt wording you wanted to review.** Exact sequence:

```
Name for this vehicle <Truck>:
Overall length of the tractor body:
Overall width of the tractor body, outside to outside:
Front overhang, front bumper back to the steering axle:
Wheelbase, steering axle back to the rear axle (use the centroid if there are several):
Track width, centre of one tire to centre of the other:
Maximum steering lock angle <30.0>:
Does SU tow another trailer? [Yes/No]:
```

**One judgement call for you, at that steering lock prompt.** 2.0 offers a default of
**30 degrees**, and 70 degrees for articulation later. Those are plausible engineering
values rather than the 28.6479 placeholder 1.1.x wrote, and unlike the placeholder they
are real enough to drive a verdict: accept them and TURN will tell the user the move is
or is not achievable on that basis. The alternative is to default to 0, which means "do
not check" and keeps the analysis silent until someone supplies a real figure. **Which
do you want?** A confident wrong verdict is worse than none, and that is your call, not
mine.

- [ ] Decide: 30/70 defaults, or 0 and stay silent

Compare against 1.1.17, which asked *"Half of maximum axel width to middle of
wheels"* and silently doubled it. 2.0 asks for the whole width and takes it at face
value.

- [ ] Prompts read clearly
- [ ] Nothing asks for a half-dimension
- [ ] A block is drawn, with the dimensions on it as attributes

---

## 3. BUILDVEHICLE — one trailer. The two prompts Kenya could not tell apart.

**Do:** `BV` again, WB-67 figures: body 27.92, width 8, overhang 4, wheelbase 19.5,
track 8. Answer **Yes** to the trailer question.

**Expect this wording** (the hitch question is two lines):

```
Does Truck tow another trailer? [Yes/No]: Yes
How far BEHIND Truck's rear axle its hitch sits
  (0 for a fifth wheel over the axle; negative if ahead of it) <0.0>:
Maximum articulation angle at that hitch <70.0>:
Name for this trailer <Trailer1>:
Hitch back to THIS trailer's axle - the trailer's own wheelbase:
Track width, centre of one tire to centre of the other:
How far the trailer nose reaches FORWARD of the hitch (0 if it starts at the hitch) <0.0>:
Overall length of the trailer body:
Overall width of the trailer body, outside to outside:
Does Trailer1 tow another trailer? [Yes/No]:
```

Three things to check, all of which cost Kenya a week in 1.1.17:

- [ ] **The two hitch questions are now distinguishable.** One says "How far BEHIND
      *&lt;name&gt;*'s rear axle", the other says "THIS trailer's own wheelbase".
      Kenya answered both 45.5 and got a spiral.
- [ ] **The hitch defaults to 0**, which is right for a fifth wheel over the drive
      axle. She had to guess.
- [ ] **Nothing asks for a negative.** 1.1.17 said "forward is NEGATIVE" and she
      typed 3 instead of -3. 2.0 asks how far it reaches FORWARD and takes a positive.

For a WB-67 answer: hitch 0, trailer wheelbase 45.5, track 8.5, nose forward 3,
body 53, width 8.5.

---

## 4. Two trailers — the feature that was asked for

**Do:** `BV` again. Say **Yes** at the trailer question twice.

- [ ] It asks a second time and keeps going
- [ ] The block that comes out carries all three segments

---

## 5. TURN on a proper course — the headline features

**Do:** Draw a polyline several hundred feet long: straight run, arc of 100 ft or
more, straight run out. Insert your WB-67 block at the start, rotated along the first
leg. `TURN`, pick the block, pick the course *away from the block*.

**Expect at the command line:**

```
TURN: 2 segment(s), NNN steps.
TURN: course NNN.N long, N.N x the rig's 65.0 wheelbase.
TURN: swept area is NNNNN.N square drawing units.
TURN: tightest turn this vehicle can make is NN.NN radius at the steering axle.
TURN: manoeuvre achievable. No limits exceeded.
```

- [ ] Tire paths and body outlines drawn
- [ ] **A closed swept-path envelope on `C-TURN-ENVL`** — no 1.1.x version ever drew
      this. This is the line a plan sheet actually wants.
- [ ] Swept area reported
- [ ] Verdict printed
- [ ] `TURN` did **not** litter POINT entities (1.1.17 drew and erased dozens)

---

## 6. Kenya's failure, reproduced on purpose

**Do:** Same vehicle, but draw a course only about 80 ft long. Run `TURN`.

**Expect:**

```
TURN: course 8N.N long, 1.N x the rig's 65.0 wheelbase.
  ! Short course. A trailer takes several rig lengths to settle into its
    true articulation. Hundreds of feet is normal; long does not hurt.
```

- [ ] Advisory appears
- [ ] It still draws — advice, not a refusal
- [ ] The rig does look like one straight box, i.e. we have reproduced her symptom
      and now explain it

---

## 7. Any curve, not just a polyline

1.1.17 used MEASURE and needed a polyline. 2.0 samples the curve itself.

**Do:** Run `TURN` picking, in separate runs: a plain ARC, a SPLINE, and if you have
Civil 3D handy, an alignment.

- [ ] Arc works
- [ ] Spline works
- [ ] Civil 3D alignment works

---

## 8. The mistake that probably caused the original bug report

The vehicle block sits exactly where the user is told to pick the course.

**Do:** Run `TURN` and deliberately pick the **block** when asked for the course.

**Expect:** a plain message telling you to pick the path, not the block, and to zoom
in. 1.1.17 said `Cannot measure that object` and then drew nothing useful.

- [ ] Message is clear and it does not draw garbage

---

## 9. An AASHTO library block

**Do:** Insert `2004_AASHTO_WB-67.dwg` from the vehicle library zip and run `TURN` on
it directly, no BUILDVEHICLE.

- [ ] Works with no method prompt (2.0 removed the User block method)
- [ ] Dimensions come off the block

---

## 10. Layer names are yours now

**Do:** Put `turn-layers.dat` on the support path. Run TURN — confirm default names.
Then uncomment the **LEGACY NAMES** block at the bottom of the file and run again.

- [ ] Defaults give `C-TURN-TRCK-FRNT-LEFT`, `C-TURN-TRL1-BODY`, `C-TURN-ENVL`
- [ ] Legacy block gives back the 1.1.x names, e.g. `C-TURN-TRCK-FRONT-LEFT-PATH`
- [ ] A second trailer lands on `C-TURN-TRL2-BODY`

---

## 11. Works with nothing but the .lsp

**Do:** Move both `.dat` files off the support path. Run `BV` then `TURN`.

- [ ] No error about missing files
- [ ] Layers still created with built-in names
- [ ] Everything still draws

(Automated as `ttc-test-no-data-files`, 8 checks — but worth seeing once by hand,
since it is the FreeLand premise: one file, downloaded and loaded.)

---

## What I could not test for you

- **Anything about how the prompts *read*.** The harness can answer them; it cannot
  tell me they make sense. That is item 2 and 3 and it is the main thing I want your
  eye on.
- **Civil 3D alignments.** The code path is the same `vlax-curve-*` one as arcs and
  splines, which the harness does exercise, but I have not run it against a real
  alignment.
- **The trusted-path prompt on first load.** See Setup.
- **Whether 2.0 output looks right to an engineer.** 129 automated checks say the
  numbers are self-consistent and match published AASHTO overall lengths. They do not
  say the drawing looks like what you would draw by hand.
