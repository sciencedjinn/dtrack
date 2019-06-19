function z_focus = holo_findFocus(iDiff, para, pos, z_estimate, verbose)

if nargin < 5, verbose = true; end
if nargin < 4, z_estimate = nan; end

% iDiff - an NxMx1 greyscale difference image
% zRange - 1x2 double vector, including the minimum and maximum expected z-position (depth, in mm)
% stepRange - 1x2 double vector [startStep finalStep], containing the starting step size and final step size, in mm. This determines the accuracy with which z will be determined.
% pos - 1x2 double vector [x y], contains the x/y coordinates of the object whose z-position is of interest
% boxSize - 1x1 double, the edge size of the box drawn around pos. This needs to be large enough to create a reasonable fourier signal (guess: at least 10x the object size???)

[x_selection, y_selection] = sub_find_section(round(pos), para.holo.boxSize, size(iDiff));
iDiffSelection = iDiff(y_selection(1):y_selection(2), x_selection(1):x_selection(2));

%% find the best focus
if isnan(z_estimate)
    % reconstuct for every possible Z
    [z, mins1] = sub_find_focus(iDiffSelection, para.holo.zRange(1):para.holo.stepRange(1):para.holo.zRange(2), para);
else
    z = z_estimate;
    mins1 = [];
end
    
    
% TODO: Dynamically go to smaller step sizes

% now do this again, but with finer step size 
zs = z-40*para.holo.stepRange(2):para.holo.stepRange(2):z+40*para.holo.stepRange(2);
[z_focus, mins2] = sub_find_focus(iDiffSelection, zs, para);

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
function [x_section, y_section] = sub_find_section(pos, bx, max_size)
    % Draw a box around the last known position, making sure it is square but not outside the image
    x_section = [pos(1)-bx pos(1)+bx];
    y_section = [pos(2)-bx pos(2)+bx];

    if x_section(1)<1, x_section = [1 1+2*bx]; end
    if y_section(1)<1, y_section = [1 1+2*bx]; end
    if x_section(2)>max_size(2), x_section = [max_size(2)-2*bx max_size(2)]; end
    if y_section(2)>max_size(1), y_section = [max_size(1)-2*bx max_size(1)]; end
end
    
function [z, allMaxs] = sub_find_focus(iDiff, zRange, para)
    % Given a difference image section and a range of z-values, finds the 
    % z-value where the central 8th of the image has the largest value, indicating best focus
    Reconst = holo_analyse2_reconstruct(iDiff, zRange, para);

    % for each z-position, calculate the maximum in Reconst, then find the maximum
    allMaxs = max(max(Reconst(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, :), [], 1), [], 2);
    
%     for i = 1:size(allMaxs, 3)
%         allMaxs(i) = estimate_sharpness(Reconst(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, i));
%     end
    
    
    [~, max_index] = max(allMaxs, [], 3); 
    z = zRange(max_index);
%     best_focus_image_section = Reconst(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, min_index); %% TODO: Is there a better criterion than just the maximum?
    
%     % Use this for diagnostics:    
%     a = reshape(Reconst, [size(Reconst, 1), size(Reconst, 2), 1, 16]);
%     figure(734); clf; montage(a(7/8*para.holo.boxSize:9/8*para.holo.boxSize, 7/8*para.holo.boxSize:9/8*para.holo.boxSize, :, :)/max(a(:)), 'BorderSize', [1 1]);
    
end

function sharpness = estimate_sharpness(I)
    % https://se.mathworks.com/matlabcentral/fileexchange/32397-sharpness-estimation-from-image-gradients
    [Gx, Gy] = gradient(I);
    S = sqrt(Gx.*Gx+Gy.*Gy);
    sharpness = sum(sum(S))./(numel(Gx));
end
