function [succ, ret] = ac_evaluate(theta, c, evalSet)
% AC_EVALUATE  Greedy global policy on a fixed fleet-wide evaluation set.
P = ac_unpack(theta, c);
env = evalSet;
retv = zeros(env.B, 1);
for t = 1:c.maxSteps
    s = nav_observe(c, env);
    p = ac_forward(P, s);
    [~, a] = max(p, [], 1);
    [env, rf, rs] = nav_step(c, env, a(:));
    retv = retv + rf + c.dtrdLambda * rs;
    if all(env.done), break; end
end
succ = mean(env.success);
ret = mean(retv);
end
