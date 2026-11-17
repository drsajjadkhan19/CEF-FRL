function j = find_column(header, name)
% FIND_COLUMN  Locate a named column of the telemetry table.
j = find(strcmpi(strtrim(header), name), 1);
if isempty(j)
    error('find_column', ['Required telemetry column is absent. ' name]);
end
end
