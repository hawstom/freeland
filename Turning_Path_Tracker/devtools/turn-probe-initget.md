# initget with hyphenated keywords

Keyword string: `A-BUS BUS-40 BUS-45 CITY-BUS MH MHB P PB PT S-BUS-36 S-BUS-40 SU WB-40 WB-50 WB-62 WB-65 WB-67`

- PASS initget accepted the hyphenated keyword list
- exact hyphenated key typed: returned "WB-67"
- lower case typed: returned "WB-62"
- empty input (want nil so caller can default): returned nil
- a key with two hyphens: returned "S-BUS-36"

END OF PROBE
