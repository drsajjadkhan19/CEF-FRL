function S = nav_observe(c, env)
% NAV_OBSERVE  State matrix, stateDim by B.
%
% Rows are the normalised goal distance, the sine and cosine of the
% bearing error, and five normalised ray ranges.
B = env.B;
d = env.goal - env.pos;
dist = sqrt(sum(d.^2, 2));
bearing = atan2(d(:, 2), d(:, 1)) - env.head;
S = zeros(c.stateDim, B);
S(1, :) = (dist / c.arena)';
S(2, :) = sin(bearing)';
S(3, :) = cos(bearing)';
nR = numel(c.rayAngles);
for i = 1:nR
    ang = env.head + c.rayAngles(i);
    ux = cos(ang); uy = sin(ang);
    % walls
    rng = c.rayRange * ones(B, 1);
    tx = inf(B, 1); ty = inf(B, 1);
    k = ux > 1e-9;  tx(k) = (c.arena - env.pos(k, 1)) ./ ux(k);
    k = ux < -1e-9; tx(k) = -env.pos(k, 1) ./ ux(k);
    k = uy > 1e-9;  ty(k) = (c.arena - env.pos(k, 2)) ./ uy(k);
    k = uy < -1e-9; ty(k) = -env.pos(k, 2) ./ uy(k);
    rng = min(rng, min(tx, ty));
    % obstacles
    ox = env.obsC(:, :, 1) - env.pos(:, 1);
    oy = env.obsC(:, :, 2) - env.pos(:, 2);
    proj = ox .* ux + oy .* uy;
    perp2 = ox.^2 + oy.^2 - proj.^2;
    R2 = env.obsR.^2;
    hit = (env.obsR > 0) & (proj > 0) & (perp2 < R2);
    t = proj - sqrt(max(R2 - perp2, 0));
    t(~hit) = inf;
    t = max(t, 0);
    rng = min(rng, min(t, [], 2));
    S(3 + i, :) = (rng / c.rayRange)';
end
end
