# TURN tracking kernel unit tests, drive kernel included

Run at CDATE 20260913.234233
AutoCAD 24.3s (LMS Tech) product AutoCAD


## Arcsine (1.1.x returned tan(asin x); the atan was missing)

- PASS asin 0.0 (expected ~0.000000, got 0.000000)
- PASS asin 0.5 (expected ~0.523599, got 0.523599)
- PASS asin -0.5 (expected ~-0.523599, got -0.523599)
- PASS asin 1.0 (expected ~1.570796, got 1.570796)

## Angle normalisation

- PASS normalize 0 (expected ~0.000000, got 0.000000)
- PASS normalize 2pi (expected ~0.000000, got 0.000000)
- PASS normalize 350 deg reads as -10 (expected ~-0.174533, got -0.174533)

## Straight course: nothing should turn

- PASS one state per course point (expected 41, got 41)
- PASS final heading unchanged (expected ~0.000000, got 0.000000)
- PASS trailing axle stays a wheelbase behind (expected ~14.000000, got 14.000000)
- PASS trailing axle stayed on the centreline (expected ~0.000000, got 0.000000)
- PASS no steer demanded (expected ~0.000000, got 0.000000)

## Circular course: trailing axle radius = sqrt(R^2 - L^2)

- PASS steady-state trailing radius (expected ~48.000000, got 48.000000)
- PASS steer angle = asin(L/R) (expected ~0.283794, got 0.283794)

## Segment chain: a tractor and two trailers

- PASS one path per segment (expected 3, got 3)
- PASS every path has one state per course point (expected (901 901 901), got (901 901 901))
- trailing-axle radii by segment: (58.3438 57.1752 55.9375)
- PASS trailer 1 tracks inside the tractor
- PASS trailer 2 tracks inside trailer 1
- PASS all radii are positive and finite

## Towing does not disturb the segment doing the towing

- PASS solo vehicle yields one path (expected 1, got 1)
- PASS towing vehicle yields two paths (expected 2, got 2)
- PASS lead segment tracks identically either way (expected ~0.000000, got 0.000000)

## Body geometry

- PASS front left x (expected ~3.000000, got 3.000000)
- PASS front left y (expected ~4.000000, got 4.000000)
- PASS front right y (expected ~-4.000000, got -4.000000)
- PASS rear right x (expected ~-17.000000, got -17.000000)
- PASS rear left y (expected ~4.000000, got 4.000000)

## Corner loci - the left/right swept lines users ask for

- PASS one locus point per step (expected 361, got 361)
- outer swept radius (front outboard corner): 54.7083
- inner swept radius (tightest body corner): 44.1022
- swept width: 10.6062 for a body only 8.0000 wide
- PASS front outboard corner sweeps outside the guide circle
- PASS body reaches inside the trailing axle circle
- PASS swept width exceeds the body width

## Analysis: steering lock and jackknife

- PASS gentle curve reports nothing (expected 0, got 0)
- reported: Steering lock exceeded on Tractor: course demands 48.3, vehicle has 30.0.
- PASS tight radius is reported as unachievable

## Reading a vehicle from block attributes

- PASS three segments read (expected 3, got 3)
- PASS segment names (expected (WB-50 Box Pup), got (WB-50 Box Pup))
- PASS tractor wheelbase (expected ~14.000000, got 14.000000)
- PASS trailer wheelbase comes from HITCHTOWHEEL (expected ~12.000000, got 12.000000)
- PASS tractor front-hang is forward-positive (expected ~3.000000, got 3.000000)
- PASS trailer front-hang is negated to the single convention (expected ~-2.000000, got -2.000000)
- PASS steer lock converted to radians (expected ~0.523599, got 0.523599)
- PASS last segment tows nothing
- PASS legacy no-trailer block reads as one segment (expected 1, got 1)

## Layer keys resolve to NCS-compliant names

- PASS segment 0 body (expected C-TURN-TRCK-BODY, got C-TURN-TRCK-BODY)
- PASS segment 1 body (expected C-TURN-TRL1-BODY, got C-TURN-TRL1-BODY)
- PASS segment 2 body (expected C-TURN-TRL2-BODY, got C-TURN-TRL2-BODY)
- PASS segment 0 rear left path (expected C-TURN-TRCK-REAR-LEFT, got C-TURN-TRCK-REAR-LEFT)
- PASS segment 3 corner loci (expected C-TURN-TRL3-CRNR, got C-TURN-TRL3-CRNR)
- PASS vehicle envelope (expected C-TURN-ENVL, got C-TURN-ENVL)

## Vehicle library: turn-vehicles.dat

- keys: (A-BUS BUS-40 BUS-45 CITY-BUS MH MHB P PB PT S-BUS-36 S-BUS-40 SU WB-40 WB-50 WB-62 WB-65 WB-67)
- PASS all 17 library drawings are represented (expected 17, got 17)
- PASS WB-50 is present
- PASS P is present
- PASS WB-50 is a two-segment vehicle (expected 2, got 2)
- PASS WB-50 tractor wheelbase (expected ~12.500000, got 12.500000)
- PASS WB-50 trailer hitch-to-axle (expected ~35.500000, got 35.500000)
- PASS WB-50 tractor tows
- PASS WB-50 trailer tows nothing
- PASS WB-50 trailer nose overhangs the fifth wheel (expected ~3.000000, got 3.000000)
- PASS A-BUS rear section starts behind the articulation joint (expected ~-2.000000, got -2.000000)
- PASS WB-50 steering lock is absent, not a placeholder (expected ~0.000000, got 0.000000)
- PASS segments still carrying the 0.5-radian placeholder angle (expected 0, got 0)
- PASS library vehicles that fail to track a curve (expected 0, got 0)
- PASS a missing library reads as empty, not an error (expected 0, got 0)

## Library unit conversion

- PASS feet to metres (expected ~0.304800, got 0.304800)
- PASS metres to metres (expected ~1.000000, got 1.000000)
- PASS an unknown unit reads as nil
- PASS wheelbase scaled (expected ~4.267200, got 4.267200)
- PASS negative front-hang keeps its sign when scaled (expected ~-0.609600, got -0.609600)
- PASS steering lock is an angle and must not scale (expected ~0.523599, got 0.523599)
- PASS a segment that tows nothing still tows nothing after scaling

## Overall length - the check a user can make with a tape measure

- PASS WB-67 overall length matches the published 73.5 ft (expected ~73.500000, got 73.500000)
- PASS a lone tractor is its own body length (expected ~20.000000, got 20.000000)
- PASS Kenya's mis-entered rig comes out at 125 (expected ~125.000000, got 125.000000)

## Minimum turning radius from the steering lock

- PASS 19.5 wheelbase at 30 degrees lock (expected ~39.000000, got 39.000000)
- PASS the lock implied by a 45 ft turning radius (expected ~45.000000, got 45.000000)
- PASS a zero steering lock reports no radius, not a wrong one
- PASS no library vehicle claims a turning radius it cannot support

## Course length against rig wheelbase

- PASS WB-67 rig wheelbase is tractor + hitch + trailer (expected ~65.000000, got 65.000000)
- PASS a lone tractor's rig wheelbase is its own wheelbase (expected ~14.000000, got 14.000000)
- PASS a 100 unit straight course measures 100 (expected ~100.000000, got 100.000000)
- PASS 82 ft under a WB-67 is below the short-course threshold
- PASS 500 ft under a WB-67 is not

## Runs with neither data file present

- PASS a missing vehicles file yields an empty library
- PASS and no keys
- PASS and asking for a vehicle gives nil, not an error
- PASS built-in tractor body layer (expected C-TURN-TRCK-BODY, got C-TURN-TRCK-BODY)
- PASS built-in trailer 2 body layer (expected C-TURN-TRL2-BODY, got C-TURN-TRL2-BODY)
- PASS built-in envelope layer (expected C-TURN-ENVL, got C-TURN-ENVL)
- PASS a layer definition still carries colour and linetype
- PASS a hand-built rig still tracks with no data files

## Library scaling follows INSUNITS

- PASS ft reads as Feet (expected Feet, got Feet)
- PASS M reads as Meters (expected Meters, got Meters)
- PASS in reads as Inches (expected Inches, got Inches)
- PASS INSUNITS 1 names itself Inches (expected Inches, got Inches)
- PASS a feet library in a drawing declaring inches scales by 12 (expected ~12.000000, got 12.000000)
- PASS INSUNITS 2 names itself Feet (expected Feet, got Feet)
- PASS a feet library in a drawing declaring feet does not scale (expected ~1.000000, got 1.000000)
- PASS a feet library in a drawing declaring metres scales by 0.3048 (expected ~0.304800, got 0.304800)
- PASS INSUNITS 0 names nothing
- PASS an undeclared drawing is left unscaled (expected ~1.000000, got 1.000000)
- PASS keyword string is space delimited (expected A-BUS WB-67, got A-BUS WB-67)
- PASS a single key has no trailing space (expected SU, got SU)

## The remembered step must still suit the vehicle

- PASS with no memory, the default is wheelbase/10 (expected ~1.400000, got 1.400000)
- PASS a finer remembered step is offered again (expected ~0.500000, got 0.500000)
- PASS a remembered step longer than the shortest body is refused (expected ~1.400000, got 1.400000)
- PASS a remembered step equal to the body length is refused (expected ~1.400000, got 1.400000)
- PASS the shortest body in the rig is the one that governs (expected ~18.000000, got 18.000000)

## Driving straight

- PASS the guide axle advances by exactly the distance driven (expected ~5.000000, got 5.000000)
- PASS it advances along the heading (expected ~0.000000, got 0.000000)
- PASS heading does not change with no steer (expected ~0.000000, got 0.000000)
- PASS nothing turned (expected ~0.000000, got 0.000000)
- PASS the trailing axle stays one wheelbase behind (expected ~20.000000, got 20.000000)

## Steer in, steer out

- PASS steering 5.0 degrees reads back as 5.0 (expected ~0.087266, got 0.087245)
- PASS steering 15.0 degrees reads back as 15.0 (expected ~0.261799, got 0.261735)
- PASS steering 30.0 degrees reads back as 30.0 (expected ~0.523599, got 0.523474)
- PASS steering -20.0 degrees reads back as -20.0 (expected ~0.349066, got 0.348980)

## Constant steer traces a circle of the right radius

- PASS one state per step, plus the state it started in (expected 201, got 201)
- wheelbase 20.0, steer 30 degrees: guide radius 40.000, trailing radius 34.641
- PASS the guide axle holds that radius to within 1 percent
- PASS the trailing axle rides wheelbase/tan(steer), also within 1 percent
- radius error at step 0.50: 0.527864
- radius error at step 0.25: 0.265390
- ratio: 1.989 (first order predicts ~2)
- PASS halving the step at least halves the error

## The rig at rest, before it is driven anywhere

- PASS one state per segment (expected 2, got 2)
- PASS the tractor's guide axle is where we put it (expected ~0.000000, got 0.000000)
- PASS the tractor's trailing axle is one wheelbase back (expected ~19.500000, got 19.500000)
- PASS the trailer is hitched at the tractor's drive axle (expected ~0.000000, got 0.000000)
- PASS and stretches its own wheelbase behind that (expected ~45.500000, got 45.500000)
- PASS everything starts straight, so no articulation (expected ~0.000000, got 0.000000)

## Driving and following a course are the same kinematics

- PASS same number of segments (expected 2, got 2)
- PASS same number of steps (expected 241, got 241)
- worst guide-point disagreement over 482 states: 0.000000000000
- PASS every segment's guide point agrees to within a millionth of a unit
- worst heading disagreement: 0.000000000000 degrees
- PASS every heading agrees too

## A driven trailer tracks inside the tractor

- 10 degrees of steer: the tractor's trailing axle rides 110.59, comfortably outside the 45.5 trailer wheelbase
- PASS articulation starts at zero
- PASS and grows as the turn is held
- articulation after 400 ft: 23.63 degrees max
- PASS the trailer's trailing axle stays inside the tractor's path

## Driving into a turn the rig cannot make

- 25 degrees of steer puts the tractor's trailing axle on 41.82, INSIDE the 45.5 trailer wheelbase - the trailer cannot follow
- articulation reaches 93.62 degrees against a 70.0 limit
- PASS articulation passes the vehicle's articulation limit
- PASS and it is reported, even though the steering lock was never exceeded
- reported: Jackknife: articulation behind Tractor reaches 93.6, limit is 70.0.

## A driven path is the same shape as a followed one

- PASS one list of states per segment (expected 2, got 2)
- PASS every segment has the same number of states
- PASS the course length of a driven path is computable
- PASS and equals the distance actually driven (expected ~40.000000, got 40.000000)
- PASS wiki-turn-findings accepts a driven path
- PASS 15 degrees of steer is inside a 30 degree lock, so no finding

## Steering past the lock is reported, not silently clamped

- PASS driving 45 degrees on a 30 degree lock produces a finding
- reported: Steering lock exceeded on Truck: course demands 44.0, vehicle has 30.0.

## Summary

- passed: 141
- failed: 0

**ALL CHECKS PASSED**
