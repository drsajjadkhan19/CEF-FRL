function [env, rFast, rSlow, active] = nav_step(c, env, a)
% NAV_STEP  Advance every unfinished episode by one control step.
%
% Returns the fast reward (progress, step cost, goal and collision terms)
% and the slow reward (actuation energy and mission completion) of the
% dual timescale decomposition. active marks the episodes that were still
% running when the action was applied.
active = ~env.done;
B = env.B;
v = c.vMax * c.actions(a, 1);
w = c.wMax * c.actions(a, 2);
v(~active) = 0; w(~active) = 0;

env.head = env.head + w * c.dt;
env.head = mod(env.head + pi, 2 * pi) - pi;
env.pos = env.pos + [v .* cos(env.head), v .* sin(env.head)] * c.dt;
env.steps = env.steps + double(active);

newDist = sqrt(sum((env.goal - env.pos).^2, 2));
progress = env.dist - newDist;
env.dist = newDist;

% collisions with obstacles or walls
ox = env.obsC(:, :, 1) - env.pos(:, 1);
oy = env.obsC(:, :, 2) - env.pos(:, 2);
gap = sqrt(ox.^2 + oy.^2) - env.obsR - c.robotRadius;
gap(env.obsR <= 0) = inf;
hitObs = any(gap < 0, 2);
hitWall = any(env.pos < c.robotRadius, 2) | any(env.pos > c.arena - c.robotRadius, 2);
collide = active & (hitObs | hitWall);
reach = active & ~collide & (newDist < c.goalRadius);
timeout = active & ~collide & ~reach & (env.steps >= c.maxSteps);

rFast = c.progressGain * progress - c.stepCost;
rFast = rFast + c.goalBonus * reach - c.collisionPenalty * collide;
energy = c.energyGainV * (v / c.vMax).^2 + c.energyGainW * (abs(w) / c.wMax).^2;
rSlow = -energy + c.slowGoalBonus * reach;
rFast(~active) = 0; rSlow(~active) = 0;

env.success = env.success | reach;
env.collision = env.collision | collide;
env.done = env.done | collide | reach | timeout;
end
