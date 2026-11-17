function summarize_learning_level(resDir, outFile)
% SUMMARIZE_LEARNING_LEVEL  Summary table of the federated actor-critic results.
%
%   summarize_learning_level('results/learning', 'results/learning_level.txt')
%
% Reports, for every method found in resDir, the final navigation success
% (mean and 95% confidence interval over seeds), the round closure, the
% share of rounds within 1 ms, the uplink volume, the end-to-end wall-clock
% time and the participation of the weakest client, followed by the
% slow-head period and reward-weight sweeps and the uneven-blockage setting.
S = load_learning_results(resDir);
order = {'CEF-FRL', 'FedCS', 'FedAsync', 'FedBuff', 'FedProx', 'SyncFedAvg', 'Centralized', ...
         'CEF-noCFAA', 'CEF-noAGSC', 'CEF-noDTRD', 'CEF-noSPG'};
fid = fopen(outFile, 'w');
fprintf(fid, 'Learning level: federated actor-critic navigation\n\n');
fprintf(fid, '%-12s %4s %15s %15s %10s %11s %10s %10s\n', 'method', 'runs', 'success %', ...
    'closure ms', 'within 1ms', 'uplink Gbit', 'wall s', 'min part %');
for i = 1:numel(order)
    R = get_runs(S, 'main', order{i});
    if isempty(R), continue; end
    [a, ah] = ci95(100 * cellfun(@(r) r.finalSucc, R));
    [c, ch] = ci95(cellfun(@(r) r.meanCloseMs, R));
    w = mean(100 * cellfun(@(r) r.within1ms, R));
    u = mean(cellfun(@(r) r.uplinkGbit, R));
    wall = mean(cellfun(@(r) r.wallMs(end), R)) / 1e3;
    p = mean(100 * cellfun(@(r) min(r.participation), R));
    fprintf(fid, '%-12s %4d %7.1f +- %4.1f %8.3f +- %4.3f %10.1f %11.2f %10.1f %10.1f\n', ...
        order{i}, numel(R), a, ah, c, ch, w, u, wall, p);
end

cef = get_runs(S, 'main', 'CEF-FRL'); syn = get_runs(S, 'main', 'SyncFedAvg');
if ~isempty(cef) && ~isempty(syn)
    mo = @(R, f) mean(cellfun(f, R));
    fprintf(fid, '\nCEF-FRL against synchronous FedAvg\n');
    fprintf(fid, '  closure speed-up        %.1f x\n', mo(syn, @(r) r.meanCloseMs) / mo(cef, @(r) r.meanCloseMs));
    fprintf(fid, '  uplink saving           %.1f %%\n', 100 * (1 - mo(cef, @(r) r.uplinkGbit) / mo(syn, @(r) r.uplinkGbit)));
    fprintf(fid, '  radio energy saving     %.1f %%\n', 100 * (1 - mo(cef, @(r) sum(r.radioJ)) / mo(syn, @(r) sum(r.radioJ))));
    fprintf(fid, '  wall-clock saving       %.1f %%\n', 100 * (1 - mo(cef, @(r) r.wallMs(end)) / mo(syn, @(r) r.wallMs(end))));
    fprintf(fid, '  mean participation      %.1f %%\n', mo(cef, @(r) 100 * mean(r.participation)));
    fprintf(fid, '  model parameters        %d (%.2f Mbit in FP16)\n', cef{1}.nParams, cef{1}.payloadBits / 1e6);
    fprintf(fid, '  rounds with active clip %.1f %%\n', 100 * max(cellfun(@(r) r.clipRate, cef)));
end

sweeps = {'Slow-head period N_s', [1 5 10 20 50], {'slow1', 'slow5', 'main', 'slow20', 'slow50'}; ...
          'DTRD weight lambda', [0.1 0.5 1.0], {'lam0p1', 'main', 'lam1p0'}};
for k = 1:size(sweeps, 1)
    x = sweeps{k, 2}; tags = sweeps{k, 3};
    if any(cellfun(@(t) isempty(get_runs(S, t, 'CEF-FRL')), tags)), continue; end
    fprintf(fid, '\n%s: final success %% of CEF-FRL\n', sweeps{k, 1});
    for j = 1:numel(x)
        R = get_runs(S, tags{j}, 'CEF-FRL');
        [a, ah] = ci95(100 * cellfun(@(r) r.finalSucc, R));
        fprintf(fid, '  %-6g %5.1f +- %4.1f  (%d runs)\n', x(j), a, ah, numel(R));
    end
end

hard = {'CEF-FRL', 'FedCS', 'FedBuff', 'SyncFedAvg'};
if ~isempty(get_runs(S, 'hard', 'CEF-FRL'))
    fprintf(fid, '\nUneven blockage (three robots blocked 70%% of the time, Dirichlet 0.1)\n');
    fprintf(fid, '%-12s %4s %15s %15s %15s %11s\n', 'method', 'runs', 'fleet %', 'blocked %', 'worst %', 'closure ms');
    for i = 1:numel(hard)
        R = get_runs(S, 'hard', hard{i});
        if isempty(R), continue; end
        [a, ah] = ci95(100 * cellfun(@(r) r.finalSucc, R));
        [b, bh] = ci95(100 * cellfun(@(r) mean(r.clientSucc(1:3)), R));
        [w, wh] = ci95(100 * cellfun(@(r) min(r.clientSucc), R));
        fprintf(fid, '%-12s %4d %7.1f +- %4.1f %7.1f +- %4.1f %7.1f +- %4.1f %11.2f\n', hard{i}, ...
            numel(R), a, ah, b, bh, w, wh, mean(cellfun(@(r) r.meanCloseMs, R)));
    end
end
fclose(fid);
type(outFile);
end
