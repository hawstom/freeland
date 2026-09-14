# TURN 2.0.0-dev integration - tractor, trailer and pup

Run at CDATE 20260913.232315
AutoCAD 24.3s (LMS Tech) product AutoCAD

- [23:23:15] start

## BUILDVEHICLE: three segments, no prompting

- [23:23:15] vehicle block built
- PASS a block insert was produced
- PASS round trip recovers three segments (expected 3, got 3)
- PASS round trip recovers the names (expected (Truck Trailer1 Pup), got (Truck Trailer1 Pup))
- PASS round trip recovers the wheelbases (expected (14.0 12.0 10.0), got (14.0 12.0 10.0))
- PASS round trip preserves front-hang signs (expected (3.0 -2.0 -2.0), got (3.0 -2.0 -2.0))
- PASS round trip preserves which segments tow

## Course sampled straight off the curve

- [23:23:15] course sampled
- PASS the course has plenty of points
- PASS travel starts at the picked end (expected ~0.000000, got 0.000000)

## TURN: track the chain and draw it

- [23:23:18] TURN finished
- PASS one path per segment (expected 3, got 3)

## What reached the drawing

**Segment 0 - TRCK**
- PASS one pline on C-TURN-TRCK-FRNT-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-FRNT-RGHT (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-REAR-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-REAR-RGHT (expected 1, got 1)
- PASS four corner loci on C-TURN-TRCK-CRNR (expected 4, got 4)
- PASS hitch path on C-TURN-TRCK-HTCH (expected 1, got 1)
- PASS body outlines plotted on C-TURN-TRCK-BODY
**Segment 1 - TRL1**
- PASS one pline on C-TURN-TRL1-FRNT-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRL1-FRNT-RGHT (expected 1, got 1)
- PASS one pline on C-TURN-TRL1-REAR-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRL1-REAR-RGHT (expected 1, got 1)
- PASS four corner loci on C-TURN-TRL1-CRNR (expected 4, got 4)
- PASS hitch path on C-TURN-TRL1-HTCH (expected 1, got 1)
- PASS body outlines plotted on C-TURN-TRL1-BODY
**Segment 2 - TRL2**
- PASS one pline on C-TURN-TRL2-FRNT-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRL2-FRNT-RGHT (expected 1, got 1)
- PASS one pline on C-TURN-TRL2-REAR-LEFT (expected 1, got 1)
- PASS one pline on C-TURN-TRL2-REAR-RGHT (expected 1, got 1)
- PASS four corner loci on C-TURN-TRL2-CRNR (expected 4, got 4)
- PASS hitch path on C-TURN-TRL2-HTCH (expected 0, got 0)
- PASS body outlines plotted on C-TURN-TRL2-BODY

## AIA / National CAD Standard layer names

- PASS layer names with a field that is not 4 characters (expected 0, got 0)

## Swept path envelope

- PASS closed polylines on C-TURN-ENVL
- PASS regions left behind on the envelope layer (expected 0, got 0)
- PASS every envelope polyline is closed (expected 1, got 1)
- envelope extents: (-154.701 -53.9962 50.0 4.1934)
- corner locus extents: (-154.701 -53.9962 50.0 4.1934)
- PASS the envelope encloses every corner locus
- swept area: 2100.0, standing footprint: 416.0
- PASS swept area exceeds the rig's standing footprint
- PASS swept area fits inside the envelope's own bounding box

## Polyline integrity

- PASS polylines whose DXF 90 disagrees with their vertex count (expected 0, got 0)
- PASS TURN drew some polylines at all

## A step coarser than the shortest body opens holes

- PASS the fine-step run gave exactly one closed envelope (expected 1, got 1)
- loops from the coarse run: 2
- PASS a step longer than the shortest body opens holes
- PASS every envelope loop is flagged closed, not merely shut-looking
- PASS no zero-area slivers survive

## Nothing was left behind

- PASS no stray POINT entities (1.1.x littered these) (expected 0, got 0)

## Model space census

| Layer | Type | Count |
|---|---|---|
| 0 | INSERT | 1 |
| 0 | LWPOLYLINE | 1 |
| C-TURN-ENVL | LWPOLYLINE | 3 |
| C-TURN-TRCK-BODY | LWPOLYLINE | 16 |
| C-TURN-TRCK-CRNR | LWPOLYLINE | 8 |
| C-TURN-TRCK-FRNT-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRCK-FRNT-RGHT | LWPOLYLINE | 2 |
| C-TURN-TRCK-HTCH | LWPOLYLINE | 2 |
| C-TURN-TRCK-REAR-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRCK-REAR-RGHT | LWPOLYLINE | 2 |
| C-TURN-TRL1-BODY | LWPOLYLINE | 16 |
| C-TURN-TRL1-CRNR | LWPOLYLINE | 8 |
| C-TURN-TRL1-FRNT-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRL1-FRNT-RGHT | LWPOLYLINE | 2 |
| C-TURN-TRL1-HTCH | LWPOLYLINE | 2 |
| C-TURN-TRL1-REAR-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRL1-REAR-RGHT | LWPOLYLINE | 2 |
| C-TURN-TRL2-BODY | LWPOLYLINE | 16 |
| C-TURN-TRL2-CRNR | LWPOLYLINE | 8 |
| C-TURN-TRL2-FRNT-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRL2-FRNT-RGHT | LWPOLYLINE | 2 |
| C-TURN-TRL2-REAR-LEFT | LWPOLYLINE | 2 |
| C-TURN-TRL2-REAR-RGHT | LWPOLYLINE | 2 |

## Summary

- passed: 44
- failed: 0

**ALL CHECKS PASSED**
- **ERROR**: Function cancelled
