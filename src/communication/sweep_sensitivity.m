function sens = sweep_sensitivity(tel, rew, learn, cfg)
% SWEEP_SENSITIVITY  One-at-a-time sensitivity to eight channel and design parameters.
%
% Each parameter is moved to a low and a high setting while the others stay
% at the baseline, and CEF-FRL and synchronous FedAvg are compared again.
% Ranges. Blockage depth spans the measured 8 to 56 dB (Shurakov 2023 at
% 156 GHz, Galeote-Cazorla 2024 at 75 to 215 GHz). The path loss exponent
% spans the measured LOS directional values 1.9 to 2.25 (NYU 142 GHz,
% SJTU 300 GHz) widened slightly. Shadowing spans 1.0 to 6.0 dB around the
% measured 1.9 to 2.9 dB.
names = {'absorption dB/m', 'blockage probability', 'shadowing dB', ...
         'sidelobe isolation dB', 'transmit power dBm', 'admission floor dB', ...
         'blockage depth dB', 'path loss exponent'};
lowHigh = [absorption_from_humidity(cfg, 0.30) absorption_from_humidity(cfg, 0.90); ...
           0.20 0.70; 1.0 6.0; 25.0 40.0; 17.0 26.0; 0.0 8.0; 8.0 56.0; 1.9 2.4];
sens.names = names;
sens.lowHigh = lowHigh;
sens.metricNames = {'CEF-FRL mean latency ms', 'CEF-FRL compliance', ...
                    'radio energy saving', 'uplink saving'};
nP = numel(names);
sens.low = zeros(nP, 4);
sens.high = zeros(nP, 4);
sens.orderingHolds = true(nP, 2);

base = cfg; base.numFrames = cfg.sensFrames;
for p = 1:nP
    for side = 1:2
        lc = base;
        v = lowHigh(p, side);
        switch p
            case 1, lc.absorptionDbPerM = v;
            case 2, lc.blockageProbability = v;
            case 3, lc.shadowSigmaDb = v;
            case 4, lc.sidelobeIsolationDb = v;
            case 5, lc.txPowerDbm = v;
            case 6, lc.sinrAdmitDb = v;
            case 7, lc.blockagePenaltyDb = v;
            case 8, lc.pathLossExponent = v;
        end
        telP = perturb_telemetry(tel, cfg, lc, p);
        telP = truncate_telemetry(telP, cfg.sensFrames);
        rewP = local_reward_loop(telP, lc);
        learnP = build_learning_problem(telP, lc, cfg.seed + 11);
        a = run_federated_scheme(telP, rewP, learnP, lc, 'CEF-FRL');
        b = run_federated_scheme(telP, rewP, learnP, lc, 'SyncFedAvg');
        m = [mean(a.latency), a.commCompliance, ...
             1 - a.radioEnergyCum(end) / max(b.radioEnergyCum(end), 1e-12), ...
             1 - a.uploadGbit / max(b.uploadGbit, 1e-12)];
        if side == 1, sens.low(p, :) = m; else, sens.high(p, :) = m; end
        sens.orderingHolds(p, side) = (mean(a.latency) < mean(b.latency)) && ...
                                      (a.uploadGbit < b.uploadGbit);
    end
end
sens.range = abs(sens.high - sens.low);
end
