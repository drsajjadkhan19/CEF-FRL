function kappa = absorption_from_humidity(cfg, relativeHumidity)
% ABSORPTION_FROM_HUMIDITY  Molecular absorption coefficient in dB per metre.
%
% Values come from ITU-R P.676 evaluated at 0.3 THz, 1013.25 hPa and
% 15 degrees Celsius over a range of water vapour densities, then stored
% as a table so no toolbox is required. Linear interpolation between
% tabulated points is adequate because the coefficient is close to linear
% in water vapour density inside a transparency window.
h = cfg.absorptionTable(:, 1);
k = cfg.absorptionTable(:, 2);
rh = min(max(relativeHumidity, h(1)), h(end));
kappa = interp1(h, k, rh, 'linear');
end
