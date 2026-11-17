function learn = build_learning_problem(tel, cfg, seed)
% BUILD_LEARNING_PROBLEM  Linear policy regression solved by every scheme.
%
% Each client owns a policy parameter vector and observes whitened
% features drawn from its own telemetry. The pooled optimum is available
% in closed form, so the distance to it is measurable and the contraction
% factor of any aggregator can be estimated instead of postulated.
init_substream(seed, 'learning-problem');
d = cfg.featureDim;

thetaStar = [1.20; -0.85; 0.60; 0.45; -0.70; 0.30];
learn.thetaStar = thetaStar(1:d);
learn.theta0 = zeros(d, 1);
learn.d = d;

planes = cell(1, 6);
planes{1} = ones(tel.T, tel.K);
planes{2} = standardise(tel.sinrDb);
planes{3} = standardise(tel.se);
planes{4} = standardise(tel.distance);
planes{5} = tel.blocked;
planes{6} = standardise(tel.loss);
learn.F = whiten_planes(planes(1:d));

% Local optima scatter around the global one with a zero mean offset, so
% the fleet mean is well defined while any subset carries a bias.
drift = cfg.clientDrift * randn(d, tel.K);
drift = drift - repmat(mean(drift, 2), 1, tel.K);
learn.drift = drift;
learn.thetaClient = repmat(learn.thetaStar, 1, tel.K) + drift;

localSkew = mean(tel.loss, 1);
localSkew = localSkew / mean(localSkew);
learn.noiseStd = cfg.observationNoise * localSkew;
learn.covariance = eye(d);
% Dirichlet data skew s_k, one value per client.
learn.skew = kl_to_uniform(dirichlet_partition(tel.K, 10, cfg.dirichletAlpha));
learn.thetaOpt = fleet_optimum(learn.F, learn.thetaClient);
learn.heterogeneity = norm(learn.thetaOpt - mean(learn.thetaClient, 2));
end
