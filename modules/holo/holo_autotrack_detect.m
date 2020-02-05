function [res, diag] = holo_autotrack_detect(im, ref1, ref2, autopara, holopara, lastPoint, lastPointType)
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
%     holo.reconBoxSize
%     holo.reconBoxSize_unmag
%     holo.searchBoxSize
%     holo.zRange
%     holo.stepRange

%% Init
res = [];
res.centroid = [nan nan];
res.area     = nan;
res.message  = '';
diag = [];
diag.centroid = [nan nan];
diag.para = [];
diag.images = [];

%% Check inputs
if isempty(lastPoint) || any(isnan(lastPoint(1:2))) || any(lastPoint(1:2)<=0) || lastPoint(1)/holopara.mag>size(im, 2) || lastPoint(2)/holopara.mag>size(im, 1)
    % If no position estimate or an invalid estimate is given, tracking is not available. 
    % The calling function should ask for a valid estimate from the user.
    res.message = 'Invalid lastPoint';
    return
else 
    pos = lastPoint(1:2); 
end

assert(ismember(lower(lastPointType), {'lastframe', 'nextframe', 'prediction', 'nearby', 'unknown'}));
assert(ismember(lower(autopara.refMethod), {'single', 'double'}))
assert(ismember(lower(autopara.findMethod), {'2nd nearest', 'middle of 3', 'largest', 'darkest'}));
if strcmpi(autopara.findMethod, 'middle of 3'), assert(strcmpi(autopara.refMethod, 'double')); end
assert(isa(im, 'double'))
assert(isa(ref1, 'double'))
if strcmpi(autopara.refMethod, 'double'), assert(~isempty(ref2) && isa(ref2, 'double')); end

%%

% 1. Calculate difference image
switch lower(autopara.refMethod)
    case 'single'
        iDiff = - im + ref1;
    case 'double'
        iDiff = - im + 0.5*ref1 + 0.5*ref2;
end
iDiff = iDiff - mean(iDiff(:));

% 2. Cut out area around the last point
% Find the best section to do the holographic computation on.
% It must be mag*reconBoxSize by mag*reconBoxSize pixels large (in the magnified image)
% cx_unmag and cy_unmag mark the position of pos inside this section
[x_selection_unmag, y_selection_unmag, cx_unmag, cy_unmag] = sub_find_section(pos/holopara.mag, holopara.reconBoxSize_unmag, size(iDiff));
iDiffSelection = iDiff(y_selection_unmag(1):y_selection_unmag(2), x_selection_unmag(1):x_selection_unmag(2));

% 3. Magnify
iDiffSelection_mag = holo_analyse1_magnify(iDiffSelection, holopara.mag); % magnify for reconstruction
cx_mag = cx_unmag*holopara.mag; cy_mag = cy_unmag*holopara.mag;

% 4. Reconstruct holographic image
% short version
% enhancedSection = holo_analyse2_reconstruct(iDiffSelection_mag, lastpoint(4), holopara);
% long version
allSections = holo_analyse2_reconstruct(iDiffSelection_mag, holopara.zRange(1):holopara.stepRange(1):holopara.zRange(2), holopara);
enhancedSection = mean(allSections, 3);

% 5. Cut out area immediately around the point and find connected regions
[x_selection2_mag, y_selection2_mag] = sub_find_section([cx_mag, cy_mag], holopara.searchBoxSize * holopara.reconBoxSize, size(enhancedSection));
enhancedSectionSelection2 = enhancedSection(y_selection2_mag(1):y_selection2_mag(2), x_selection2_mag(1):x_selection2_mag(2));
enhancedSectionSelection2 = 1 - enhancedSectionSelection2/max(enhancedSectionSelection2(:)); % normalise to 1-0, with points being black on white background

% 6. calculate function to transform points back and forth
fun_full2box = @(p) [p(1) - (x_selection_unmag(1)-1)*holopara.mag - (x_selection2_mag(1)-1), p(2) - (y_selection_unmag(1)-1)*holopara.mag - (y_selection2_mag(1)-1)];
fun_box2full = @(p) [p(1) + (x_selection_unmag(1)-1)*holopara.mag + (x_selection2_mag(1)-1), p(2) + (y_selection_unmag(1)-1)*holopara.mag + (y_selection2_mag(1)-1)];

%% Binarise image and detect objects
% Depending on the algorithm, the number of detected objects must be within a certain range.
switch lower(autopara.findMethod)
    case 'middle of 3'
        nObjRange = [3 3];
    case '2nd nearest'
        nObjRange = [2 5];
    case {'largest', 'darkest'}
        nObjRange = [1 5];
end

% Now find objects, and repeat until within range
[props, bwImages] = sub_detectObjects(enhancedSectionSelection2, autopara);
adjustments = 0;
maxAdjustments = 3; % Only allow this process to occur a limited number of times per frame
while length(props)<nObjRange(1) || length(props)>nObjRange(2)
    adjustments = adjustments + 1;
    if length(props)<nObjRange(1)
        if adjustments>maxAdjustments
            res.message = sprintf('Grey threshold adjusted %d times, up to %.2f; Still not enough objects found (%d)', adjustments-1, autopara.greythr, length(props));
            return;
        end
        % More objects needed, relax thresholds
        % NOTE: Currently, only the grey threshold is adjusted. Area threshold could also be lowered.
        autopara.greythr = 1.2*autopara.greythr;
        [props, bwImages] = sub_detectObjects(enhancedSectionSelection2, autopara);
    elseif length(props)>nObjRange(2)
        if adjustments>maxAdjustments
            res.message = sprintf('Grey threshold adjusted %d times, down to %.2f; Still too many objects found (%d)', adjustments-1, autopara.greythr, length(props));
            return;
        end
        % More objects needed, relax thresholds
        % NOTE: Currently, only the grey threshold is adjusted. Area threshold could also be lowered.
        autopara.greythr = 0.8*autopara.greythr;
        [props, bwImages] = sub_detectObjects(enhancedSectionSelection2, autopara);
        
%         % Alt: Too many objects, select the three largest (doesn't work)
%         [~, idxs] = sort([props.Area]);
%         props = props(idxs(1:3));
    end
end

%% Find the correct object
    % Find the best
    switch lower(autopara.findMethod)
        case 'largest'
            [~, idx] = max([props.Area]);
        case 'darkest'
            [~, idx] = max([props.MeanIntensity]);
        case '2nd nearest'
            if length(props)<2, error('Fewer than 2 found'); end % Shouldn't happen
            cs = cat(1, props.WeightedCentroid);
            lastpoint_inBox = fun_full2box(pos);
            cs(:, 1) = cs(:, 1) - lastpoint_inBox(1);
            cs(:, 2) = cs(:, 2) - lastpoint_inBox(2);
            d = sqrt(sum(cs.^2, 2)); % square of distance between points
            [~, idx] = min(d);
        case 'middle of 3'
            if length(props)<3, error('Fewer than 3 found'); end % Shouldn't happen
            % find the 3 largest
            [~, idxs] = sort([props.Area], 'descend');
            cs = cat(1, props(idxs(1:3)).WeightedCentroid);
            totaldist(1) = sqrt((cs(1, 1) - cs(2, 1))^2 + (cs(1, 2) - cs(2, 2))^2) + sqrt((cs(1, 1) - cs(3, 1))^2 + (cs(1, 2) - cs(3, 2))^2);
            totaldist(2) = sqrt((cs(2, 1) - cs(1, 1))^2 + (cs(2, 2) - cs(1, 2))^2) + sqrt((cs(2, 1) - cs(3, 1))^2 + (cs(2, 2) - cs(3, 2))^2);
            totaldist(3) = sqrt((cs(3, 1) - cs(1, 1))^2 + (cs(3, 2) - cs(1, 2))^2) + sqrt((cs(3, 1) - cs(2, 1))^2 + (cs(3, 2) - cs(2, 2))^2);
            [~, i] = min(totaldist);
            idx = idxs(i);
        otherwise
            error('Internal error: Unknown autotrack method %s', autopara.findMethod);
    end
    
    res.centroid = fun_box2full(props(idx).WeightedCentroid);
    res.area     = props(idx).Area;


if nargout>=2 % return diagnostics
    diag.para = autopara;
    diag.images{1} = enhancedSectionSelection2;
    diag.images{2} = bwImages{1}; 
    diag.images{3} = bwImages{2};
    diag.images{4} = bwImages{3};
    diag.centroid  = props(idx).WeightedCentroid;
    diag.area      = res.area;
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
    x_section = round(x_section);
    y_section = round(y_section);
end

function [props, bwImages] = sub_detectObjects(gsImage, autopara)
    bwImages{1}  = imbinarize(gsImage, 'adaptive', 'foregroundpolarity', 'dark', 'sensitivity', autopara.greythr);
    bwImages{2}  = ~bwImages{1}; bwImages{2}(~autopara.roimask) = 0;    % apply RoI
    bwImages{3}  = bwareaopen(bwImages{2}, autopara.areathr);           % apply area threshold
    
    % find connected regions
    props = regionprops(bwImages{3}, 1-gsImage, 'Area', 'MeanIntensity', 'WeightedCentroid'); % calculate area and centroid for each region
end
    