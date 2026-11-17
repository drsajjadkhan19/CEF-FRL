function s = kl_to_uniform(P)
% KL_TO_UNIFORM  Normalised divergence of each row from the uniform reference.
C = size(P, 2);
Q = max(P, 1e-12);
s = sum(Q .* log(Q * C), 2)' / log(C);
end
