function [theta, opt] = adam_step(theta, g, opt, lr)
% ADAM_STEP  One Adam update with global gradient-norm clipping at 1.
gn = norm(g);
if gn > 1, g = g / gn; end
b1 = 0.9; b2 = 0.999;
opt.m = b1 * opt.m + (1 - b1) * g;
opt.v = b2 * opt.v + (1 - b2) * g.^2;
opt.k = opt.k + 1;
mh = opt.m / (1 - b1^opt.k);
vh = opt.v / (1 - b2^opt.k);
theta = theta - lr * mh ./ (sqrt(vh) + 1e-8);
end
