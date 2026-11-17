function [m, h] = ci95(Y)
% CI95  Mean and half-width of the 95% confidence interval over runs.
%
%   [m, h] = ci95(Y) treats every row of Y as one independent run and
%   returns the column means and the Student-t half-widths. A vector is
%   treated as one value per run.
if isvector(Y), Y = Y(:); end
n = size(Y, 1);
m = mean(Y, 1);
if n < 2, h = zeros(size(m)); return; end
tq = [12.71 4.30 3.18 2.78 2.57 2.45 2.36 2.31 2.26 2.23 2.20 2.18 2.16 2.14 2.13 2.12 2.11 2.10 2.09];
if n - 1 <= numel(tq), t = tq(n - 1); else, t = 1.96; end
h = t * std(Y, 0, 1) / sqrt(n);
end
