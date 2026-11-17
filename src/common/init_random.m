function init_random(seed)
% INIT_RANDOM  Deterministic seeding of the random number generator.
try
    rng(seed, 'twister');
catch
    rand('state', seed);   %#ok<RAND>
    randn('state', seed);  %#ok<RAND>
end
end
