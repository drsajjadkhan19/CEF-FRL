function mc = run_monte_carlo(tel, rew, cfg, schemes, nSeeds)
% RUN_MONTE_CARLO  Repeat the communication-level comparison over independent seeds.
%
% The channel traces stay fixed and every seed resamples the learning
% noise (observation noise, client drift and jitter). Returns the mean
% trajectory of every curve, its standard deviation across seeds, and the
% mean and standard deviation of every scalar metric.

if nargin < 5
    nSeeds = cfg.mcSeeds;
end

mc = struct();
mc.nSeeds = nSeeds;
mc.schemes = schemes;

for si = 1:numel(schemes)
    scheme = schemes{si};
    rewardAll = []; latencyAll = []; radioAll = []; totalAll = []; errAll = [];
    admitAll = []; partAll = []; perClientAll = [];
    scalars = zeros(nSeeds, 8);

    for s = 1:nSeeds
        seedCfg = cfg;
        seedCfg.seed = cfg.seed + 1000 * s;
        learn = build_learning_problem(tel, seedCfg, seedCfg.seed + 11);
        r = run_federated_scheme(tel, rew, learn, seedCfg, scheme);

        rewardAll(:, s) = r.rewardSmooth(:);   %#ok<AGROW>
        latencyAll(:, s) = r.latency(:);       %#ok<AGROW>
        radioAll(:, s) = r.radioEnergyCum(:);  %#ok<AGROW>
        totalAll(:, s) = r.energyCum(:);       %#ok<AGROW>
        errAll(:, s) = r.errNorm(:);           %#ok<AGROW>
        % Admission is deterministic given the channel traces.
        admitAll(:, s) = mean(r.admit, 2);      %#ok<AGROW>
        partAll(s, :) = r.participation;        %#ok<AGROW>
        perClientAll(:, :, s) = r.perClientLatency; %#ok<AGROW>

        scalars(s, :) = [r.rhoHat, r.finalReward, mean(r.latency), ...
                         100 * r.commCompliance, r.radioEnergyCum(end), ...
                         r.energyCum(end), r.uploadGbit, r.coverageMissRate];
    end

    res = struct();
    res.name = scheme;
    res.rewardSmooth = mean(rewardAll, 2);
    res.rewardBand = std(rewardAll, 0, 2);
    res.latency = mean(latencyAll, 2);
    res.latencyBand = std(latencyAll, 0, 2);
    res.radioEnergyCum = mean(radioAll, 2);
    res.radioBand = std(radioAll, 0, 2);
    res.energyCum = mean(totalAll, 2);
    res.energyBand = std(totalAll, 0, 2);
    res.errNorm = mean(errAll, 2);
    res.errBand = std(errAll, 0, 2);
    res.timeVector = tel.timeVector;
    % Mean admitted fraction per frame
    res.admit = mean(admitAll, 2);
    res.admitBand = std(admitAll, 0, 2);
    res.participation = mean(partAll, 1);
    res.participationBand = std(partAll, 0, 1);
    res.perClientLatency = mean(perClientAll, 3);

    res.scalarNames = {'contraction', 'final reward', 'mean latency ms', ...
        'within bound percent', 'radio energy J', 'device energy J', ...
        'uplink Gbit', 'coverage miss'};
    res.scalarMean = mean(scalars, 1);
    if nSeeds > 1
        res.scalarStd = std(scalars, 0, 1);
    else
        res.scalarStd = zeros(1, size(scalars, 2));
    end
    res.scalarAll = scalars;

    % Scalar shortcuts
    res.rhoHat = res.scalarMean(1);
    res.finalReward = res.scalarMean(2);
    res.commCompliance = res.scalarMean(4) / 100;
    res.uploadGbit = res.scalarMean(7);
    res.coverageMissRate = res.scalarMean(8);

    mc.results{si} = res;
end
end
