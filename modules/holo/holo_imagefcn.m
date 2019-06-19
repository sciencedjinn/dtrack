function [gui, status, para, data] = holo_imagefcn(gui, status, para, data)

%%
iDiff = double(status.currim);
% offset = 0;
% iDiff = iDiff(:, (1:size(iDiff, 1))+140+(offset*140)); % crop difference frame to be square
iDiff = iDiff - mean(iDiff(:)); % subtract the mean from incoming image

status.diffim = holo_analyse1_magnify(iDiff, para.holo.mag); % store the magnified difference image in a new variable. This will be reused for findZ

switch status.holo.image_mode
    case 'camera'
        status.currim = holo_analyse1_magnify(double(status.currim_ori(:, :, 2)), para.holo.mag);
    case 'interference'
        status.currim = status.diffim;
    case 'holo'
        iReconstructed = holo_analyse2_reconstruct(status.diffim, status.holo.z, para);
        iReconstructed = max(iReconstructed(:))-iReconstructed;
        status.currim = iReconstructed/max(iReconstructed(:));
end


    