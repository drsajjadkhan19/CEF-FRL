function export_figure_data(commFile, learnDir, outFile)
% EXPORT_FIGURE_DATA  Collect the plotted means and confidence intervals into one JSON file.
%
%   export_figure_data('results/communication_level.mat', 'results/learning', ...
%                      'results/paper_fig_data.json')
%
% Communication level: latency CDF (101 quantiles), participation and
% cumulative energy of each scheme (means over cfg.mcSeeds seeds), the
% blockage sweep with 95% confidence intervals, and the sensitivity
% ranges. Learning level: mean success curves with 95% confidence
% intervals, end-to-end wall-clock time, ablation and timescale sweeps.
q = load(commFile);
A = struct();
for s = 1:numel(q.studyA)
    r = q.studyA{s};
    idx = [1:10:991, numel(r.radioEnergyCum)];
    e.cdfx = rnd(quantile_linear(r.latency(:), 0:100), 3);
    e.part = rnd(100 * r.participation(:)', 2);
    e.t = rnd((idx - 1) * q.cfg.frameDurationS, 3);
    e.radio = rnd(r.radioEnergyCum(idx)', 4);
    e.energy = rnd(r.energyCum(idx)', 3);
    A.(field(r.name)) = e;
end
b = q.blk; n = q.cfg.sweepSeeds; t = tquant(n) / sqrt(n);
A.blk = struct('grid', b.grid, 'schemes', {b.schemes}, 'nseeds', n, ...
    'close', b.closeMs, 'closeCi', t * b.closeStd, ...
    'within', b.within, 'withinCi', t * b.withinStd);
A.sens = struct('names', {q.sens.names}, 'closeLo', q.sens.low(:, 1)', 'closeHi', q.sens.high(:, 1)', ...
    'upLo', 100 * q.sens.low(:, 4)', 'upHi', 100 * q.sens.high(:, 4)');

S = load_learning_results(learnDir);
B = struct();
for m = {'CEF-FRL', 'FedCS', 'FedAsync', 'FedBuff', 'FedProx', 'SyncFedAvg', 'Centralized'}
    R = get_runs(S, 'main', m{1});
    if isempty(R), continue; end
    xr = R{1}.evalRound(:)';
    Y = cell2mat(cellfun(@(r) 100 * r.evalSucc(:)', R(:), 'UniformOutput', false));
    [mu, h] = ci95(Y);
    e = struct('round', xr, 'mean', rnd(mu, 2), 'ci', rnd(h, 2), 'n', numel(R));
    if ~strcmp(m{1}, 'Centralized')
        e.wall = rnd(mean(cell2mat(cellfun(@(r) r.wallMs(xr)' / 1e3, R(:), 'UniformOutput', false)), 1), 3);
    end
    B.(field(m{1})) = e;
end
fin = @(tag) final_success(get_runs(S, tag, 'CEF-FRL'));
B.ablation = struct();
for m = {'CEF-FRL', 'CEF-noCFAA', 'CEF-noAGSC', 'CEF-noDTRD', 'CEF-noSPG'}
    B.ablation.(field(m{1})) = final_success(get_runs(S, 'main', m{1}));
end
B.slow = struct('x', [1 5 10 20 50], 'v', [fin('slow1'); fin('slow5'); fin('main'); fin('slow20'); fin('slow50')]);
B.lam = struct('x', [0.1 0.5 1.0], 'v', [fin('lam0p1'); fin('main'); fin('lam1p0')]);

fid = fopen(outFile, 'w');
fprintf(fid, '%s', jsonencode(struct('A', A, 'B', B)));
fclose(fid);
fprintf('Figure data written to %s\n', outFile);
end

function v = final_success(R)
if isempty(R), v = [NaN NaN]; return; end
[a, h] = ci95(100 * cellfun(@(r) r.finalSucc, R));
v = rnd([a h], 2);
end

function q = quantile_linear(x, p)
% percentiles with linear interpolation between order statistics
x = sort(x(:)); n = numel(x);
pos = 1 + (n - 1) * p / 100;
lo = floor(pos); hi = min(lo + 1, n); w = pos - lo;
q = (1 - w) .* x(lo)' + w .* x(hi)';
end

function t = tquant(n)
tq = [12.71 4.30 3.18 2.78 2.57 2.45 2.36 2.31 2.26 2.23 2.20 2.18 2.16 2.14 2.13 2.12 2.11 2.10 2.09];
if n - 1 <= numel(tq), t = tq(n - 1); else, t = 1.96; end
end

function f = field(name)
f = strrep(name, '-', '_');
end

function y = rnd(x, d)
% round to d decimal places
y = round(x * 10 ^ d) / 10 ^ d;
end
