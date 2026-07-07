# Gear Milling

This document describes the gear‑specific milling workflow built on top of the general CAM suite. It explains how cycloidal gear geometry is turned into toolpaths, how roughing and finishing are organised, and how the circular tooth pattern is implemented in G‑code.

The general CAM classes (CBT_MillPath, CBT_Layer, CBT_Trace, CBT_Tools, CBT_MillingMachine) are documented separately. Here we focus on the CBT_GearMilling class and its use.

1. Overview
Gear milling in this toolkit is based on three ideas:

work in object coordinates (gear centre, tooth gap)

generate offset curves for the tool centre

use the CAM suite to turn these curves into G‑code

The gear geometry (pitch radius, addendum, dedendum, fillet, epi/hypo curves) is provided by CBT_CycloidGear. CBT_GearMilling takes that geometry and builds:

a finishing path that cuts the final tooth shape

one or more roughing paths that remove bulk material

a circular pattern that repeats the gap around all teeth

G‑code, currently tuned to an Eding CNC controller

2. Inputs to CBT_GearMilling
The main inputs are:

gear geometry object (CBT_CycloidGear)

module, tooth count, rolling radii, hA, hD

mill diameter

stock to leave (for roughing)

milling depth (Z)

curve tolerance (for adaptive sampling)

machine configuration (3‑axis or 4‑axis)

From these, CBT_GearMilling constructs the toolpaths in object coordinates.

3. Finishing path (tool centre offset)
The gear geometry provides the gap curve between two teeth:

fillet at the root

hypocycloid flank

epicycloid flank

This curve describes the material boundary. The tool centre must follow an offset of this boundary.

The finishing offset is:

Code
offset = millDiameter / 2
Optionally plus a small stock value if desired.

3.1 Steps to build the finishing path
Obtain the gap curve from CBT_CycloidGear as a function of a parameter.

Compute the offset curve for the tool centre at the chosen offset.

Apply adaptive sampling to the offset curve to meet a geometric tolerance.

Build a CBT_Layer at the finishing depth Z.

Convert sampled points into CBT_Trace objects (cuts, lead‑ins, lead‑outs).

Assemble the traces into a CBT_MillPath.

This produces a single finishing path for one gap.

4. Roughing paths
Roughing paths remove material before the finishing pass. They are generated as inner offsets of the gap curve, leaving radial stock.

Typical roughing offset:

Code
offsetRough = millDiameter / 2 + stockToLeave
Roughing is usually done in multiple Z levels:

first pass at shallow depth

subsequent passes stepping down to final depth

Each roughing level is a separate CBT_Layer with its own traces.

5. Adaptive sampling
To avoid excessive point counts and uneven spacing, the offset curves are sampled adaptively.

The algorithm:

starts with a segment between two parameter values

evaluates the true curve at the midpoint

compares the midpoint to the straight line between endpoints

if the deviation exceeds a tolerance, splits the segment

repeats recursively

This yields:

more points where curvature is high (fillet, tight cycloid regions)

fewer points where the curve is nearly straight

a good balance between accuracy and file size

Typical tolerances:

Code
0.01 mm to 0.001 mm
Smaller tolerances produce more points and larger G‑code files.

6. Circular tooth pattern
The finishing and roughing paths described above cover one gap between two teeth. To mill the full gear, this gap must be repeated around the pitch circle.

The circular pattern is implemented in G‑code using:

a subroutine containing the gap toolpath

a loop that rotates the coordinate system for each tooth

a rotation command (G68 in Eding CNC) to apply the angle

6.1 Structure of the G‑code
Conceptually:

Code
SUB GearGap
  ... toolpath for one gap ...
ENDSUB

#NTeeth = <tooth count>
#Angle  = 360.0 / #NTeeth

i = 0
Do While i < #NTeeth
  G68 ... rotate by i * #Angle ...
  CALL GearGap
  i = i + 1
Loop
The subroutine GearGap contains only the toolpath for one gap.

The loop and G68 rotation live in the header of the G‑code file.

The subroutine body is controller‑independent; only the header uses Eding extensions.

On other controllers, the user may need to:

replace Do While and variables with that controller’s macro syntax

replace G68 with the equivalent rotation command

or unroll the loop manually by repeating the subroutine call with different angles.

7. Tool compensation and normals
The gear‑milling workflow does not use controller‑side tool compensation (no G41, G42, G43). Instead:

the tool centre path is computed explicitly in object coordinates

the offset curve already accounts for tool radius

the CAM does not attempt to compute surface normals or apply automatic compensation

This is necessary because:

tilted tools and ball‑nose cutters complicate normal‑based compensation

general surface normals on complex shapes are best handled in CAD/CAM (e.g. Fusion)

controller‑side compensation is unreliable for 3D contouring

For gear milling, the explicit offset curve is sufficient and robust.

8. Practical workflow
A typical gear‑milling workflow is:

Define gear geometry in CBT_CycloidGear.

Create a CBT_GearMilling instance with gear + milling parameters.

Generate finishing and roughing paths (one gap).

Build a CBT_MillPath from these layers.

Create a CBT_MillingMachine with the appropriate configuration.

Map the MillPath to G‑code and write a .cnc file.

Inspect and, if necessary, adapt the header (loop, rotation, macros) for the target controller.

Run a dry‑run or air‑cut before cutting material.

9. Summary
CBT_GearMilling provides a gear‑specific layer on top of the general CAM suite:

uses cycloidal gear geometry from CBT_CycloidGear

builds offset curves for tool centre paths

generates roughing and finishing layers

applies adaptive sampling for efficient, accurate toolpaths

creates a circular tooth pattern via subroutines and coordinate rotation

outputs G‑code tuned to Eding CNC, with a header that may need adaptation for other controllers

This keeps the gear‑milling logic compact and focused, while reusing the general CAM machinery for path representation and G‑code generation.
