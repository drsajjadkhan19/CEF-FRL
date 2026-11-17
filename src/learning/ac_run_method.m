function res = ac_run_method(c, method, seed, ch, evalSet)
% AC_RUN_METHOD  Federated actor-critic training under one aggregation method.
%
% Methods
%   'CEF-FRL'      full scheme: CFAA admission and weighting, AGSC, DTRD
%   'CEF-noCFAA'   ablation: no link gate, uniform weights
%   'CEF-noAGSC'   ablation: staleness factor fixed at one
%   'CEF-noDTRD'   ablation: single scalar reward and one value head
%   'CEF-noSPG'    ablation: starvation priority gain b_s = 0
%   'SyncFedAvg'   synchronous FedAvg over all clients
%   'FedProx'      synchronous FedAvg with a proximal local term
%   'FedCS'        deadline-aware selection, synchronous over the selected
%   'FedAsync'     asynchronous mixing with polynomial staleness (Xie 2019)
%   'FedBuff'      buffered asynchronous aggregation (Nguyen 2022)
%   'Centralized'  one learner on all clients' episodes, no communication
%
% Round closure latency is the time until the last update aggregated in
% the round arrives (the maximum over aggregated clients), or the soft
% deadline tau_agg when nothing arrives.
rng(seed);
K = c.K; T = c.rounds;
theta = ac_init(c);
nP = numel(theta);
payload = nP * c.quantBits;
zeroOpt = struct('m', zeros(nP, 1), 'v', zeros(nP, 1), 'k', 0, 't', 0);
opts = repmat(zeroOpt, 1, K);

% client task distributions (non-IID over four arena zones)
zones = ac_dirichlet(K, 4, c.dirichletAlpha);
skew = sum(zones .* log(max(4 * zones, 1e-12)), 2)' / log(4);

isCef = strncmp(method, 'CEF', 3);
useCFAA = isCef && ~strcmp(method, 'CEF-noCFAA');
useAGSC = isCef && ~strcmp(method, 'CEF-noAGSC');
dtrd = ~strcmp(method, 'CEF-noDTRD');
bS = c.bS; if strcmp(method, 'CEF-noSPG'), bS = 0; end
isAsync = any(strcmp(method, {'FedAsync', 'FedBuff'}));
proxMu = 0; if strcmp(method, 'FedProx'), proxMu = c.proxMu; end

lastUp = zeros(1, K);           % last upload round, for AGSC delta_k
base = repmat(theta, 1, K);     % client base models (async methods)
baseVer = zeros(1, K);          % version each base was taken at
pending = false(1, K);          % async client holding an undelivered update
pendDelta = zeros(nP, K);
buffer = zeros(nP, 1); bufN = 0;
version = 0;

nEval = floor(T / c.evalEvery);
evalRound = zeros(nEval, 1); evalSucc = zeros(nEval, 1); evalRet = zeros(nEval, 1);
closeMs = zeros(T, 1); nAgg = zeros(T, 1); bits = zeros(T, 1);
radioJ = zeros(T, 1); computeJ = zeros(T, 1); trainSucc = zeros(T, 1);
admitLog = zeros(T, K); stalLog = zeros(T, K);
ie = 0; clipHits = 0;

for t = 1:T
    hopBase = ch.txMs(t, :) + c.edgeProcessMs + c.fogForwardMs;
    if strcmp(method, 'Centralized')
        for k = 1:K
            [theta, opts(1), st] = ac_local_train(theta, c, zones(k, :), opts(1), theta, 0, true);
            trainSucc(t) = trainSucc(t) + st.succRate / K;
        end
        computeJ(t) = sum(ch.computeJ(t, :));
        closeMs(t) = 0;
    elseif ~isAsync
        % ---- broadcast and local training -------------------------------
        delta = zeros(nP, K); loss = zeros(1, K);
        for k = 1:K
            [thk, opts(k), st] = ac_local_train(theta, c, zones(k, :), opts(k), theta, proxMu, dtrd);
            delta(:, k) = thk - theta; loss(k) = st.loss;
            trainSucc(t) = trainSucc(t) + st.succRate / K;
        end
        computeJ(t) = sum(ch.computeJ(t, :));
        % ---- admission ----------------------------------------------------
        switch method
            case {'SyncFedAvg', 'FedProx'}
                admit = true(1, K);
            case 'FedCS'
                admit = ch.feasible(t, :);
            otherwise  % CEF variants
                delta_k = t - lastUp - 1;   % consecutive missed rounds
                if useCFAA
                    forced = delta_k >= c.stalenessMax;
                    admit = ch.feasible(t, :) & (~ac_mad_flag(loss, c.lossAnomalyZ) | forced);
                else
                    admit = (ch.txMs(t, :) + c.edgeProcessMs + c.fogForwardMs) <= c.aggDeadlineMs;
                end
        end
        nA = sum(admit);
        hop = hopBase + c.edgeQueueMsPerClient * max(nA, 1);
        if nA > 0
            closeMs(t) = max(hop(admit));
            if isCef
                dbar = min(t - lastUp - 1, c.stalenessMax);
                if useCFAA
                    phi = 1 ./ (1 + exp(-(ch.sinrDb(t, :) - c.sinrAdmitDb) / 3.0));
                    w = phi.^c.aPhi .* exp(-c.beta * skew) .* (1 + bS * dbar / c.stalenessMax);
                else
                    w = ones(1, K);
                end
                if useAGSC
                    om = exp(-c.mu * dbar);
                else
                    om = ones(1, K);
                end
                w = w .* admit; w = w / sum(w);
                stalLog(t, :) = dbar;
                upd = delta * (w .* om)';
                nu = norm(upd);
                if nu > c.clipNorm, upd = upd * (c.clipNorm / nu); clipHits = clipHits + 1; end
            else
                w = double(admit) / nA;
                upd = delta * w';
            end
            theta = theta + upd;
            lastUp(admit) = t;
        else
            closeMs(t) = c.aggDeadlineMs;
        end
        nAgg(t) = nA; bits(t) = nA * payload;
        radioJ(t) = sum(ch.radioJ(t, admit));
        admitLog(t, :) = admit;
    else
        % ---- asynchronous methods ---------------------------------------
        for k = 1:K
            if ~pending(k)
                [thk, opts(k), st] = ac_local_train(base(:, k), c, zones(k, :), opts(k), base(:, k), 0, true);
                pendDelta(:, k) = thk - base(:, k); pending(k) = true;
                trainSucc(t) = trainSucc(t) + st.succRate / K;
                computeJ(t) = computeJ(t) + ch.computeJ(t, k);
            end
        end
        arrive = pending & ch.feasible(t, :);
        nA = sum(arrive);
        hop = hopBase + c.edgeQueueMsPerClient * max(nA, 1);
        order = find(arrive);
        for k = order
            tau = version - baseVer(k);
            s = (1 + tau)^(-c.asyncA);
            stalLog(t, k) = tau;
            if strcmp(method, 'FedAsync')
                a = c.asyncAlpha * s;
                theta = (1 - a) * theta + a * (base(:, k) + pendDelta(:, k));
                version = version + 1;
            else
                buffer = buffer + s * pendDelta(:, k); bufN = bufN + 1;
                if bufN >= c.buffSize
                    theta = theta + buffer / bufN;
                    buffer(:) = 0; bufN = 0; version = version + 1;
                end
            end
            base(:, k) = theta; baseVer(k) = version; pending(k) = false;
        end
        if nA > 0, closeMs(t) = max(hop(arrive)); else, closeMs(t) = c.aggDeadlineMs; end
        nAgg(t) = nA; bits(t) = nA * payload;
        radioJ(t) = sum(ch.radioJ(t, arrive));
        admitLog(t, :) = arrive;
    end

    if mod(t, c.evalEvery) == 0
        ie = ie + 1;
        [evalSucc(ie), evalRet(ie)] = ac_evaluate(theta, c, evalSet);
        evalRound(ie) = t;
    end
end

% Optional per-client evaluation: each robot's final policy is tested on
% its own task distribution, which exposes coverage bias directly.
if isfield(c, 'clientEval') && c.clientEval
    res.clientSucc = zeros(1, K);
    for k = 1:K
        evK = nav_reset(c, repmat(zones(k, :), c.clientEvalEpisodes, 1));
        res.clientSucc(k) = ac_evaluate(theta, c, evK);
    end
    res.zones = zones;
end
res.method = method;
res.clipRate = clipHits / T;
res.nParams = nP; res.payloadBits = payload;
res.evalRound = evalRound; res.evalSucc = evalSucc; res.evalRet = evalRet;
res.finalSucc = mean(evalSucc(end - 2:end));
res.finalRet = mean(evalRet(end - 2:end));
res.closeMs = closeMs; res.nAgg = nAgg; res.bits = bits;
res.radioJ = radioJ; res.computeJ = computeJ; res.trainSucc = trainSucc;
res.admit = admitLog; res.staleness = stalLog;
res.trainCycleMs = ch.trainMs;
res.meanCloseMs = mean(closeMs);
res.within1ms = mean(closeMs <= c.strictMs);
res.uplinkGbit = sum(bits) / 1e9;
res.participation = mean(admitLog, 1);
% end-to-end wall clock: per round, the slowest local training cycle of
% the clients that trained, plus the communication closure
res.wallMs = cumsum(max(ch.trainMs, [], 2) + closeMs);
end
