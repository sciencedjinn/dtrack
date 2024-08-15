function [gui, status, para, data] = dtrack_tools_autotrack_main(gui, status, para, data, atp)
% loads reference frame and ROI, then calls dtrack_tools_autotrack_deetect for each frame 
% to detect the main feature of the image and track it.
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_select

%% if a point has been tracked in the last 10 frames, use that as an anchor
lastpoints = data.points(max([1 atp.From-10]):atp.From, atp.PointNr, :);
if strcmp(atp.Method, 'nearest') && any(lastpoints(:, 1, 3))
    ind = find(lastpoints(:, 1, 3), 1, 'last');
    lastpoint = lastpoints(ind, 1, 1:2);
else
    lastpoint = nan;
end

%% confirm overwriting existing points
if any(data.points(atp.From:atp.Step:atp.To, atp.PointNr, 3))
    button = questdlg('Some points in the selected range have already been tracked. Overwrite?', 'Warning', 'Yes, overwrite points', 'No, cancel', 'No, cancel');
    if strcmp(button, 'No, cancel')
        return;
    end
else
    data.points(atp.From:atp.Step:atp.To, atp.PointNr, :) = 0;
end

%% change paras to suit autotracking
oldstatus                   = status;
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
status.autoref      = 1;



%% create roimask                
if atp.UseRoi && ~isempty(status.roi)
    para.im.roi = 1;
    switch status.roi(1, 1)
        case 0  %0 indicates polygon vertices
            [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
            roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
        case 1  %1 indicates ellipse
            [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
            roimask = inellipse(Y, X, status.roi(2:end)); 
        otherwise %old roi file
            Logger.log(LogLevel.DEBUG, 'No ROI type indicator found, assuming old ROI file.\n');
            status.roih=line(status.roi(:, 1), status.roi(:, 2), 'tag', 'roiline');   
    end
else
    para.im.roi = 0;
    roimask     = [];
end

%% Init main loop vars
cancelled = false;
stats = nan(1, atp.To);  % this will save the size of the detected area
tic
Logger.log(LogLevel.INFO, 'Autotracking started\n');
waitbar(0.01, autowbh, 'Automatic tracking...');

%% test
% % v1
% imout = status.mh.readFrame([1 100]);
% imout = double(imout);
% pause(2);
% tic
% for i = 1:size(imout, 4)
%     im1 = imout(:, :, :, 4) - status.autoref;
%     im2 = rgb2gray(im1);
%     level = autopara.greythresh * graythresh(im2);
%     if level>1, level=1; end  % limit level to allowed range
%     bwi   = imbinarize(im2, level); % without level, takes forever
% end
% toc;
% pause(2);

% % v2;
% tic;
% ims2 = bsxfun(@minus, imout, status.autoref);
% ims2 = squeeze(0.2989 * ims2(:, :, 1, :) + 0.5870 * ims2(:, :, 2, :) + 0.1140 * ims2(:, :, 3, :));
% level = autopara.greythresh * graythresh(ims2(:, :, 1));
% if level>1, level=1; end  % limit level to allowed range
% bwis   = imbinarize(ims2, level); % without level, takes forever
% toc
% return;

%% Main loops
try
    for trackframe=atp.From:atp.Step:atp.To
        drawnow;
        if getappdata(autowbh, 'canceling')
            cancelled = true;
            break;
        end
        status.framenr = trackframe;
        [~, status, para] = dtrack_action(gui, status, para, [], 'loadonly');
        [centroid, stats(status.framenr)] = dtrack_tools_autotrack_detect(atp.RefFrame.getFrame(), status.currim_ori, roimask, atp.GreyThresh, atp.AreaThresh, atp.Method, lastpoint);
        if isnan(stats(status.framenr)) % no large enough area was found
            data.points(status.framenr, atp.PointNr, 1:2)  = [0 0];
            data.points(status.framenr, atp.PointNr, 3)    = -43; % DEF: -43 means autotracked point, no point found
            lastpoint = nan;
        else
            data.points(status.framenr, atp.PointNr, 1:2)  = centroid;
            data.points(status.framenr, atp.PointNr, 3)    = 42; % DEF: 42 means autotracked point
            lastpoint = centroid;
        end
        if atp.ShowIm
            [~, status, para] = dtrack_action(gui, status, para, data, 'redraw');
        end
        waitbar((trackframe-atp.From+1)/(atp.To-atp.From+1), autowbh);
    end
catch me
    warndlg(sprintf("The tracking stopped with an error at frame %d: %s", trackframe, me.message))
end

delete(autowbh);  % DELETE the waitbar; don't try to CLOSE it.

%% exit
if cancelled
    Logger.log(LogLevel.INFO, 'Autotracking canceled after %.1f seconds after frame %d.\n', toc, num2str(trackframe-atp.Step));
else
    Logger.log(LogLevel.INFO, 'Autotracking finished after %.1f seconds.\n', toc);
end

%% re-set frame block overlap
para   = oldpara;
status = oldstatus;
dtrack_guivisibility(gui, para, status); %this toggles and activates gui elements