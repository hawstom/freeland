# CLAUDE.md — FreeLand

## What this repo is
FreeLand is a collection of free (GPL) AutoCAD/Civil 3D civil-engineering tools by
Thomas Gail Haws, published at https://hawsedc.com/gnu/index.php. Historically each folder
has been a standalone tool, downloaded and loaded one .lsp at a time by users who know
nothing more than how to load a LISP file — and each must stay usable that way.

**Tom conceives it as a package deal** (2026-09-27), and the direction includes listing it
in the Autodesk App Store and the Bricsys Application Store. So FreeLand-wide concerns —
the website, licensing, release tooling — belong at this level, not inside one tool.

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

## The website: `hawsedc.com/`
A clone of https://github.com/hawstom/hawsedc.com.git sits at the freeland root, because
its `gnu/` directory serves every FreeLand tool. (It lived inside `Turning_Path_Tracker/`
until 2026-09-27, when TURN was the only tool being released through it.) It is a nested
git repo with its own remote: gitignored here, never committed into freeland.

- **Tom uploads to the server; the clone is not the live site.** Compare before assuming:
  `curl -s https://hawsedc.com/gnu/<file>` against the clone. PHP pages differ because the
  server renders them; compare `.lsp`, `.dat` and zips byte for byte (normalise CRLF).
- Page format: PHP calling `echoHawsEDCHeader()` / `echoHawsEDCFooter()` from
  `../hawsedc.lib.php`, plain HTML between. Files are **CRLF** — write them with
  `newline='\r\n'` or multi-line replacements will not match.
- Zips are gitignored as a class and **admitted by exact path** (see the website repo's
  `.gitignore`); the two AASHTO library zips and the turntest zips are tracked.
- **The contact form is `https://hawsedc.com/engcalcs/contact.php`.** `../contact.php` is a
  404 on the live site and is still linked from `addtick`, `curvesauto`, `gdd`, `gradlbl`,
  `pointsin` and the tao-te-ching pages (TURN's pages fixed 2026-09-26).
- The AutoCAD Wiki page for TURN now points to hawsedc.com and GitHub (Tom, 2026-09-26).
  Collaboration happens on GitHub: `github.com/hawstom/freeland`, public, issues on.

## Licensing: GPL v3 or later, except three co-owned tools
Tom released everything he solely owns as GPL "version 3 of the License, or (at your
option) any later version" on 2026-09-27; the text is in the root `LICENSE`, and the
headers of `curves`, `tip`, `geotables`, `laterin`, `reloclat`, `pointsin`, `endtick`,
`fselect` (and the website pages for them) were changed to match. `haws-subdivision.lsp`
and `haws-mocoro.lsp` had no notice and got one.

**Three tools are co-owned and stay GPL v2 only** until their co-owners agree: Profile
Labeler and Subdivision Grading Plan Labeler ("Thomas Gail Haws and WRG Design Inc.",
2002) and `zz_alignment` ("David Wilkins and Thomas Gail Haws", 2006). Each of those
folders carries the GPL v2 text as its own `LICENSE`, and the README says so. Do not
relicense them without Tom confirming the co-owner's agreement.

Also found: the served zips `pointsin-v1.0.16.zip` and `curvesauto/geotables-2.0.17.zip`
still contain the old v2 notices inside, and `gnu/tip.zip` is a 7-Zip archive with a
`.zip` name, identical on the live site — Windows cannot open it.

## Current focus: Turning_Path_Tracker
See `Turning_Path_Tracker/CLAUDE.md`.
