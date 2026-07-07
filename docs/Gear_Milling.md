# Gear Milling

This document describes the gear‑specific milling workflow built on top of the general CAM suite. It explains how cycloidal gear geometry is turned into toolpaths, how roughing and finishing are organised, and how the circular tooth pattern is implemented in G‑code. The general CAM classes (CBT_MillPath, CBT_Layer, CBT_Trace, CBT_Tools, CBT_MillingMachine) are documented separately. Here we focus on the CBT_GearMilling class and its use.

By and large, we describe the working of the key scripts in the scripts folder.

1. Creation of a the gear object
The functions for gear creation are described in the document Gear_Geometry. A gear is created using the create(..) function, which takes as inputs the module, the tooth count, the rolling circle radii, the addendum and dedendum heights. For example: gear = CBT_CycloidGear.create(1.2, 10, 2.0, 2.0, 1.0, 1.05) are typical numbers for a gear of module 1.2 with 10 teeth. At this point, the gear is fully defined.

2. Creation of the gear milling object
A CBT_GearMilling object is then created, using the function CBT_GearMilling.create(gear, safeR, safeZ), where:
- gear is the gear from the step
- safeR is a safe radius for the mill. It is only used in the G code for the circular pattern, not in the mill path of the tooth gap.
- safeZ is a safe Z value for the mill. It is only used in the G code for the circular pattern, not in the mill path the tooth gap.

3. Creation of the milling curves
CBT_GearMilling, by querying its gear property, calculates the mill curves, offset from the tooth curve by a distance millradius + stockToLeave.
**In the current version, we use a flat end mill and take small radial cuts at full depth. We assume that the stock diameter is prepared to equal the outer radius of the gear.**

We have two different kinds of millpath: roughing and finishing.

Roughing millpaths are created by CBT_GearMilling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance, cutDepth), where:
- tolerance is the error allowed by the adaptive sampling algorithm, typical values are 0.01 to 0.001mm
- millDiameter is the diameter of the mill
- stockToLeave is the material to be left for the finishing cut
- xClearance is the radial distance outside of the stock at which the mill path starts and end. Specifically: radiusStart = obj.rStock + millRadius + xClearance
- cutDepth is an array of **radial depth** of cut values.
The resulting mill path is best appreciated by looking at the graphs produced by the script. For each cut there is a radial cutting move at the radial cut depth, followed by a small retract and positioning for the next cut.

The next function to be called creates the actual millpath from these curves. Hence, in this function we interface with the CAM suite.
We have millPathRoughing1 = milling.createRoughingMillPath(zCut, zRetract), where:
- zCut is the vertical depth Z of the cut
- zRetract is the Z of retract moves
Finally, this function also sets the zero point (which will become the origin of the machine's work coordinates) 
The resulting mill path can be plotted. 

The script also illustrates how the roughing stage implements the concept of rest machining. One can start with a mill that is too large to mill all the way down to the fillet. One sets the radial cut depth array. At some cut depth the mill, accounting for stock to leave, will no longer fit and the script will throw an error. In that case, the user has to modify the cut depth array. Until no error is thrown. One can then continue with a smaller mill. The first cut depth of the smaller mill should be equal to, or slightly smaller, than the last cut depth of the bigger mill.

The procedure for the finishing millpath is, mutatis mutandis, the same. The finishing cut simply runs, at full depth, along the periphery of the tooth to remove the roughing stock to leave. Optionally, one can leave stock to leave also for a finishing cut.

Finally, one creates the machine and the tools, using the following calls: 

machine = CBT_MillingMachine.create3Axis();

toolR1 = CBT_Tool.create(88, CBT_ToolTypes.endmill, 2.0, 135.00);
toolR2 = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
toolF  = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
where:
- the first argument is the tool index in the machine's tool table
- the second arguments indicates this is a standard end mill
- the third argument is the diameter
- the final argument - 135.0 - is not meaningfull in this context, it is only relevant to swivel settings.

For each operation, we need to set the tool, the feeds, and the millpath. For example:µ
machine.setTool(toolF);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathFinishing);

All is ready now for extracting the G-code:

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

The logic for the circular pattern uses G68, G69 for coordinate rotations in the XY plane, and relies in the language extensions built in the Eding CNC controller. This is the only part of the G-code that may not be compatible with other controllers, and that may therefore require either manual corrections or some rewriting of the code.


