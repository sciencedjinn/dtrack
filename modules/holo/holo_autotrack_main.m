function [gui, status, para, data] = holo_autotrack_main(gui, status, para, data, autopara)
% holo_autotrack_main loads reference frame and ROI, then calls dtrack_tools_autotrack_shikhar for each frame 
% to detect the main feature of the image and track it.
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_select
   
%% Initialise frame buffer
buffer = [];

%% confirm overwriting existing points
if any(data.points(autopara.from:autopara.step:autopara.to, autopara.pointnr, 3))
    button = 'Yes';%questdlg('Some points in the selected range have already been tracked. Overwrite?', 'Warning', 'Yes, overwrite points', 'No, cancel', 'No, cancel');
    if strcmp(button, 'No, cancel')
        return;
    end
end

%% change paras to suit autotracking
oldpara                     = para;
para.mmreadoverlap          = 0;   % set frame block overlap to 0 (for slightly faster loading)
para.gui.minimap            = 1;
dtrack_guivisibility(gui, para, status); % this toggles and activates gui elements (Menu entries are not changed, but will be ok after the reset at the end of this function

%% waitbar
autowbh = waitbar(0, 'Reading reference frame...', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
setappdata(autowbh, 'canceling', 0);
a = get(autowbh, 'OuterPosition');
set(autowbh, 'OuterPosition', [a(1) a(2)+a(4) a(3) a(4)]);

%% create roimask                
if autopara.useroi && ~isempty(status.roi)
    para.im.roi = 1;
    switch status.roi(1, 1)
        case 0  %0 indicates polygon vertices
            [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
            autopara.roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
        case 1  %1 indicates ellipse
            [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
            autopara.roimask = inellipse(Y, X, status.roi(2:end)); 
        otherwise %old roi file
            disp('No ROI type indicator found, assuming old ROI file.');
            status.roih=line(status.roi(:, 1), status.roi(:, 2), 'tag', 'roiline');   
    end
else
    para.im.roi = 0;
    autopara.roimask     = [];
end

%% Init main loop vars
cancelled = false;
stats = nan(1, autopara.to);  % this will save the size of the detected area
tic
disp([datestr(now, 13) ' - Autotracking started']);
waitbar(0.01, autowbh, 'Automatic tracking...');

%% Main loop
for trackframe = autopara.from:autopara.step:autopara.to
    drawnow;
    if getappdata(autowbh, 'canceling')
        cancelled = true;
        break;
    end
    
    %% find where this point was last tracked
    refstep = autopara.refstep;
    if trackframe-refstep>0 && data.points(trackframe-refstep, status.cpoint, 3)>0
        lastPoint = data.points(trackframe-refstep, status.cpoint, 1:2);
        lastPointType = 'lastframe';
    elseif data.points(trackframe, status.cpoint, 3)>0
        lastPoint = data.points(trackframe, status.cpoint, 1:2);
        lastPointType = 'prediction';
    elseif size(data.points, 1)>=trackframe+refstep && data.points(trackframe+refstep, status.cpoint, 3)>0
        lastPoint = data.points(trackframe+refstep, status.cpoint, 1:2);
        lastPointType = 'nextframe';
    elseif any(data.points(max([1 trackframe-100]):min([size(data.points, 1) trackframe+100]), status.cpoint, 3)>0)
        allTrackedFrames = find(data.points(max([1 trackframe-100]):min([size(data.points, 1) trackframe+100]), status.cpoint, 3)>0);
        [~, i] = min(abs(allTrackedFrames-trackframe));
        lastPoint = data.points(allTrackedFrames(i), status.cpoint, 1:2);
        lastPointType = 'nearby';
    else
        warndlg('Invalid last point. Please start the autotracking only after manually tracking the point at least once within 100 frames of the starting frame.')
        cancelled = true;
        break;
    end     
    
    %% TODO: Buffer frames
    
    % load ref1
    ref1 = nested_loadframe(trackframe-refstep);

    % load ref2     
    if strcmp(autopara.refMethod, 'double')
        ref2 = nested_loadframe(trackframe+refstep);
    else
        ref2 = [];
    end
    
    % load image
    im = nested_loadframe(trackframe);
    
    nested_purgebuffer([trackframe-refstep trackframe+refstep])
    
    % calculate centroids
    [res, diag] = holo_autotrack_detect(im, ref1, ref2, autopara, para.holo, lastPoint, lastPointType);
    switch res.message
        case ''
            data.points(trackframe, autopara.pointnr, 1:2)  = res.centroid;
            data.points(trackframe, autopara.pointnr, 3)    = 42; % DEF: 42 means autotracked point
        case 'Invalid lastPoint'
            warndlg('Autotracking has lost the point for too many frames to continue. This is often due to the tracked object approaching the boundaries of the trackable area. Switch to interference mode and forward the video until you can find the object again. Then, manually track one point and press CTRL+D (CMD+D) to continue tracking.')
            cancelled = true;
            break;
        otherwise
            data.points(trackframe, autopara.pointnr, 1:2)  = [nan nan];
            data.points(trackframe, autopara.pointnr, 3)    = 43; % DEF: 43 means autotracked point, no point found
            continue
    end

    % plot
    if autopara.showim
        status.framenr    = trackframe;
        [~, status, para] = dtrack_action(gui, status, para, data, 'redraw');
    end
    if autopara.showdiag
        diag.fnr = trackframe;
        diag.pnr = autopara.pointnr;
        holo_autotrack_plotdiag(diag, gui.diag.ah);   
    end
%     set(findobj('tag', 'framenr'), 'string', ['frame ', num2str(trackframe), '/', num2str(status.nFrames)]); % takes an extra 1 second per 100 frames
    if mod((trackframe-autopara.from)/autopara.step, 10)==0
        waitbar((trackframe-autopara.from+1)/(autopara.to-autopara.from+1), autowbh);
    end
end

delete(autowbh);  % DELETE the waitbar; don't try to CLOSE it.

%% exit
if cancelled
    disp([datestr(now, 13) ' - Autotracking canceled after ' num2str(toc) ' seconds after frame ' num2str(trackframe-autopara.step) '.']);
else
    disp([datestr(now, 13) ' - Autotracking finished after ' num2str(toc) ' seconds.']);
end

%% re-set old parameters
para = oldpara;
dtrack_guivisibility(gui, para, status); % this toggles and activates gui elements




%% Nested functions for buffering
    function im = nested_loadframe(fnr)
        if isempty(buffer) || ~ismember(fnr, [buffer.fnr])
            status.framenr = fnr;
            [~, status]    = dtrack_action([], status, para, data, 'loadonly_noref');
            image3d        = double(status.currim_ori);
            im             = para.im.gs1 * image3d(:, :, 1) + para.im.gs2 * image3d(:, :, 2) + para.im.gs3 * image3d(:, :, 3);
            fobj.fnr = fnr;
            fobj.im  = im;
            if isempty(buffer)
                buffer = fobj;
            else
                buffer(end+1) = fobj;
            end
%             fprintf('Frame %04d loaded and added to buffer\n', fnr);
        else
            im = buffer([buffer.fnr]==fnr).im;
%             fprintf('Frame %04d loaded from buffer\n', fnr);
        end
    end

    function nested_purgebuffer(frange)
        if ~isempty(buffer)
            buffer = buffer([buffer.fnr]>=frange(1) & [buffer.fnr]<=frange(2));
        end
%         fprintf('Buffer now had %4d entries\n', length(buffer));
    end
        end % main

