# FreeLand internal references

*Survey 2026-09-09. Which sibling projects are worth reading before writing new code
here, and what specifically to take from each. Newest first — Tom's guidance is that
the last decade of work is the cleanest.*

## Tier 1 — read these

### `Civil_3D_Subdivision/haws-subdivision.lsp` (2025-08-28, 562 lines)

**The reference for settings management.** It says so itself in its own header:

> - Saves to (setcfg) to remember settings between sessions. Saves to a single global
>   variable during a session.
> - For programmers, demonstrates small functions with self-documenting names and
>   variable names. Also demonstrates settings management.

The pattern, in full:

| Function | Job |
|---|---|
| `haws-sdt:define-settings` | The defaults. **Placed at the very end of the file**, with a note at the top saying so, because that is where a user is told to look. |
| `haws-sdt:initialize-settings` | Load defaults if the session global is empty, then overlay anything stored. Called at the top of **every** command. |
| `haws-sdt:get-stored-settings` | Read `getcfg` under a storage location, skipping keys that come back `""`. |
| `haws-sdt:storage-location` | One function returning `"Appdata/Haws/SDT/"`. One place to change it. |
| `haws-sdt:save-to-settings-list` | Session global only. |
| `haws-sdt:save-to-storage` | `setcfg` only. |
| `haws-sdt:setvar` | **Type-checks against the declared type** and alerts + exits on mismatch, then writes to both. |
| `haws-sdt:getvar` | Converts the stored string back to the declared type. |

Three things TURN 2.0 does not do and should:

1. **Persistence.** TURN's settings reset on every load. `setcfg`/`getcfg` fixes that.
   Note Tom's own caveat in the source: *"The setcfg/getcfg functions might be removed
   in a future release."*
2. **Type checking in setvar.** TURN accepts whatever it is handed.
3. **Defaults at the end of the file.** TURN has them at the top, in front of the code.
   For an audience told only "load the file and look inside", the end is friendlier —
   and the header should say where they are.

TURN already matches it on the session-global-plus-declared-type-triple shape
(`*wiki-turn-settings*` vs `*haws-sdt:settings*`), so this is a small change, not a
rewrite.

**One caveat: it is not standalone.** It calls `haws-core-init`, `haws-vsave`,
`haws-core-restore` and `haws-vrstor` without defining them, so it needs edclib from
the flagship loaded first. Take the settings pattern; do not copy the dependency into
a FreeLand tool that has to work as a single downloaded file.

### `Proliferator/haws-mocoro.lsp` (2025-10-15, 152 lines)

The best small example of **structure without ceremony**. No settings, no globals. A
`source-data` list is threaded through `get-source-data` → `do-destination` → back,
and the main loop is literally `(while (setq source-data (haws-mocoro-do-destination source-data)))`.
Verb-noun names throughout. Uses `vl-cmdf` rather than `command`. Worth copying as a
model for how small a command can be when the data is passed rather than stashed.

## Tier 2 — read for one specific idea

### `Survey_Points_Importer/pointsin.lsp` (2020-10-18, 990 lines)

A different, older answer to user configuration: `PI:CONFIG-INITIALIZE` is a block of
`PI:SETVAR` calls where **the alternatives are present but commented out**, and the
active line `PROMPT`s to tell the user what is on and where to change it:

```lisp
(PI:SETVAR "TAGNAMES" '("NORTH" "EAST" "POINT" "DESC" "ELEV"))
(PROMPT "\nOption to fill in NORTH and EAST attributes is active.  Search this text [20] in the source code to deactivate.")
```

The numbered `[20]` bookmarks are a genuinely good idea for a tool whose users edit the
source — the runtime message tells you the exact string to search for. Worth stealing
for TURN's user-editable settings block. The rest is noisy; do not copy the volume.

### `zz_alignment/alignment.lsp` (2015-10-29, 224 lines)

Same lineage as TURN — `wiki-alignment-setvar`, and its REVISION HISTORY still carries
TURN's entries verbatim, trailer plotting and all. Useful only as evidence of how the
`wiki-*-setvar` settings idiom spread. Nothing to take.

## Tier 3 — legacy, do not model on these

`Grading_Designer/gdd.lsp` (2015, 2160 lines), `Curve_etc_Tables_Auto/geotables.lsp`
(2015, 2784 lines), `DDMSW_Maps_Exporter/ddmsw.lsp` (2019), `zz_editoptions/*` (2011),
`Sewer_Lateral_*` (2010–2011), `Curve_Tables_Simple/curves.lsp` (2008),
`Subdivision_Grading_Plan_Labeler/gradlbl.lsp` (2002).

All carry the AutoCAD Wiki copy-and-paste boilerplate header, most are uppercase-era,
and the two large ones are long procedural files. `gdd.lsp` and `geotables.lsp` are
worth grepping for a specific technique, but not for structure.

## What this changes for Turning Path Tracker

In rough priority:

1. Move TURN's user-editable defaults to the end of `src/turn.lsp` and point at them
   from the header.
2. Add `setcfg`/`getcfg` persistence so plot frequency, calculation step and the
   envelope toggle survive a session.
3. Type-check `wiki-turn-setvar` the way `haws-sdt:setvar` does.
4. Consider pointsin's numbered `[nn]` source bookmarks for the settings block.
