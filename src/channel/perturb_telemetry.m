function telP = perturb_telemetry(tel, cfgBase, cfgNew, whichParam)
% PERTURB_TELEMETRY  Recompute the affected telemetry columns analytically.
%
% Rather than regenerating the dataset for every sensitivity point, the
% columns that depend on the perturbed parameter are recomputed in closed
% form from the stored geometry and shadowing, which keeps the mobility
% and blockage realisations identical across the sweep.
telP = tel;
recompute = ismember(whichParam, [1 2 3 4 5 7 8]);
if ~recompute
    return;   % the admission floor changes no physical column
end
blocked = tel.blocked;
if whichParam == 2
    % Two state Markov chain with the configured dwell, so the perturbed
    % blockage keeps the temporal clustering of the baseline.
    init_substream(cfgBase.seed + 4242, 'sens-blockage');
    L = cfgBase.blockageDwellFrames; pb = cfgNew.blockageProbability;
    pRec = 1 / L; pBlk = min(pb / (L * (1 - pb)), 1);
    blocked = zeros(tel.T, tel.K);
    s = rand(1, tel.K) < pb;
    for t = 1:tel.T
        u = rand(1, tel.K);
        s = (s & ~(u < pRec)) | (~s & (u < pBlk));
        blocked(t, :) = s;
    end
end
shadow = tel.shadowing;
if whichParam == 3
    shadow = tel.shadowing * (cfgNew.shadowSigmaDb / cfgBase.shadowSigmaDb);
end
pl = fspl_db(tel.distance, cfgBase.carrierHz, cfgNew.pathLossExponent) + ...
     absorption_db(tel.distance, cfgNew.absorptionDbPerM);
rx = cfgNew.txPowerDbm + cfgBase.txGainDbi + cfgBase.rxGainDbi ...
     - pl - shadow - cfgNew.blockagePenaltyDb * blocked;
rxMw = 10.^(rx / 10);
noiseMw = 10^(thermal_noise_dbm(cfgBase.bandwidthHz, ...
    cfgBase.noiseDensityDbmPerHz, cfgBase.noiseFigureDb) / 10);
iso = 10^(-cfgNew.sidelobeIsolationDb / 10);
interference = (repmat(sum(rxMw, 2), 1, tel.K) - rxMw) * iso;
sinrLin = rxMw ./ (noiseMw + interference);
telP.blocked = blocked;
telP.shadowing = shadow;
telP.pathLoss = pl;
telP.absorption = absorption_db(tel.distance, cfgNew.absorptionDbPerM);
telP.rxPowerDbm = rx;
telP.sinrDb = 10 * log10(sinrLin);
telP.capMbps = shannon_capacity_bps(cfgBase.bandwidthHz, sinrLin) / 1e6;
telP.uplinkMs = 1e3 * cfgBase.modelBits ./ (telP.capMbps * 1e6);
telP.deadlineMet = double(telP.uplinkMs <= cfgBase.urllcDeadlineMs);
telP.se = log2(1 + sinrLin);
end
