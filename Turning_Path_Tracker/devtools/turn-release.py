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


VERSION_RE = r"([0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.]+)?)"


def version_of(p: Path) -> str:
    text = p.read_text(encoding="utf-8", errors="replace")
    m = re.search(r'"general\.version"\s+"' + VERSION_RE + '"', text)
    if not m:
        sys.exit(f"FATAL: no general.version setting found in {p}")
    banner = re.search(r";;;\s*VERSION\s+" + VERSION_RE, text)
    if banner and banner.group(1) != m.group(1):
        sys.exit(
            f"FATAL: {p.name} disagrees with itself: header banner says "
            f"{banner.group(1)}, general.version says {m.group(1)}."
        )
    return m.group(1)


def is_prerelease(version: str) -> bool:
    """A version with a suffix, e.g. 2.1.0-dev, is work in progress.

    The trunk keeps being edited after a release, so for most of its life it is
    AHEAD of what users download. Publishing it then would replace a good
    release with a half-finished one. The suffix is how the trunk says so; this
    is what enforces it. Drop the suffix to release.
    """
    return "-" in version


def main() -> int:
    publish = "--publish" in sys.argv

    if not TRUNK.exists():
        sys.exit(f"FATAL: trunk not found: {TRUNK}")
    if not GNU.is_dir():
        sys.exit(f"FATAL: website tree not found: {GNU}\n"
                 "Clone github.com/hawstom/hawsedc.com into Turning_Path_Tracker/.")

    version = version_of(TRUNK)

    print(f"trunk    {TRUNK}")
    print(f"version  {version}")
    print()

    if is_prerelease(version):
        print(f"{version} is a PRE-RELEASE. Nothing will be published.")
        print()
        print("The trunk is ahead of what users download, which is normal while")
        print("work is in progress. Publishing now would replace a good release")
        print("with a half-finished one.")
        print()
        print(f"Already published in {GNU.name}/:")
        for f in sorted(GNU.glob("turn-*.lsp")):
            print(f"    {f.name}")
        print()
        print("To release: drop the -suffix from BOTH the VERSION banner and the")
        print('general.version setting in turn.lsp, run the full test matrix,')
        print("then run this again with --publish.")
        return 1

    targets = [(TRUNK, GNU / f"turn-{version}.lsp")]
    targets += [(TRUNK.parent / d, GNU / d) for d in DATA]

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
