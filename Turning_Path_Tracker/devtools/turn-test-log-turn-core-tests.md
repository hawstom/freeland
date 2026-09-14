# TURN 2.0.0-dev tracking kernel unit tests

Run at CDATE 20260909.032039
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

## Layer naming stays backward compatible

- PASS segment 0 body (expected C-TURN-TRCK-BODY, got C-TURN-TRCK-BODY)
- PASS segment 1 body (expected C-TURN-TRAL-BODY, got C-TURN-TRAL-BODY)
- PASS segment 2 body (expected C-TURN-TRAL2-BODY, got C-TURN-TRAL2-BODY)
- PASS segment 0 rear left path (expected C-TURN-TRCK-REAR-LEFT-PATH, got C-TURN-TRCK-REAR-LEFT-PATH)

## Summary

- passed: 46
- failed: 0

**ALL CHECKS PASSED**
