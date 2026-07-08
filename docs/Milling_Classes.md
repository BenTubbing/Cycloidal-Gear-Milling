# The Milling Classes (CAM Overview)

The code in the milling directory implements a general‑purpose CAM suite for 3‑axis and 4‑axis CNC milling. It was originally developed for contour‑milling complex 3D surfaces such as centrifugal compressor wheels. It supports:
- X, Y, Z linear axes
- A rotary axis
an optional fixed swivel angle B (for machines with a tilting head)

The implementation was written for an EMCO F1CNC equipped with an Eding CNC controller. The gear‑milling application uses only part of the available functionality; the gear‑specific workflow is described in a separate document.

1. Coordinate Systems
The CAM suite distinguishes between object coordinates and machine coordinates.

1.1 Object coordinates
In this CAM system, the toolpath is designed in object coordinates. This means that every tool position is described by two things:
- Where the tool is: the vector from the object origin to the tool centre. The coordinates are x1, x2, x3 (notation to distinguish from machine X, Y, Z)
- How the tool is oriented: a vector along the tool axis in object space. It is given by the angles theta and phi, as in aspherical polar coordinate system.
where:
- theta — the tilt of the tool axis relative to the object’s vertical direction
- phi — the rotation of the tool axis around that vertical direction

To illustrate the logic: if one keeps x1, x2, x3 constant but changes phi, the tool stays at the same point on the surface while its axis changes orientation. This is the same behaviour seen in 4‑axis or 5‑axis machining: the tool centre remains fixed on the surface, but the tool tilts or rotates to obtain the correct cutting direction. This logic is ideal for ball nose contouring, where x1, x2, x3 are the ball centre position. By changing phi, we change tool orientation but the tool keeps touching the object at the same spot.

**It is important to point out that the CAM does not take care of tool compensation**. Instead, the user needs to supply tool centre coordinates including the correct tool offsets, as calculated from the object's curve or surface normal vectors. This limitation exists because the normal G41, G42, G43 offset compensations work in machine coordinates, but not in object coordinates. Therefore they not apply to general 3D milling with arbitary tool orientations and ballnose mills. The user also has to specify the "zero point", i.e. the object coordinates for which the machine's work coordinates will be set 0.

1.2 Machine coordinates
After a tool path is designed, the machine mapping then converts this object‑space orientation into actual machine axes (X, Y, Z, A, B). To follow the discussion just above: on a 4‑axis machine, changing phi while keeping (x1, x2, x3) fixed causes coordinated motion of A and Y so that the tool centre remains on the same point of the object while the tool axis rotates. Obviously, the mapping from object coordinates to machine coordinates depends on the machine configuration.

2. Machine Configurations
The CAM suite supports three machine setups:
- 3‑axis machine, where object axes map directly to machine axes.
- 4‑axis machine with A parallel to X
- 4‑axis machine with A parallel to Z
The user selects the machine type when creating a CBT_MillingMachine object.

2.1 Swivel angle B
The swivel angle theta is mapped to machine axis B.
In the EMCO/Eding setup, the mapping is:
```B = 90 * (pi/2 - theta)```
This is purely conventional and may differ on other machines.

3. CAM Structure: MillPath, Layers, Traces
All toolpath design happens in object coordinates.

3.1 MillPath (CBT_MillPath)
A MillPath - in object coordinates - represents a complete machining operation. It consists of:
- one or more layers
- each layer containing one or more traces

3.2 Layers (CBT_Layer)
A layer typically corresponds to a number of passes at a given cutting depth.
Typical examples:
- roughing passes at multiple Z levels
- finishing passes at final depth
- clearance moves above the part

3.3 Traces (CBT_Trace)
A trace represents a single motion of the tool along an aray of points. Various tracetypes are supported:
- rapid move
- slow cut (often useful for a first cut in ball nose work, because this cut is heavier than subsequent ones) 
- cut
- lead‑in / lead‑out
- The CBT_TraceTypes enumeration gives the full set.

4. Tools
Tools are defined in CBT_Tools. Two types are supported:
- Flat endmill, where the machine controls the tip of the tool and tool length refers to the physical tip
- Ball‑nose endmill, where the machine controls the ball centre. Here, the software uses an effective tool length which equals the measured length minus the radius of the ball. 

5. Mapping to Machine Coordinates
Once a MillPath is defined, the user creates a CBT_MillingMachine object. The machine:

- maps object coordinates to machine coordinates (X, Y, Z, A, B)
- takes care of making machine coordinates relative to the object's zero-point - which maps to the work origin.
- applies feeds according to the tracetypes
- converts the millpath into G‑code
- writes the G‑code to a .cnc file

5.1 Subroutine generation
It is often convenient to generate G‑code as a subroutine.
This allows the user to embed the generated path into their own program.

The CAM suite supports exporting:
```
SUB <name>
  ... G-code ...
ENDSUB
This SUB syntax is specific to Eding CNC, but can of course easily be edited
```
6. Application to gear milling
The gear milling application (CBT_GearMilling) is a recent extension using this CAM suite. It is described in a different document.

