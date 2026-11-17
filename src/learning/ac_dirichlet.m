function Z = ac_dirichlet(K, n, alpha)
% AC_DIRICHLET  K rows drawn from a symmetric Dirichlet(alpha) over n bins.
G = zeros(K, n);
for i = 1:K
    for j = 1:n
        G(i, j) = ac_gamma(alpha);
    end
end
Z = G ./ sum(G, 2);
Z = max(Z, 1e-3); Z = Z ./ sum(Z, 2);
end

function x = ac_gamma(a)
% Marsaglia and Tsang, with the boost for a < 1.
if a < 1
    x = ac_gamma(a + 1) * rand()^(1 / a); return;
end
d = a - 1/3; cc = 1 / sqrt(9 * d);
while true
    z = randn(); v = (1 + cc * z)^3;
    if v > 0 && log(rand()) < 0.5 * z^2 + d - d * v + d * log(v)
        x = d * v; return;
    end
end
end
