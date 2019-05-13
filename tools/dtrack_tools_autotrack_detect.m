function [outcentroid, outarea, outimages, allregions] = dtrack_tools_autotrack_detect(ref, current_frame, roimask, greythr, areathresh, method, lastpoint)
%
%
%
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_setect, dtrack_tools_autotrack_main

%% check inputs, set defaults
if nargin<7, lastpoint = nan;           end
if nargin<6, method = 'largest';        end
if nargin<5, areathresh = 50;           end
if nargin<4, greythr = 3;               end
if nargin<3 || isempty(roimask), roimask = ones(size(ref)); end

if strcmp(method, 'nearest') && isnan(lastpoint)
    method = 'largest';
end

%% subtract reference frame
diffim = uint8(abs(double(current_frame) - double(ref)));

%% gray scale conversion
if strcmp(method, 'absolute')
    level = greythr;
else
    level = greythr * graythresh(diffim);
end
if level>1, level=1; end  % limit level to allowed range
bwi   = im2bw(diffim, level);

%% cut out points outside region of interest
bwi2 = bwi;
bwi2(~roimask) = 0;

if nargout>3
    % calculate ALL connected regions for later post-processing
    allregions = regionprops(bwconncomp(bwi2), 'Area', 'Centroid');
end

%% remove all regions smaller than areathresh
bwi3  = bwareaopen(bwi2, areathresh);

%% find connected regions
cc    = bwconncomp(bwi3); 
props = regionprops(cc, 'Area', 'Centroid'); % calculate area and centroid for each region

if isempty(props)
    outcentroid = [nan nan];
    outarea = nan;
else
    switch method
        case 'largest'
            [~,idx] = max([props.Area]);
            
        case {'nearest', 'absolute'}
            distances = zeros(length(props), 1);
            for i = 1:length(props)
                distances(i) = norm(props(i).Centroid(:) - lastpoint(:));
            end
            [~,idx] = min(distances);
        otherwise
            error('Internal error: Unknown autotrack method');
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

        