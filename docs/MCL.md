# The Milling Classes (CAM Overview)

The code in the milling directory implements a general‑purpose CAM suite for 3‑axis and 4‑axis CNC milling. It was originally developed for contour‑milling complex 3D surfaces such as centrifugal compressor wheels. It supports:
- X, Y, Z linear axes
- A rotary axis
an optional fixed swivel angle B (for machines with a tilting head)

The implementation was written for an EMCO F1CNC equipped with an Eding CNC controller. The gear‑milling application uses only part of the available functionality; the gear‑specific workflow is described in a separate document.

1. Coordinate Systems
The CAM suite distinguishes between object coordinates and machine coordinates.

1.1 Object coordinates
When designing a toolpath, the CAM system works entirely in object coordinates. This means that every tool position is described by two things:
- Where the tool is — the Cartesian point (x1, x2, x3)
- How the tool is oriented — the direction of the tool axis in object space

This tool orientation is expressed using two angles:
- theta — the tilt of the tool axis relative to the object’s vertical direction
- phi — the rotation of the tool axis around that vertical direction

To repeat: these angles do not (directly) represent a rotation of the object. Instead, they describe the direction of the tool axis as seen by an observer on the object. For illustration: as one would see in 5‑axis machining videos: the tool stays at the same point on the surface but changes orientation. This logic is ideal for ball nose contouring, where x1, x2, x3 are the ball centre position. By changing phi, we can change tool orientation but the tool keeps touching the object at precisely the same spot.

It is important to point out that, given the complex 3D shapes it was designed for, the **CAM does not take care of tool compensation**. Instead, the user is expected to calculate the coordinates of the mill centre. For milling flat shapes with a flat end mill perpendicular, the user therefore has to calculate the normal vector for each object point. Equivalent to G41 or G42. For contouring 3D surfaces with variable tool orientation, the user has to calculate the normal vectors on the surface, multiply by ball radius, and apply the offset to go from object position to mill position.

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

