# Cycloidal-Gear-Milling
- MATLAB scripts for the generation of true cycloidal gears: G-code for milling and csv / obj exports

The repository provides:
- A set of classes for the generation of true epi / hypo cycloidal gear wheel shapes.
    - Inputs include the module, toothcount, rolling ball radii, and addendum / dedendum heights
    - The gear classes calculate the epi and hypo branches of the tooth shape and insert a fillet at the dedendum to allow for milling
    - Other are CSV and / or OBJ files of a single tooth, which can be imported in tools like Fusion 360 for manipulation and subsequent 3D printing
- A set of CAD classes to support production of machine-ready G-code for the milling of the designed gears
    - The CAD, in the simplest use case, provide G-code for vertical 3 axis milling
    - The CAD classes also support G-code generation for 4-axis milling with the A-axis parallel X or parallel Z   
