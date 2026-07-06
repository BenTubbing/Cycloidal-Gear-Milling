📘 Cycloidal Gear Milling Toolkit (MATLAB)
A complete, open‑source workflow for generating cycloidal gears, exporting geometry, and producing CNC G‑code.

🔧 Overview
This repository provides a full MATLAB implementation of cycloidal gear geometry, offset‑curve milling, G‑code generation, and Fusion‑friendly exports. It is designed for:

horology and clockmaking

CNC machining of cycloidal wheels and pinions

computational geometry exploration

educational demonstrations

open‑source engineering workflows

The codebase is modular, mathematically rigorous, and structured for clarity and extensibility.
´´´
🧱 Repository Structure
Code
cycloidal-gear-milling/
│
├── geometry/        # Core cycloid geometry + meshing
│   ├── CBT_CycloidGear.m
│   └── CBT_Meshing.m
│
├── milling/         # Milling paths, layers, traces, tools, feeds
│   ├── CBT_GearMilling.m
│   ├── CBT_MillPath.m
│   ├── CBT_Layer.m
│   ├── CBT_Trace.m
│   ├── CBT_Tool.m
│   ├── CBT_ToolTypes.m
│   ├── CBT_TraceTypes.m
│   └── CBT_Feeds.m
│
├── scripts/         # Production scripts (G-code, CSV, OBJ)
│   ├── CycloidGearMilling.m
│   ├── CycloidGearToCSVAndOBJ.m
│   └── PinionAndWheelSet.m
│
├── examples/        # Illustrative scripts
│   ├── FilletRadiusFunctionOfHd.m
│   ├── Optimise3StageGearTrain.m
│   └── Optimise4StageGearTrain.m
│
├── output/          # Export targets (created locally)
│   ├── cnc/
│   ├── csv/
│   └── obj/
│
└── docs/            # Extended documentation (to be added)
```

🚀 Quick Start
Clone or download the repository.

Open MATLAB.

Run a production script from /scripts — they are self‑locating and work regardless of MATLAB’s working directory.

Generate geometry, exports, or G‑code depending on your workflow.

Generate a gear (CSV + OBJ)
matlab
scripts/CycloidGearToCSVAndOBJ.m
Produces:

output/csv/<name>.csv

output/obj/<name>.obj

Generate CNC G‑code
matlab
scripts/CycloidGearMilling.m
Produces:

output/cnc/<name>_Finishing.cnc

output/cnc/<name>_Roughing1.cnc

output/cnc/<name>_Roughing2.cnc

⚙️ Core Concepts
Cycloidal Geometry
Implemented in CBT_CycloidGear:

epicycloid addendum

hypocycloid dedendum

fillet construction

offset curves for milling

full wheel and gap generation

OBJ mesh export

See geometry documentation.

Milling Workflow
Implemented in CBT_GearMilling:

finishing offset curves

roughing curves with rest machining

adaptive sampling

mirrored tooth gaps

multi‑layer mill paths

G‑code subroutines + circular pattern

See milling documentation.

Exports
The toolkit supports:

CSV (Fusion 360 knife‑body workflow)

OBJ (mesh export)

CNC G‑code (3‑axis milling)

See export documentation.

📂 Production Scripts
CycloidGearMilling.m
Generates roughing + finishing G‑code for CNC machining.

CycloidGearToCSVAndOBJ.m
Exports a single gear as CSV and OBJ.

PinionAndWheelSet.m
Generates a matched pinion + wheel pair, plots them, and exports CSV.

📚 Examples
FilletRadiusFunctionOfHd.m — fillet radius vs dedendum height

Optimise3StageGearTrain.m — brute‑force 3‑stage ratio search

Optimise4StageGearTrain.m — canonicalised 4‑stage gear‑train search

See examples documentation.

🧩 Dependencies
Pure MATLAB — no toolboxes required.

📝 License
MIT recommended (permissive, simple, widely used).

🤝 Contributing
Contributions are welcome:

new examples

documentation improvements

additional milling strategies

Fusion/FreeCAD plugins

Python ports

Open an issue or submit a pull request.

📬 Contact
For questions or collaboration, open an issue or start a discussion.
