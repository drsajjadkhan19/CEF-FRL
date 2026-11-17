function P = ac_unpack(theta, c)
% AC_UNPACK  Flat parameter vector to network matrices.
%
% Shared trunk of two tanh layers, a softmax policy head and two value
% heads (row 1 fast, row 2 slow) of the dual timescale critic.
n = c.stateDim; h = c.hidden; m = c.nActions;
sz = {[h n], [h 1], [h h], [h 1], [m h], [m 1], [2 h], [2 1]};
names = {'W1', 'b1', 'W2', 'b2', 'Wp', 'bp', 'Wv', 'bv'};
o = 0;
for i = 1:numel(sz)
    k = prod(sz{i});
    P.(names{i}) = reshape(theta(o + 1:o + k), sz{i});
    o = o + k;
end
end
