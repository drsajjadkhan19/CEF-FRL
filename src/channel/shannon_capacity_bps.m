function C = shannon_capacity_bps(bandwidthHz, sinrLinear)
% SHANNON_CAPACITY_BPS  Continuous Shannon capacity of the slice.
C = bandwidthHz * log2(1.0 + sinrLinear);
end
