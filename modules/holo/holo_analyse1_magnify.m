function iDiffMagnified = holo_analyse1_magnify(iDiff, mag)
% HOLO_ANALYSE1_MAGNIFY Summary of this function goes here
%   Detailed explanation goes here

%% Magnify
n = size(iDiff, 1);
m = size(iDiff, 2);
if mag>1
    [ixx, iyy]      = meshgrid(1/mag:1/mag:m, 1/mag:1/mag:n);
    iDiffMagnified  = interp2(iDiff, ixx, iyy); % interpolated version of difference image
else
    iDiffMagnified  = iDiff;
end

iDiffMagnified(isnan(iDiffMagnified)) = 0; % remove Nans TODO: Why do they happen? Should only happen outside the original image



end

