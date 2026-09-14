"""Build the replacement instruction sheets for the AASHTO vehicle block zips.

The sheets that shipped inside Turn.lsp_Turn_Radius_Modeling_AASHTO_*.zip tell the
reader to draw the course along the FRONT LEFT WHEEL. TURN moved to front-axle
centreline tracking in 1.1.3 (January 2008) and never looked back, so those sheets
have been wrong for the whole life of every version anyone can download. A reader
who follows them places the rig half an axle width off.

Rather than patch a wrong document, these replacements are short: they say what
changed, give the handful of facts someone needs offline, and point at
hawsedc.com/gnu/turn-instructions.php for the rest.

The one genuinely valuable thing in the originals was the minimum-radius table, so
it is carried over -- recomputed. The originals needed TWO radius columns because
the left wheel is the outer wheel turning one way and the inner wheel turning the
other. Tracking the axle centre is symmetric, so one column now serves both
directions:

    minimum course radius = AASHTO minimum turning radius - 1/2 front axle width

AASHTO radii and axle widths are taken from each edition's own sheet, read out of
the shipped PDFs -- not retyped, and not carried across between editions (the two
editions genuinely differ; 2011 lists WB-62/67 on an 8.5 ft axle where 2004 says 8.0).

Usage:  python make-turn-instruction-pdf.py <outdir>
"""
import os
import sys
from decimal import Decimal, ROUND_HALF_UP

import pymupdf


def ft(x):
    """One decimal, rounded half UP.

    Plain %.1f would print 39.8 - 4.25 = 35.55 as "35.5", because binary floating
    point holds it as 35.5499... Rounding a MINIMUM radius down is the wrong
    direction, and it would also disagree with the table on turn-instructions.php.
    """
    return str(Decimal(repr(x)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))

URL = "https://hawsedc.com/gnu/turn-instructions.php"

# (vehicle type, designation, AASHTO min turning radius ft, front axle width ft)
AASHTO_2004 = [
    ("Articulated Bus", "A-BUS", 39.8, 8.5),
    ("Intercity Bus", "BUS-40", 45.0, 8.5),
    ("Intercity Bus", "BUS-45", 45.0, 8.5),
    ("City Transit Bus", "CITY-BUS", 42.0, 8.5),
    ("Motor Home", "MH", 40.0, 8.0),
    ("Motor Home and Boat Trailer", "MH/B", 50.0, 8.0),
    ("Passenger Car", "P", 24.0, 6.0),
    ("Passenger Car and Boat Trailer", "P/B", 24.0, 6.0),
    ("Passenger Car and Camper Trailer", "P/T", 33.0, 6.0),
    ("Conventional School Bus", "S-BUS-36", 38.9, 8.0),
    ("Large School Bus", "S-BUS-40", 39.4, 8.0),
    ("Single-Unit Truck", "SU", 42.0, 8.0),
    ("Intermediate Semitrailer", "WB-40", 40.0, 8.0),
    ("Intermediate Semitrailer", "WB-50", 45.0, 8.0),
    ("Interstate Semitrailer", "WB-62", 45.0, 8.0),
    ("Interstate Semitrailer", "WB-65", 45.0, 8.0),
    ("Interstate Semitrailer", "WB-67", 45.0, 8.0),
]

AASHTO_2011 = [
    ("Articulated Bus", "A-BUS", 39.4, 8.5),
    ("Intercity Bus", "BUS-40", 41.7, 8.5),
    ("Intercity Bus", "BUS-45", 44.0, 8.5),
    ("City Transit Bus", "CITY-BUS", 41.6, 8.5),
    ("Motor Home", "MH", 39.7, 8.0),
    ("Motor Home and Boat Trailer", "MH/B", 49.8, 8.0),
    ("Passenger Car", "P", 23.8, 6.0),
    ("Passenger Car and Boat Trailer", "P/B", 23.8, 6.0),
    ("Passenger Car and Camper Trailer", "P/T", 32.9, 6.0),
    ("Conventional School Bus", "S-BUS-36", 38.6, 8.0),
    ("Large School Bus", "S-BUS-40", 39.1, 8.0),
    ("Single-Unit Truck", "SU-30", 41.8, 8.0),
    ("Single-Unit Truck", "SU-40", 51.2, 8.0),
    ("Intermediate Semitrailer", "WB-40", 39.9, 8.0),
    ("Interstate Semitrailer", "WB-62", 44.8, 8.5),
    ("Interstate Semitrailer", "WB-67", 44.8, 8.5),
]

LEFT, RIGHT, TOP, BOTTOM = 62, 550, 60, 742
BLACK, RED, GREY = (0, 0, 0), (0.60, 0, 0), (0.42, 0.42, 0.42)


class Sheet:
    """A tiny flowing-text layout. Tracks a y cursor and starts pages as needed."""

    def __init__(self, doc):
        self.doc = doc
        self.page = None
        self.y = 0
        self.new_page()

    def new_page(self):
        self.page = self.doc.new_page(width=612, height=792)
        self.y = TOP

    def space(self, dy):
        self.y += dy

    def text(self, s, size=9.5, font="helv", color=BLACK, indent=0, leading=1.35):
        width = RIGHT - LEFT - indent
        # Measure first so we never straddle a page break mid-paragraph.
        need = pymupdf.get_text_length(s, fontname=font, fontsize=size)
        lines = max(1, int(need / width) + 1)
        height = lines * size * leading + 4
        if self.y + height > BOTTOM:
            self.new_page()
        rect = pymupdf.Rect(LEFT + indent, self.y, RIGHT, self.y + height + size * 2)
        rc = self.page.insert_textbox(rect, s, fontname=font, fontsize=size,
                                      color=color, lineheight=leading, align=0)
        # insert_textbox returns remaining vertical space; negative means overflow.
        used = (height + size * 2) - rc
        self.y += used + 2
        return rc

    def heading(self, s, size=11.5, color=BLACK, gap=12, keep=76):
        # Reserve room for the heading AND the first lines under it, so a heading
        # never ends up orphaned at the foot of a page.
        self.space(gap)
        if self.y + keep > BOTTOM:
            self.new_page()
        self.text(s, size=size, font="hebo", color=color)
        self.space(2)

    def rule(self, color=GREY, width=0.6):
        if self.y + 8 > BOTTOM:
            self.new_page()
        self.page.draw_line(pymupdf.Point(LEFT, self.y), pymupdf.Point(RIGHT, self.y),
                            color=color, width=width)
        self.space(7)

    def bullet(self, s, size=9.5):
        self.page.insert_text(pymupdf.Point(LEFT + 4, self.y + size), "•",
                              fontname="helv", fontsize=size)
        self.text(s, size=size, indent=16)
        self.space(1)


def draw_box(sheet, top, bottom, color=RED):
    """Outline for the correction notice, from the y it started at to the y it ended."""
    r = pymupdf.Rect(LEFT - 8, top - 6, RIGHT + 8, bottom)
    sheet.page.draw_rect(r, color=color, width=1.4)


def radius_table(sheet, rows):
    cols = [LEFT, LEFT + 196, LEFT + 262, LEFT + 360, LEFT + 452]
    head = ["Vehicle type", "AASHTO", "AASHTO minimum", "Front axle width,",
            "Minimum course"]
    head2 = ["", "designation", "turning radius (ft)", "centre to centre (ft)",
             "radius, either", ]
    head3 = ["", "", "", "", "direction (ft)"]

    if sheet.y + 60 > BOTTOM:
        sheet.new_page()

    for line in (head, head2, head3):
        for x, s in zip(cols, line):
            if s:
                sheet.page.insert_text(pymupdf.Point(x, sheet.y + 8), s,
                                       fontname="hebo", fontsize=7.6)
        sheet.space(9)
    sheet.space(1)
    sheet.rule(color=BLACK, width=0.9)

    for (name, desig, radius, axle) in rows:
        if sheet.y + 16 > BOTTOM:
            sheet.new_page()
        minimum = radius - axle / 2.0
        cells = [name, desig, ft(radius), ft(axle), ft(minimum)]
        for i, (x, s) in enumerate(zip(cols, cells)):
            sheet.page.insert_text(
                pymupdf.Point(x, sheet.y + 8), s,
                fontname="hebo" if i == 4 else "helv", fontsize=8)
        sheet.space(11.5)
    sheet.rule(color=BLACK, width=0.9)


def build(edition, rows, path):
    doc = pymupdf.open()
    s = Sheet(doc)

    s.text("TURN.LSP Turning Path Tracker", size=16, font="hebo")
    s.text("Instructions for the Imperial Unit AASHTO %s vehicle blocks" % edition,
           size=11, color=GREY)
    s.space(6)
    s.rule(color=BLACK, width=1.2)

    # ---------------------------------------------------------- the correction
    box_top = s.y
    s.space(6)
    s.text("THIS SHEET REPLACES THE ONE THAT USED TO SHIP IN THIS ZIP FILE",
           size=10.5, font="hebo", color=RED, indent=4)
    s.space(3)
    s.text("The previous instruction sheet told you to draw your path along the "
           "FRONT LEFT WHEEL, and to line the little circle in the block's left "
           "front tire up with the start of that path. That was correct for TURN "
           "1.1.2 and earlier. It has been wrong since version 1.1.3, released in "
           "January 2008.", indent=4)
    s.space(2)
    s.text("Every current version of TURN follows the CENTRE OF THE FRONT AXLE. "
           "If you draw a front-wheel path and hand it to TURN, the whole vehicle "
           "is placed half an axle width to one side -- 4 feet on a WB-67 -- and "
           "both edges of the swept path are wrong by that much.", indent=4)
    s.space(2)
    s.text("The change makes your job simpler, not harder. The old sheet needed a "
           "second column of corrected radii for counterclockwise turns, because "
           "the left wheel is the outer wheel turning one way and the inner wheel "
           "turning the other. The axle centre is in the middle, so one radius now "
           "serves both directions.", indent=4)
    s.space(8)
    draw_box(s, box_top, s.y)
    s.space(14)

    # ------------------------------------------------------------- essentials
    s.heading("WHAT TURN NEEDS FROM YOU")
    s.text("A course -- a polyline showing where the centre of the front axle "
           "should travel -- and a vehicle block. The AASHTO blocks in this zip "
           "carry full dimension attributes, so use them with TURN's GENERATED "
           "VEHICLE method, not the User block method.")

    s.heading("DRAW THE COURSE ALONG THE FRONT AXLE CENTRELINE")
    s.text("Not along a wheel. Make all line and arc segments tangent. The course "
           "does not have to be on any particular layer; TURN does not care. The "
           "old sheet's insistence on C-TURN-TRCK-FLTR-PATH was never a "
           "requirement.")

    s.heading("MAKE THE COURSE LONG")
    s.text("A trailer is still reacting to where the tractor was a full wheelbase "
           "ago, and it takes several rig lengths of travel before the articulation "
           "settles into the shape it would really take. A course only about as "
           "long as the vehicle shows you almost nothing, and the rig plots as one "
           "straight box. This one does not look like a mistake when you hit it.")
    s.space(3)
    s.text("Hundreds of feet. Five times the wheelbase or more, with a straight run "
           "at each end to warm up. For a WB-67, whose wheelbase is 65 ft, that is "
           "400 feet and up. Long does not hurt.", font="hebo")

    s.heading("PLACING THE BLOCK")
    s.text("Insert the vehicle block and rotate it to the direction of travel at "
           "the start of the course. TURN reads the block's rotation and its "
           "attributes; it does not use the insertion point for position, so the "
           "exact spot need not be perfect -- but the angle must be right.")
    s.space(3)
    s.text("The small circle in these blocks sits at the centre of the front LEFT "
           "WHEEL, because the blocks were drawn for the old convention. Do not "
           "line it up with your course. Your course is the axle centre, half an "
           "axle width inboard of that circle.")

    s.heading("RUNNING IT")
    s.text("Type TURN. Choose the Generated vehicle method, select the block, then "
           "select the course near its starting end -- pick a little way along the "
           "polyline so you do not select the block by mistake. Accept the "
           "suggested calculation step distance and plot frequency; raise the plot "
           "frequency if the drawing is cluttered, lower it if the plots are too "
           "sparse to read.")

    # ------------------------------------------------------------ the table
    s.heading("MINIMUM RADIUS (AASHTO %s)" % edition)
    s.text("TURN will track any path you draw, including one no real vehicle could "
           "drive. Checking the radius is your job. AASHTO publishes its minimum "
           "turning radius to the outside front wheel; your course follows the axle "
           "centre, half the front axle width inboard:")
    s.space(4)
    s.text("minimum course radius  =  AASHTO minimum turning radius  -  "
           "1/2 front axle width", font="hebo", indent=20)
    s.space(6)
    s.text("The last column below applies to turns in BOTH directions.")
    s.space(8)
    radius_table(s, rows)
    s.space(4)
    s.text("How exact is that last column? Not exact, and it is ours, not AASHTO's. "
           "The front axle width is certainly centre of tire to centre of tire -- "
           "that is what BUILDVEHICLE asks for, and the blocks' marker circle sits "
           "exactly half that off the centreline. The other end is not settled: "
           "AASHTO measures to the outer EDGE of the outer front tire, so strictly "
           "another half tire width should come off, about half a foot on a truck. "
           "The old sheets said the blocks were built to reconcile that but not by "
           "how much, and we have not confirmed it. Good to a few inches; leave a "
           "margin.", size=8, color=GREY)

    # ---------------------------------------------------------------- footer
    s.heading("FULL INSTRUCTIONS, AND HELP")
    s.text(URL, font="hebo")
    s.space(2)
    s.text("That page carries the rest: the layer list, defining your own vehicle "
           "with BUILDVEHICLE, and a troubleshooting table covering the mistakes "
           "that actually reach our inbox.")

    # Small keep: the licence is boilerplate and is not worth a page of its own.
    s.heading("LICENSE", gap=10, keep=26)
    s.text("These instructions and the Imperial Unit AASHTO vehicle blocks are free "
           "software: you may redistribute and/or modify them under the GNU General "
           "Public License as published by the Free Software Foundation, either "
           "version 3 or (at your option) any later version. Distributed in the hope "
           "they will be useful, but WITHOUT ANY WARRANTY; without even the implied "
           "warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the "
           "GNU General Public License for details.", size=8, color=GREY)

    doc.set_metadata({
        "title": "TURN.LSP Instructions - AASHTO %s Imperial Unit Vehicle Blocks" % edition,
        "author": "Thomas Gail Haws",
        "subject": "Turning path modeling instructions for TURN.LSP",
        "keywords": "TURN.LSP AASHTO turning path swept path AutoCAD",
    })
    doc.save(path, deflate=True, garbage=4)
    doc.close()
    return path


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(outdir, exist_ok=True)
    for edition, rows in (("2004", AASHTO_2004), ("2011", AASHTO_2011)):
        p = os.path.join(outdir, "%s_AASHTO_Turn_Radius_Instructions.pdf" % edition)
        build(edition, rows, p)
        d = pymupdf.open(p)
        print("%-46s %d pages  %6d bytes" % (os.path.basename(p), d.page_count,
                                             os.path.getsize(p)))
        d.close()


if __name__ == "__main__":
    main()
