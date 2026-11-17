function rho = estimate_contraction(errTrace)
% ESTIMATE_CONTRACTION  Contraction factor from the transient phase.
%
% Fitting the whole trace would average the transient together with the
% stochastic floor that every method reaches, driving the estimate toward
% one regardless of the aggregator, so the fit is restricted to the
% interval where the contraction condition binds.
errTrace = errTrace(:);
if isempty(errTrace) || errTrace(1) <= 0
    rho = NaN; return;
end
last = find(errTrace > 0.15 * errTrace(1), 1, 'last');
if isempty(last)
    last = numel(errTrace);
end
last = max(min(last, numel(errTrace)), 10);
idx = (1:last)';
ok = errTrace(idx) > 0;
if sum(ok) < 10
    rho = NaN; return;
end
p = polyfit(idx(ok), log(errTrace(idx(ok))), 1);
rho = exp(p(1));
end
