Milling Classes (CAM Overview)
The code in the milling directory implements a general‑purpose CAM suite for 3‑axis and 4‑axis CNC milling. It was originally developed for contour‑milling complex 3D surfaces such as centrifugal compressor wheels. It supports:

X, Y, Z linear axes

A rotary axis

an optional fixed swivel angle B (for machines with a tilting head)

The implementation was written for an EMCO F1CNC equipped with an Eding CNC controller. The gear‑milling application uses only part of the available functionality; the gear‑specific workflow is described in a separate document.

1. Coordinate Systems
The CAM suite distinguishes between object coordinates and machine coordinates.

1.1 Object coordinates
These describe the position and orientation of the tool relative to the workpiece:

x1, x2, x3 — Cartesian coordinates of the tool centre

phi — rotation angle around the object’s vertical axis

theta — tilt angle of the tool (radians)

These coordinates are used when designing toolpaths.

1.2 Machine coordinates
These describe the actual CNC machine axes:

X, Y, Z — linear axes

A — rotary axis

B — swivel axis (fixed angle in this implementation)

The mapping from object coordinates to machine coordinates depends on the machine configuration.

2. Machine Configurations
The CAM suite supports three machine setups:

3‑axis machine

Object axes map directly to machine axes.

4‑axis machine with A parallel to X

Rotation around the object’s vertical axis (phi) maps to the machine’s A axis.

The Y axis compensates to keep the tool centre fixed while orientation changes.

4‑axis machine with A parallel to Z

Similar mapping, but rotation is around the Z axis.

The user selects the machine type when creating a CBT_MillingMachine object.

2.1 Swivel angle B
The swivel angle theta is mapped to machine axis B.
In the EMCO/Eding setup, the mapping is:

Code
B = 90 * (pi/2 - theta)
This is purely conventional and may differ on other machines.

3. CAM Structure: MillPath, Layers, Traces
All toolpath design happens in object coordinates.

3.1 MillPath (CBT_MillPath)
A MillPath represents a complete machining operation. It consists of:

one or more layers

each layer containing one or more traces

3.2 Layers (CBT_Layer)
A layer corresponds to a single cutting depth.
Typical examples:

roughing passes at multiple Z levels

finishing pass at final depth

clearance moves above the part

3.3 Traces (CBT_Trace)
A trace represents a single motion of the tool centre:

rapid move

linear cut

circular arc

lead‑in / lead‑out

dwell

Each trace stores:

start and end coordinates

trace type (CBT_TraceTypes)

feed (CBT_Feeds)

plane (XY, XZ, YZ)

This abstraction allows the same MillPath to be mapped to different CNC controllers.

4. Tools
Tools are defined in CBT_Tools. Two types are supported:

Flat endmill

Machine controls the tip

Tool length equals measured physical length

Ball‑nose endmill

Machine controls the centre of the ball

Effective tool length = measured length minus ball radius

This behaviour is ideal for contouring complex 3D surfaces, where the tool centre must follow the surface precisely.

5. Mapping to Machine Coordinates
Once a MillPath is defined, the user creates a CBT_MillingMachine object. The machine:

maps object coordinates to machine coordinates (X, Y, Z, A, B)

applies tool length compensation

applies feed and speed settings

converts traces into G‑code

writes the G‑code to a .cnc file

5.1 Subroutine generation
It is often convenient to generate G‑code as a subroutine.
This allows the user to embed the generated path into their own program.

The CAM suite supports exporting:

Code
SUB <name>
  ... G-code ...
ENDSUB
This syntax is specific to Eding CNC.

6. Controller Caveats
6.1 Eding CNC extensions
The gear‑milling application uses Eding CNC language extensions:

Do While loops

controller variables

arithmetic expressions

coordinate rotation inside loops (for tooth indexing)

These appear in the header of the generated G‑code file.

The subroutine body (the actual toolpath) is universal and typically requires no modification.

6.2 Porting to other controllers
For controllers such as:

Fanuc

Heidenhain

LinuxCNC

Mach3

Haas

the user may need to:

remove SUB / ENDSUB

replace loops with explicit repeated code

adjust macro syntax

adjust coordinate rotation commands

The geometry and toolpaths remain valid; only the controller‑specific syntax changes.

7. Summary
The milling classes provide a general CAM framework:

object‑space toolpath design

layers and traces

tool definitions

feed and speed control

machine mapping for 3‑axis and 4‑axis setups

G‑code generation

optional subroutine output

support for Eding CNC extensions

The gear‑milling workflow builds on this foundation and is described in a separate document.
