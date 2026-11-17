function out = run_communication_level(outDir, varargin)
% RUN_COMMUNICATION_LEVEL  Communication-level evaluation on the sub-THz traces.
%
%   run_communication_level('results')
%   run_communication_level('results/quick_check', 'quick', true)
%
% Runs CEF-FRL, synchronous FedAvg, FedCS and a greedy scheduler over the
% five-client channel traces for cfg.mcSeeds independent seeds, repeats
% the comparison under three rate models and across the stationary
% blockage probability, and moves eight parameters one at a time between a
% low and a high setting. The channel traces stay fixed across seeds; each
% seed resamples the learning noise. Local learning is a linear policy
% regression whose closed-form optimum enables the offline contraction
% diagnostic.
%
% Writes communication_level.mat and communication_level.txt to outDir.
opt.quick = false;
for i = 1:2:numel(varargin), opt.(varargin{i}) = varargin{i + 1}; end
if exist(outDir, 'dir') ~= 7, mkdir(outDir); end

cfg = cef_frl_config();
if opt.quick
    cfg.mcSeeds = 3; cfg.sweepSeeds = 2; cfg.sensFrames = 120;
    cfg.blockageGrid = 0:0.35:0.70;
end
init_random(cfg.seed);
tel = load_telemetry(cfg.csvPath);
if opt.quick, tel = truncate_telemetry(tel, 200); cfg.numFrames = 200; end
validate_telemetry(tel, cfg);
eqReport = validate_equations(tel, cfg);
nFail = sum(cellfun(@(e) ~e.pass, eqReport));
fprintf('Model consistency checks: %d of %d passed.\n', numel(eqReport) - nFail, numel(eqReport));
if nFail > 0, error('run_communication_level:checks', 'Model consistency checks failed.'); end

rew = local_reward_loop(tel, cfg);
schemes = {'CEF-FRL', 'SyncFedAvg', 'FedCS', 'Greedy'};

% Main comparison over independent seeds
mcA = run_monte_carlo(tel, rew, cfg, schemes, cfg.mcSeeds);
studyA = mcA.results;

% Rate models: Shannon, finite blocklength, finite blocklength with a 3 dB gap
rateModels = {'shannon', 'fbl', 'fbl-gap'};
rateRes = cell(numel(rateModels), 1);
for r = 1:numel(rateModels)
    telR = rate_model_telemetry(tel, cfg, rateModels{r});
    rateRes{r} = run_monte_carlo(telR, rew, cfg, schemes, cfg.sweepSeeds);
end

% Stationary blockage probability sweep with the measured dwell time
pbGrid = cfg.blockageGrid;
blk.grid = pbGrid; blk.schemes = schemes;
blk.closeMs = zeros(numel(schemes), numel(pbGrid));
blk.closeStd = blk.closeMs; blk.within = blk.closeMs; blk.withinStd = blk.closeMs;
for g = 1:numel(pbGrid)
    lc = cfg; lc.blockageProbability = pbGrid(g);
    telP = perturb_telemetry(tel, cfg, lc, 2);
    mc = run_monte_carlo(telP, local_reward_loop(telP, lc), lc, schemes, cfg.sweepSeeds);
    for s = 1:numel(schemes)
        blk.closeMs(s, g) = mc.results{s}.scalarMean(3);
        blk.closeStd(s, g) = mc.results{s}.scalarStd(3);
        blk.within(s, g) = mc.results{s}.scalarMean(4);
        blk.withinStd(s, g) = mc.results{s}.scalarStd(4);
    end
end

% One-at-a-time sensitivity to eight channel and design parameters
sens = sweep_sensitivity(tel, rew, build_learning_problem(tel, cfg, cfg.seed + 11), cfg);

save(fullfile(outDir, 'communication_level.mat'), 'studyA', 'rateRes', 'rateModels', ...
    'blk', 'sens', 'cfg', '-v7');
write_summary(fullfile(outDir, 'communication_level.txt'), studyA, rateRes, rateModels, ...
    schemes, blk, sens, cfg);
out = struct('studyA', {studyA}, 'rateRes', {rateRes}, 'blk', blk, 'sens', sens);
end

function write_summary(path, studyA, rateRes, rateModels, schemes, blk, sens, cfg)
fid = fopen(path, 'w');
fprintf(fid, 'Communication level, %d frames, %d seeds\n\n', cfg.numFrames, cfg.mcSeeds);
fprintf(fid, '%-11s %16s %16s %15s %9s %9s %9s %9s\n', 'scheme', 'reward', 'closure ms', ...
    'within 1 ms %', 'radio J', 'device J', 'up Gbit', 'gap > cap');
for s = 1:numel(studyA)
    m = studyA{s}.scalarMean; d = studyA{s}.scalarStd;
    fprintf(fid, '%-11s %7.4f +- %.4f %7.3f +- %.3f %6.2f +- %.2f %9.4f %9.3f %9.4f %9.4f\n', ...
        studyA{s}.name, m(2), d(2), m(3), d(3), m(4), d(4), m(5), m(6), m(7), m(8));
end
fprintf(fid, '\nRate models (%d seeds): median closure ms / rounds within 1 ms %%\n', cfg.sweepSeeds);
for r = 1:numel(rateModels)
    fprintf(fid, '%-8s', rateModels{r});
    for s = 1:numel(schemes)
        m = rateRes{r}.results{s}.scalarMean;
        fprintf(fid, '  %s %.3f / %.1f', schemes{s}, median(rateRes{r}.results{s}.latency), m(4));
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\nBlockage sweep, p_b = %s: rounds within 1 ms %%\n', mat2str(blk.grid));
for s = 1:numel(schemes)
    fprintf(fid, '%-11s %s\n', schemes{s}, mat2str(round(blk.within(s, :) * 10) / 10));
end
fprintf(fid, '\nSensitivity (low | high): CEF-FRL closure ms, within 1 ms, radio saving, uplink saving\n');
for p = 1:numel(sens.names)
    fprintf(fid, '%-24s %s | %s\n', sens.names{p}, mat2str(sens.low(p, :), 4), mat2str(sens.high(p, :), 4));
end
fclose(fid);
type(path);
end
