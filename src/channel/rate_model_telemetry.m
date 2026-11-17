function telR = rate_model_telemetry(tel, cfg, model)
% RATE_MODEL_TELEMETRY  Recompute capacity and upload delay under a rate model.
%
%   'shannon'  Shannon capacity of the slice
%   'fbl'      normal approximation of Polyanskiy, Poor and Verdu (2010),
%              R = W [log2(1+g) - sqrt(V/n) Qinv(eps) log2(e)], with
%              dispersion V = 1 - (1+g)^-2, n channel uses per codeword and
%              block error target eps
%   'fbl-gap'  as 'fbl' with an additional implementation SNR gap of
%              cfg.implGapDb, which stands for practical coding and
%              hardware losses of a sub-THz front end
% The SINR column, and therefore the admission floor, is unchanged.
telR = tel;
g = 10 .^ (tel.sinrDb / 10);
switch model
    case 'shannon'
        se = log2(1 + g);
    case {'fbl', 'fbl-gap'}
        if strcmp(model, 'fbl-gap')
            g = g * 10^(-cfg.implGapDb / 10);
        end
        V = 1 - (1 + g).^(-2);
        qinv = sqrt(2) * erfcinv(2 * cfg.fblEpsilon);
        se = log2(1 + g) - sqrt(V / cfg.fblSymbols) * qinv * log2(exp(1));
        se = max(se, 1e-6);
    otherwise
        error('rate_model_telemetry:model', 'Unknown rate model %s.', model);
end
telR.capMbps = cfg.bandwidthHz * se / 1e6;
telR.uplinkMs = 1e3 * cfg.modelBits ./ (telR.capMbps * 1e6);
telR.deadlineMet = double(telR.uplinkMs <= cfg.urllcDeadlineMs);
telR.se = se;
end
