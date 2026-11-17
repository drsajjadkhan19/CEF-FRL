function runs = blockage_run_lengths(blocked)
% BLOCKAGE_RUN_LENGTHS  Lengths of consecutive blocked intervals, in frames.
runs = [];
[T, K] = size(blocked);
for k = 1:K
    n = 0;
    for t = 1:T
        if blocked(t, k) > 0.5
            n = n + 1;
        elseif n > 0
            runs(end+1) = n; %#ok<AGROW>
            n = 0;
        end
    end
    if n > 0
        runs(end+1) = n; %#ok<AGROW>
    end
end
if isempty(runs)
    runs = 0;
end
end
