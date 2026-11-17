function c = ac_config()
% AC_CONFIG  Parameters of the learning-level evaluation (federated actor-critic).
%
% Embodied task: indoor navigation of a point robot among circular
% obstacles, with the kinematic limits of a TurtleBot3 Burger (linear speed
% up to 0.22 m/s, angular speed up to 2.84 rad/s) and five range readings.

% ---- reproducibility ---------------------------------------------------
c.seed = 20261103;

% ---- fleet and schedule -------------------------------------------------
c.K = 10;                 % federated clients (robots)
c.rounds = 300;           % aggregation rounds
c.localEpisodes = 2;      % episodes per client per round
c.evalEvery = 10;         % rounds between global policy evaluations
c.evalEpisodes = 40;      % fixed evaluation set size

% ---- environment --------------------------------------------------------
c.arena = 4.0;            % m, square side
c.robotRadius = 0.10;     % m
c.goalRadius = 0.20;      % m
c.dt = 0.25;              % s per control step
c.maxSteps = 100;         % steps per episode
c.vMax = 0.22;            % m/s, TurtleBot3 Burger
c.wMax = 2.84;            % rad/s, TurtleBot3 Burger
% discrete actions [v w] as fractions of the limits
c.actions = [1.0 0.0; 0.7 0.45; 0.7 -0.45; 0.0 0.6; 0.0 -0.6];
c.rayAngles = [-pi/3 -pi/6 0 pi/6 pi/3];
c.rayRange = 1.0;         % m
c.obsMax = 8;             % maximum obstacles per episode
c.obsRadius = [0.15 0.30];
c.dirichletAlpha = 0.5;   % non-IID concentration over four arena zones

% ---- rewards (DTRD) ----------------------------------------------------
c.progressGain = 5.0;
c.stepCost = 0.005;
c.goalBonus = 1.0;
c.collisionPenalty = 1.0;
c.energyGainV = 0.02;
c.energyGainW = 0.01;
c.slowGoalBonus = 0.5;
c.gammaFast = 0.90;
c.gammaSlow = 0.99;
c.dtrdLambda = 0.5;
c.slowEvery = 10;         % slow value head update period N_s

% ---- network ------------------------------------------------------------
c.stateDim = 8;
c.hidden = 354;           % 131,341 parameters (2.10 Mbit in FP16)
c.nActions = size(c.actions, 1);
c.lr = 1.0e-3;            % Adam
c.entropyCoef = 0.01;
c.valueCoef = 0.5;
c.quantBits = 16;         % FP16 upload

% ---- CEF-FRL aggregator -----------------------------------------------
c.sinrAdmitDb = 4.0;
c.deadlineMs = 2.0;       % per-client upload feasibility budget D
c.strictMs = 1.0;         % strict closure bound D_s
c.aggDeadlineMs = 2.0;    % soft aggregation deadline tau_agg
c.stalenessMax = 5;
c.mu = 0.4;               % AGSC decay
c.aPhi = 1.0;             % reliability exponent
c.beta = 0.3;             % non-IID suppressor
c.bS = 2.0;               % starvation priority gain
c.lossAnomalyZ = 2.5;
c.clipNorm = 2.0;         % aggregate update radius, a safeguard above typical norms

% ---- baselines ----------------------------------------------------------
c.proxMu = 0.01;          % FedProx
c.asyncAlpha = 0.6;       % FedAsync mixing
c.asyncA = 0.5;           % FedAsync polynomial staleness exponent
c.buffSize = 3;           % FedBuff buffer size

% ---- edge path delays ---------------------------------------------------
c.edgeProcessMs = 0.06;
c.edgeQueueMsPerClient = 0.012;
c.fogForwardMs = 0.35;

% ---- channel ------------------------------------------------------------
c.bandwidthHz = 2.0e9;
c.useFiniteBlocklength = false;  % normal approximation when true
c.fblEpsilon = 1.0e-5;
c.fblSymbols = 2000;             % channel uses per codeword
c.csvPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'data', 'telemetry_v3.csv');
end
