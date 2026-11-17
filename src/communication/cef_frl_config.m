function cfg = cef_frl_config()
% CEF_FRL_CONFIG  Parameters of the communication-level evaluation.
%
% The source of each parameter is marked in the comments:
%   M  published measurement         S  standard or device datasheet
%   A  design assumption, varied in the sensitivity analysis
%   L  common choice in the literature

% ---- reproducibility -------------------------------------------------
cfg.seed = 20260917;
cfg.csvPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'data', 'telemetry_v3.csv');

% ---- scenario --------------------------------------------------------
cfg.numDevices = 5;
cfg.numFrames = 1000;
cfg.frameDurationS = 10.0e-3;          % A

% ---- sub-THz radio ---------------------------------------------------
cfg.carrierHz = 0.3e12;                % A
cfg.bandwidthHz = 2.0e9;               % A
% S. ITU-R P.676 line-by-line at 1013.25 hPa, 15 C and 7.5 g/m^3.
cfg.absorptionDbPerM = 0.005203;
% S. Same model at relative humidity 30 to 90 percent (sensitivity analysis).
cfg.absorptionTable = [0.30 0.002496; 0.50 0.004362; 0.60 0.005360; ...
                       0.75 0.006940; 0.90 0.008618];
cfg.txPowerDbm = 23.0;                 % A
cfg.txGainDbi = 20.0;                  % A
cfg.rxGainDbi = 25.0;                  % A
cfg.noiseDensityDbmPerHz = -174.0;     % S, thermal noise at 290 K
cfg.noiseFigureDb = 7.0;               % A
cfg.sidelobeIsolationDb = 32.0;        % A
cfg.blockagePenaltyDb = 30.0;          % M, 8 to 56 dB measured at 156 GHz and 300 GHz
% M. Close-in path loss exponent and shadowing at 142 GHz, urban micro-cell,
% line of sight (Xing and Rappaport, IEEE ICC 2021).
cfg.pathLossExponent = 2.1;
cfg.shadowSigmaDb = 2.8;

% ---- geometry --------------------------------------------------------
cfg.areaSizeM = 200.0;
cfg.minLinkDistanceM = 1.0;

% ---- human blockage --------------------------------------------------
cfg.blockerWidthM = 0.40;              % A
cfg.blockerSpeedMps = 0.40 / 0.375;    % M, 375 ms blockage dwell measured at 156 GHz
cfg.blockageProbability = 0.45;        % A
cfg.blockageDwellFrames = blockage_dwell_frames(cfg.blockerWidthM, ...
    cfg.blockerSpeedMps, cfg.frameDurationS);

% ---- deadlines -------------------------------------------------------
% The strict bound applies to the communication path: upload, edge
% processing, edge queueing and edge-to-fog forwarding. Local training
% runs on the slower timescale and is not part of the round closure.
cfg.strictCommBoundMs = 1.0;           % strict bound D_s
cfg.urllcDeadlineMs = 2.0;             % admission budget D
% Finite blocklength rate model
cfg.fblEpsilon = 1.0e-5;               % block error target
cfg.fblSymbols = 2000;                 % channel uses per codeword
cfg.implGapDb = 3.0;                   % implementation gap

% ---- edge and fog delays ---------------------------------------------
cfg.edgeProcessMs = 0.06;              % A
cfg.edgeQueueMsPerClient = 0.012;      % A
cfg.fogForwardMs = 0.35;               % A
cfg.fogJitterMs = 0.05;                % A

% ---- edge device (NVIDIA Jetson Nano) --------------------------------
% M. 61 measured rows: training cycle mean 60.46 ms, standard deviation
% 10.77 ms, fitted lognormal log-mean 4.0854 and log-sigma 0.1857;
% CPU load mean 5.55 percent, standard deviation 3.78 percent.
cfg.trainCycleLogMean = 4.0854;
cfg.trainCycleLogSigma = 0.1857;
cfg.cpuLoadMean = 0.0555;
cfg.cpuLoadSigma = 0.0378;
cfg.jetsonIdleW = 1.25;                % S
cfg.jetsonPeakW = 5.00;                % S
cfg.powerAmplifierEfficiency = 0.28;   % A

% ---- aggregation -----------------------------------------------------
cfg.modelParameters = 131072;
cfg.quantizationBits = 16;
cfg.modelBits = cfg.modelParameters * cfg.quantizationBits;
cfg.stalenessMax = 5;                  % staleness cap Delta_max
cfg.agscDecayMu = 0.4;                 % AGSC decay mu
cfg.reliabilityExponent = 1.0;         % reliability exponent a_phi
cfg.nonIidSuppressBeta = 0.3;          % data skew suppression beta
cfg.starvationBoost = 2.0;             % starvation priority gain b_s
cfg.sinrAdmitDb = 4.0;                 % A, admission floor
cfg.lossAnomalyZ = 2.5;                % MAD loss test threshold
cfg.gradClipNorm = 4.0;
cfg.greedyFraction = 0.6;              % share of clients the greedy scheduler admits
cfg.serverMomentum = 0.0;
cfg.momentumForBaselines = false;

% ---- local learning --------------------------------------------------
cfg.featureDim = 6;
cfg.learningRate = 2.0e-2;
cfg.localSteps = 4;
cfg.localBatch = 64;
cfg.replayCapacity = 4096;
cfg.observationNoise = 0.05;
cfg.clientDrift = 0.25;
cfg.rewardScale = 1.0;
cfg.dtrdLambda = 0.1;
cfg.dirichletAlpha = 0.5;              % L

% ---- Monte Carlo and sweeps ------------------------------------------
% The channel traces stay fixed; every seed resamples the learning noise.
cfg.mcSeeds = 100;                     % seeds of the main comparison
cfg.sweepSeeds = 20;                   % seeds per point of the rate and blockage sweeps
cfg.blockageGrid = 0:0.1:0.70;         % stationary blockage probabilities
cfg.sensFrames = 400;                  % frames per sensitivity evaluation
end
