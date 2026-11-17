function n = blockage_dwell_frames(widthM, speedMps, frameS)
% BLOCKAGE_DWELL_FRAMES  Mean self-blockage dwell from transit geometry.
%
% A blocker of the given width crossing the beam at the given speed
% occludes it for width divided by speed seconds. Expressing that in
% frames gives the dwell length. A 0.40 m blocker at 1.07 m/s gives the
% measured 375 ms, which is 37.5 frames of 10 ms.
n = (widthM / speedMps) / frameS;
end
