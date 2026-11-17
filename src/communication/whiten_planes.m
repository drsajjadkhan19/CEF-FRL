function W = whiten_planes(planes)
% WHITEN_PLANES  Whiten feature planes so the second moment is the identity.
%
% Two telemetry features are strongly collinear by construction, since
% spectral efficiency is a monotone function of the ratio and the blockage
% indicator correlates with both. Without preconditioning the Hessian of
% the local objective is near singular and the contraction diagnostic
% would reflect the conditioning of the features instead of the
% aggregator.
d = numel(planes);
N = numel(planes{1});
X = zeros(N, d);
for f = 1:d
    X(:, f) = planes{f}(:);
end
M = (X' * X) / N + 1e-9 * eye(d);
[V, D] = eig(M);
dv = max(diag(D), 1e-12);
Wm = V * diag(1 ./ sqrt(dv)) * V';
W = cell(1, d);
for f = 1:d
    acc = zeros(size(planes{1}));
    for g = 1:d
        acc = acc + planes{g} * Wm(g, f);
    end
    W{f} = acc;
end
end
