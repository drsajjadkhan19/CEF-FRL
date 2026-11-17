function init_substream(masterSeed, label)
% INIT_SUBSTREAM  Seed the generator from a stable hash of a label.
%
% Deriving one stream per physical process keeps the streams decoupled, so
% changing the frame count does not perturb, for instance, the Dirichlet
% partition, and a single-parameter ablation stays comparable against its
% baseline.
h = 0;
for i = 1:numel(label)
    h = mod(h * 131 + double(label(i)), 2^31 - 1);
end
init_random(mod(masterSeed + h, 2^31 - 1));
end
