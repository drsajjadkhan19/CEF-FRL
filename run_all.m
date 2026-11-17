% RUN_ALL  Reproduce every result and figure of the paper.
%
%   run_all                 full reproduction (several hours)
%
% The script runs from the repository root and writes
%   results/communication_level.mat       communication-level results
%   results/communication_level.txt       summary table (Tables 3 and 4)
%   results/learning/*.mat                one file per (setting, method, seed)
%   results/learning_level.txt            summary table (Table 5 and sweeps)
%   results/paper_fig_data.json           means and confidence intervals
%   figures/*.eps                         Figures 2 to 7
%
% The learning-level campaign is resumable: if MATLAB stops, run this
% script again and it continues from the last completed run.
%
% To redraw the figures from the data reported in the paper without
% running the simulations, use plot_paper_figures.

root = fileparts(mfilename('fullpath'));
cd(root);
addpath(genpath(fullfile(root, 'src')));
if exist('results', 'dir') ~= 7, mkdir('results'); end

% 1. Communication level: four schemes, rate models, blockage sweep,
%    sensitivity analysis (Sections 6.2 to 6.4).
run_communication_level('results');

% 2. Learning level: federated actor-critic navigation (Sections 6.5 to 6.7).
run_learning_level(fullfile('results', 'learning'));
summarize_learning_level(fullfile('results', 'learning'), fullfile('results', 'learning_level.txt'));

% 3. Figures: Monte Carlo means and 95% confidence intervals.
export_figure_data(fullfile('results', 'communication_level.mat'), ...
    fullfile('results', 'learning'), fullfile('results', 'paper_fig_data.json'));
make_paper_figures(fullfile('results', 'paper_fig_data.json'), 'figures');
