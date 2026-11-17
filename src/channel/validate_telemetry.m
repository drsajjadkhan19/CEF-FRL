function validate_telemetry(tel, cfg)
% VALIDATE_TELEMETRY  Structural assertions on the imported streams.
n = tel.T * tel.K;
fields = {'sinrDb','capMbps','uplinkMs','loss','energyJ','radioEnergyJ', ...
          'computeEnergyJ','trainCycleMs','distance','pathLoss'};
for i = 1:numel(fields)
    v = tel.(fields{i});
    if numel(v) ~= n
        error('validate_telemetry', ['Wrong element count in ' fields{i}]);
    end
    if ~all(isfinite(v(:)))
        error('validate_telemetry', ['Non finite values in ' fields{i}]);
    end
end
if any(tel.capMbps(:) <= 0)
    error('validate_telemetry', 'Capacity must be strictly positive.');
end
if any(tel.distance(:) < cfg.minLinkDistanceM - 1e-9)
    error('validate_telemetry', 'Distance below the configured guard.');
end
dt = diff(tel.timeVector);
if max(abs(dt - cfg.frameDurationS)) > 1e-9
    error('validate_telemetry', ...
        'Frame cadence in the file disagrees with the configured frame duration.');
end
end
