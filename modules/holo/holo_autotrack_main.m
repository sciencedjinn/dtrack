function [gui, status, para, data] = holo_autotrack_main(gui, status, para, data, autoPara)
% holo_autotrack_main finds XY position for holographic videos, for each frame
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_select
   

%% Initialise frame buffer
buffer = [];

%% confirm overwriting existing points
if autoPara.overwritePoints && any(data.points(autoPara.from:autoPara.step:autoPara.to, autoPara.pointNr, 3))
    button = questdlg('Some points in the selected range have already been tracked. Are you sure you want to overwrite them?', 'Warning', 'Yes, overwrite points', 'No, cancel', 'No, cancel');
    if strcmp(button, 'No, cancel')
        return;
    end
end

%% change paras to suit autotracking
oldpara                     = para;
para.mmreadoverlap          = 0;   % set frame block overlap to 0 (for slightly faster loading)
if autoPara.showIm
    para.gui.minimap            = 1;   % activate the mini map
    dtrack_guivisibility(gui, para, status); % this toggles and activates gui elements (Menu entries are not changed, but will be ok after the reset at the end of this function
end

%% waitbar
autowbh = waitbar(0, '', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
setappdata(autowbh, 'canceling', 0);
a = get(autowbh, 'OuterPosition');
set(autowbh, 'OuterPosition', [a(1) a(2)+a(4) a(3) a(4)]);

%% create roimask
if autoPara.useROI && ~isempty(status.roi)
    para.im.roi = 1;
    switch status.roi(1, 1)
        case 0  %0 indicates polygon vertices
            [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
            autoPara.roiMask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
        case 1  %1 indicates ellipse
            [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
            autoPara.roiMask = inellipse(Y, X, status.roi(2:end)); 
        otherwise %old roi file
            disp('No ROI type indicator found, assuming old ROI file.');
            status.roih = line(status.roi(:, 1), status.roi(:, 2), 'tag', 'roiline');   
    end
else
    para.im.roi = 0;
    autoPara.roiMask     = [];
end

%% Main loop
% Init main loop vars
tic
cancelled     = false;
if autoPara.pointNr == 0
    objectsToTrack = 1:size(data.points, 2);
else
    objectsToTrack = autoPara.pointNr;
end

for currentObject = objectsToTrack(:)'
    if cancelled
        break;
    end
    
    trackFrame    = autoPara.from;
    disp([datestr(now, 13) ' - Autotracking started for object ' num2str(currentObject)]);
    waitbar(0.01, autowbh, sprintf('Tracking object #%d...', currentObject));
    
    while trackFrame <= autoPara.to
        drawnow;
        if getappdata(autowbh, 'canceling')
            cancelled = true;
            break;
        end

        try
            %% find where this point was last tracked
            refStep = autoPara.refStep;
            if trackFrame-refStep>0 && data.points(trackFrame-refStep, currentObject, 3)>0
                lastPoint = data.points(trackFrame-refStep, currentObject, 1:2);
                lastPointType = 'lastframe';
            elseif data.points(trackFrame, currentObject, 3)>0
                lastPoint = data.points(trackFrame, currentObject, 1:2);
                lastPointType = 'prediction';
            elseif size(data.points, 1)>=trackFrame+refStep && data.points(trackFrame+refStep, currentObject, 3)>0
                lastPoint = data.points(trackFrame+refStep, currentObject, 1:2);
                lastPointType = 'nextframe';
            elseif any(data.points(max([1 trackFrame-100]):min([size(data.points, 1) trackFrame+100]), currentObject, 3)>0)
                pointsToSearch = max([1 trackFrame-100]):min([size(data.points, 1) trackFrame+100]);
                allTrackedFrames = pointsToSearch(data.points(pointsToSearch, currentObject, 3)>0);
                [~, i] = min(abs(allTrackedFrames-trackFrame));
                lastPoint = data.points(allTrackedFrames(i), currentObject, 1:2);
                lastPointType = 'nearby';
            else
               lastPoint = [nan, nan];
            end     

            %% Buffer frames
            % load ref1 and ref2
            ref1 = nested_loadframe(trackFrame-refStep);
            if strcmp(autoPara.refMethod, 'double')
                ref2 = nested_loadframe(trackFrame+refStep);
            else
                ref2 = [];
            end

            im = nested_loadframe(trackFrame); % load image

            nested_purgebuffer([trackFrame-refStep trackFrame+refStep])

            %% Calculate centroids
            [res, diag] = holo_autotrack_detect(im, ref1, ref2, autoPara, para.holo, lastPoint, lastPointType);
            switch res.message
                case '' % A point was successfully found
                    if data.points(trackFrame, currentObject, 3)>0 && ~autoPara.overwritePoints
                        % This object was already tracked in this frame
                        % OPTION: Any checks on path coherence should be made here
                    else
                        data.points(trackFrame, currentObject, 1:2)  = res.centroid;
                        data.points(trackFrame, currentObject, 3)    = 42;              % DEF: 42 means autotracked point
                        data.points(trackFrame, currentObject, 5)    = diag.area;
                    end
                case 'Invalid lastPoint'
                    if autoPara.skipGaps
                        nextTrackedPoint = find(data.points(trackFrame:end, currentObject, 3)>0, 1, 'first');
                        if isempty(nextTrackedPoint)
                            fprintf('Autotracking has lost object #%d for too many frames to continue, and there is no other marked point. Moving on to next object.\n', currentObject)                
                            break;
                        else
                            trackFrame = trackFrame + nextTrackedPoint - 1;
                            fprintf('Autotracking has lost object #%d for too many frames to continue. Moving on to next known position of this object (frame %d).\n', currentObject, trackFrame)
                            continue;
                        end
                    else
                        warndlg('Autotracking has lost the object for too many frames to continue. This is often due to the tracked object approaching the boundaries of the trackable area. Switch to interference mode and forward the video until you can find the object again. Then, manually track one point and press CTRL+D (CMD+D) to continue tracking.')
                        cancelled = true;
                        break;
                    end
                otherwise % There are other messages indicating that autotracking can not find a point or finds more than 1
                    data.points(trackFrame, currentObject, 1:5)  = [nan nan -43 0 nan]; % DEF: -43 means autotracked point, no point found
                    trackFrame = trackFrame + autoPara.step;
                    continue;
            end

            % plot
            if autoPara.showIm
                status.framenr    = trackFrame;
                [~, status, para] = dtrack_action(gui, status, para, data, 'redraw');
            end
            if autoPara.showDiag
                diag.fnr = trackFrame;
                diag.pnr = currentObject;
                holo_autotrack_plotdiag(diag, gui.diag.ah);   
            end
        %     set(findobj('tag', 'framenr'), 'string', ['frame ', num2str(trackframe), '/', num2str(status.mh.NFrames)]); % takes an extra 1 second per 100 frames
            if mod((trackFrame-autoPara.from)/autoPara.step, 10)==0
                waitbar((trackFrame-autoPara.from+1)/(autoPara.to-autoPara.from+1), autowbh);
            end
        catch me
            warndlg(sprintf('Autotracking stopped with a %s error: %s.', me.identifier, me.message))
            cancelled = true;
            break;
        end

        trackFrame = trackFrame + autoPara.step;
    end
end

delete(autowbh);  % DELETE the waitbar; don't try to CLOSE it.

%% exit
if cancelled
    disp([datestr(now, 13) ' - Autotracking canceled after ' num2str(toc) ' seconds after frame ' num2str(trackFrame-autoPara.step) '.']);
else
    disp([datestr(now, 13) ' - Autotracking finished after ' num2str(toc) ' seconds.']);
end

%% re-set old parameters
para = oldpara;
dtrack_guivisibility(gui, para, status); % this toggles and activates gui elements



%% Nested functions for buffering
    function im = nested_loadframe(fnr)
        if isempty(buffer) || ~ismember(fnr, [buffer.fnr])
            % if this frame is not in the buffer yet, load it
            im              = status.mh.readFrame(fnr);
            image3d         = double(im);
            im              = para.im.gs1 * image3d(:, :, 1) + para.im.gs2 * image3d(:, :, 2) + para.im.gs3 * image3d(:, :, 3);
            % add image object to buffer
            fobj.fnr = fnr;
            fobj.im  = im;
            if isempty(buffer)
                buffer = fobj;
            else
                buffer(end+1) = fobj;
            end
        else
            % if it is in the buffer already, return it
            im = buffer([buffer.fnr]==fnr).im;
        end
    end

    function nested_purgebuffer(frange)
        if ~isempty(buffer)
            buffer = buffer([buffer.fnr]>=frange(1) & [buffer.fnr]<=frange(2));
        end
    end

end % main

