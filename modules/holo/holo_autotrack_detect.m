function [outcentroid, outarea, outimages, allregions] = holo_autotrack_detect(im, ref1, ref2, autopara, holopara, lastpoint)
% holo_autotrack_detect
%
% autopara.roimask, autopara.greythr, autopara.areathr, autopara.method
%
% Call sequence: holo_action -> holo_autotrack_select -> holo_autotrack_detect
%                            -> holo_autotrack_main -> holo_autotrack_detect
% See also: holo_autotrack_select, holo_autotrack_main

% %% check inputs, set defaults
% autopara needs to contain:
%     method
%     greythr
%     areathr
%     roimask
% holopara needs to contain:
%     holo.pix_um
%     holo.lambda_nm
%     holo.mag
%     holo.boxSize

%% FIXME
% if strcmp(method, 'nearest') && isnan(lastpoint)
%     method = 'largest';
% end

switch autopara.method
    case '2nd nearest'
        diffim = - im + ref1;
        
    case {'Max of 3', 'Middle of 3'}
        diffim = - im + 0.5*ref1 + 0.5*ref2;
end

diffim = diffim - mean(diffim(:));
diffim = holo_analyse1_magnify(diffim, holopara.holo.mag); % store the magnified difference image in a new variable. This will be reused for findZ
iReconstructed = holo_analyse2_reconstruct(diffim, lastpoint(4), holopara);
iReconstructed = max(iReconstructed(:))-iReconstructed;
iReconstructed = iReconstructed/max(iReconstructed(:));
% iReconstructed = zeros(size(diffim)); % brings the calculation time down from .37 to .19s in test
% now replace zoomed-in area
% 1. find closest tracked point 
if ~any(isnan(lastpoint))
    pos = lastpoint(1:2);
else
    error('This point has to be tracked at least once to find a suitable area');
end

[x_selection, y_selection, cx, cy] = sub_find_section(round(pos), holopara.holo.boxSize, size(iReconstructed));
iDiffSelection  = diffim(y_selection(1):y_selection(2), x_selection(1):x_selection(2));
% short version
enhancedSection = holo_analyse2_reconstruct(iDiffSelection, lastpoint(4), holopara);
%             % long version
%             allSections = holo_analyse2_reconstruct(iDiffSelection, para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), para);
%             enhancedSection = mean(allSections, 3);

enhancedSection = max(enhancedSection(:))-enhancedSection;
enhancedSection = enhancedSection/max(enhancedSection(:));
iReconstructed(y_selection(1):y_selection(2), x_selection(1):x_selection(2)) = enhancedSection;

diffim = iReconstructed;

diffim([1:round(lastpoint(2)-holopara.holo.boxSize/8) round(lastpoint(2)+holopara.holo.boxSize/8):end], :) = max(diffim(:)); 
diffim(:, [1:round(lastpoint(1)-holopara.holo.boxSize/8) round(lastpoint(1)+holopara.holo.boxSize/8):end]) = max(diffim(:)); 

%% gray scale conversion
level = autopara.greythr * graythresh(diffim);
level = min([level 1]); % limit level to allowed range
bwi   = im2bw(diffim, level);

%% cut out points outside region of interest
bwi2  = ~bwi;
bwi2(~autopara.roimask) = 0;

if nargout>3
    % calculate ALL connected regions for later post-processing
    allregions = regionprops(bwconncomp(bwi2), 'Area', 'Centroid');
end

%% remove all regions smaller than areathresh
bwi3  = bwareaopen(bwi2, autopara.areathr);

%% find connected regions
cc    = bwconncomp(bwi3); 
props = regionprops(cc, 'Area', 'Centroid'); % calculate area and centroid for each region

if isempty(props)
    outcentroid = [nan nan];
    outarea = nan;
else
    switch autopara.method
        case '2nd nearest'
            [~,idx] = max([props.Area]);
        case 'Max of 3'
            [~,idx] = max([props.Area]);
        case 'Middle of 3'
            [~,idx] = max([props.Area]);
        otherwise
            error('Internal error: Unknown autotrack method %s', autopara.method);
    end
    
    outcentroid = props(idx).Centroid;
    outarea = props(idx).Area;
end

if nargout>2 % return diagnostic images (currently only used for preview)
    outimages{1} = diffim;
    outimages{2} = bwi; 
    outimages{3} = bwi2;
    outimages{4} = bwi3;
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
    