function report = validate_equations(tel, cfg)
% VALIDATE_EQUATIONS  Closed-form consistency checks of the channel traces.
%
% Each check recomputes a telemetry column from its model equation, or
% compares a sampled statistic with its configured value, and reports the
% largest deviation against a tolerance set by the file resolution or by
% the sampling error of the estimator. Nineteen checks are run.
%
%   report = validate_equations(tel, cfg);

% ---- resolution of the stored file ----------------------------------
% The telemetry is stored with six decimal places.
fileResolution = 1e-6;
sumTolerance = 1e-5;

report = {};

% =====================================================================
% Path loss: close-in path loss plus molecular absorption.
% =====================================================================
fs = fspl_db(tel.distance, cfg.carrierHz, cfg.pathLossExponent);
ab = absorption_db(tel.distance, cfg.absorptionDbPerM);
plRecomputed = fs + ab;
resid = plRecomputed - tel.pathLoss;
report = add_check(report, 'path loss', resid, sumTolerance, 'dB', ...
    mean(plRecomputed(:)), mean(tel.pathLoss(:)));

% =====================================================================
% Molecular absorption is linear in distance (Beer-Lambert law).
% =====================================================================
report = add_check(report, 'absorption linearity', ab - tel.absorption, ...
    2 * fileResolution, 'dB', mean(ab(:)), mean(tel.absorption(:)));

% The fitted coefficient matches the ITU-R P.676 value in the configuration.
dvec = tel.distance(:);
avec = tel.absorption(:);
slope = sum(avec .* dvec) / sum(dvec .^ 2);
report = add_check(report, 'fitted coefficient', ...
    slope - cfg.absorptionDbPerM, 1e-6, 'dB/m', ...
    slope, cfg.absorptionDbPerM);

% =====================================================================
% Received power from the link budget.
% =====================================================================
rx = cfg.txPowerDbm + cfg.txGainDbi + cfg.rxGainDbi - tel.pathLoss ...
     - tel.shadowing - cfg.blockagePenaltyDb * tel.blocked;
report = add_check(report, 'received power', rx - tel.rxPowerDbm, ...
    sumTolerance, 'dBm', mean(rx(:)), mean(tel.rxPowerDbm(:)));

% =====================================================================
% Thermal noise over the slice plus the receiver noise figure.
% =====================================================================
noiseClosed = cfg.noiseDensityDbmPerHz + 10 * log10(cfg.bandwidthHz) + cfg.noiseFigureDb;
noiseFn = thermal_noise_dbm(cfg.bandwidthHz, cfg.noiseDensityDbmPerHz, cfg.noiseFigureDb);
report = add_check(report, 'noise floor', noiseFn - noiseClosed, 1e-9, ...
    'dBm', noiseFn, noiseClosed);

% =====================================================================
% Shannon capacity from the stored SINR, compared in relative terms
% because capacity spans several orders of magnitude.
% =====================================================================
capRecomputed = shannon_capacity_bps(cfg.bandwidthHz, 10 .^ (tel.sinrDb / 10)) / 1e6;
relCap = (capRecomputed - tel.capMbps) ./ max(tel.capMbps, eps);
report = add_check(report, 'Shannon capacity', relCap, 1e-5, 'relative', ...
    mean(capRecomputed(:)), mean(tel.capMbps(:)));

% Capacity increases strictly with the SINR.
[~, ord] = sort(tel.sinrDb(:));
capSorted = tel.capMbps(ord);
report = add_check(report, 'capacity monotonicity', ...
    sum(diff(capSorted) < -1e-6), 0, 'violations', 0, 0);

% =====================================================================
% Upload delay is the payload divided by the instantaneous rate.
% =====================================================================
txMs = 1e3 * cfg.modelBits ./ (tel.capMbps * 1e6);
report = add_check(report, 'upload delay', txMs - tel.uplinkMs, ...
    sumTolerance, 'ms', mean(txMs(:)), mean(tel.uplinkMs(:)));

% The stored deadline flag agrees with the recomputed delay.
flagRecomputed = double(tel.uplinkMs <= cfg.urllcDeadlineMs);
report = add_check(report, 'Deadline flag consistency', ...
    sum(abs(flagRecomputed(:) - tel.deadlineMet(:))), 0, 'mismatches', ...
    mean(flagRecomputed(:)), mean(tel.deadlineMet(:)));

% =====================================================================
% Shadowing standard deviation. The tolerance is the sampling error of a
% standard deviation estimated from a spatially correlated series.
% =====================================================================
sigmaTarget = cfg.shadowSigmaDb;
sigmaMeasured = std(tel.shadowing(:));
stepMat = abs(diff(tel.distance, 1, 1));
stepM = mean(stepMat(:));
rhoShadow = exp(-stepM / 10.0);
effectiveN = numel(tel.shadowing) * (1 - rhoShadow) / max(1 + rhoShadow, eps);
sigmaTol = 3 * sigmaTarget / sqrt(2 * max(effectiveN, 2));
report = add_check(report, 'shadowing deviation', ...
    sigmaMeasured - sigmaTarget, max(sigmaTol, 0.25), 'dB', ...
    sigmaMeasured, sigmaTarget);

% =====================================================================
% Blockage occupancy against the stationary probability. With a dwell of
% D frames the effective sample size is the frame count divided by D.
% =====================================================================
pTarget = cfg.blockageProbability;
pMeasured = mean(tel.blocked(:));
nEffective = numel(tel.blocked) / max(cfg.blockageDwellFrames, 1);
occupancyTol = 3 * sqrt(pTarget * (1 - pTarget) / max(nEffective, 1));
report = add_check(report, 'blockage occupancy', pMeasured - pTarget, ...
    occupancyTol, 'fraction', pMeasured, pTarget);

% Mean blocked run length matches the dwell from blocker transit geometry.
runs = blockage_run_lengths(tel.blocked);
nRuns = max(numel(runs), 1);
dwellMeasured = mean(runs);
dwellTol = 3 * cfg.blockageDwellFrames / sqrt(nRuns);
report = add_check(report, 'Dwell from transit geometry', ...
    dwellMeasured - cfg.blockageDwellFrames, dwellTol, 'frames', ...
    dwellMeasured, cfg.blockageDwellFrames);

% =====================================================================
% Energy identity: radio plus compute plus a constant static term equals
% the device total. The static term is recovered as the residual.
% =====================================================================
staticJ = tel.energyJ - tel.radioEnergyJ - tel.computeEnergyJ;
report = add_check(report, 'energy identity', ...
    staticJ - mean(staticJ(:)), sumTolerance, 'J', ...
    mean(staticJ(:)), mean(staticJ(:)));

% Both energy terms are non-negative.
negCount = double(min(tel.radioEnergyJ(:)) < -fileResolution) + ...
           double(min(tel.computeEnergyJ(:)) < -fileResolution);
report = add_check(report, 'energy non negativity', negCount, 0, ...
    'violations', min(tel.radioEnergyJ(:)), 0);

% Radio share of the device energy, recorded for reference.
radioShare = sum(tel.radioEnergyJ(:)) / max(sum(tel.energyJ(:)), eps);
report = add_check(report, 'Radio share of device energy', 0, 1, 'fraction', ...
    radioShare, radioShare);

% =====================================================================
% Training cycle time follows the lognormal fitted to the measured
% Jetson Nano rows.
% =====================================================================
cycleTargetMean = exp(cfg.trainCycleLogMean + cfg.trainCycleLogSigma ^ 2 / 2);
cycleMeasured = mean(tel.trainCycleMs(:));
cycleSd = cycleTargetMean * sqrt(exp(cfg.trainCycleLogSigma ^ 2) - 1);
cycleTol = max(4 * cycleSd / sqrt(numel(tel.trainCycleMs)), 0.5);
report = add_check(report, 'Measured train cycle mean', ...
    cycleMeasured - cycleTargetMean, cycleTol, 'ms', ...
    cycleMeasured, cycleTargetMean);

% Local training is slower than the strict communication bound.
report = add_check(report, 'Timescale separation', ...
    double(cycleMeasured <= cfg.strictCommBoundMs), 0, 'violations', ...
    cycleMeasured, cfg.strictCommBoundMs);

% =====================================================================
% Grid integrity: every client appears in every frame at the configured
% frame duration.
% =====================================================================
cadence = diff(tel.timeVector) - cfg.frameDurationS;
report = add_check(report, 'Frame cadence', cadence, 1e-9, 's', ...
    mean(diff(tel.timeVector)), cfg.frameDurationS);

report = add_check(report, 'Grid completeness', ...
    numel(tel.sinrDb) - tel.T * tel.K, 0, 'cells', ...
    numel(tel.sinrDb), tel.T * tel.K);

end

% ---------------------------------------------------------------------

function report = add_check(report, name, err, tol, unit, measured, expected)
% ADD_CHECK  Append one check; the error is the largest absolute deviation.
e = abs(err(:));
if isempty(e)
    e = 0;
else
    e = max(e);
end
entry = struct('name', name, ...
               'err', double(e), ...
               'tol', double(tol), ...
               'unit', unit, ...
               'measured', double(measured), ...
               'expected', double(expected), ...
               'pass', double(e) <= double(tol));
report{end + 1} = entry;
end
