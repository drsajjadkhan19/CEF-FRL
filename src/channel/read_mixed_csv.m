function [header, numericData, deviceTags] = read_mixed_csv(csvPath)
% READ_MIXED_CSV  Robust CSV reader with a low level fallback.
header = {}; numericData = []; deviceTags = {};
used = false;
if exist('readtable', 'file') == 2 || exist('readtable', 'builtin') == 5
    try
        tbl = readtable(csvPath);
        header = tbl.Properties.VariableNames;
        numericData = zeros(height(tbl), numel(header));
        deviceTags = cell(height(tbl), 1);
        for j = 1:numel(header)
            c = tbl.(header{j});
            if isnumeric(c)
                numericData(:, j) = double(c);
            else
                numericData(:, j) = NaN;
                if strcmpi(header{j}, 'DeviceID')
                    deviceTags = cellstr(c);
                end
            end
        end
        used = true;
    catch
        used = false;
    end
end
if ~used
    fid = fopen(csvPath, 'r');
    if fid < 0
        error('read_mixed_csv', 'Unable to open the telemetry file.');
    end
    header = strsplit(strtrim(fgetl(fid)), ',');
    n = numel(header);
    raw = textscan(fid, repmat('%s', 1, n), 'Delimiter', ',');
    fclose(fid);
    m = numel(raw{1});
    numericData = zeros(m, n);
    deviceTags = cell(m, 1);
    for j = 1:n
        numericData(:, j) = str2double(raw{j});
        if strcmpi(strtrim(header{j}), 'DeviceID')
            deviceTags = strtrim(raw{j});
        end
    end
end
header = strtrim(header);
if isempty(deviceTags) || all(cellfun(@isempty, deviceTags))
    error('read_mixed_csv', 'DeviceID column missing.');
end
end
