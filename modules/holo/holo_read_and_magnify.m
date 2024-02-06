function hol = holo_read_and_magnify(vid, fn1, fn2, para)
% vid - VideoReader handle
% fn1 - First frame number for comparison
% fn2 - Second frame number for comparison
% para.mag - magnification factor for interpolation
% para.ch -  which channel to use, 2 for green

% Bottlenecks: 
% Reading (17% each) -> could remove one
% Interpolation (46%)
% Removing nans (9%)
% Meshgrids (6%) -> could be done once only

%% Read
persistent f2
persistent f2_fn
if ~isempty(f2_fn) && f2_fn == fn1
    % if the last frame's f2 is this frame's f1, reuse it
    f1 = f2;
else
    f1 = double(read(vid, fn1));
    f1 = f1(:, :, para.ch);
end
f2 = double(read(vid, fn2));
f2 = f2(:, :, para.ch);
f2_fn = fn2;

n = size(f1, 1);
m = size(f1, 2);

f_diff = f1 - f2;

%% Magnify
if para.mag>1
    [ixx, iyy]  = meshgrid(1/para.mag:1/para.mag:m, 1/para.mag:1/para.mag:n);
    hol         = interp2(f_diff, ixx, iyy); % interpolated version of difference image
else
    hol = f_diff;
end

hol(isnan(hol)) = 0; % remove Nans TODO: Why do they happen?