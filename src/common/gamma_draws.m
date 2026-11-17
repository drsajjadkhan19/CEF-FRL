function g = gamma_draws(n, shape)
% GAMMA_DRAWS  Marsaglia and Tsang gamma sampler for any positive shape.
g = zeros(1, n);
for i = 1:n
    a = shape; boost = 1;
    if a < 1
        u = rand(); boost = u ^ (1 / a); a = a + 1;
    end
    dd = a - 1 / 3;
    c = 1 / sqrt(9 * dd);
    while true
        x = randn();
        v = (1 + c * x) ^ 3;
        if v <= 0, continue; end
        u = rand();
        if log(u) < 0.5 * x ^ 2 + dd - dd * v + dd * log(v)
            g(i) = dd * v * boost; break;
        end
    end
end
end
