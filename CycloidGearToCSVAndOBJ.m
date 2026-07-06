%% CycloidGearToCSVAndOBJ
% Export a cycloidal gear as CSV (Fusion-friendly) and OBJ (mesh).
% Uses self-locating paths so it works regardless of MATLAB's working directory.

clear

%% Self-locating repository root
thisFile   = matlab.desktop.editor.getActiveFilename;
repoRoot   = fileparts(thisFile);

folderCSV  = fullfile(repoRoot, "..", "output", "csv");
folderOBJ  = fullfile(repoRoot, "..", "output", "obj");

%% Gear definition
gear = CBT_CycloidGear.create(1.2, 27, 2, 2, 1.0, 1.05);

%% CSV export
csvName = "GearToCSV.csv";
csvPath = fullfile(folderCSV, csvName);

gear.exportCSV(csvPath);

%% OBJ export
objName = "GearToOBJ.obj";
objPath = fullfile(folderOBJ, objName);

thickness = 1.0;
alphaMax  = 3.3;
tol       = 1e-2;

gear.exportOBJ(objPath, thickness, alphaMax, tol);
