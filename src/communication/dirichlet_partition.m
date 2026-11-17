function P = dirichlet_partition(K, C, alpha)
% DIRICHLET_PARTITION  Label partition from normalised gamma variates.
P = zeros(K, C);
for k = 1:K
    g = gamma_draws(C, alpha);
    if sum(g) <= 0
        g = ones(1, C);
    end
    P(k, :) = g / sum(g);
end
end
