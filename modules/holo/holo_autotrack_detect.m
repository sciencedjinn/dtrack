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

% 1. find closest tracked point 
if ~any(isnan(lastpoint))
    pos = lastpoint(1:2);
else
    error('This point has to be tracked at least once to find a suitable area');
end

% 2. Calculate difference image
switch autopara.method
    case '2nd nearest'
        iDiff = - im + ref1;
    case {'Max of 3', 'Middle of 3'}
        iDiff = - im + 0.5*ref1 + 0.5*ref2;
end
iDiff = iDiff - mean(iDiff(:)); x = 1:size(iDiff, 2); y = 1:size(iDiff, 1); % x and y coordinates along original unmagnified image axes

% 3. Cut out area around the last point
% Find the best section to do the holographic computation on
% It must be 2*boxSize by 2*boxSize (in the magnified image)
% cx_unmag and cy_unmag mark the position of pos inside this section
[x_selection_unmag, y_selection_unmag, cx_unmag, cy_unmag] = sub_find_section(round(pos/holopara.holo.mag), holopara.holo.boxSize_unmag, size(iDiff));
iDiffSelection = iDiff(y_selection_unmag(1):y_selection_unmag(2), x_selection_unmag(1):x_selection_unmag(2));
xSelection = x(x_selection_unmag(1):x_selection_unmag(2)); ySelection = y(y_selection_unmag(1):y_selection_unmag(2)); % x and y coordinates along original unmagnified image axes

iDiffSelection_mag = holo_analyse1_magnify(iDiffSelection, holopara.holo.mag); % magnify for reconstruction
xSelection = xSelection(1)-1 + 1/holopara.holo.mag:1/holopara.holo.mag:xSelection(end); ySelection = ySelection(1)-1 + 1/holopara.holo.mag:1/holopara.holo.mag:ySelection(end);% x and y coordinates along original unmagnified image axes

% 4. Reconstruct holographic image
% short version
% enhancedSection = holo_analyse2_reconstruct(iDiffSelection_mag, lastpoint(4), holopara);
%             % long version
            allSections = holo_analyse2_reconstruct(iDiffSelection_mag, holopara.holo.zRange(1):holopara.holo.stepRange(1):holopara.holo.zRange(2), holopara);
            enhancedSection = mean(allSections, 3);

enhancedSection = 1-enhancedSection/max(enhancedSection(:)); % normalise to 1-0, with points being black on white background

% 5. Cut out area immediately around the point and find connected regions
[x_selection2_mag, y_selection2_mag] = sub_find_section(round([cx_unmag, cy_unmag]*holopara.holo.mag), holopara.holo.boxSize/8, size(enhancedSection));
enhancedSectionSelection2 = enhancedSection(y_selection2_mag(1):y_selection2_mag(2), x_selection2_mag(1):x_selection2_mag(2));
xSelection2 = xSelection(x_selection2_mag(1):x_selection2_mag(2)); ySelection2 = ySelection(y_selection2_mag(1):y_selection2_mag(2)); % x and y coordinates along original unmagnified image axes

%% gray scale conversion
bwi   = imbinarize(enhancedSectionSelection2, 'adaptive', 'foregroundpolarity', 'dark', 'sensitivity', autopara.greythr);

%% cut out points outside region of interest
bwi2 = ~bwi;
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
    outimages{1} = enhancedSectionSelection2;
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
    