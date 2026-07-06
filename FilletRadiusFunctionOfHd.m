module = 1.2;
toothCount = linspace(10, 40, 25);
hD = [1.25, 1.15, 1.05];
cols = lines(3);

rhoF    = [];
radiusF = [];
radiusO = [];
txt     = strings(1, numel(hD));
radiusFMin = zeros(1, numel(hD));

for k = 1:numel(hD)
    txt(k) = "hD =" + hD(k);
    for i = 1:numel(toothCount)
        gear = CBT_CycloidGear.create(module, toothCount(i), 2, 2, 1.0, hD(k));
        rhoF(k, i)    = gear.rhoFillet;
        radiusF(k, i) = gear.radiusFillet;
        radiusO(k, i) = gear.radiusOuter;
    end
    radiusFMin(k) = min(radiusF(k, :));
end

figure();
title("Fillet radius as a function of nTooth and hD");
subtitle("module:  " + module);
hold on;
for k = 1:numel(hD)
    plot(toothCount, radiusF(k, :));
end
legend(txt);
radiusFMin

figure();
title("Diameter as a function of nTooth and hD");
subtitle("module:  " + module);
hold on;
plot(toothCount, 2 * radiusO(end, :));
