# Overview of the scripts

In this document we do not repeat the presentation of the CycloidGearMilling.m script. It is already covered in the Gear_milling.md document. Hence, the scope here covers the export script and the usitility scripts. Where we note that exports are also availaibe as an option at the bottom of the CycloidGearMilling.m script.

# Export Script CycloidGearToCSVAbdOBJ.m
The export script converts tooth shapes into formats suitable for CAD systems, such as (in particular) Fusion.
We deliberate limit the amount of data in these exports by providing only one tooth or half-tooth. The reason is that Fusion tends to slow down significantly when dealing with large polylines or large meshes. It is best to work in Fusion as long as possible on a sector, and only create the entire tooth (using a circular pattern) at the last moment. For example for 3D printing. It is also important not to exaggerate the requested tolerance, as tighter tolerance increases the size of the exports.

# The CSV export
Fusion, under utilities, supports reading of CSV polyline files. It has the following particularities:
- It requires a header
- It requires X, Y, Z data
- It imports in **centimeters**
Our CSV exports satisfies these requirements: it is in cm units.

Fusion creates a sketch with the imported polyline.

# The OBJ export



The CSV export script writes a 2D point set to a simple comma‑separated file:

Code
x0, y0
x1, y1
...
Fusion’s “Insert CSV” workflow interprets these points as a polyline. This is useful for:

inspecting geometry

importing a single tooth gap

building sketches based on the curve

Fusion can become slow with large point counts, so the export scripts typically write only one gap section. The user can then mirror and pattern the section inside Fusion.

)))))))))))))))))))))))))))

Units and Format (CSV and OBJ)
The CSV exporter writes coordinates in centimeters, because Fusion’s CSV importer always interprets values as centimeters regardless of the document’s unit settings. The CSV file includes a header row and three columns (X, Y, Z), with Z = 0 for 2D curves.

The OBJ exporter writes coordinates in millimeters. The curve is extruded symmetrically in the Z direction: a thickness t produces a mesh from Z = -t/2 to Z = +t/2. Fusion imports OBJ meshes directly without unit conversion.

)))))))))))))))))))))))))))






# OBJ Export
The OBJ export script writes a 3D mesh with a user‑specified thickness. This is useful when:

a solid representation is needed

the user prefers to work with bodies rather than sketches

Fusion’s spline engine struggles with large point sets

The OBJ file contains:

vertices

faces

a thin extrusion of the 2D curve

Fusion imports OBJ meshes reliably, though editing them is more limited than editing sketches.

# Fillet Radius vs Tooth Count Graph
This script plots the relationship between:

the fillet radius

the number of teeth

the chosen rolling radii

the dedendum height

The fillet radius is determined by the geometry of the hypocycloid and the chosen dedendum height. As the tooth count changes, the pitch radius changes, and the fillet radius changes accordingly.

The script is useful for:

selecting a mill diameter that fits into the fillet

determining whether rest machining is required

understanding how geometry scales with module and tooth count

The graph helps the user choose:

appropriate roughing mill sizes

appropriate finishing mill sizes

appropriate dedendum height (hD)

The script prints the fillet radius as part of the gear properties and plots it for a range of tooth counts.

# Gear‑Train Optimisation Scripts
Two scripts are provided for optimising gear trains. They are intended for clockwork or other applications where:

a specific ratio is required

tooth counts must be integers

modules must be practical

rolling radii must be compatible

dedendum and addendum heights must be feasible

Ratio Search
This script searches for combinations of tooth counts that achieve a desired ratio within a tolerance. It evaluates:

gear pairs

gear trains of multiple stages

integer constraints

practical tooth counts (e.g. avoiding very small gears)

The output includes:

candidate tooth counts

achieved ratio

deviation from target

pitch diameters

# Geometry Feasibility Check
This script checks whether a candidate gear train is geometrically feasible:

rolling radii compatibility

dedendum and addendum heights

fillet radius

mill diameter constraints

minimum tooth count for cycloidal geometry

It is useful for validating gear trains before committing to machining.

# Summary
The utility scripts provide:

CSV and OBJ export of geometry and milling curves

a fillet‑radius graph for selecting mill sizes

optimisation tools for designing gear trains

These scripts complement the geometry and milling modules and help users explore and validate designs before machining.
