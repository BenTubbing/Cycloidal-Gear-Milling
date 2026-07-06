clear

TARGET  = 120;
PINIONS = [9, 10];
Wrange  = 24:40;

solutions = [];

P = combos_with_repetition(PINIONS, 4);

for k = 1:size(P, 1)
    p1 = P(k, 1); p2 = P(k, 2); p3 = P(k, 3); p4 = P(k, 4);

    RHS = TARGET * p1 * p2 * p3 * p4;

    for w1 = Wrange
        if mod(RHS, w1) ~= 0, continue; end
        R2 = RHS / w1;
    
        for w2 = Wrange
            if mod(R2, w2) ~= 0, continue; end
            R3 = R2 / w2;
    
            for w3 = Wrange
                if mod(R3, w3) ~= 0, continue; end
                w4 = R3 / w3;
    
                if ~ismember(w4, Wrange), continue; end
    
                solutions(end+1, :) = [p1 w1 p2 w2 p3 w3 p4 w4];
            end
        end
    end
end

s = solutions;
check = s(:,2) .* s(:,4) .* s(:,6) .* s(:,8) ./ (s(:,1) .* s(:,3) .* s(:,5) .* s(:,7));

N     = size(solutions, 1);
canon = zeros(N, 8);

for i = 1:N
    row = solutions(i, :);

    stages = [row(1) row(2);
              row(3) row(4);
              row(5) row(6);
              row(7) row(8)];

    ratios = stages(:,2) ./ stages(:,1);
    [~, idx] = sort(ratios);

    stages_sorted = stages(idx, :);
    canon(i, :)   = stages_sorted(:).';
end

[canon_unique, ia] = unique(canon, 'rows');
solutions_unique = solutions(ia, :);

i = 1;

function C = combos_with_repetition(vals, k)
    if k == 1
        C = vals(:);
        return;
    end

    C = [];
    for i = 1:numel(vals)
        tails = combos_with_repetition(vals(i:end), k-1);
        C = [C; [vals(i) * ones(size(tails, 1), 1), tails]];
    end
end
