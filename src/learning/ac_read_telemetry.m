function tel = ac_read_telemetry(path)
% AC_READ_TELEMETRY  Frames by devices matrices from the telemetry CSV.
fid = fopen(path, 'r');
header = strsplit(strtrim(fgetl(fid)), ',');
fmt = repmat('%f', 1, numel(header));
di = find(strcmp(header, 'DeviceID'));
fmt(2 * di) = 's';
C = textscan(fid, fmt, 'Delimiter', ',');
fclose(fid);
col = @(n) C{find(strcmp(header, n))};
step = col('TimeStep'); dev = col('DeviceID');
[~, ~, f] = unique(step); [~, ~, k] = unique(dev);
T = max(f); K = max(k); idx = [f(:) k(:)];   % row and column subscripts
g = @(n) accumarray(idx, col(n), [T K]);
tel.sinrDb = g('SINR_dB');
tel.blocked = g('BlockageFlag');
tel.computeJ = g('ComputeEnergy_Joule');
tel.trainMs = g('TrainCycle_ms');
tel.radioJ = g('RadioEnergy_Joule');
end
