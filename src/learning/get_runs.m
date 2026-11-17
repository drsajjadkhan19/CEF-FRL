function R = get_runs(S, tag, method)
% GET_RUNS  All seeds of one setting and method, or an empty cell.
key = result_key(tag, method);
if isfield(S, key), R = S.(key); else, R = {}; end
end
