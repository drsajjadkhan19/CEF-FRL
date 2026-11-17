function P = thermal_noise_dbm(bandwidthHz, densityDbmPerHz, noiseFigureDb)
% THERMAL_NOISE_DBM  Noise power over the slice, including the receiver figure.
P = densityDbmPerHz + 10.0 * log10(bandwidthHz) + noiseFigureDb;
end
