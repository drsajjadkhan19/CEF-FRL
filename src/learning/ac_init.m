function theta = ac_init(c)
% AC_INIT  Orthogonal-scale random initialisation of the actor-critic.
n = c.stateDim; h = c.hidden; m = c.nActions;
W1 = randn(h, n) * sqrt(1 / n);
W2 = randn(h, h) * sqrt(1 / h);
Wp = randn(m, h) * 0.01;
Wv = randn(2, h) * sqrt(1 / h);
theta = [W1(:); zeros(h, 1); W2(:); zeros(h, 1); Wp(:); zeros(m, 1); ...
         Wv(:); zeros(2, 1)];
end
