# TURN - envelope fidelity (BASELINE, before fills)

Run at CDATE 20260922.211615
AutoCAD 25.1s (LMS Tech) product AutoCAD


## Escape: ground the rig covers that the envelope leaves out

WB-67, 90 degree left turn on radius 50, three step lengths.

- step 2.40: 159 states, area 5677.46, 362 vertices, worst escape 0.6088 (corner at (-205.03 -57.46))
- step 1.20: 317 states, area 5699.47, 700 vertices, worst escape 0.3047 (corner at (-180.29 -4.04))
- step 0.60: 632 states, area 5710.86, 1347 vertices, worst escape 0.1525 (corner at (-179.61 -3.6))
- PASS every run gave exactly one envelope loop
- halving the step cut the escape by 2.00 then 2.00 (about 2 = first order, about 4 = second order)
- **FAIL** the escape is second order: halving the step cuts it by more than 3

## Summary

- passed: 1
- failed: 1

**THERE ARE FAILURES**
