function iReconstructed = holo_analyse2_reconstruct(iMagnified, zRange, para)
% HOLO_ANALYSE2_RECONSTRUCT Summary of this function goes here
%   Detailed explanation goes here

    iSize = size(iMagnified);

    % Darudi included some trick to optionally double the input image (Ze_pad). Not sure why, but can be looked up in obsolete version.

    iReconstructed = complex(zeros(iSize(1), iSize(2), numel(zRange))); % pre-allocate %%TODO: complex needed?


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         Reconstruction

    [p, j] = meshgrid(floor(-iSize(2)/2):floor(iSize(2)/2)-1,floor(-iSize(1)/2):floor(iSize(1)/2)-1);

    %% calculate some constants
    Ro2 = (j*para.pix_um).^2+(p*para.pix_um).^2;
    fft_hol = fft2(iMagnified);

    for i = 1:numel(zRange)
        iReconstructed(:, :, i) = 1/1i/(para.lambda_nm/1e6)/zRange(i).*fftshift(ifft2(fft_hol.*fft2(exp(1i*pi*Ro2/(para.lambda_nm/1e6)/zRange(i)))));
    end
    
    iReconstructed = iReconstructed.*conj(iReconstructed);
end

