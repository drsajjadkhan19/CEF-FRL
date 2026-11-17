function make_paper_figures(dataFile, outDir)
% MAKE_PAPER_FIGURES  Draw Figures 2 to 7 of the paper as vector EPS files.
%   make_paper_figures('paper_fig_data.json', 'Figures_eps')
% Every curve is the Monte Carlo mean over all independent runs; shaded
% bands are 95% confidence intervals of that mean. Individual runs are not
% drawn. Learning curves are smoothed with a three-point moving average
% and drawn with shape-preserving (pchip) interpolation.
if nargin < 1, dataFile = 'paper_fig_data.json'; end
if nargin < 2, outDir = fullfile(pwd, 'Figures_eps'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
J = jsondecode(fileread(dataFile));
A = J.A; B = J.B;
W = 4.8;                                  % printed width (in), fonts print at true size

C.CEF = hex('#0072B2'); C.Sync = hex('#D55E00'); C.FedCS = hex('#009E73');
C.Greedy = hex('#CC79A7'); C.FedAsync = hex('#E69F00'); C.FedBuff = hex('#56B4E9');
C.FedProx = hex('#666666'); C.Cent = [0 0 0];
key = {'CEF-FRL','FedCS','Greedy','SyncFedAvg','FedAsync','FedBuff','FedProx','Centralized'};
fld = {'CEF','FedCS','Greedy','Sync','FedAsync','FedBuff','FedProx','Cent'};
lab = {'Proposed CEF-FRL','FedCS','Greedy scheduler','Synchronous FedAvg','FedAsync','FedBuff','FedProx','Centralized'};
mk  = {'o','^','d','s','v','>','<','x'};
ls  = {'-','-','-','-','-','-','-','--'};
col = @(n) C.(fld{strcmp(key, n)});
lbl = @(n) lab{strcmp(key, n)};
mrk = @(n) mk{strcmp(key, n)};
lst = @(n) ls{strcmp(key, n)};
order = {'CEF-FRL','FedCS','Greedy','SyncFedAvg'};

%% Figure 2: latency CDF and participation
f = newfig(W, 2.05);
ax1 = axes(f); hold(ax1, 'on'); ax2 = axes(f); hold(ax2, 'on');
hl = gobjects(0);
for i = 1:4
    s = A.(fn(order{i})); n = order{i};
    cy = linspace(0, 100, numel(s.cdfx));
    hl(end + 1) = plot(ax1, s.cdfx, cy, lst(n), 'Color', col(n), 'LineWidth', 1.5, ...
        'Marker', mrk(n), 'MarkerSize', 3.5, 'MarkerIndices', mi(numel(s.cdfx), 5, i), ...
        'MarkerFaceColor', 'w', 'DisplayName', lbl(n)); %#ok<AGROW>
end
hl(end + 1) = plot(ax1, [1 1], [0 100], 'k--', 'LineWidth', 0.9, 'DisplayName', 'Strict bound D_s');
set(ax1, 'XScale', 'log', 'XLim', [0.4 40], 'YLim', [0 100], 'XTick', [0.5 1 2 5 10 20]);
xlabel(ax1, 'Round closure latency (ms)'); ylabel(ax1, 'CDF (%)');
P = zeros(numel(A.CEF_FRL.part), 4);
for i = 1:4, P(:, i) = A.(fn(order{i})).part(:); end
hb = bar(ax2, 1:size(P, 1), P, 0.85, 'EdgeColor', 'none');
for i = 1:4, set(hb(i), 'FaceColor', col(order{i})); end
set(ax2, 'XTick', 1:size(P, 1), 'YLim', [0 105], 'XLim', [0.5 size(P, 1) + 0.5]);
xlabel(ax2, 'Client index'); ylabel(ax2, 'Participation (%)');
style(ax1, '(a)'); style(ax2, '(b)');
place2(f, ax1, ax2, hl, 3);
save_eps(f, outDir, 'fig_latency_participation');

%% Figure 3: radio and device energy
f = newfig(W, 2.0);
ax1 = axes(f); hold(ax1, 'on'); ax2 = axes(f); hold(ax2, 'on'); hl = gobjects(0);
for i = 1:4
    s = A.(fn(order{i})); n = order{i}; t = s.t(:)';
    hl(end + 1) = plot(ax1, t, s.radio(:)', 'Color', col(n), 'LineWidth', 1.5, 'Marker', mrk(n), ...
        'MarkerSize', 3.5, 'MarkerIndices', mi(numel(t), 6, i), 'MarkerFaceColor', 'w', 'DisplayName', lbl(n)); %#ok<AGROW>
    plot(ax2, t, s.energy(:)', 'Color', col(n), 'LineWidth', 1.5, 'Marker', mrk(n), ...
        'MarkerSize', 3.5, 'MarkerIndices', mi(numel(t), 6, i), 'MarkerFaceColor', 'w');
end
set(ax1, 'XLim', [0 10]); set(ax2, 'XLim', [0 10]);
xlabel(ax1, 'Time (s)'); ylabel(ax1, 'Radio energy (J)');
xlabel(ax2, 'Time (s)'); ylabel(ax2, 'Device energy (J)');
style(ax1, '(a)'); style(ax2, '(b)');
place2(f, ax1, ax2, hl, 2);
save_eps(f, outDir, 'fig_energy');

%% Figure 4: blockage sweep (mean and 95% CI over the sweep seeds)
bk = A.blk; g = bk.grid(:)'; sch = cellstr(bk.schemes); gf = linspace(min(g), max(g), 141);
f = newfig(W, 2.05);
ax1 = axes(f); hold(ax1, 'on'); ax2 = axes(f); hold(ax2, 'on'); hl = gobjects(0);
for i = 1:numel(sch)
    n = sch{i}; c = col(n);
    m1 = rowof(bk.close, i); h1 = rowof(bk.closeCi, i);
    m2 = rowof(bk.within, i); h2 = rowof(bk.withinCi, i);
    band(ax1, gf, pchip(g, m1 - h1, gf), pchip(g, m1 + h1, gf), c);
    band(ax2, gf, pchip(g, max(m2 - h2, 0), gf), pchip(g, min(m2 + h2, 100), gf), c);
end
for i = 1:numel(sch)
    n = sch{i}; c = col(n);
    m1 = rowof(bk.close, i); m2 = rowof(bk.within, i);
    plot(ax1, gf, pchip(g, m1, gf), 'Color', c, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    plot(ax1, g, m1, 'LineStyle', 'none', 'Marker', mrk(n), 'MarkerSize', 4, 'Color', c, 'MarkerFaceColor', 'w', 'HandleVisibility', 'off');
    plot(ax2, gf, pchip(g, m2, gf), 'Color', c, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    plot(ax2, g, m2, 'LineStyle', 'none', 'Marker', mrk(n), 'MarkerSize', 4, 'Color', c, 'MarkerFaceColor', 'w', 'HandleVisibility', 'off');
    hl(end + 1) = plot(ax1, nan, nan, '-', 'Color', c, 'LineWidth', 1.5, 'Marker', mrk(n), ...
        'MarkerSize', 4, 'MarkerFaceColor', 'w', 'DisplayName', lbl(n)); %#ok<AGROW>
end
hl(end + 1) = plot(ax1, [-0.02 max(g) + 0.02], [1 1], 'k--', 'LineWidth', 0.9, 'DisplayName', 'Strict bound D_s');
set(ax1, 'YScale', 'log', 'XLim', [0 max(g)], 'YLim', [0.4 30], 'YTick', [0.5 1 2 5 10 20]);
set(ax2, 'YLim', [0 102], 'XLim', [0 max(g)]);
xlabel(ax1, 'Stationary blockage probability p_b'); ylabel(ax1, 'Mean closure (ms)');
xlabel(ax2, 'Stationary blockage probability p_b'); ylabel(ax2, 'Within 1 ms (%)');
style(ax1, '(a)'); style(ax2, '(b)');
place2(f, ax1, ax2, hl, 3);
save_eps(f, outDir, 'fig_blockage');

%% Figure 5: one-at-a-time sensitivity
sn = A.sens; names = cellstr(sn.names);
pretty = containers.Map( ...
    {'absorption dB/m','blockage probability','shadowing dB','sidelobe isolation dB', ...
     'transmit power dBm','admission floor dB','blockage depth dB','path loss exponent'}, ...
    {'Absorption (RH 30-90%)','Blockage prob. 0.2-0.7','Shadowing 1-6 dB','Sidelobe isol. 25-40 dB', ...
     'Tx power 17-26 dBm','Admission floor 0-8 dB','Blockage depth 8-56 dB','Path loss exp. 1.9-2.4'});
ylab = cellfun(@(x) pretty(x), names, 'UniformOutput', false);
f = newfig(W, 2.15);
ax1 = axes(f); hold(ax1, 'on'); ax2 = axes(f); hold(ax2, 'on');
pairs = {sn.closeLo, sn.closeHi, 'CEF-FRL mean closure (ms)', ax1; ...
         sn.upLo, sn.upHi, 'Uplink saving (%)', ax2};
for j = 1:2
    ax = pairs{j, 4}; a = pairs{j, 1}(:); b = pairs{j, 2}(:); y = (1:numel(a))';
    for k = 1:numel(a)
        lo = min(a(k), b(k)); w = abs(b(k) - a(k));
        if w > 0
            patch(ax, lo + [0 w w 0], y(k) + [-0.28 -0.28 0.28 0.28], tint(C.CEF, 0.45), ...
                'EdgeColor', C.CEF, 'LineWidth', 0.6, 'HandleVisibility', 'off');
        end
    end
    h1 = plot(ax, a, y, 'o', 'Color', C.CEF, 'MarkerSize', 4, 'MarkerFaceColor', 'w', 'LineWidth', 1.1);
    h2 = plot(ax, b, y, 's', 'Color', C.Sync, 'MarkerSize', 4, 'MarkerFaceColor', C.Sync);
    span = max([a; b]) - min([a; b]);
    set(ax, 'YDir', 'reverse', 'YLim', [0.4 numel(a) + 0.6], 'YTick', y, ...
        'XLim', [min([a; b]) - 0.1 * span, max([a; b]) + 0.1 * span]);
    if j == 1, set(ax, 'YTickLabel', ylab); else, set(ax, 'YTickLabel', {}); end
    xlabel(ax, pairs{j, 3}); style(ax, ['(' char('a' + j - 1) ')']); set(ax, 'YGrid', 'off');
end
lg = legend(ax2, [h1 h2], {'Low setting', 'High setting'}, 'Orientation', 'horizontal');
fh = 2.15; b0 = 0.62 / fh + 0.02;
set(lg, 'Units', 'normalized', 'Position', [0.30 0.005 0.6 0.07], 'Box', 'off', 'FontSize', 7.5, 'FontName', 'Times');
set(ax1, 'Position', [0.255 b0 0.33 0.9 - b0]); set(ax2, 'Position', [0.645 b0 0.33 0.9 - b0]);
save_eps(f, outDir, 'fig_sensitivity');

%% Figure 6: federated actor-critic learning (mean and 95% CI over seeds)
mainM = {'CEF-FRL','FedCS','FedAsync','FedBuff','FedProx','SyncFedAvg','Centralized'};
f = newfig(W, 2.45);
ax1 = axes(f); hold(ax1, 'on'); ax2 = axes(f); hold(ax2, 'on'); hl = gobjects(0);
for i = numel(mainM):-1:1
    n = mainM{i}; s = B.(fn(n)); [xf, m, h] = smoothc(s.round(:)', s.mean(:)', s.ci(:)');
    band(ax1, xf, m - h, m + h, col(n));
end
for i = 1:numel(mainM)
    n = mainM{i}; s = B.(fn(n)); c = col(n);
    [xf, m] = smoothc(s.round(:)', s.mean(:)', s.ci(:)');
    hl(end + 1) = plot(ax1, xf, m, lst(n), 'Color', c, 'LineWidth', 1.4, 'Marker', mrk(n), 'MarkerSize', 3.5, ...
        'MarkerIndices', mi(numel(xf), 6, i), 'MarkerFaceColor', 'w', 'DisplayName', lbl(n)); %#ok<AGROW>
    if isfield(s, 'wall')
        [wf, mw] = smoothc(s.wall(:)', s.mean(:)', s.ci(:)');
        plot(ax2, wf, mw, lst(n), 'Color', c, 'LineWidth', 1.4, 'Marker', mrk(n), 'MarkerSize', 3.5, ...
            'MarkerIndices', mi(numel(wf), 6, i), 'MarkerFaceColor', 'w');
    end
end
set(ax1, 'YLim', [20 90], 'XLim', [0 300]); set(ax2, 'YLim', [20 90]);
xlabel(ax1, 'Aggregation round'); ylabel(ax1, 'Navigation success (%)');
xlabel(ax2, 'End-to-end wall-clock time (s)'); ylabel(ax2, 'Navigation success (%)');
style(ax1, '(a)'); style(ax2, '(b)');
place2(f, ax1, ax2, hl, 4);
save_eps(f, outDir, 'fig_ac_learning');

%% Figure 7: ablation and timescale sweeps (mean and 95% CI over seeds)
f = newfig(W, 1.95);
ab = B.ablation; ak = {'CEF_FRL','CEF_noCFAA','CEF_noAGSC','CEF_noDTRD','CEF_noSPG'};
al = {'Full','No CFAA','No AGSC','No DTRD','No SPG'};
v = cellfun(@(k) ab.(k)(1), ak); e = cellfun(@(k) ab.(k)(2), ak);
ax = axes(f); hold(ax, 'on'); axs = ax;
bar(ax, 1, v(1), 0.62, 'FaceColor', C.CEF, 'EdgeColor', 'none');
bar(ax, 2:5, v(2:5), 0.62, 'FaceColor', tint(C.CEF, 0.5), 'EdgeColor', 'none');
errorbar(ax, 1:5, v, e, 'k', 'LineStyle', 'none', 'LineWidth', 0.9, 'CapSize', 3);
set(ax, 'XTick', 1:5, 'XTickLabel', al, 'XTickLabelRotation', 35, 'YLim', [50 90], 'XLim', [0.4 5.6]);
ylabel(ax, 'Final success (%)'); style(ax, '(a)'); set(ax, 'XGrid', 'off');
sw = {B.slow, 'Slow-head period $N_s$', true; B.lam, 'DTRD weight $\lambda$', false};
for k = 1:2
    ax = axes(f); hold(ax, 'on'); axs(end + 1) = ax; %#ok<AGROW>
    s = sw{k, 1}; x = s.x(:)'; V = reshape(s.v, [], 2); m = V(:, 1)'; h = V(:, 2)';
    if sw{k, 3}, xf = logspace(log10(min(x)), log10(max(x)), 120); else, xf = linspace(min(x), max(x), 120); end
    band(ax, xf, pchip(x, m - h, xf), pchip(x, m + h, xf), C.CEF);
    plot(ax, xf, pchip(x, m, xf), 'Color', C.CEF, 'LineWidth', 1.5);
    plot(ax, x, m, 'o', 'Color', C.CEF, 'MarkerSize', 4, 'MarkerFaceColor', 'w', 'LineWidth', 1.1);
    set(ax, 'YLim', [50 90]);
    if sw{k, 3}
        set(ax, 'XScale', 'log', 'XTick', x, 'XLim', [0.8 62]);
    else
        set(ax, 'XTick', x, 'XLim', [0.05 1.05]);
    end
    xlabel(ax, sw{k, 2}, 'Interpreter', 'latex'); style(ax, ['(' char('b' + k - 1) ')']);
end
b0 = 0.56 / 1.95 + 0.06; hgt = 0.88 - b0;
set(axs(1), 'Position', [0.09 b0 0.26 hgt]); set(axs(2), 'Position', [0.42 b0 0.26 hgt]);
set(axs(3), 'Position', [0.73 b0 0.25 hgt]);
save_eps(f, outDir, 'fig_ac_ablation');
fprintf('EPS figures written to %s\n', outDir);
end

% -------------------------------------------------------------------------
function [xf, m, h] = smoothc(x, m, h)
% three-point moving average, then pchip on a fine grid
m = movmean(m, 3); h = movmean(h, 3);
xf = linspace(min(x), max(x), 10 * numel(x));
m = pchip(x, m, xf); h = pchip(x, h, xf);
end

function band(ax, x, lo, hi, c)
fill(ax, [x fliplr(x)], [lo fliplr(hi)], tint(c, 0.16), 'EdgeColor', 'none', 'HandleVisibility', 'off');
end

function t = tint(c, a)
t = 1 - a * (1 - c);          % opaque light shade of colour c (EPS has no transparency)
end

function k = mi(n, cnt, i)
k = unique(round(linspace(1, n, cnt) + (i - 1) * n / (cnt * 7)));
k = k(k >= 1 & k <= n);
end

function f = newfig(w, h)
f = figure('Color', 'w', 'Units', 'inches', 'Position', [1 1 w h], ...
    'PaperUnits', 'inches', 'PaperPosition', [0 0 w h], 'PaperSize', [w h]);
end

function style(ax, tag)
set(ax, 'FontName', 'Times', 'FontSize', 8, 'LineWidth', 0.6, 'Box', 'on', ...
    'XGrid', 'on', 'YGrid', 'on', 'GridLineStyle', ':', 'GridAlpha', 0.35, ...
    'TickDir', 'in', 'TickLength', [0.015 0.015], 'Layer', 'top');
title(ax, tag, 'FontWeight', 'normal', 'FontSize', 8.5, 'FontName', 'Times', ...
    'HorizontalAlignment', 'left', 'Units', 'normalized', 'Position', [0 1.0 0]);
set(get(ax, 'XLabel'), 'FontSize', 8.5, 'FontName', 'Times');
set(get(ax, 'YLabel'), 'FontSize', 8.5, 'FontName', 'Times');
end

function place2(f, a1, a2, hl, ncol)
p = get(f, 'Position'); h = p(4); nrow = ceil(numel(hl) / ncol);
lgh = (0.17 * nrow + 0.08) / h;
lg = legend(a1, hl, 'Orientation', 'horizontal', 'NumColumns', ncol);
set(lg, 'Units', 'normalized', 'Position', [0.03 0.005 0.94 lgh], 'Box', 'off', ...
    'FontSize', 7.5, 'FontName', 'Times');
b = lgh + 0.50 / h;
set(a1, 'Position', [0.095 b 0.375 0.9 - b]); set(a2, 'Position', [0.6 b 0.375 0.9 - b]);
end

function save_eps(f, outDir, name)
p = fullfile(outDir, [name '.eps']);
if exist('exportgraphics', 'file') == 2 || exist('exportgraphics', 'builtin') == 5
    exportgraphics(f, p, 'ContentType', 'vector', 'BackgroundColor', 'white');
else
    print(f, p, '-depsc2', '-painters');
end
close(f);
end

function c = hex(s)
c = [hex2dec(s(2:3)) hex2dec(s(4:5)) hex2dec(s(6:7))] / 255;
end

function n = fn(name)
n = strrep(name, '-', '_');
end

function r = rowof(M, i)
if iscell(M), r = M{i}(:)'; else, r = M(i, :); end
end
