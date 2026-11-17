function ch = ac_channel(c, payloadBits, seed)
% AC_CHANNEL  Per-client sub-THz channel trace for the learning-level evaluation.
%
% Client k replays the SINR, blockage and device energy columns of
% telemetry device mod(k-1,5)+1 with a client-specific time offset and a
% fixed large-scale offset. Upload delay is the model payload divided by the achievable
% rate, which is the Shannon capacity or, when c.useFiniteBlocklength is
% set, the normal approximation of Polyanskiy, Poor and Verdu (2010) at
% block error target c.fblEpsilon over c.fblSymbols channel uses.
rng(seed);
K = c.K; T = c.rounds;
if exist(c.csvPath, 'file') == 2
    tel = ac_read_telemetry(c.csvPath);
else
    error('ac_channel:noTelemetry', 'Telemetry file %s not found.', c.csvPath);
end
Ttel = size(tel.sinrDb, 1); Ktel = size(tel.sinrDb, 2);
ch.sinrDb = zeros(T, K); ch.blocked = zeros(T, K);
ch.computeJ = zeros(T, K); ch.trainMs = zeros(T, K);
for k = 1:K
    src = 1 + mod(k - 1, Ktel);
    shift = mod(97 * (k - 1), Ttel);
    rows = 1 + mod((0:T - 1)' + shift, Ttel);
    offset = 1.5 * randn() - 0.6 * (k / K);
    blk = tel.blocked(rows, src);
    clearDb = tel.sinrDb(rows, src) + 30.0 * blk;   % remove blockage loss
    ch.sinrDb(:, k) = clearDb + offset - 30.0 * blk;
    ch.blocked(:, k) = blk;
    ch.computeJ(:, k) = tel.computeJ(rows, src);
    ch.trainMs(:, k) = tel.trainMs(rows, src);
end
% Optional uneven blockage: the first c.heavyClients robots are blocked
% with stationary probability c.pbHeavy and the others with c.pbLight,
% each as a two-state Markov chain with the measured mean dwell.
if isfield(c, 'heavyClients') && c.heavyClients > 0
    L = c.blockDwellFrames;
    for k = 1:K
        if k <= c.heavyClients, pb = c.pbHeavy; else, pb = c.pbLight; end
        pRec = 1 / L; pBlk = min(pb / (L * (1 - pb)), 1);
        s = rand() < pb; nb = zeros(T, 1);
        for t = 1:T
            u = rand();
            if s, s = ~(u < pRec); else, s = u < pBlk; end
            nb(t) = s;
        end
        ch.sinrDb(:, k) = ch.sinrDb(:, k) + 30.0 * ch.blocked(:, k) - 30.0 * nb;
        ch.blocked(:, k) = nb;
    end
end
gam = 10 .^ (ch.sinrDb / 10);
se = log2(1 + gam);
if c.useFiniteBlocklength
    Vd = 1 - 1 ./ (1 + gam).^2;                 % channel dispersion, nats^2
    qinv = sqrt(2) * erfcinv(2 * c.fblEpsilon);
    se = se - sqrt(Vd / c.fblSymbols) * qinv / log(2);
    se = max(se, 1e-6);
end
ch.rateBps = c.bandwidthHz * se;
ch.txMs = 1e3 * payloadBits ./ ch.rateBps;
ch.feasible = (ch.sinrDb >= c.sinrAdmitDb) & (ch.txMs <= c.deadlineMs);
% radio energy, 23 dBm at 28 percent amplifier efficiency for the airtime
ch.radioJ = (10^((23 - 30) / 10) / 0.28) * ch.txMs / 1e3;
end
