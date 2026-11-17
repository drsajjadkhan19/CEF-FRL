function tel = load_telemetry(csvPath)
% LOAD_TELEMETRY  Import the telemetry CSV and reshape to frames by devices.
%
% readtable is used when available and a low-level parser otherwise.
if exist(csvPath, 'file') ~= 2
    error('load_telemetry', ['Telemetry file not found. Expected ' csvPath]);
end
[header, data, tags] = read_mixed_csv(csvPath);
col = @(name) data(:, find_column(header, name));

steps = col('TimeStep');
uSteps = unique(steps);
uDev = unique(tags);
T = numel(uSteps);
K = numel(uDev);
if T * K ~= size(data, 1)
    error('load_telemetry', 'Telemetry grid is ragged.');
end
rowFrame = zeros(size(steps));
for i = 1:T
    rowFrame(steps == uSteps(i)) = i;
end
rowDev = zeros(size(steps));
for i = 1:K
    rowDev(strcmp(tags, uDev{i})) = i;
end
idx = sub2ind([T K], rowFrame, rowDev);
g = @(name) scatter_grid(col(name), idx, T, K);

tel.T = T;
tel.K = K;
tel.devices = uDev;
tel.timeSeconds = g('TimeSeconds');
tel.timeVector = tel.timeSeconds(:, 1);
tel.sinrDb = g('SINR_dB');
tel.capMbps = g('LinkCapacity_Mbps');
tel.uplinkMs = g('UplinkLatency_ms');
tel.loss = g('LocalTrainingLoss');
tel.energyJ = g('Energy_Joule');
tel.radioEnergyJ = g('RadioEnergy_Joule');
tel.computeEnergyJ = g('ComputeEnergy_Joule');
tel.trainCycleMs = g('TrainCycle_ms');
tel.blocked = g('BlockageFlag');
tel.distance = g('Distance_m');
tel.deadlineMet = g('DeadlineMet');
tel.pathLoss = g('PathLoss_dB');
tel.absorption = g('AbsorptionLoss_dB');
tel.shadowing = g('Shadowing_dB');
tel.rxPowerDbm = g('RxPower_dBm');
tel.se = log2(1 + 10.^(tel.sinrDb / 10));
end
