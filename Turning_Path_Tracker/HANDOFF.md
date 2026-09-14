# Handoff — Turning Path Tracker, 2026-09-13 (second session)

Read `CLAUDE.md` first for the durable facts. This file is the perishable part.

The previous handoff said *"The freeland repo itself is uncommitted, and that is
deliberate."* **That was wrong, twice over.** It was not deliberate, it was
"don't commit unless asked" applied without ever asking; and the repo was not
uncommitted — it has 15 commits going back to 2017, and the snapshots were all in
them. Tom's standing instruction, given this session:

> **"Commit and push prudently and parsimoniously, of course."**

That is now the rule. It supersedes the old note. Do not re-invent the ban.

## What this session did — a directional cleanup, no program changes

`turn.lsp` was not touched. Everything below is structure, tooling and docs.

1. **One True Copy, applied.** Twenty-two concurrent `turn*.lsp` snapshots deleted
   (recoverable: `git show cafd98a:Turning_Path_Tracker/<name>`). `src/` — an
   invention of the last session to avoid dealing with the attic — flattened away.
   The program is `Turning_Path_Tracker/turn.lsp`, flat at the folder top like
   every other FreeLand tool.
2. **The shipped copy is now an artifact, not a second source.**
   `devtools/turn-release.py` publishes trunk → `gnu/turn-<version>.lsp`, reads the
   version out of the file, and refuses to proceed silently when the published copy
   has drifted. **On its first run it found drift the hand-copy ritual had missed**
   — `turn-layers.dat`, line endings only. Fixed by normalising the trunk, so no
   published file changed.
3. **The harness has no hardcoded paths and runs on three products.**
   `turn-tests.bat` sets `TURNDEV` from `%~dp0`; `devtools/turn-dev-paths.lsp` (first
   line of every `.scr`) derives the rest. 28 files of absolute paths are gone.
   `turn-tests.bat <script> [c3d|acad|2024] [c3d]`.
4. **First-ever run on Civil 3D, and on AutoCAD 2027.** 106 kernel, 44 end to end,
   30 curve, 7 release smoke — passing on Civil 3D 2026, AutoCAD 2027 and AutoCAD 2024.
5. **Punch list item 7 closed by automating it.** See below.
6. **A TRUSTEDPATHS leak, found and fixed.** It is saved in the profile, not the
   session, so appending to it grew the list every run — that is what made Tom's Civil
   3D trusted locations a mess, and the old release-smoke `.scr` had accumulated seven
   copies of a path ending in a literal `...`. Paths are now normalised and added only
   when absent; the affected profiles were cleaned. Verified convergent over three runs.
7. **`.gitignore` written** at the freeland root — `user_help/`, `hawsedc.com/`,
   build output, AutoCAD litter. See the warning below.
8. Docs corrected where they had gone false. A citation in ROADMAP was stale by 158
   lines; **do not cite line numbers in prose** unless something checks them.

## The one thing to be careful about

`user_help/` holds **other people's drawings and correspondence**, with their names
in them, and freeland pushes to a public GitHub. It is gitignored. That is adequate,
not a lock: `git add -f` overrides it and it does nothing about zips or backups.
Never commit it. Never quote a user's name into a public file.

## Open, and who owns them

### Tom
- **The punch list is down to items 2 and 3, and they are the two worth your eye.**
  Ten of eleven are automated: `turn-punch-tests` (53 checks) and `turn-curve-tests`
  (30). What remains is whether the BUILDVEHICLE prompts *read* clearly — whether a
  user can tell the tractor's rear-hitch question from the trailer's kingpin
  question, which is exactly what Kenya could not do — plus one decision: keep
  offering 30° steering lock and 70° articulation as defaults, or default to 0 and
  stay silent rather than stand behind numbers nobody measured. A confident wrong
  verdict is worse than none, and that call is yours.
- **Kenya has not been replied to.** Draft ready and approved in substance:
  `user_help/Kenya_Caldwell/draft-reply-4.md`.
- **Rob Livingston** was emailed the REGION/UNION envelope approach. No reply yet.
- **AutoCAD 2027 is done.** `turn-tests.bat <script> acad` drives it, and TURN 2.0.0
  passes 106 kernel and 44 end-to-end checks on it unchanged. `2024` still selects the
  2024 install.
- **Download counts.** Tom's host has a stats page. What it answers: which of the 15
  FreeLand tools humans actually download, and whether anyone still takes 1.1.17.
  That number is the input to two open decisions — when to stop serving 1.1.17, and
  whether the User block method dropped in 2.0 was load-bearing for anyone.

### Still waiting on the world
The WANTED notice on `turn.php` — four asks we cannot close ourselves: articulation
angles for standard vehicles; the WB1/WB2 split; non-US standard vehicles; where
AASHTO measures minimum turning radius from.

### Next build
**Phase 4's command, `c:drive`.** The kernel half is done, tested and committed:
`wiki-turn-drive-path` takes a list of (steer . travel) inputs and returns the same
shape `wiki-turn-path` returns, so everything downstream already works on a driven
rig. What is left is the interaction — a `grread` loop, and a decision about what the
user sees while steering. The model is not the hard part any more.

The trunk is **2.1.0-dev** and `turn-release.py` refuses to publish while the version
carries a suffix, so the shipped 2.0.0 is safe from a work in progress. Drop the suffix
from both the `;;; VERSION` banner and `general.version` to release.

## Traps that cost time, still true

- **This shell eats backslashes, even inside a quoted heredoc.** It bit THREE times
  in one session: `devtools\turn-tests.bat` inside a Python heredoc becomes a literal
  TAB, so either the replacement silently matches nothing or a tab lands in the file.
  Once was in the very handoff note warning about it. Use the Write and Edit tools for
  any content containing a backslash. No exceptions, no cleverness.
- **Never end a `.scr` with a bare `quit`.** The "Save changes?" prompt is a modal
  task dialog; no script line answers it, and the run holds an AutoCAD process
  forever. Use `(tt-safe-quit)`. A leftover `acad.exe` is the symptom.
- **Verify AutoLISP assumptions, do not reason about them.** `getenv` was assumed to
  read the environment the `.bat` hands to `acad.exe`. It does — but that was proven
  by running it on both products, not by arguing it.
- **Measure drawings, do not look at them.**
- **Nothing closes in AutoCAD unless you tell it to.**

## Style notes worth carrying

- Be brief. *"Remember to try to be as brief as Tom was for 20 years. Don't overwhelm
  20 years of parsimony in a week."*
- Do not assume one user's mistake is common.
- Follow AutoCAD's settings rather than second-guessing them.
- **Ask.** The single clearest instruction of this session: *"I would expect you to
  clean up autonomously or ask me about every file that seems like an unexplained
  mess to you."* An unexamined mess inherited from the last session is not a
  convention. Question it.
