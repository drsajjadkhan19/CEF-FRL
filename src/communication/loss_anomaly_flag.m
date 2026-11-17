function flag = loss_anomaly_flag(lossRow, zMax)
% LOSS_ANOMALY_FLAG  Robust anomaly detector on the median absolute deviation.
%
% The median absolute deviation replaces a mean and variance test because
% the latter breaks down when several clients degrade at once, which is
% the common case under correlated blockage.
med = median(lossRow);
dev = median(abs(lossRow - med));
scale = 1.4826 * dev;
if scale < 1e-9
    flag = false(size(lossRow));
    return;
end
flag = abs(lossRow - med) / scale > zMax;
end
