# How AutoLISP reads scientific notation

- `1e-9` -> type REAL, value 1.0e-09
- `1.0e-9` -> type REAL, value 1.0e-09
- `1E-9` -> type REAL, value 1.0e-09
- `1e9` -> type REAL, value 1.0e+09
- `0.000000001` -> type REAL, value 1.0e-09

How a whole call reads, which is what actually broke:
- `(list 5.0 1e-9) read as a list` -> type LIST, value (5.0 1.0e-09)
- `(list 5.0 1e-9)` reads to: (LIST 5.0 1.0e-09)
- `(f "a" 5.0 x 1e-9)` reads to: (F a 5.0 X 1.0e-09)
- `(f "a" 5.0 x 1.0e-9)` reads to: (F a 5.0 X 1.0e-09)
