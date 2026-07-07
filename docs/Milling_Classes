#The Milling Classes

The code in the milling section represents a CAM suite for 3-axes or 4-axes milling in 3 dimensions. It was written some years ago for contour-milling of complex surfaces like centrifugal compressor wheels. In addition to the X, Y, Z, A coordinates, it can handle a fixed swivel angle B, i.e. for machines with a swivel head. It was written for an EMCO F1CNC with an Eding CNC controller.

The application here to milling of gear wheels is relatively straightforward and requires only part of the functionalities. It is detailed in a separate document.

We distinguish between:
Object coordinates: 
- cartesian x1, x2, x3 for a position on the object
- phi and theta polar angles (in radians) defining the orientation of the mill
Machine coordinates:
- X, Y, Z, A, B
As we have a swivel machine, theta will be a fixed angle and it maps to the swivel angle B. Phi maps to the 4'th axis angle A.
The implementation is such that, on a four axis machine with A parallel X, if one changes phi for constand x1, x2, x3, both the A and Y axes move so that the mill stays in the same place on the object, but changes orientation. This behaviour is ideal for contouring complex 3D surfaces with a ball-nose mill, where the machine coordinates essentially refer to the centre of the ball. 

The design of a millpath (CBT_MillPath class) takes place entirely in object coordinates. The MillPath consists of one or more layers (CBT_Layer class) that correspond to cutting depths. Layers consist of one or more traces (CBT_Trace class) that corresponds to mill passes. And of course one can set trace types (traverse, cut, lead-in etcetera) and their feeds (CBT_TraceTypes, CBT_Feeds classes).

Finally there are the tools (CBT_Tools class), limited to either a flat end mill or a ball nose. For a flat end mill, things are simple, the machine controls the tip and the tool length equals the measured physical length. For a ball nose, the machine controls the ball centre, and the software uses the effective length which equals the measured length minus the ball radius. 

Once a MillPath has been designed one creates the machine (CBT_MillingMachine). The machine implements the mapping from object to XYZA (for a fixed swivel). The mapping depends on the machine setup, of which three are supported:
- Straightforward 3 axes, machine coordinate orientation corresponds to object coordinate orientation
- 4 axes with A parallel X
- 4 axes with A parallel Z
The user chooses the type when creating the machine object.

Subsequently, after setting a tool and a set of feeds, the user passes the millpath to the machine. And the machine can create the G-code and write it to a file.

It is often advantageous to generate the G-code in the form of a subroutine, which the user can call from within his / her own G-code. This is supported.

