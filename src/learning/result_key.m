function key = result_key(tag, method)
% RESULT_KEY  Field name used to group learning-level results.
key = [tag '__' strrep(method, '-', '_')];
end
