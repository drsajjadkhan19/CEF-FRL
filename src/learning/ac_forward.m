function [p, V, cache] = ac_forward(P, S)
% AC_FORWARD  Policy probabilities (nActions by N) and values (2 by N).
z1 = P.W1 * S + P.b1;  h1 = tanh(z1);
z2 = P.W2 * h1 + P.b2; h2 = tanh(z2);
logits = P.Wp * h2 + P.bp;
logits = logits - max(logits, [], 1);
e = exp(logits);
p = e ./ sum(e, 1);
V = P.Wv * h2 + P.bv;
cache.h1 = h1; cache.h2 = h2; cache.S = S;
end
