function [gui, status, para, data] = dtrack_tools_autotrack_main(gui, status, para, data, autopara)
% loads reference frame and ROI, then calls dtrack_tools_autotrack_shikhar for each frame 
% to detect the main feature of the image and track it.
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_select

%% if a point has been tracked in the last 10 frames, use that as an anchor
lastpoints = data.points(max([1 autopara.from-10]):autopara.from, autopara.pointnr, :);
if strcmp(autopara.method, 'nearest') && any(lastpoints(:, 1, 3))
    ind = find(lastpoints(:, 1, 3), 1, 'last');
    lastpoint = lastpoints(ind, 1, 1:2);
else
    lastpoint = nan;
end

%% confirm overwriting existing points
if any(data.points(autopara.from:autopara.step:autopara.to, autopara.pointnr, 3))
    button = questdlg('Some points in the selected range have already been tracked. Overwrite?', 'Warning', 'Yes, overwrite points', 'No, cancel', 'No, cancel');
    if strcmp(button, 'No, cancel')
        return;
    end
else
    data.points(autopara.from:autopara.step:autopara.to, autopara.pointnr, :) = 0;
end

%% change paras to suit autotracking
oldpara                     = para;
para.mmreadoverlap          = 0;   % set frame block overlap to 0 (for slightly faster loading)
para.gui.infopanel          = 1;
para.gui.infopanel_points   = 0;
para.gui.infopanel_markers  = 0;
para.gui.infopanel_mani     = 0;
para.gui.minimap            = 1;
para.im.manicheck           = 0;
dtrack_guivisibility(gui, para, status); % this toggles and activates gui elements (Menu entries are not changed, but will be ok after the reset at the end of this function

%% waitbar
autowbh = waitbar(0, 'Reading reference frame...', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
setappdata(autowbh, 'canceling', 0);
a = get(autowbh, 'OuterPosition');
set(autowbh, 'OuterPosition', [a(1) a(2)+a(4) a(3) a(4)]);

%% get reference frame
status.framenr      = autopara.ref;
[~, status, para]   = dtrack_action(gui, status, para, [], 'loadonly');
%status.autoref      = status.currim_ori;
[imout, status.mh] = readframe(status.mh, [1 100], para, status, false);
status.autoref = median(imout, 4);

%% create roimask                
if autopara.useroi && ~isempty(status.roi)
    para.im.roi = 1;
    switch status.roi(1, 1)
        case 0  %0 indicates polygon vertices
            [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
            roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
        case 1  %1 indicates ellipse
            [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
            roimask = inellipse(Y, X, status.roi(2:end)); 
        otherwise %old roi file
            disp('No ROI type indicator found, assuming old ROI file.');
            status.roih=line(status.roi(:, 1), status.roi(:, 2), 'tag', 'roiline');   
    end
else
    para.im.roi = 0;
    roimask     = [];
end

%% Init main loop vars
cancelled = false;
stats=nan(1, autopara.to);  %this will save the size of the detected area
tic
disp([datestr(now, 13) ' - Autotracking started']);
waitbar(0.01, autowbh, 'Automatic tracking...');

%% Main loop
for trackframe=autopara.from:autopara.step:autopara.to
    drawnow;
    if getappdata(autowbh,'canceling')
        cancelled = true;
        break;
    end
    if trackframe==autopara.ref
        continue;
    end
    status.framenr = trackframe;
    [~, status, para] = dtrack_action(gui, status, para, [], 'loadonly');
    [centroid, stats(status.framenr)] = dtrack_tools_autotrack_detect(status.autoref, status.currim_ori, roimask, autopara.greythresh, autopara.areathresh, autopara.method, lastpoint);
    if isnan(stats(status.framenr)) % no large enough area was found
        data.points(status.framenr, autopara.pointnr, 1:2)  = [0 0];
        data.points(status.framenr, autopara.pointnr, 3)    = -43; % DEF: -43 means autotracked point, no point found
        lastpoint = nan;
    else
        data.points(status.framenr, autopara.pointnr, 1:2)  = centroid;
        data.points(status.framenr, autopara.pointnr, 3)    = 42; % DEF: 42 means autotracked point
        lastpoint = centroid;
    end
    if autopara.showim
        [~, status, para] = dtrack_action(gui, status, para, data, 'redraw');
    end
    waitbar((trackframe-autopara.from+1)/(autopara.to-autopara.from+1), autowbh);
end

delete(autowbh);  % DELETE the waitbar; don't try to CLOSE it.

%% exit
if cancelled
    disp([datestr(now, 13) ' - Autotracking canceled after ' num2str(toc) ' seconds after frame ' num2str(trackframe-autopara.step) '.']);
else
    disp([datestr(now, 13) ' - Autotracking finished after ' num2str(toc) ' seconds.']);
end

%% re-set frame block overlap
para = oldpara;
dtrack_guivisibility(gui, para, status); %this toggles and activates gui elements