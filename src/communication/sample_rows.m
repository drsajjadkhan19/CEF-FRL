function rows = sample_rows(t, batch, capacity)
% SAMPLE_ROWS  Draw a local mini batch from the client replay buffer.
%
% The buffer holds the most recent frames up to its capacity and the batch
% is drawn uniformly from it. Sampling a short recent window instead would
% leave the batch second moment nearly rank deficient along some
% directions, and the iterate then random walks rather than contracting.
lo = max(1, t - capacity + 1);
span = t - lo + 1;
rows = lo + min(span - 1, floor(span * rand(batch, 1)));
end
