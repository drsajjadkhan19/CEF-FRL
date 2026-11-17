% RUN_QUICK_CHECK  Fast end-to-end check of the code (a few minutes).
%
% Runs every stage of run_all on a reduced scale: fewer frames and seeds
% at the communication level, and two seeds of 40 rounds for four methods
% at the learning level. The numbers are not those of the paper; the
% purpose is to confirm that the installation works before the full run.

root = fileparts(mfilename('fullpath'));
cd(root);
addpath(genpath(fullfile(root, 'src')));
out = fullfile('results', 'quick_check');
if exist(out, 'dir') ~= 7, mkdir(out); end

run_communication_level(out, 'quick', true);
methods = {'CEF-FRL', 'SyncFedAvg', 'FedCS', 'FedBuff'};
ac_campaign(methods, 1:2, 'main', fullfile(out, 'learning'), 'rounds', 40, 'evalEvery', 10);
summarize_learning_level(fullfile(out, 'learning'), fullfile(out, 'learning_level.txt'));
fprintf('\nQuick check completed. Results are in %s\n', out);
