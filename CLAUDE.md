# CLAUDE.md — FreeLand

## What this repo is
FreeLand is a loose collection of free (GPL) AutoCAD/Civil 3D civil-engineering tools by
Thomas Gail Haws, published individually at https://hawsedc.com/gnu/index.php. It has never
been installed or released as a *suite* — each folder is a standalone tool, downloaded and
loaded one .lsp at a time by users who know nothing more than how to load a LISP file.

Sibling project: `C:\TGHFiles\programming\hawsedc\develop` (CNM/edclib — the flagship).
Its `CLAUDE.md` and `devtools/docs/standards/` hold the mature standards and the unattended
AutoCAD test harness worth borrowing. Treat it as a source of ideas, not gospel: parts of its
early structure were misguided, and both the tooling and the human/AI collaboration have
improved since.

## Language
AutoLISP (**not** Common Lisp) with DCL. Before using any function, verify it exists —
`fboundp`, `consp`, `vlax-object-p` do not exist in AutoLISP.

## Ground rules (inherited from the flagship, still in force here)
- **No superstitious code.** No "just in case" defensive code, no error handling for errors
  you cannot name. Git lets us revert.
- **Do not `git commit`** unless asked.
- **Do not claim "fixed" or "loads successfully."** Say "validation passes" / "no syntax
  errors detected" until an actual AutoCAD run proves otherwise.
- Paren/syntax validation scripts live in the flagship at
  `C:\TGHFiles\programming\hawsedc\develop\devtools\scripts\haws-lisp-paren-check.ps1`
  and `validate-lisp-syntax.ps1`.

## Testing
AutoCAD 2026 and Civil 3D 2026 are installed. The flagship's pattern — a `.bat` that launches
`acad.exe ... /b <script>.scr` against a fixture `.dwg` — works here and is the way to get
real runtime data instead of guessing. `Turning_Path_Tracker/turn-test.scr` is a seed of that
idea (it drives TURN with canned keystrokes) but has no `.bat`, no fixture drawing, and no
result log yet.

## Current focus: Turning_Path_Tracker
See `Turning_Path_Tracker/CLAUDE.md`.
