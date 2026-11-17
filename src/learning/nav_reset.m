function env = nav_reset(c, zoneProbs)
% NAV_RESET  Start a batch of navigation episodes.
%
% zoneProbs is B by 4. Row b gives the probability that an obstacle or
% the goal of episode b falls in each quadrant of the arena, which is how
% the non-IID client distributions enter the task.
B = size(zoneProbs, 1);
A = c.arena;
env.B = B;
env.pos = zeros(B, 2);
env.head = zeros(B, 1);
env.goal = zeros(B, 2);
env.obsC = zeros(B, c.obsMax, 2);
env.obsR = zeros(B, c.obsMax);   % zero radius means no obstacle
env.done = false(B, 1);
env.success = false(B, 1);
env.collision = false(B, 1);
env.steps = zeros(B, 1);
zoneLo = [0 0; A/2 0; 0 A/2; A/2 A/2];

for b = 1:B
    cdf = cumsum(zoneProbs(b, :));
    nObs = randi([3 c.obsMax]);
    for j = 1:nObs
        z = find(rand() <= cdf, 1, 'first');
        r = c.obsRadius(1) + (c.obsRadius(2) - c.obsRadius(1)) * rand();
        ctr = zoneLo(z, :) + r + (A/2 - 2 * r) * rand(1, 2);
        env.obsC(b, j, :) = reshape(ctr, 1, 1, 2);
        env.obsR(b, j) = r;
    end
    % goal in a zone drawn from the same client distribution
    for tries = 1:200
        z = find(rand() <= cdf, 1, 'first');
        g = zoneLo(z, :) + 0.3 + (A/2 - 0.6) * rand(1, 2);
        if clearance(env, b, g) > c.goalRadius + 0.05, break; end
    end
    env.goal(b, :) = g;
    % start anywhere free and far enough from the goal
    for tries = 1:500
        p = 0.3 + (A - 0.6) * rand(1, 2);
        if clearance(env, b, p) > c.robotRadius + 0.10 && norm(p - g) >= 1.5
            break;
        end
    end
    env.pos(b, :) = p;
    env.head(b) = 2 * pi * rand() - pi;
end
env.dist = sqrt(sum((env.goal - env.pos).^2, 2));
end

function m = clearance(env, b, p)
r = env.obsR(b, :);
k = r > 0;
if ~any(k), m = inf; return; end
cx = env.obsC(b, k, 1); cy = env.obsC(b, k, 2);
m = min(sqrt((cx - p(1)).^2 + (cy - p(2)).^2) - r(k));
end
