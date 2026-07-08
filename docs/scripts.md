# Overview of the scripts

This document gives an introduction to the scripts in the scripts folder. They are the primary user-interfaces.

We will not repeat the presentation of the CycloidGearMilling.m script. It is already covered in the Gear_milling.md document. Hence, the scope here covers the export script and the usitility scripts. *Where we note that exports are also available as an option at the bottom of the CycloidGearMilling.m script.*

# Export Script CycloidGearToCSVAndOBJ.m -> 3D printing
The export script converts tooth shapes into formats suitable for CAD systems. We expect them to be used for:
- preparation of 3D printing files
- design of decorative elements on gearwheels and their milling using Fusion CAM

We deliberate limit the amount of data in these exports by providing only one tooth or half-tooth. The reason: Fusion tends to slow down significantly when dealing with large polylines or large meshes. It is best to work in Fusion as long as possible on a single sector, and only create the entire tooth (using a circular pattern and combine-bodies) at the last moment. For example for 3D printing. It is also important not to exaggerate the requested tolerance, as tighter tolerance increases the size of the exports.

By default, the exports include a point outside of the tooth, which is a linear extrapolation of the outer element of the tooth. This allows, for example, to create a body that is used in Fusion as a knife, cutting out a tooth from a cylindrical sector instead of being used additive. In any case, the outer point can be deleted, or the mesh can be clipped at the gear outer dadius. 

# The CSV export
Fusion supports reading of CSV polyline files, using a script under the Utilities tab. It has the following particularities:
- It requires a header
- It requires X, Y, Z data
- It imports in **centimeters** -> assuming our code works in mm, values are divided by 10 on output.
Our CSV exports satisfies these requirements: output is converted to cm units.
The Fusion script will create a sketch with the imported points / polyline.

# The OBJ export
The OBJ export script writes a 3D mesh with a user‑specified thickness. This is useful when the user prefers to work with bodies rather than sketches.
The OBJ file contains an extrusion to user-defined thickness. The extrusion is symmetric in the XY plane, half-thickness up, half down. Here, there is no unit conversion.
- vertices
- faces

Fusion imports OBJ meshes reliably. However, as with the CSVs, Fusion’s spline engine slows down with large point sets. In our experience it is easier to deal with the CSV input.

# Fillet Radius script FilletRadiusFunctionOfHd.m
When CNC milling gears in this way, the fillet radius is an important factor in the process. Fillet radius must be larger than tool radius plus any stock to leave. And even without stock to leave, it is not good practice to give the mill some room of manouvre at the bottom of the fillet.

Fillet radius, for a given module, depends on dedendum height hD and tooth count N. We note that, for a given hD, fillet radius decreases with tooth count. In other words, a mill may fit with a pinion, but not with the matching wheel.

This scripts provides graphs of the fillet radius as a function of tooth count for a range of hD values, all user input. It can help at gear design stage.

# Gear‑Train Optimisation Scripts
When designing a gear train, it is typical to know the desired end-to-end ratio, but not how this should be broken down over the various stages. For example, one may break down a 120 ratio as 4, 5, 6, or 4, 5, 2, 3. These choices depend on design desiderate, e.g. to give the first stage pinion the maximum number of teeth, or to fit the train inside some space.

We provide two scripts that can help design on this point. The user provides:
- the target end-to-end ratio
- a array of permitted pinion tooth counts, for example 7, 8, 9. 
- a range of permissible gear ratios, e.g. from 3 to 4.

The scripts provides a list of all pinion / wheel combinations that satisfy these constraints - there tend to be rather a few. The user can then choose.

We note that there is always the freedom to swap around the selected pinions (i.e. 9 * 10 * 8 = 10 * 8 * 9) and independently the selected wheels.

The algorithm: 
- given the pinions, all possible products of pinion counts are calculated
- these numbers are multiplied by the end-to-end target
- the resulting numbers are factored into integer numbers that satisfy the range of permitted ratios

# Geometry Feasibility Check: PinionAndWheelSet.m
For this script, the user provides:
- the parameters to creta a pinion - the usual set
- the number of teeth on a wheel to match

With these inputs, the script:
- creates a pinion with the user provided parameters
- then creates a matching wheel with the required number of teeth and with matching parameters

If the user has chosen different values for the pinion rolling ball ratios rhoA and rhoD, then the wheel will be created with the correct, swapped rhoA and rhoD values. 

The outputs are plotted, and all data of the pinion / wheel set can be inspected.

