function [theta, opt, st] = ac_local_train(theta, c, zoneRow, opt, anchor, proxMu, dtrd)
% AC_LOCAL_TRAIN  Local actor-critic training on one client.
%
% Runs c.localEpisodes episodes from the client's own task distribution
% and applies one Adam step per episode. With dtrd true, the advantage is
% the sum of a fast advantage and lambda times a slow advantage, each with
% its own value head and discount, and the slow head is trained once every
% c.slowEvery local updates. With dtrd false the two rewards are summed
% into one scalar and only one value head is trained (ablation).
% anchor and proxMu add the FedProx proximal term when proxMu > 0.
E = c.localEpisodes;
st.ret = zeros(E, 1); st.succ = zeros(E, 1); st.loss = 0;
for e = 1:E
    env = nav_reset(c, zoneRow);
    Tm = c.maxSteps;
    S = zeros(c.stateDim, Tm); A = zeros(1, Tm);
    RF = zeros(1, Tm); RS = zeros(1, Tm);
    P = ac_unpack(theta, c);
    n = 0;
    for t = 1:Tm
        s = nav_observe(c, env);
        p = ac_forward(P, s);
        a = find(rand() <= cumsum(p), 1, 'first');
        if isempty(a), a = c.nActions; end
        [env, rf, rs] = nav_step(c, env, a);
        n = n + 1;
        S(:, n) = s; A(n) = a; RF(n) = rf; RS(n) = rs;
        if env.done, break; end
    end
    S = S(:, 1:n); A = A(1:n); RF = RF(1:n); RS = RS(1:n);
    st.ret(e) = sum(RF) + c.dtrdLambda * sum(RS);
    st.succ(e) = double(env.success);

    [~, V] = ac_forward(P, S);
    if dtrd
        Gf = disc(RF, c.gammaFast); Gs = disc(RS, c.gammaSlow);
        adv = (Gf - V(1, :)) + c.dtrdLambda * (Gs - V(2, :));
    else
        Gf = disc(RF + c.dtrdLambda * RS, c.gammaSlow); Gs = [];
        adv = Gf - V(1, :);
    end
    adv = (adv - mean(adv)) / (std(adv) + 1e-8);

    opt.t = opt.t + 1;
    trainSlow = dtrd && mod(opt.t, c.slowEvery) == 0;
    [g, l] = ac_grad(theta, c, S, A, adv, Gf, Gs, trainSlow);
    if proxMu > 0
        g = g + proxMu * (theta - anchor);
    end
    [theta, opt] = adam_step(theta, g, opt, c.lr);
    st.loss = st.loss + l / E;
end
st.meanRet = mean(st.ret);
st.succRate = mean(st.succ);
end

function G = disc(r, gamma)
G = zeros(size(r));
acc = 0;
for t = numel(r):-1:1
    acc = r(t) + gamma * acc;
    G(t) = acc;
end
end
