function L = fspl_db(distanceM, carrierHz, exponent)
% FSPL_DB  Close in (CI) path loss with a 1 m free space reference, in dB.
%
% L = 20 log10(4 pi f / c) + 10 n log10(d). With n = 2 this is exactly the
% Friis free space loss. The exponent n = 2.1 is the value measured at
% 142 GHz for directional line-of-sight links in an urban micro-cell (Xing and
% Rappaport, IEEE ICC 2021).
if nargin < 3
    exponent = 2.0;
end
c = 2.99792458e8;
L = 20.0 * log10(4.0 * pi * carrierHz / c) + 10.0 * exponent * log10(distanceM);
end
