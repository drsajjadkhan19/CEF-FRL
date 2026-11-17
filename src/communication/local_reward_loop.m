function rew = local_reward_loop(tel, cfg)
% LOCAL_REWARD_LOOP  Fast and slow rewards of the dual-timescale reward decomposition.
%
% The fast term rewards spectral efficiency and penalises delay relative
% to the deadline. The slow term rewards energy economy and local loss
% reduction and credits deadline compliance. Splitting them prevents the
% fast gradients from suppressing the slow objective.
seNorm = tel.se / max(tel.se(:));
latNorm = min(tel.uplinkMs / cfg.strictCommBoundMs, 4);
enNorm = tel.energyJ / max(tel.energyJ(:));
lossNorm = tel.loss / max(tel.loss(:));

rew.fast = 0.75 * seNorm - 0.25 * latNorm;
rew.slow = -0.5 * enNorm - 0.5 * lossNorm + 0.5 * tel.deadlineMet;
rew.total = rew.fast + cfg.dtrdLambda * rew.slow;
rew.seNorm = seNorm;
end
