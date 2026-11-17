function v = clip_norm(v, bound)
% CLIP_NORM  Project a vector onto the ball of the given radius.
n = norm(v);
if n > bound && n > 0
    v = v * (bound / n);
end
end
