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
        switch status.holo.z_mode
            case 'single'
                iReconstructed = holo_analyse2_reconstruct(status.diffim, status.holo.z, para.holo);
            case 'mean'
                allSections = holo_analyse2_reconstruct(status.diffim, para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), para.holo);
                iReconstructed = mean(allSections, 3);
        end
        
        iReconstructed = max(iReconstructed(:))-iReconstructed;
        status.currim = iReconstructed/max(iReconstructed(:));
    case 'holo_mag'
        iReconstructed = holo_analyse2_reconstruct(status.diffim, status.holo.z, para.holo);
        iReconstructed = max(iReconstructed(:))-iReconstructed;
        iReconstructed = iReconstructed/max(iReconstructed(:));
        
        % now replace zoomed-in area
        % 1. find closest tracked point 
        if data.points(status.framenr, status.cpoint, 3)>0
            pos = data.points(status.framenr, status.cpoint, 1:2);
        elseif all(data.points(:, status.cpoint, 3)==0)
            warning('This object has to be tracked at least once to find a suitable area');
            pos = NaN;
        else
            allTrackedFrames = find(data.points(:, status.cpoint, 3)>0);
            [~, i] = min(abs(allTrackedFrames-status.framenr));
            pos = data.points(allTrackedFrames(i), status.cpoint, 1:2);
        end
        if ~isnan(pos)
            [x_selection, y_selection] = sub_find_section(round(pos), para.holo.reconBoxSize, size(iReconstructed));
            iDiffSelection = status.diffim(y_selection(1):y_selection(2), x_selection(1):x_selection(2));
            switch status.holo.z_mode
                case 'single'
                    enhancedSection = holo_analyse2_reconstruct(iDiffSelection, status.holo.z, para.holo);
                case 'mean'
                    allSections = holo_analyse2_reconstruct(iDiffSelection, para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), para.holo);
                    enhancedSection = mean(allSections, 3);
            end

            enhancedSection = max(enhancedSection(:))-enhancedSection;
            enhancedSection = enhancedSection/max(enhancedSection(:));
            iReconstructed(y_selection(1):y_selection(2), x_selection(1):x_selection(2)) = enhancedSection;
        end
        
        status.currim = iReconstructed;       
end

end

%% Sub-functions
function [x_section, y_section, cx, cy] = sub_find_section(pos, bx, max_size)
    % Draw a box around the last known position, making sure it is square but not outside the image
    x_section = [pos(1)-bx pos(1)+bx];
    y_section = [pos(2)-bx pos(2)+bx];
    cx = bx + 1; 
    cy = bx + 1;
    if x_section(1)<1, x_section = [1 1+2*bx]; cx = pos(1); end
    if y_section(1)<1, y_section = [1 1+2*bx]; cy = pos(2); end
    if x_section(2)>max_size(2), x_section = [max_size(2)-2*bx max_size(2)]; cx = pos(1) - (max_size(2)-2*bx-1); end
    if y_section(2)>max_size(1), y_section = [max_size(1)-2*bx max_size(1)]; cy = pos(2) - (max_size(1)-2*bx-1); end
end
    