# TURN - envelope fidelity

Run at CDATE 20260926.154202
AutoCAD 25.1s (LMS Tech) product AutoCAD


## Escape: ground the rig covers that the envelope leaves out

WB-67, 90 degree left turn on radius 50, three step lengths.

- [15:42:03] step 2.40: envelope starts, 16 polygons
- [15:42:10] envelope done
- step 2.40: 159 states, area 5724.82, 217 vertices, worst escape 0.0155 (corner at (-205.26 -50.25))
- [15:42:15] step 1.20: envelope starts, 16 polygons
- [15:42:30] envelope done
- step 1.20: 317 states, area 5725.10, 415 vertices, worst escape 0.0039 (corner at (-205.26 -50.91))
- [15:42:46] step 0.60: envelope starts, 16 polygons
- [15:43:36] envelope done
- step 0.60: 632 states, area 5725.15, 794 vertices, worst escape 0.0022 (mid-edge at (-95.59 -4.25))
- PASS every run gave exactly one envelope loop
- halving the step cut the escape by 4.00 then 1.80 (about 2 = first order, about 4 = second order)
- documented floor (1e-4 of the longest body): 0.0053
- PASS the escape is second order: halving the step cuts it by more than 3
- PASS then second order again, or down at the floor

## Overreach: ground the envelope claims that the rig never covered

- PASS one envelope loop to measure
- step 1.20, reference of 16 placements per step: worst envelope point outside them all 0.009493 at (-204.44 -77.35)
- step 1.20, reference of 64 placements per step: worst envelope point outside them all 0.001738 at (-161.36 -21.54)
- PASS any overreach is the reference's own sawtooth (4x finer cuts it by more than 3) or under the floor

## Every tire path lies inside the envelope

- PASS WB-67, track equal to body: one envelope loop
- WB-67, track equal to body: worst tire path point outside the envelope 0.0003 (TRL1-REAR-LEFT at (-89.19 -4.25))
- PASS WB-67, track equal to body: every tire path lies inside the envelope, to within the floor 0.0053
- PASS flatbed 4 wide on a 6 ft track: one envelope loop
- flatbed 4 wide on a 6 ft track: worst tire path point outside the envelope 0.0013 (TRCK-REAR-LEFT at (-195.94 -125.37))
- PASS flatbed 4 wide on a 6 ft track: every tire path lies inside the envelope, to within the floor 0.0034

## A rig that starts facing against its course

- PASS no regions left on the envelope layer (expected 0, got 0)
- PASS an envelope was drawn
- PASS every envelope loop is flagged closed
- PASS the report says the vehicle starts facing away from the course

## Summary

- passed: 13
- failed: 0

**ALL CHECKS PASSED**
