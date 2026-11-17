function flag = ac_mad_flag(loss, zMax)
% AC_MAD_FLAG  Robust anomaly test on local losses (median absolute deviation).
med = median(loss);
mad = max(1.4826 * median(abs(loss - med)), 1e-12);
flag = abs(loss - med) / mad > zMax;
end
