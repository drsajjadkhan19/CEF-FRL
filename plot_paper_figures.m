% PLOT_PAPER_FIGURES  Redraw Figures 2 to 7 from the data reported in the paper.
%
% Uses paper_results/paper_fig_data.json, which holds the Monte Carlo means
% and 95% confidence intervals behind the published figures, and writes
% the EPS files to figures/. Runs in a few seconds.

root = fileparts(mfilename('fullpath'));
cd(root);
addpath(genpath(fullfile(root, 'src')));
make_paper_figures(fullfile('paper_results', 'paper_fig_data.json'), 'figures');
