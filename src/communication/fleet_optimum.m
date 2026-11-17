function thetaOpt = fleet_optimum(F, thetaClient)
% FLEET_OPTIMUM  Closed form minimiser of the pooled federated objective.
%
% Clients observe different feature distributions, so the optimum of the
% sum of local objectives is a curvature weighted combination of the local
% optima and not their arithmetic mean; it is solved for exactly here.
d = numel(F);
[T, K] = size(F{1});
Msum = zeros(d, d);
b = zeros(d, 1);
for k = 1:K
    Phi = zeros(T, d);
    for f = 1:d
        Phi(:, f) = F{f}(:, k);
    end
    Mk = (Phi' * Phi) / T;
    Msum = Msum + Mk;
    b = b + Mk * thetaClient(:, k);
end
thetaOpt = Msum \ b;
end
