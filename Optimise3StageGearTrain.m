clear

TARGET  = 24;
PINIONS = [7 8 9 10];
Wrange  = 12:120;

solutions = [];

[P1, P2, P3] = ndgrid(PINIONS, PINIONS, PINIONS);

for k = 1:numel(P1)
    p1 = P1(k); p2 = P2(k); p3 = P3(k);

    RHS = TARGET * p1 * p2 * p3;

    for w1 = Wrange
        if mod(RHS, w1) ~= 0, continue; end
        R2 = RHS / w1;

        for w2 = Wrange
            if mod(R2, w2) ~= 0, continue; end
            w3 = R2 / w2;

            solutions(end+1, :) = [p1 w1 p2 w2 p3 w3];
        end
    end
end
