%% Cycloid gear milling: prepare G-code
% Production script for generating roughing + finishing G-code
% using CBT_CycloidGear and CBT_GearMilling.
%
% Output folders:
%   ../output/cnc/   → G-code files
%   ../output/csv/   → optional CSV exports
%   ../output/obj/   → optional OBJ exports

clear

%% Self-locating repository root
thisFile   = matlab.desktop.editor.getActiveFilename;
repoRoot   = fileparts(thisFile);

folderCNC  = fullfile(repoRoot, "..", "output", "cnc");
folderCSV  = fullfile(repoRoot, "..", "output", "csv");
folderOBJ  = fullfile(repoRoot, "..", "output", "obj");

%% Gear definition: USER PLEASE REPLACE filenameStub WITH A CONVENIENT NAME
filenameStub = "20260703_W2";
gear = CBT_CycloidGear.create(1.2, 27, 2.0, 2.0, 1.0, 1.05);

%% Milling object
safeR   = gear.radiusOuter + 5;
safeZ   = 20;
milling = CBT_GearMilling.create(gear, safeR, safeZ);

%% Common parameters
xClearance = 1.5;
zCut       = -2.0;
zRetract   = 3;
plotRange  = gear.radiusOuter * 1.5;
arng       = [0, plotRange, -plotRange/2, plotRange/2, -plotRange/2, plotRange/2];

%% Finishing millpath
tolerance    = 1.0e-3;
millDiameter = 1.0;
stockToLeave = 0.0;

milling.createFinishingMillCurve(tolerance, millDiameter, stockToLeave, xClearance);
millPathFinishing = milling.createFinishingMillPath(zCut, zRetract);

figure();
millPathFinishing.plotMillPath();
title("Finishing millpath");
axis(arng); axis square;

%% Roughing millpath 1
millDiameter = 2.0;
stockToLeave = 0.05;
cutDepth     = linspace(0.0, 1.6, 6);

milling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance, cutDepth);
millPathRoughing1 = milling.createRoughingMillPath(zCut, zRetract);

figure();
millPathRoughing1.plotMillPath();
title("First roughing millpath");
axis(arng); axis square;

%% Roughing millpath 2 (rest machining)
millDiameter  = 1.0;
stockToLeave  = 0.05;
cutIncr       = 0.15;
firstCutDepth = 1.6;

cutDepthMax = milling.getMaxRoughingCutDepth(millDiameter, stockToLeave);
cutCount    = floor(cutDepthMax / cutIncr + 0.5);
cutDepth    = linspace(firstCutDepth, cutDepthMax, cutCount);

milling.createRoughingMillCurve(tolerance, millDiameter, stockToLeave, xClearance, cutDepth);
millPathRoughing2 = milling.createRoughingMillPath(zCut, zRetract);

figure();
millPathRoughing2.plotMillPath();
title("Second roughing millpath");
axis(arng); axis square;

%% Machine and tools
machine = CBT_MillingMachine.create3Axis();

toolR1 = CBT_Tool.create(88, CBT_ToolTypes.endmill, 2.0, 135.00);
toolR2 = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);
toolF  = CBT_Tool.create(89, CBT_ToolTypes.endmill, 1.0, 135.00);

%% G-code: finishing
machine.setTool(toolF);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathFinishing);

name        = filenameStub + "_Finishing";
gCode       = machine.getMillPathGCodeAsSub(name);
gCodePattern = milling.getGCodeForPattern(name);

fid = fopen(fullfile(folderCNC, name + ".cnc"), 'w');
fprintf(fid, '%s', gCodePattern + gCode);
fclose(fid);

machine.resetMachine();

%% G-code: roughing 1
machine.setTool(toolR1);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathRoughing1);

name        = filenameStub + "_Roughing1";
gCode       = machine.getMillPathGCodeAsSub(name);
gCodePattern = milling.getGCodeForPattern(name);

fid = fopen(fullfile(folderCNC, name + ".cnc"), 'w');
fprintf(fid, '%s', gCodePattern + gCode);
fclose(fid);

machine.resetMachine();

%% G-code: roughing 2
machine.setTool(toolR2);
machine.setFeeds(10, 25, 15, 150, 25, 150, 150);
machine.setMillPath(millPathRoughing2);

name        = filenameStub + "_Roughing2";
gCode       = machine.getMillPathGCodeAsSub(name);
gCodePattern = milling.getGCodeForPattern(name);

fid = fopen(fullfile(folderCNC, name + ".cnc"), 'w');
fprintf(fid, '%s', gCodePattern + gCode);
fclose(fid);

machine.resetMachine();

%% Optional CSV + OBJ export. TO USE PLEASE SET doExport = true
doExport = false;
if doExport
    csvPath = fullfile(folderCSV, filenameStub + "_CSV.csv");
    milling.cycloidGear.exportCSV(csvPath);

    objPath = fullfile(folderOBJ, filenameStub + "_OBJ.obj");
    thickness = 1.5;
    milling.cycloidGear.exportOBJ(objPath, thickness);
end
