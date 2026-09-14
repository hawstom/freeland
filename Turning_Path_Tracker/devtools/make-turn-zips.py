"""Rebuild the two AASHTO vehicle block zips with the corrected instruction sheet.

The vehicle DWGs are copied through byte for byte -- they are the published blocks
and nothing about them is being changed. Only the instruction PDF is replaced.

Note on the 2011 source archive: its central directory spells the path separator
"\\" while its local file headers spell it "/". Python's zipfile refuses that
mismatch and unzip(1) on this machine mishandles it too, so entries are read by
normalising both names first. The rebuilt archives use "/" throughout, which is
what the zip format actually specifies.

The output goes into the website clone's gnu/ directory, where *.zip is already
gitignored -- so the folder mirrors the server layout for upload without the
binaries ever entering the repository.

Usage:  python make-turn-zips.py <2004-src-dir> <2011-src-dir> <newpdf-dir> <outdir>
"""
import os
import sys
import zipfile

EDITIONS = [
    ("2004", "Turn.lsp Turn Radius Modeling AASHTO 2004 Edition",
     "Turn.lsp_Turn_Radius_Modeling_AASHTO_2004_Edition.zip"),
    ("2011", "Turn.lsp Turn Radius Modeling AASHTO 2011 Edition",
     "Turn.lsp_Turn_Radius_Modeling_AASHTO_2011_Edition.zip"),
]


def source_files(d):
    """Every DWG in a directory, by basename."""
    return sorted(f for f in os.listdir(d) if f.lower().endswith(".dwg"))


def build(edition, folder, zipname, srcdir, pdfdir, outdir):
    pdf = os.path.join(pdfdir, "%s_AASHTO_Turn_Radius_Instructions.pdf" % edition)
    if not os.path.exists(pdf):
        raise SystemExit("missing replacement PDF: " + pdf)

    dwgs = source_files(srcdir)
    if not dwgs:
        raise SystemExit("no DWGs found in " + srcdir)

    out = os.path.join(outdir, zipname)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name in dwgs:
            z.write(os.path.join(srcdir, name), "%s/%s" % (folder, name))
        z.write(pdf, "%s/%s" % (folder, os.path.basename(pdf)))

    # Read it back and prove it: every DWG must survive byte for byte.
    with zipfile.ZipFile(out) as z:
        names = z.namelist()
        for name in dwgs:
            want = open(os.path.join(srcdir, name), "rb").read()
            got = z.read("%s/%s" % (folder, name))
            if want != got:
                raise SystemExit("ROUND TRIP FAILED: " + name)
    print("%s  %d DWGs + 1 PDF  %d entries  %d bytes"
          % (zipname, len(dwgs), len(names), os.path.getsize(out)))
    return out


def main():
    src2004, src2011, pdfdir, outdir = sys.argv[1:5]
    os.makedirs(outdir, exist_ok=True)
    srcs = {"2004": src2004, "2011": src2011}
    for edition, folder, zipname in EDITIONS:
        build(edition, folder, zipname, srcs[edition], pdfdir, outdir)


if __name__ == "__main__":
    main()
