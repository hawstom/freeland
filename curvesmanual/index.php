<html>

<head>
<meta http-equiv="Content-Type"
content="text/html; charset=iso-8859-1">
<meta name="Author" content="Thomas Gail Haws">
<meta name="Copyright"
content="Copyright © 1999-2000 by Thomas Gail Haws.">
<meta name="Description"
content="HawsEDC AutoCAD and civil engineering software and services">
<meta name="Keywords"
content="AutoLISP autocadd civil engineering routines LDT alternative">
<meta name="GENERATOR" content="Microsoft FrontPage Express 2.0">
<link rel="stylesheet" href="../hawsedc.css" type="text/css" />
<title>HawsEDC Free Simple Curve Data Tables AutoLISP (LISP) for AutoCAD</title>
</head>

<body>
<div
align="left">

<table border="0" cellpadding="0" cellspacing="0" width="80%">
    <tr>
        <td width="100%"><font size="7">HawsEDC</font></td>
    </tr>
    <tr>
        <td width="100%"><font size="3">Engineering, Drafting,
        and Computing</font></td>
    </tr>
</table>
</div>

<h2 align="left">FREE SIMPLE CURVE DATA TABLES FOR AutoCAD</h2>

<p>GET CURVE DATA. SHOW IT ON A LEADER. PUT IT IN A TABLE.</p>

<p align="left"><a href="curves.lsp" title="In Internet Explorer, RIGHT-click, Save Target As... to your computer">Download CURVES.LSP</a><br>
<a href="curvestest.dwg" title="In Internet Explorer, RIGHT-click, Save Target As... to your computer">Download CURVESTEST.DWG for a quick
test</a> <br>
<a href="cn.dwg" title="In Internet Explorer, RIGHT-click, Save Target As... to your computer">Download generic curve number block (can be changed as needed)</a> <br>
<a href="ct.dwg" title="In Internet Explorer, RIGHT-click, Save Target As... to your computer">Download generic curve table block (can be changed as needed)</a> <br>
<a href="cthead.dwg" title="In Internet Explorer, RIGHT-click, Save Target As... to your computer">Download generic curve table header block (can be changed as needed)</a> </p>

<h3 align="left">OVERVIEW</h3>

<p align="left">CURVES.LSP is a <a href="http://www.gnu.org/philosophy/free-sw.html">Free Software</a> simple substitute for the
AutoCAD Land Desktop method of getting curve data and creating civil
engineering curve tables. CURVES.LSP is
simple, simple, simple, providing just enough automation to avoid 
headaches and mistakes.  CURVES.LSP extracts curve data (RADIUS,
LENGTH, DELTA, TANGENT, CHORD, and BEARING) from one arc or heavy
polyline arc segment at a time, and stores whatever values are
received into an attributed curve number block.  You then add the
number (label) for the curve and let CURVES.LSP copy all the data 
from the curve number block to the curve table.</p>

<p align="left">Very simple. No grand schemes. No headaches. No
typos. No calculator required.  Everything you need to get started is included.</p>

<h3 align="left">GETTING STARTED</h3>

<p align="left">Download CURVES.LSP (save it to your computer) 
by following the link on this page.</p>

<p>At minimum, all CURVES.LSP needs to work is an arc or polyline
arc segment, a curve number block with a curve number attribute
and one or more of the following attributes: (RADIUS, LENGTH,
DELTA, TANGENT, CHORD, and BEARING), and a curve data table block
with the same attributes. Try the following exercise (You can
download CURVESTEST.DWG instead of doing steps 1-3):</p>

<p align="left">First, draw an arc and a polyline with an arc
segment. Now you have curves to label.</p>

<p align="left">Second, insert the CN.dwg (Curve Number) block
from <a href="http://www.hawsedc.com/gnu/cn.dwg">http://www.hawsedc.com/gnu/cn.dwg</a>
twice-- once for each curve. See below for tools to edit and use
the block. Now you have empty curve labels.</p>

<p align="left">Third, insert the CTHEAD.dwg (Curve Table Header)
block from <a href="http://www.hawsedc.com/gnu/cthead.dwg">http://www.hawsedc.com/gnu/cthead.dwg</a>,
then the CT.dwg (Curve Table) block from <a
href="http://www.hawsedc.com/gnu/ct.dwg">http://www.hawsedc.com/gnu/ct.dwg</a>
twice below it. Now you have an empty curve table.</p>

<p align="left">Fourth, load and run CURVES.LSP by dragging it
from Windows Explorer into your drawing and typing CURVES.</p>

<p align="left">Fifth, follow the prompts to Set your drawing
units for a curve table, Get curve data from a curve and put it
into a curve number block, Edit the block if you want to change
the curve number or look at the data, and Copy the data to a
single-line block of the curve table.</p>

<p align="left">That's all there is to it. CURVES works with
curves that are nested in xrefs and blocks, too. It couldn't be
simpler.</p>

<h3 align="left">EFFICIENCY NOTES</h3>

<p align="left">For increased efficiency, you can invoke the
parts of the CURVES command separately. <br>
GEODATA: get curve data and put into block <br>
EDIT: edit blocks <br>
COPYATTS: copy attributes</p>

<p align="left">For even better efficiency, you can define
shorter aliases for CURVES (CRV) and the separate commands (CD,
EE, CA) as explained in CURVES.LSP under EFFICIENCY NOTES</p>

<h3 align="left">DEVELOPMENT NOTES</h3>

<h3 align="left">REVISION HISTORY</h3>
<div align="left">

<table border="1" cellpadding="0" cellspacing="0">
    <tr>
        <th align="left">Date</th>
        <th align="left">Programmer</th>
        <th align="left">Revision</th>
    </tr>
    <tr>
        <td>20021028</td>
        <td>TGH</td>
        <td>Put together CURVES package from GEODATA, CA, and EE.</td>
    </tr>
</table>
</div>

<p align="left">To submit revisions, use the contact form on this web site.</p>

<h3 align="left">LICENSE TERMS</h3>

<p align="left">This program is free software under the terms of
the GNU (GNU--acronym for Gnu's Not Unix--sounds like canoe)
General Public License as published by the Free Software
Foundation, version 2 of the License.</p>

<p align="left">You can redistribute this software for any fee or
no fee and/or modify it in any way, but it and ANY MODIFICATIONS
OR DERIVATIONS continue to be governed by the license, which
protects the perpetual availability of the software for free
distribution and modification.</p>

<p align="left">You CAN'T put this code into any proprietary
package. Read the license.</p>

<p align="left">If you improve this software, please make a
revision submittal to the copyright owner at www.hawsedc.com.</p>

<p align="left">This program is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the <a href="http://www.gnu.org/copyleft/gpl.html">GNU General Public License</a> on the World Wide Web
for more details..</p>

<div>
<?php
require '../../menu.php';
hawsedcmenu();
?>
</div>

<hr>

<p><!--webbot bot="HTMLMarkup" startspan alt="Site Meter" -->
<script type="text/javascript" language="JavaScript">var site="sm3gen-tgh"</script>
<script type="text/javascript" language="JavaScript1.2" src="http://sm3.sitemeter.com/js/counter.js?site=sm3gen-tgh">
</script>
<noscript>
<a href="http://sm3.sitemeter.com/stats.asp?site=sm3gen-tgh" target="_top">
<img src="http://sm3.sitemeter.com/meter.asp?site=sm3gen-tgh" alt="Site Meter" border=0></a>
</noscript>
<!-- Copyright (c)2000 Site Meter -->
<!--webbot
bot="HTMLMarkup" endspan --> </p>
<script language="JavaScript" type="text/javascript">
<!--

         document.write("Last Modified " + document.lastModified)

// -->
</script>
</body>
</html>








