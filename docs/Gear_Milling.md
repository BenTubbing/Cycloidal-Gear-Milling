# Gear Milling
This document describes the gear‑specific milling workflow built on top of the general CAM suite. It explains how cycloidal gear geometry is turned into toolpaths, how roughing and finishing are organised, and how the circular tooth pattern is implemented in G‑code.

For milling, the main user‑facing script is CycloidGearMilling.m. After creating the gear geometry, this script relies exclusively on the class CBT_GearMilling. The easiest way to understand the workflow is to follow the steps of this script.

**NOTE: this script assumes that the stock has been pre-machined to the gear's outer diameter, and that the thickness is equal or very close to the intended thickness of the gear.**
Typical ways of handling the stock are to super-glue the stock disc to an MDF base (and remove it using acetone), or to premachine the disk on a stem that is held in a vertical collet.

**NOTE: please avoid crashes or breakages by checking carefully and by carrying out a dry run**

# Step 1 — Create the gear object
A gear is created using:
```
gear = CBT_CycloidGear.create(module, toothCount, rhoA, rhoD, hA, hD)
where:
module — gear module
toothCount — number of teeth
rhoA — normalised radius of the addendum rolling circle
rhoD — normalised radius of the dedendum rolling circle
hA — addendum height
hD — dedendum height
```

Example for a module 1.2, 10 tooth pinion with reasonable defaults for the geometry:
```
gear = CBT_CycloidGear.create(1.2, 10, 2.0, 2.0, 1.0, 1.05)
```
At this point the gear geometry is fully defined: pitch radius, addendum/dedendum circles, fillet radius, and the epi/hypo cycloidal curves.

# Step 2 — Create the gear‑milling object
A CBT_GearMilling object is created using:

```
milling = CBT_GearMilling.create(gear, safeR, safeZ)
where:
gear — the gear object from Step 1
safeR — a safe radial position for the mill (used only in the circular pattern G‑code)
safeZ — a safe Z height (also used only in the circular pattern G‑code)
```

These values do not affect the tooth‑gap millpath itself; they are used only in the header that rotates the coordinate system for each tooth.

# Step 3 — Create milling curves (offset from tooth curves)
Notes:
- The current workflow uses a flat endmill.
- Radial cuts are taken at full depth.
- The stock is assumed to be pre‑machined to the outer diameter and thickness of the gear.
- CBT_GearMilling queries its gear property and computes the offset curve for the tool centre:

```
offset = millRadius + stockToLeave
```
This offset curve is sampled using the same adaptive sampling method used in the geometry module, with a user‑specified tolerance.

# Step 4 — Roughing and finishing milling curves
**Roughing curves**
Roughing curves are created using:

```
curveRough = milling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance, cutDepth)
Parameters:
tolerance — adaptive sampling tolerance (typ. 0.01 to 0.001 mm)
millDiameter — diameter of the mill
stockToLeave — radial stock left for finishing
xClearance — radial clearance outside the stock
cutDepth — array of radial depth‑of‑cut values
```

The resulting roughing path consists of:
- a radial cutting move at each depth
- a small retract
- positioning for the next cut

The script plots these curves for inspection.

**Rest machining**
The roughing stage supports rest machining:

- Start with a larger mill
- If a cut depth is too deep for the current mill, the script throws an error and suggests modifying the radial depths array
- Mill until the mill no longer fits into the gap (considering stock‑to‑leave)
- Switch to a smaller mill -note G43 can be used
- The first cut depth of the smaller mill should match the last cut depth of the larger mill

**Finishing curves**
Finishing curves are created using:

```
curveFinish = milling.createFinishingMillCurve(tolerance, millDiameter, stockToLeave, xClearance)
```
Finishing simply runs the offset curve at full depth to remove the roughing stock.

The script plots these curves as well.

# Step 5 — Convert milling curves into millpaths
The milling curves are converted into CAM millpaths using:

```
millPathRough = milling.createRoughingMillPath(zCut, zRetract)
Parameters:
- zCut — Z depth of the cut
- zRetract — retract height
```
This function:
- creates traces (CBT_Trace)
- creates a single layer (CBT_Layer) because we cut at full depth
- adds lead‑ins, lead‑outs, and transitions
- sets trace types
- sets the zero point (origin of work coordinates)
**The zero point - on the object side - is at the centre of the gear and at z = 0. The user has to match this, hence set the machine's work X, Y coordinates to zero at the centre of the stock and Z at the top of the stock.**  

Finishing paths are created similarly.

# Step 6 — Create machine and tools, set feeds
Example of a 3 axis vertical machine:
```
machine = CBT_MillingMachine.create3Axis();
```
Create tools:
```
toolR1 = CBT_Tool.create(88, CBT_ToolTypes.endmill, 2.0, 135.00);
toolR2 = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
toolF  = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
Where the arguments are:
tool index in the machine’s tool table
tool type
diameter
effective length parameter (only meaningful for swivel machines; irrelevant here)
```

Setting up the machine, here shown for a finishing operation. It should be done in this order, and redone after a machine reset:
```
machine.setTool(toolF);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathFinishing);
```
# Step 7 — Extract G‑code
Sequence:
```
name         = filenameStub + "_Finishing";
gCode        = machine.getMillPathGCodeAsSub(name);
gCodePattern = milling.getGCodeForPattern(name);

fid = fopen(fullfile(folderCNC, name + ".cnc"), 'w');
fprintf(fid, '%s', gCodePattern + gCode);
fclose(fid);

machine.resetMachine();
```
Meaning:
- filenameStub — user‑chosen prefix
- gCode — G‑code for one tooth gap, wrapped in a subroutine
- gCodePattern — header G‑code that rotates the coordinate system and calls the subroutine once per tooth
- resetMachine() — prepares for the next operation

# Caveat — Circular pattern and controller compatibility
The circular pattern uses:
- G68 / G69 for coordinate rotation
- Eding CNC loop constructs (Do While, variables)

This is the only part of the G‑code that may not be compatible with other controllers.
The subroutine itself is universal; only the header may require adaptation.




