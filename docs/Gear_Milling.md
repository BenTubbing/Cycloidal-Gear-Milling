# Gear Milling

This document describes the gear‑specific milling workflow built on top of the general CAM suite. It explains how cycloidal gear geometry is turned into toolpaths, how roughing and finishing are organised, and how the circular tooth pattern is implemented in G‑code. 

For milling, the relevant script is CycloidGearMilling.m. This script, after creating the gear geometry proper, relies exclusively on the class CBT_GearMilling. To understand the methodology it is useful to go through the steps of this script.

**Step 1: Creation of a the gear object**
A gear is created using the CBT_CycloidGear.create(module, toothCount, rhoA, rhoD, hA, hD), where:
- module is the gear module
- toothCount is the number of teeth
- rhoA is the normalised radius of the addendum rolling ball
- rhoD is the normalised radius of the dedendum rolling ball
- hA is the addendum height
- hD is the dedendum height
For example: gear = CBT_CycloidGear.create(1.2, 10, 2.0, 2.0, 1.0, 1.05) are typical numbers for a gear of module 1.2 with 10 teeth. At this point, the gear is fully defined.

**Step 2: Creation of the gear milling object**
A CBT_GearMilling object is then created, using the function CBT_GearMilling.create(gear, safeR, safeZ), where:
- gear is the gear from the previous step
- safeR is a safe radius for the mill. It is only used in the G code for the circular pattern, not in the mill path of the tooth gap.
- safeZ is a safe Z value for the mill. It is only used in the G code for the circular pattern, not in the mill path the tooth gap.

**Step 3: Creation of the milling curves, offset from the tooth curves by mill radius plus stock-to-leave**
**NOTE: - in the current version, we use a flat end mill and we take small radial cuts at full depth. 
        - We assume that the stock diameter is pre-machined to the outer diameter of the gear.**

CBT_GearMilling, by querying its gear property, calculates the mill curves, offset from the tooth curve by a distance millradius + stockToLeave. As in the geometry, it uses adaptive sampling to do so with a tolerance given by the user.

**Step 4: Creation of milling curves, using roughing curves as example**
**Roughing mill curves** are created by CBT_GearMilling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance, cutDepth), where:
- tolerance is the error allowed by the adaptive sampling algorithm, typical values are 0.01 to 0.001mm
- millDiameter is the diameter of the mill
- stockToLeave is the material to be left for the finishing cut
- xClearance is the radial distance outside of the stock at which the mill path starts and end. Specifically: radiusStart = obj.rStock + millRadius + xClearance
- cutDepth is an array of **radial depth** of cut values.
The resulting mill path is best appreciated by looking at the graphs produced by the script. For each cut there is a radial cutting move at the radial cut depth, followed by a small retract and positioning for the next cut.

The script also illustrates how the roughing stage implements the concept of rest machining. One can start with a mill that is too large to mill all the way down into the fillet. The user sets the values for the radial cut depth array. If at any depth the mill, accounting for stock to leave, does not fit the space, the script will throw an error and tell the user to reduce the radial depth of cut. Once the bigger mill has run to its maximum radial cut depth, one uses a smaller mill to continue. The first cut depth of the smaller mill should be equal to, or slightly smaller, than the last cut depth of the bigger mill. Incidentally, the script will show the fillet radius as part of the properties of the gear.

**Finishing milling curves** are created by CBT_GearMilling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance), where the meaning of the parameters is the same as for roughing curves. Finishing curves simply run, at full depth, along the periphery of the tooth to remove stock left in the roughing stage.  

The script plots each milling curve.

**Step 5: Turning milling curves into mill paths**
Next we call the function that interfaces with the CAM suite to create actual millpaths from the milling curves. It adds lead-ins, leadouts, and transitions. And it sets the trace types. In this current case, we create traces (CBT_Trace), and we have only one Layer (CBT_layer) because we are working full depth.
The function is millPathRoughing1 = milling.createRoughingMillPath(zCut, zRetract), where:
- zCut is the vertical depth Z of the cut
- zRetract is the Z of retract moves
This function also sets the zero point (which will become the origin of the machine's work coordinates) 

The procedure for the finishing millpath is, mutatis mutandis, the same. The finishing cut simply runs, at full depth, along the periphery of the tooth to remove the roughing stock to leave. Optionally, one can leave stock to leave also for a finishing cut.

The script plots each milling curve.

**Step 6: creating the machine and tools, decide on feeds**
Finally, one creates the machine and the tools, using the following calls: 

machine = CBT_MillingMachine.create3Axis();
This represents a classical 3 axis vertical mill.

We then create one or more tools, as needed:
toolR1 = CBT_Tool.create(88, CBT_ToolTypes.endmill, 2.0, 135.00);
toolR2 = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
toolF  = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
where:
- the first argument is the tool index in the machine's tool table
- the second arguments indicates this is a standard end mill
- the third argument is the diameter
- the final argument - 135.0 - is not meaningfull in this context, it is only relevant to swivel settings.

For each operation, we need to set the tool, the feeds, and the millpath. For example for a finishing operation:
machine.setTool(toolF);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathFinishing);

**Step 7: extract the G code**
The sequence is:
name        = filenameStub + "_Finishing";
gCode       = machine.getMillPathGCodeAsSub(name);
gCodePattern = milling.getGCodeForPattern(name);
fid = fopen(fullfile(folderCNC, name + ".cnc"), 'w');
fprintf(fid, '%s', gCodePattern + gCode);
fclose(fid);
machine.resetMachine();

where:
- filenameStub is a user-chosen prefix for the CNC file. It is set at the top of the script. It will also be the name of the G-code subroutine.
- gCode is the G-code for a single tooth gap, wrapped up in a subroutine.
- gCodePattern is the additional header G-code that calls the subroutine in a circular pattern, once for each tooth
- machine.resetMachine() resets the machine for a next operation. It will require again to set a tool, a feed and a millPath.

**Caveat**
The logic for the circular pattern uses G68, G69 for coordinate rotations in the XY plane. It relies on the language extensions of the Eding CNC controller. This is the only part of the G-code that may not be compatible with other controllers, and that may therefore require either manual corrections or some rewriting of the code.


