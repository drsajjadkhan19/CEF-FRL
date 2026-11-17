function L = absorption_db(distanceM, kappaDbPerM)
% ABSORPTION_DB  Molecular absorption loss in dB.
%
% A coefficient stated in dB per metre is already the logarithmic form of
% the Beer and Lambert transmittance, so the loss is strictly linear in
% distance.
L = kappaDbPerM * distanceM;
end
