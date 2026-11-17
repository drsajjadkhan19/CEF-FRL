function res = run_federated_scheme(tel, rew, learn, cfg, scheme)
% RUN_FEDERATED_SCHEME  One federated scheme, frame by frame, on the channel traces.
%
% CEF-FRL runs the asynchronous aggregator with the link budget gate, the
% robust loss test. SyncFedAvg waits for every client, so its round closes
% at the straggler delay. FedCS aggregates the clients whose upload fits
% the budget and waits for all of them. Greedy admits only the highest capacity clients
% and therefore starves the weakest links, which shows up as a bias.
init_substream(cfg.seed + sum(double(scheme)), ['scheme-' scheme]);
T = tel.T; K = tel.K; d = learn.d;

theta = learn.theta0;
thetaLocal = repmat(theta, 1, K);
staleness = zeros(1, K);
pHat = ones(1, K);
mBuf = zeros(d, 1);
useMomentum = cfg.serverMomentum > 0 && ...
    (strcmp(scheme, 'CEF-FRL') || cfg.momentumForBaselines);

errTrace = zeros(T, 1); rewardTrace = zeros(T, 1);
latencyTrace = zeros(T, 1); perClientLatency = zeros(T, K);
radioTrace = zeros(T, 1); computeTrace = zeros(T, 1); energyTrace = zeros(T, 1);
admitTrace = zeros(T, K); uploadBits = zeros(T, 1);
dampHits = 0; coverageMiss = 0; wAccum = zeros(1, K);
e0 = norm(learn.theta0 - learn.thetaOpt);
nGreedy = max(1, round(cfg.greedyFraction * K));

for t = 1:T
    % ---- local training from the broadcast model ---------------------
    % The fog broadcast reaches every client each round, so a skipped
    % upload costs data coverage alone and never leaves a client training
    % against an outdated model.
    thetaLocal = repmat(theta, 1, K);
    for s = 1:cfg.localSteps
        rows = sample_rows(t, cfg.localBatch, cfg.replayCapacity);
        grad = batch_gradient(learn.F, rows, thetaLocal, learn.thetaClient, learn.noiseStd);
        thetaLocal = thetaLocal - cfg.learningRate * grad;
    end
    delta = thetaLocal - repmat(theta, 1, K);

    % A link that cannot meet the deadline delays the update; it does not
    % corrupt it.

    % ---- admission control -------------------------------------------
    feasible = link_budget_ok(tel.sinrDb(t, :), tel.capMbps(t, :), cfg);
    anomaly = loss_anomaly_flag(tel.loss(t, :), cfg.lossAnomalyZ);
    switch scheme
        case 'CEF-FRL'
            forced = staleness >= cfg.stalenessMax;
            admit = feasible & (~anomaly | forced);
        case 'SyncFedAvg'
            admit = true(1, K);
        case 'FedCS'
            % deadline-aware selection (Nishio and Yonetani 2019): the
            % clients whose upload fits the budget, aggregated synchronously
            admit = feasible;
        case 'Greedy'
            [~, order] = sort(tel.capMbps(t, :), 'descend');
            admit = false(1, K);
            admit(order(1:nGreedy)) = true;
        otherwise
            error('run_federated_scheme', 'Unknown scheme.');
    end
    pHat = ((t - 1) * pHat + double(admit)) / t;

    % ---- aggregation weights -----------------------------------------
    if any(admit)
        switch scheme
            case 'CEF-FRL'
                % CFAA weight: reliability proxy, data skew suppressor
                % and starvation priority gain.
                phiRel = link_reliability(tel.sinrDb(t, :), cfg.sinrAdmitDb);
                dbar = min(staleness, cfg.stalenessMax);   % consecutive missed rounds
                boost = 1 + cfg.starvationBoost * dbar / cfg.stalenessMax;
                w = (phiRel .^ cfg.reliabilityExponent) .* ...
                    exp(-cfg.nonIidSuppressBeta * learn.skew) .* boost;
            otherwise
                w = ones(1, K);
        end
        w = w .* double(admit);
        if sum(w) <= 0
            w = double(admit);
        end
        w = w / sum(w);
        wAccum = wAccum + w;
        % AGSC factor on the capped coverage gap, CEF-FRL only.
        if strcmp(scheme, 'CEF-FRL')
            om = exp(-cfg.agscDecayMu * min(staleness, cfg.stalenessMax));
        else
            om = ones(1, K);
        end
        aggDelta = clip_norm(delta * (w(:) .* om(:)), cfg.gradClipNorm * cfg.learningRate);
        if useMomentum
            mBuf = cfg.serverMomentum * mBuf + (1 - cfg.serverMomentum) * aggDelta;
            step = mBuf;
        else
            step = aggDelta;
        end

        % The contraction ratio is computed afterwards as an offline
        % diagnostic and is not used by the algorithm.
        theta = theta + step;
        staleness(admit) = 0;
    end
    staleness(~admit) = staleness(~admit) + 1;
    coverageMiss = coverageMiss + sum(staleness > cfg.stalenessMax);

    % ---- communication path delay -------------------------------------
    nAdmit = max(sum(admit), 1);
    hop = tel.uplinkMs(t, :) + cfg.edgeProcessMs ...
        + cfg.edgeQueueMsPerClient * nAdmit + cfg.fogForwardMs ...
        + cfg.fogJitterMs * rand(1, K);
    perClientLatency(t, :) = hop;
    switch scheme
        case 'SyncFedAvg'
            latencyTrace(t) = max(hop);
        case {'Greedy', 'FedCS'}
            if any(admit)
                latencyTrace(t) = max(hop(admit));
            else
                latencyTrace(t) = cfg.urllcDeadlineMs;
            end
        otherwise
            % The round closes when the last admitted
            % update arrives, or at the soft deadline if none is admitted.
            if any(admit)
                latencyTrace(t) = max(hop(admit));
            else
                latencyTrace(t) = cfg.urllcDeadlineMs;
            end
    end

    % ---- energy, split by term ---------------------------------------
    % radio energy of the uploads actually made in this round: amplifier
    % draw P_tx / eta_pa times the full airtime Q / C_k(t) of each upload
    pDraw = 10^((cfg.txPowerDbm - 30) / 10) / cfg.powerAmplifierEfficiency;
    radio = pDraw * sum(tel.uplinkMs(t, admit)) / 1e3;
    compute = sum(tel.computeEnergyJ(t, :));
    radioTrace(t) = radio;
    computeTrace(t) = compute;
    energyTrace(t) = radio + compute;

    uploadBits(t) = sum(admit) * cfg.modelBits;
    admitTrace(t, :) = double(admit);

    errTrace(t) = norm(theta - learn.thetaOpt);
    gap = (theta - learn.thetaOpt)' * learn.covariance * (theta - learn.thetaOpt);
    if any(admit)
        baseline = mean(rew.total(t, admit));
    else
        baseline = 0;
    end
    rewardTrace(t) = cfg.rewardScale * exp(-gap) * (0.85 + 0.15 * max(baseline, 0));
end

res.name = scheme;
res.err = errTrace;
res.errNorm = errTrace / e0;
res.reward = rewardTrace;
res.rewardSmooth = smooth_series(rewardTrace, 15);
res.latency = latencyTrace;
res.perClientLatency = perClientLatency;
res.radioEnergy = radioTrace;
res.computeEnergy = computeTrace;
res.energy = energyTrace;
res.radioEnergyCum = cumsum(radioTrace);
res.energyCum = cumsum(energyTrace);
res.admit = admitTrace;
res.participation = mean(admitTrace, 1);
res.skipRate = 1 - mean(admitTrace(:));
res.uploadGbit = sum(uploadBits) / 1e9;
res.timeVector = tel.timeVector;
res.dampHits = dampHits;
res.coverageMissRate = coverageMiss / (T * K);
res.wbar = wAccum / max(sum(wAccum), 1e-12);
res.rhoHat = estimate_contraction(errTrace);
res.finalReward = res.rewardSmooth(end);
res.commCompliance = mean(latencyTrace <= cfg.strictCommBoundMs);
res.deadlineViolation = 1 - res.commCompliance;
res.meanTrainCycleMs = mean(tel.trainCycleMs(:));
end
