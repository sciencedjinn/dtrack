function z_focus = holo_findFocus(iDiff, para, pos, z_estimate, verbose)

if nargin < 5, verbose = false; end
if nargin < 4, z_estimate = nan; end

% iDiff - an NxMx1 greyscale difference image
% zRange - 1x2 double vector, including the minimum and maximum expected z-position (depth, in mm)
% stepRange - 1x2 double vector [startStep finalStep], containing the starting step size and final step size, in mm. This determines the accuracy with which z will be determined.
% pos - 1x2 double vector [x y], contains the x/y coordinates of the object whose z-position is of interest
% reconBoxSize - 1x1 double, the edge size of the box drawn around pos. This needs to be large enough to create a reasonable fourier signal (guess: at least 10x the object size???)

[x_selection, y_selection, cx, cy] = sub_find_section(round(pos), para.holo.reconBoxSize, size(iDiff));
iDiffSelection = iDiff(y_selection(1):y_selection(2), x_selection(1):x_selection(2));

%% find the best focus
if isnan(z_estimate)
    % reconstuct for every possible Z
    [z, mins1] = sub_find_focus(iDiffSelection, para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), para, cx, cy, verbose);
else
    z = z_estimate;
    mins1 = [];
end
    
% TODO: Dynamically go to smaller step sizes

% now do this again, but with finer step size 
zs = z-40*para.holo.stepRange(2):para.holo.stepRange(2):z+40*para.holo.stepRange(2);
[z_focus, mins2] = sub_find_focus(iDiffSelection, zs, para, cx, cy, verbose);

disp('This run: ');
fprintf('Search between %.2f and %.2f mm.\nBest position with %.2f mm resolution: %.2f\nSecond search between %.2f and %.2f mm\nBest position with %.2f mm resolution: %.2f\n', ...
    para.holo.zRange(1), para.holo.zRange(2), para.holo.stepRange(1), z, z - 40*para.holo.stepRange(2), z + 40*para.holo.stepRange(2), para.holo.stepRange(2), z_focus);

if verbose
    figure(274); clf; hold on;
    if ~isempty(mins1)
        plot(para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), squeeze(mins1), 'k.');
    end
    plot(zs, squeeze(mins2), 'b.');
    plot(z_focus, max(mins2), 'ro');
    xlabel('z-Position (mm)')
    ylabel('maximum resonstruction value')
end

end % main

%% Sub-functions
function [x_section, y_section, cx, cy] = sub_find_section(pos, bx, max_size)
    % Draw a box around the last known position, making sure it is square but not outside the image
    % 
    % input:
    % pos: [x y], the position of the tracked centre in the full image
    % max_size: [y x], the size of the full image
    %
    % output:
    % x_section, y_section: a 2*bx+1 wide and high section of the original image, surrounding the tracked centre
    % cx, cy: the position of the tracked centre within that image
       
    x_section = [pos(1)-bx pos(1)+bx];
    y_section = [pos(2)-bx pos(2)+bx];
    cx = bx + 1; 
    cy = bx + 1;
    if x_section(1)<1, x_section = [1 1+2*bx]; cx = pos(1); end
    if y_section(1)<1, y_section = [1 1+2*bx]; cy = pos(2); end
    if x_section(2)>max_size(2), x_section = [max_size(2)-2*bx max_size(2)]; cx = pos(1) - max_size(2) + 2*bx+1; end
    if y_section(2)>max_size(1), y_section = [max_size(1)-2*bx max_size(1)]; cy = pos(2) - max_size(1) + 2*bx+1; end
end
    
function [z, allMaxs] = sub_find_focus(iDiff, zRange, para, cx, cy, verbose)
    % Given a difference image section and a range of z-values, finds the 
    % z-value where the central 8th of the image has the largest value, indicating best focus
    
    Reconst = holo_analyse2_reconstruct(iDiff, zRange, para.holo);

    % for each z-position, calculate the maximum in Reconst, then find the maximum
    % (make sure that the centre does not go past image edges)
    bs = para.holo.searchBoxSize*para.holo.reconBoxSize;
    minx = max([cx - bs 1]);
    maxx = min([cx + bs size(Reconst, 2)]);
    miny = max([cy - bs 1]);
    maxy = min([cy + bs size(Reconst, 1)]);
    ReconstCentre = Reconst(miny:maxy, minx:maxx, :);
    allMaxs = max(max(ReconstCentre, [], 1), [], 2);
    
    [~, max_index] = max(allMaxs, [], 3); 
    z = zRange(max_index);
%     best_focus_image_section = Reconst(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, min_index); %% TODO: Is there a better criterion than just the maximum?
    
%     % Use this for diagnostics:    
%     a = reshape(Reconst, [size(Reconst, 1), size(Reconst, 2), 1, 16]);
%     figure(734); clf; montage(a(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, :, :)/max(a(:)), 'BorderSize', [1 1]);
    
    if verbose
        cm = colormap('gray');
        figure(3); clf; montage(64-round(63*Reconst(cy - bs : cy + bs, cx - bs : cx + bs, :)/max(Reconst(:))), cm, 'bordersize', [1 1])
        figure(4); clf; imagesc(64-round(63*mean(Reconst, 3)/max(Reconst(:)))); colormap('gray');
        hold on; rectangle('Position', [cx - bs, cy - bs, 2*bs, 2*bs])
    end
end

function sharpness = estimate_sharpness(I)
    % https://se.mathworks.com/matlabcentral/fileexchange/32397-sharpness-estimation-from-image-gradients
    [Gx, Gy] = gradient(I);
    S = sqrt(Gx.*Gx+Gy.*Gy);
    sharpness = sum(sum(S))./(numel(Gx));
end
