function ok = link_budget_ok(sinrDbRow, capMbpsRow, cfg)
% LINK_BUDGET_OK  Admission gate on the instantaneous link budget.
%
% A client is feasible when its ratio clears the admission floor and the
% model payload fits inside the URLLC budget at the instantaneous rate.
capBps = capMbpsRow * 1e6;
txMs = 1e3 * cfg.modelBits ./ max(capBps, 1);
ok = (sinrDbRow >= cfg.sinrAdmitDb) & (txMs <= cfg.urllcDeadlineMs);
end
