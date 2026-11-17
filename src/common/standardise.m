function z = standardise(x)
% STANDARDISE  Zero mean unit deviation scaling with a constant guard.
mu = mean(x(:));
sd = std(x(:));
if sd < 1e-12
    sd = 1;
end
z = (x - mu) / sd;
end
