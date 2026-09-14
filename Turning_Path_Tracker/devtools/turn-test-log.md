# TURN 2.0.0 - the punch list, automated

Run at CDATE 20260914.012442
AutoCAD 25.1s (LMS Tech) product AutoCAD

- [01:24:42] start

## Item 1 - Load

- version: `2.1.0-dev`
- PASS a version is set
- PASS the header banner agrees with general.version
- PASS TURN is defined
- PASS BUILDVEHICLE is defined
- PASS the BV alias is defined
- PASS DRIVE is defined
- PASS the load banner names TURN, DRIVE and BV

## Item 4 - two trailers, the asked-for feature

- PASS a block was produced
- PASS the block carries the second trailer's tags
- PASS three segments read back off the block (expected 3, got 3)
- PASS the pup's wheelbase survived the round trip (expected ~10.000000, got 10.000000)
- PASS only the last segment tows nothing

## Item 5 - a proper course, the headline features

- PASS tire paths drawn for the tractor
- PASS tire paths drawn for the trailer
- PASS body outlines plotted repeatedly
- PASS a swept path envelope exists on C-TURN-ENVL
- PASS the envelope is reported with an area
- PASS every envelope loop is a CLOSED polyline
- PASS TURN littered no POINT entities (expected 0, got 0)
- PASS the step count is reported
- PASS the course is reported against the wheelbase
- PASS the swept area is reported
- PASS the tightest turn is reported
- PASS a verdict is printed
- PASS a long course draws NO short-course advisory

## Item 6 - Kenya's failure, reproduced on purpose

- PASS the course really is short for this rig
- PASS the short-course advisory appears
- PASS it explains why, in rig lengths
- PASS it still drew the trailer's tire paths
- PASS it still drew an envelope
- 150 ft radius, 80 ft of arc:  12.37 degrees of articulation
- 150 ft radius, 800 ft of arc: 17.81 degrees of articulation
- PASS 80 ft never develops the articulation the rig really reaches

## Item 8 - the mistake that probably caused the bug report

- PASS a vehicle block is an INSERT
- PASS TURN rejects the block as a course
- PASS and accepts a real curve
- PASS an ARC is accepted too

## Item 9 - a published AASHTO block, no BUILDVEHICLE

- PASS the WB-67 library drawing is present
- PASS it inserted
- PASS attributes were read off it
- PASS wheelbase 19.50 comes off the block (expected ~19.500000, got 19.500000)
- PASS front overhang 4.00 comes off the block (expected ~4.000000, got 4.000000)
- PASS body width 8.00 comes off the block (expected ~8.000000, got 8.000000)
- PASS TrailHave Yes yields two segments (expected 2, got 2)
- PASS the trailer's kingpin-to-axle is 45.50 (expected ~45.500000, got 45.500000)

## Item 10 - layer names are yours now

- PASS default tractor front left (expected C-TURN-TRCK-FRNT-LEFT, got C-TURN-TRCK-FRNT-LEFT)
- PASS default first trailer body (expected C-TURN-TRL1-BODY, got C-TURN-TRL1-BODY)
- PASS a second trailer needs no new entry (expected C-TURN-TRL2-BODY, got C-TURN-TRL2-BODY)
- PASS the envelope has no segment stem (expected C-TURN-ENVL, got C-TURN-ENVL)
- PASS the shipped turn-layers.dat carries a legacy block
- PASS legacy tractor front left (expected C-TURN-TRCK-FRONT-LEFT-PATH, got C-TURN-TRCK-FRONT-LEFT-PATH)
- PASS legacy trailer body (expected C-TURN-TRAL-BODY, got C-TURN-TRAL-BODY)
- PASS a second trailer keeps its modern name under legacy (expected C-TURN-TRL2-BODY, got C-TURN-TRL2-BODY)

> The legacy toggle is exercised through the override list that `turn-read-layers-dat` produces, parsed out of the shipped file. Whether `(findfile)` locates that file on a given machine's support path is a configuration question, not a code one.

## Item 11 - works with nothing but the .lsp

- PASS with no layers.dat the built-in names are used (expected C-TURN-TRCK-FRNT-LEFT, got C-TURN-TRCK-FRNT-LEFT)
- PASS with no vehicles.dat the library is simply empty
- PASS and everything still draws
- PASS layers were still created

## Still Tom's, deliberately

- **Item 2 and 3: do the BUILDVEHICLE prompts read clearly?**
  Specifically whether the tractor's rear-hitch question and the
  trailer's kingpin question can be told apart. That confusion is what
  produced the original bug report. A harness answers prompts; it cannot
  judge their wording.
- **Item 2: the 30/70 steering-lock and articulation defaults.** Whether
  to keep offering them or to default to 0 and stay silent is an
  engineering call about standing behind numbers we did not measure.
- [01:25:02] finished

## Summary

- passed: 55
- failed: 0

**ALL CHECKS PASSED**
