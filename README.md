# Cycloidal Gear Milling Toolkit (MATLAB)

A complete open-source workflow for generating cycloidal gears, exporting geometry, and producing CNC G-code.

## Overview

This repository provides a full MATLAB implementation of cycloidal gear geometry, offset-curve milling, G-code generation, and Fusion-friendly exports. It is designed for:

- horology and clockmaking
- CNC machining of cycloidal wheels and pinions
- computational geometry exploration
- educational demonstrations
- open-source engineering workflows

The codebase is modular, mathematically rigorous, and structured for clarity and extensibility.

**The scripts in the scripts folder represents the user-interface. With them the user can create gear geometry, exports (CSV, OBJ), and create G-code files (CNC). The scrpits folder also contains a few utility scripts that can help design.**

## Repository Structure

```
cycloidal-gear-milling/
│
├── geometry/
│   ├── CBT_CycloidGear.m
│   └── CBT_Meshing.m
│
├── milling/
│   ├── CBT_GearMilling.m
│   ├── CBT_MillPath.m
│   ├── CBT_Layer.m
│   ├── CBT_Trace.m
│   ├── CBT_Tool.m
│   ├── CBT_ToolTypes.m
│   ├── CBT_TraceTypes.m
│   └── CBT_Feeds.m
│
├── scripts/
│   ├── CycloidGearMilling.m
│   ├── CycloidGearToCSVAndOBJ.m
│   └── PinionAndWheelSet.m
│
├── examples/
│   ├── FilletRadiusFunctionOfHd.m
│   ├── Optimise3StageGearTrain.m
│   └── Optimise4StageGearTrain.m
│
├── output/
│   ├── cnc/
│   ├── csv/
│   └── obj/
│
└── docs/

```

## Quick Start

1. Clone or download the repository.
2. Open MATLAB.
3. Run a production script from the scripts folder.
4. Generate geometry, exports, or G-code depending on your workflow.

### Generate a gear (CSV + OBJ)

- scripts/CycloidGearToCSVAndOBJ.m

### Generate CNC G-code

- scripts/CycloidGearMilling.m

## Core Concepts

### Cycloidal Geometry

Implemented in CBT_CycloidGear:

- epicycloid addendum
- hypocycloid dedendum
- fillet construction
- offset curves for milling
- full wheel and gap generation
- OBJ mesh export

### Milling Workflow

Implemented in CBT_GearMilling:

- finishing offset curves
- roughing curves with rest machining
- adaptive sampling
- mirrored tooth gaps
- multi-layer mill paths
- G-code subroutines and circular pattern

### Exports

The toolkit supports:

- CSV
- OBJ
- CNC G-code

## Production Scripts

- CycloidGearMilling.m
- CycloidGearToCSVAndOBJ.m
- PinionAndWheelSet.m
- FilletRadiusFunctionOfHd.m
- Optimise3StageGearTrain.m
- Optimise4StageGearTrain.m

## Examples

- To follow

## Dependencies

Pure MATLAB. No toolboxes required.

## License

MIT recommended.

## Contributing

Contributions are welcome.
