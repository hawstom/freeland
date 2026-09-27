# Handoff — FreeLand, 2026-09-27

`CLAUDE.md` (here and in each tool folder) holds the durable facts. This file is the
perishable part: what is open, in the order worth doing it. Tool-specific handoffs live
in the tool folders — `Turning_Path_Tracker/HANDOFF.md` for TURN and its DRIVE test.

## State

- freeland and the website repo (`hawsedc.com/`, at the freeland root) are committed and
  pushed. **Pushing does not deploy the site**: the server updates on a `git pull` there.
  Evidence: the 2026-09-13 zips reached the live site, the later 2.0.0 commits the same
  day did not. Until Tom pulls on the server, the live site lacks TURN 2.1.0, the TURN page
  audit and the GPL v3 page changes.
- TURN 2.1.0 is released into `hawsedc.com/gnu/`. DRIVE is in it, experimental and
  unannounced, waiting for Tom to drive it by hand.
- All suites green on Civil 3D 2026, AutoCAD 2027, AutoCAD 2024.

## Open issues found 2026-09-22..27, not yet resolved

**Website**
1. `../contact.php` is a 404 on the live site and is still linked from `gnu/addtick.php`,
   `gnu/curvesauto/index.php`, `gnu/gdd.php`, `gnu/gradlbl.php`, `gnu/pointsin.php` and the
   tao-te-ching pages. The working form is `https://hawsedc.com/engcalcs/contact.php`
   (TURN's pages are fixed). Check every other page on the site for the same link.
2. `gnu/tip.zip` is a 7-Zip archive named `.zip`, identical on the live site; Windows cannot
   open it. **Better than repacking it:** `C:\TGHFiles\programming\hawsedc\develop\devsource\haws-tip.lsp`
   and `.dcl` (the CNM tip opt-out system, with a tip-ID registry) can be implemented in
   FreeLand and evangelized to replace `tip.dvb`. Read its header and
   `develop/devtools/docs/standards_05_architecture.md` S05.6 first.
3. The served zips `gnu/pointsin-v1.0.16.zip` and `gnu/curvesauto/geotables-2.0.17.zip`
   still carry GPL v2 notices inside; rebuild them from the relicensed sources (and check
   the zipped source matches the repo's before trusting that it does).
4. The other tools' pages have not had TURN's audit: stale instructions, broken links,
   descriptions of old versions. Same treatment, one tool at a time.

**Licensing**
5. Profile Labeler and Subdivision Grading Plan Labeler (co-owned with WRG Design Inc.) and
   `zz_alignment` (co-owned with David Wilkins) stay GPL v2 only. If Tom obtains the
   co-owners' agreement, change their notices, pages (`gnu/gradlbl.php`, `gnu/proflbl.php`)
   and folder LICENSE files to v3 or later. Needed before a store listing ships them.
6. The Sewer Lateral tools were "commissioned by Apache Junction Sewer District". Their
   headers say copyright Thomas Gail Haws, which is the default for a contractor unless a
   contract assigned it. Worth Tom confirming before a store listing.

**Distribution**
7. Autodesk App Store and Bricsys Application Store: research packaging and listing
   requirements for FreeLand as a package. Items 3, 5 and 6 feed into it.

**AutoCAD profiles**
8. The harness runs under its own profile, `Turning_Path_Tracker`, in each product; Tom's
   are `TGH` and `<<C3D_Imperial>>`. On 2026-09-27 the harness profile lost the P:\ trusted
   paths it had inherited from Tom's when it was created, and Tom's two Civil 3D 2026
   profiles lost a backslash-less `C:TGHFiles...Turning_Path_Tracker...` entry an earlier
   session wrote. A backup of every value from before is in
   `Turning_Path_Tracker/devtools/profile-backup-2026-09-27.txt` (gitignored).
   The 2024 and 2027 `<<Unnamed Profile>>` list `Turning_Path_Tracker` on their support path;
   ask Tom whether anything uses those profiles before touching them.
   **Lesson: never write a registry value from a list you have not printed first.** A
   PowerShell function returning a one-element array unrolled to a string, and `[0]` then
   took its first character; six values became `C` or `P` until restored from the backup.
