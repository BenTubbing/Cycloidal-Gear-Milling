clear()

%NOTE: Fusion will not digest CSV or OBJ with "too many" points. Limit
%tolerance to not < 1e-2, which is the default for the full pinion and wheel;

%Fusion will be slow

%spacing = 25          %Pinion / wheel spacing, optional instead of spêcifying module
nP = 9;                %Pinion tooth count
nW = 40;               %Wheel tooth count
ratio = nW / nP      %Gear ratio

%module = 2 * spacing / nP / (1 + ratio) %Or specify module explicity
module = 1.2
tol = 1e-2;           %Tolerance for adaptive curve generation
nptsOuter = 10;       %Number of points to generate on outer half arc
rotation = 0.5;       %As a function of a single tooth rotation of pinion
%% Create pinion and wheel, calculate spacing, get the gap curves

pinion = CBT_CycloidGear.create(module, nP, 2, 2, 1.0, 1.05)
wheel = CBT_CycloidGear.createFromPinion(pinion, nW, 1.0, 1.05)

spacing = pinion.radiusPitch * (1.0 + ratio)

xyGap = pinion.getFullGap();
plot(xyGap(1, :), xyGap(2, :), "-b");

xyPinion = pinion.getFullGear();
xyPinion = CBT_CycloidGear.rotate(xyPinion, rotation * 2 * pi / pinion.toothCount);
plot(xyPinion(1, :), xyPinion(2, :), "-b");
hold on
xyWheel = wheel.getFullGear();
%Rotate, and after that translate into place
xyWheel = CBT_CycloidGear.rotate(xyWheel, pi / wheel.toothCount);
xyWheel = CBT_CycloidGear.rotate(xyWheel, -rotation * 2 * pi / wheel.toothCount);
xyWheel = xyWheel + [spacing; 0.0];
plot(xyWheel(1, :), xyWheel(2, :), "-r");

zP = zeros(1, size(xyPinion, 2));
xyzP = [xyPinion;zP];

zW = zeros(1, size(xyWheel, 2));
xyzW = [xyWheel;zW];

%OLD: write to fixed location, absolute path
% folder = "C:\Users\Bjdt\OneDrive\Projects\202601_LavetMotorClock\Gearing\MatlabOut";
% filename = "FullPinion.csv";
% filePath = folder + "\" + filename;
% CBT_CycloidGear.writeCSV(filePath, xyzP);
% filename = "FullWheel.csv";
% filePath = folder + "\" + filename;
% CBT_CycloidGear.writeCSV(filePath, xyzW);
%

thisFile = matlab.desktop.editor.getActiveFilename;
repoRoot = fileparts(thisFile);
folderForOutput = fullfile(repoRoot, "..", "output", "csv");
csvPath = fullfile(folderForOutput, "FullPinion_CSV.csv");
CBT_CycloidGear.writeCSV(csvPath, xyzP);
csvPath = fullfile(folderForOutput, "FullWheel_CSV.csv");
CBT_CycloidGear.writeCSV(csvPath, xyzW);