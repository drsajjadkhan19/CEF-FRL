function S = load_learning_results(resDir)
% LOAD_LEARNING_RESULTS  Group the learning-level run files by setting and method.
%
%   S = load_learning_results('results/learning') returns a struct whose
%   field <tag>__<method> holds a cell array with one result per seed.
files = dir(fullfile(resDir, '*.mat'));
if isempty(files), error('load_learning_results:empty', 'No result files in %s.', resDir); end
S = struct();
for i = 1:numel(files)
    q = load(fullfile(resDir, files(i).name));
    key = result_key(q.r.tag, q.r.method);
    if ~isfield(S, key), S.(key) = {}; end
    S.(key){end + 1} = q.r;
end
end
