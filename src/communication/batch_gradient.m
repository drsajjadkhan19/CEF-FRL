function grad = batch_gradient(F, rows, theta, thetaTarget, noiseStd)
% BATCH_GRADIENT  Vectorised local gradient for every client at once.
%
% The batch of trace rows is shared across the fleet, so each feature
% plane contributes a batch by clients matrix and the squared loss
% gradient reduces to elementwise products and a column mean. This is
% mathematically identical to looping over clients.
d = numel(F);
B = numel(rows);
K = size(F{1}, 2);
if size(thetaTarget, 2) == 1
    thetaTarget = repmat(thetaTarget, 1, K);
end
pred = zeros(B, K);
truth = zeros(B, K);
slice = cell(1, d);
for f = 1:d
    slice{f} = F{f}(rows, :);
    pred = pred + slice{f} .* repmat(theta(f, :), B, 1);
    truth = truth + slice{f} .* repmat(thetaTarget(f, :), B, 1);
end
if isscalar(noiseStd)
    noiseStd = noiseStd * ones(1, K);
end
truth = truth + repmat(noiseStd, B, 1) .* randn(B, K);
residual = pred - truth;
grad = zeros(d, K);
for f = 1:d
    grad(f, :) = sum(slice{f} .* residual, 1) / B;
end
end
