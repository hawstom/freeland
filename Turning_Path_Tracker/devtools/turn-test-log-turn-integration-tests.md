# TURN 2.0.0-dev integration - tractor with TWO trailers

Run at CDATE 20260909.032110
AutoCAD 24.3s (LMS Tech) product AutoCAD

- [03:21:10] sources loaded
- [03:21:10] course drawn
- [03:21:11] vehicle built
- [03:21:11] TURN finished

## Integration: BUILDVEHICLE with two trailers, then TURN

**Segment 0**
- PASS one pline on C-TURN-TRCK-FRONT-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-FRONT-RGHT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-REAR-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRCK-REAR-RGHT-PATH (expected 1, got 1)
- PASS four corner loci on C-TURN-TRCK-ENVELOPE (expected 4, got 4)
- PASS hitch path on C-TURN-TRCK-HTCH-PATH (expected 1, got 1)
- PASS body outlines plotted on C-TURN-TRCK-BODY
**Segment 1**
- PASS one pline on C-TURN-TRAL-FRONT-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL-FRONT-RGHT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL-REAR-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL-REAR-RGHT-PATH (expected 1, got 1)
- PASS four corner loci on C-TURN-TRAL-ENVELOPE (expected 4, got 4)
- PASS hitch path on C-TURN-TRAL-HTCH-PATH (expected 1, got 1)
- PASS body outlines plotted on C-TURN-TRAL-BODY
**Segment 2**
- PASS one pline on C-TURN-TRAL2-FRONT-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL2-FRONT-RGHT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL2-REAR-LEFT-PATH (expected 1, got 1)
- PASS one pline on C-TURN-TRAL2-REAR-RGHT-PATH (expected 1, got 1)
- PASS four corner loci on C-TURN-TRAL2-ENVELOPE (expected 4, got 4)
- PASS hitch path on C-TURN-TRAL2-HTCH-PATH (expected 0, got 0)
- PASS body outlines plotted on C-TURN-TRAL2-BODY

## Polyline integrity

- PASS polylines whose DXF 90 disagrees with their vertex count (expected 0, got 0)
- PASS TURN drew some polylines at all

## Nothing was left behind

- PASS no stray POINT entities (1.1.x littered these) (expected 0, got 0)

## Model space census

| Layer | Type | Count |
|---|---|---|
| 0 | INSERT | 1 |
| 0 | LWPOLYLINE | 1 |
| C-TURN-TRAL-BODY | LWPOLYLINE | 14 |
| C-TURN-TRAL-ENVELOPE | LWPOLYLINE | 4 |
| C-TURN-TRAL-FRONT-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL-FRONT-RGHT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL-HTCH-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL-REAR-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL-REAR-RGHT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL2-BODY | LWPOLYLINE | 14 |
| C-TURN-TRAL2-ENVELOPE | LWPOLYLINE | 4 |
| C-TURN-TRAL2-FRONT-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL2-FRONT-RGHT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL2-REAR-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRAL2-REAR-RGHT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRCK-BODY | LWPOLYLINE | 14 |
| C-TURN-TRCK-ENVELOPE | LWPOLYLINE | 4 |
| C-TURN-TRCK-FRONT-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRCK-FRONT-RGHT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRCK-HTCH-PATH | LWPOLYLINE | 1 |
| C-TURN-TRCK-REAR-LEFT-PATH | LWPOLYLINE | 1 |
| C-TURN-TRCK-REAR-RGHT-PATH | LWPOLYLINE | 1 |

## Summary

- passed: 24
- failed: 0

**ALL CHECKS PASSED**
