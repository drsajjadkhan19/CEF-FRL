function [g, loss] = ac_grad(theta, c, S, act, adv, Gf, Gs, trainSlow)
% AC_GRAD  Gradient of the actor-critic loss by explicit backpropagation.
%
% Loss = -mean(log pi(a|s) * adv) - entropyCoef * mean(H)
%        + valueCoef/2 * mean((Vf - Gf)^2) + valueCoef/2 * mean((Vs - Gs)^2)
% The slow head term is present only when trainSlow is true, which is how
% the slow value head is updated at a lower frequency than the fast head.
% Pass Gs = [] to train the fast head alone (single-timescale ablation).
P = ac_unpack(theta, c);
N = size(S, 2);
[p, V, ca] = ac_forward(P, S);
idx = sub2ind(size(p), act(:)', 1:N);
logp = log(max(p, 1e-12));
H = -sum(p .* logp, 1);

onehot = zeros(size(p)); onehot(idx) = 1;
dlogits = (p - onehot) .* adv(:)' / N;
dlogits = dlogits + c.entropyCoef * p .* (logp + H) / N;

dV = zeros(2, N);
dV(1, :) = c.valueCoef * (V(1, :) - Gf(:)') / N;
lossV = 0.5 * mean((V(1, :) - Gf(:)').^2);
if trainSlow && ~isempty(Gs)
    dV(2, :) = c.valueCoef * (V(2, :) - Gs(:)') / N;
    lossV = lossV + 0.5 * mean((V(2, :) - Gs(:)').^2);
end

dWp = dlogits * ca.h2'; dbp = sum(dlogits, 2);
dWv = dV * ca.h2';      dbv = sum(dV, 2);
dh2 = P.Wp' * dlogits + P.Wv' * dV;
dz2 = dh2 .* (1 - ca.h2.^2);
dW2 = dz2 * ca.h1'; db2 = sum(dz2, 2);
dh1 = P.W2' * dz2;
dz1 = dh1 .* (1 - ca.h1.^2);
dW1 = dz1 * ca.S'; db1 = sum(dz1, 2);

g = [dW1(:); db1; dW2(:); db2; dWp(:); dbp; dWv(:); dbv];
loss = -mean(logp(idx) .* adv(:)') - c.entropyCoef * mean(H) + c.valueCoef * lossV;
end
