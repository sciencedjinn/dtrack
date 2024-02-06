function reconst = holo_recon(f_diff, mag, Z_mm, pix_um, lambda_nm)

if nargin < 5, lambda_nm  = 780; end
if nargin < 4, pix_um     = 0.0052*4.5/4; end
if nargin < 3, Z_mm = 85; end
if nargin < 2, mag = 2; end

%% Magnify

n = size(f_diff, 1);
m = size(f_diff, 2);
if mag>1
    [ixx, iyy]  = meshgrid(1/mag:1/mag:m, 1/mag:1/mag:n);
    hol         = interp2(f_diff, ixx, iyy); % interpolated version of difference image
else
    hol = f_diff;
end

hol(isnan(hol)) = 0; % remove Nans TODO: Why do they happen?

%%
hol = hol(:, (1:size(hol, 1))+140+(offset*140)); % crop difference frame to be square
hol = hol - mean(hol(:)); % subtract the mean from incoming image
hol_size = size(hol);

% Darudi included some trick to optionally double the input image (Ze_pad). Not sure why, but can be looked up in obsolete version.

reconst = complex(zeros(hol_size(1), hol_size(2), numel(Z_mm))); % pre-allocate


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         Reconstruction

[p, j] = meshgrid(floor(-hol_size(2)/2):floor(hol_size(2)/2)-1,floor(-hol_size(1)/2):floor(hol_size(1)/2)-1);

%% calculate some constants
Ro2 = (j*pix_um).^2+(p*pix_um).^2;
fft_hol = fft2(hol);

for i = 1:numel(Z_mm)
    reconst(:, :, i) = 1/1i/(lambda_nm/1e6)/Z_mm(i).*fftshift(ifft2(fft_hol.*fft2(exp(1i*pi*Ro2/(lambda_nm/1e6)/Z_mm(i)))));
end