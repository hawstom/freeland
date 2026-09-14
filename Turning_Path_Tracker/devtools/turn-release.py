#!/usr/bin/env python3
"""Publish the trunk to the website tree. One True Copy, enforced.

    python devtools/turn-release.py            check only, change nothing
    python devtools/turn-release.py --publish   copy trunk -> gnu/turn-<version>.lsp

Turning_Path_Tracker/turn.lsp is canon. hawsedc.com/gnu/turn-<version>.lsp is a
release artifact: produced by this script, named by the version inside the file,
never hand-edited. Before overwriting, this script checks whether the published
copy differs from the last thing it published, because a difference means
somebody edited the artifact instead of the trunk -- which is the one failure
mode the old copy-by-hand ritual could not detect.

After publishing, run:  devtools\\turn-tests.bat turn-release-smoke
"""

import hashlib
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TRUNK = HERE.parent / "turn.lsp"
GNU = HERE.parent / "hawsedc.com" / "gnu"
DATA = ["turn-layers.dat", "turn-vehicles.dat"]


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def version_of(p: Path) -> str:
    text = p.read_text(encoding="utf-8", errors="replace")
    m = re.search(r'"general\.version"\s+"([0-9]+\.[0-9]+\.[0-9]+)"', text)
    if not m:
        sys.exit(f"FATAL: no general.version setting found in {p}")
    banner = re.search(r";;;\s*VERSION\s+([0-9]+\.[0-9]+\.[0-9]+)", text)
    if banner and banner.group(1) != m.group(1):
        sys.exit(
            f"FATAL: {p.name} disagrees with itself: header banner says "
            f"{banner.group(1)}, general.version says {m.group(1)}."
        )
    return m.group(1)


def main() -> int:
    publish = "--publish" in sys.argv

    if not TRUNK.exists():
        sys.exit(f"FATAL: trunk not found: {TRUNK}")
    if not GNU.is_dir():
        sys.exit(f"FATAL: website tree not found: {GNU}\n"
                 "Clone github.com/hawstom/hawsedc.com into Turning_Path_Tracker/.")

    version = version_of(TRUNK)
    targets = [(TRUNK, GNU / f"turn-{version}.lsp")]
    targets += [(TRUNK.parent / d, GNU / d) for d in DATA]

    print(f"trunk    {TRUNK}")
    print(f"version  {version}")
    print()

    stale = []
    for src, dst in targets:
        if not src.exists():
            sys.exit(f"FATAL: missing source file: {src}")
        if not dst.exists():
            state = "NEW - not published yet"
        elif sha(src) == sha(dst):
            state = "in sync"
        else:
            state = "DIFFERS"
            stale.append(dst)
        print(f"  {state:24}  {dst.name}")

    if not stale and all(d.exists() for _, d in targets):
        print("\nEverything published and identical. Nothing to do.")
        return 0

    if not publish:
        print("\nRun again with --publish to copy the trunk over these.")
        print("If a file DIFFERS, satisfy yourself the trunk is the one you want:")
        print("a difference can mean the artifact was edited instead of the trunk.")
        return 1

    print()
    for src, dst in targets:
        shutil.copy2(src, dst)
        ok = sha(src) == sha(dst)
        print(f"  {'copied' if ok else 'COPY FAILED'}  {dst.name}")
        if not ok:
            return 1

    print(f"\nPublished {version}. Now run:")
    print("  devtools\\turn-tests.bat turn-release-smoke")
    print("then commit in hawsedc.com/.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
