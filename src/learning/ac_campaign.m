function ac_campaign(methods, seeds, tag, outDir, varargin)
% AC_CAMPAIGN  Resumable Monte Carlo campaign of the learning-level evaluation.
%
%   ac_campaign({'CEF-FRL','FedCS'}, 1:10, 'main', 'results')
%   ac_campaign({'CEF-FRL'}, 1:5, 'slow20', 'results', 'slowEvery', 20)
%
% Every (method, seed) pair is written to its own MAT file, so a campaign
% that is interrupted continues where it stopped. Extra
% name-value pairs override fields of ac_config. The channel trace is the
% same for every method and seed of a campaign; the seed changes the
% initialisation, the client task distributions and the episode draws.
c = ac_config();
for i = 1:2:numel(varargin)
    c.(varargin{i}) = varargin{i + 1};
end
if exist(outDir, 'dir') ~= 7, mkdir(outDir); end
rng(c.seed);
evalSet = nav_reset(c, repmat(0.25, c.evalEpisodes, 4));
nP = numel(ac_init(c));
ch = ac_channel(c, nP * c.quantBits, c.seed + 7);
for s = seeds
    for i = 1:numel(methods)
        m = methods{i};
        f = fullfile(outDir, sprintf('%s__%s__s%03d.mat', tag, strrep(m, '-', '_'), s));
        if exist(f, 'file') == 2, continue; end
        t0 = tic;
        r = ac_run_method(c, m, 1000 + s, ch, evalSet);
        r.runtimeS = toc(t0);
        r.seed = s; r.tag = tag; r.cfg = c;
        r = rmfield(r, {'admit', 'staleness'});
        save(f, 'r', '-v7');
        fprintf('%s %-12s seed %3d  succ %.3f  close %.3f ms  %.0f s\n', ...
            tag, m, s, r.finalSucc, r.meanCloseMs, r.runtimeS);
    end
end
end
