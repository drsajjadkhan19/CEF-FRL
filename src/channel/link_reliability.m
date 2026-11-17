function phi = link_reliability(sinrDb, floorDb, slope)
% LINK_RELIABILITY  Smooth reliability proxy in the open unit interval.
%
% A logistic function of the margin above the admission floor replaces a
% hard indicator inside the aggregation weights, which avoids injecting a
% discontinuity into the weighting.
if nargin < 3
    slope = 3.0;
end
phi = 1.0 ./ (1.0 + exp(-(sinrDb - floorDb) / slope));
end
