function s = smooth_series(x, window)
% SMOOTH_SERIES  Centred moving average without toolbox dependencies.
x = x(:);
n = numel(x);
s = zeros(n, 1);
half = floor(window / 2);
for i = 1:n
    lo = max(1, i - half);
    hi = min(n, i + half);
    s(i) = mean(x(lo:hi));
end
end
