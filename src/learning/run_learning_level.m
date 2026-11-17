function run_learning_level(outDir)
% RUN_LEARNING_LEVEL  Federated actor-critic campaigns of the learning-level evaluation.
%
%   run_learning_level('results/learning')
%
% Ten robots train the dual-timescale actor-critic over the sub-THz traces.
% The campaigns are
%   main     CEF-FRL, six baselines and four ablations, 10 seeds each
%   slowN    CEF-FRL with slow-head period N_s = 1, 5, 20, 50, 5 seeds each
%   lamX     CEF-FRL with DTRD weight lambda = 0.1 and 1.0, 5 seeds each
%   hard     strong heterogeneity (Dirichlet 0.1) and uneven blockage, in
%            which three robots are blocked 70% of the time, 5 seeds each
% Every (setting, method, seed) run is saved to its own file, so the
% campaign resumes where it stopped if it is interrupted.
methods = {'CEF-FRL', 'SyncFedAvg', 'FedCS', 'FedAsync', 'FedBuff', 'CEF-noCFAA', ...
           'CEF-noAGSC', 'CEF-noDTRD', 'CEF-noSPG', 'FedProx', 'Centralized'};
ac_campaign(methods, 1:10, 'main', outDir);
for Ns = [1 5 20 50]
    ac_campaign({'CEF-FRL'}, 1:5, sprintf('slow%d', Ns), outDir, 'slowEvery', Ns);
end
for lam = [0.1 1.0]
    ac_campaign({'CEF-FRL'}, 1:5, strrep(sprintf('lam%.1f', lam), '.', 'p'), outDir, 'dtrdLambda', lam);
end
ac_campaign({'CEF-FRL', 'FedCS', 'FedBuff', 'SyncFedAvg'}, 1:5, 'hard', outDir, ...
    'dirichletAlpha', 0.1, 'heavyClients', 3, 'pbHeavy', 0.7, 'pbLight', 0.2, ...
    'blockDwellFrames', 37.5, 'clientEval', true, 'clientEvalEpisodes', 20);
end
