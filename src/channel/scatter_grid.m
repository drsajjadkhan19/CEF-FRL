function out = scatter_grid(vec, idx, T, K)
% SCATTER_GRID  Scatter a column vector into a frames by devices grid.
out = zeros(T, K);
out(idx) = vec;
end
