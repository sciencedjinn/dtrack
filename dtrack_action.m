function [gui, status, para, data] = dtrack_action(gui, status, para, data, action, modifier, x, y, src)
% DTRACK_ACTION is DTrack's main callback function. Whenever a button or key is pressed, this functions determines the appropriate response.
% 
% Each entry has to assign the status variables redraw and saveneeded, which determine how the figure window has to be redrawn after this function
% exits, and whether a save is neccessary/whether this action counts towards the autosave-counter.
%
% Inputs:
%   gui/status/para/data  - main dtrack variables
%   action                - name of the last event. This is either the key that was pressed, or the tag of the calling uicontrol
%   modifier              - a cell array of modifiers that were held while the event took place
%   x/y                   - the x and y coordinates (in pixels) of the cursor as the event took place
%   src                   - handle of the source object
% Output:
%   gui/status/para/data  - main dtrack variables
% 
% Call sequence:    dtrack>cbmain -> dtrack_action -> dtrack_image
% Uses:             dtrack_image; and pretty much every other function in dtrack is called through dtrack_action
% See also:         dtrack, dtrack_image

%% check inputs
if nargin<9, src = [];      end
if nargin<7, x = 0; y = 0;  end
if nargin<6, modifier = {}; end

%% calculate modifiers
alt   = ismember('alt', modifier);
shift = ismember('shift', modifier);
ctrl  = ismember('control', modifier);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Find the right action %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Init
autoforward = false;

%% 1. Actions with a modifier
if alt&&shift&&ctrl
    status.currentaction = status.lastaction;
    redraw = 0;
    saveneeded = 0;
    
elseif alt&&shift
    switch action
        case {'d', 'r', 's', 'e', 'p'}
            % Move to previous pointmarker
            temp = dtrack_findnextmarker(data, status.framenr, action, 'p');
            if ~isempty(temp), status.framenr = temp; redraw = 1; else, redraw = 0; end
            saveneeded = 0;
        otherwise
            status.currentaction = status.lastaction;
            redraw = 0;
            saveneeded = 0;
    end
    
elseif ctrl&&shift
    status.currentaction = status.lastaction;
    redraw = 0;
    saveneeded = 0;
    
elseif ctrl&&alt
    status.currentaction = status.lastaction;
    redraw = 0;
    saveneeded = 0;
    
elseif ctrl
    switch action
        case {'leftarrow'}
            % Move 10 frames back
            status.framenr = status.framenr-10*para.gui.stepsize; 
            redraw = 1;
            saveneeded = 0;
    
        case {'rightarrow'}
            % Move 10 frames forward
            status.framenr = status.framenr+10*para.gui.stepsize; 
            redraw = 1;
            saveneeded = 0;
    
        otherwise
            status.currentaction = status.lastaction;
            redraw = 0;
            saveneeded = 0;
    end
    
elseif alt
    switch action
        case {'s', 'e', 'r', 'd', 'p'}
            % Add or remove frame marker
            h = findobj('tag', ['marker_' action]);
            if get(h, 'value')
                set(h, 'value', 0);
                data = dtrack_removemarker(data, status.framenr, action);
            else
                set(h, 'value', 1);
                data = dtrack_addmarker(data, status.framenr, action);
            end
            redraw = 0;
            saveneeded = 1;
            
        case 'alt'
            status.currentaction = status.lastaction;
            redraw = 0;
            saveneeded = 0;
            
        otherwise
            letter = regexp(action, '[a-z]');
            if length(letter)==1 && letter
                % Add or remove frame marker
                if any(ismember(action, data.markers(status.framenr).m))
                    data = dtrack_removemarker(data, status.framenr, action);
                else
                    data = dtrack_addmarker(data, status.framenr, action);
                end
            end
            redraw = 20;
            saveneeded = 1;
    end
    
elseif shift
    switch action
        case {'d', 'r', 's', 'e', 'p'}
            % Move to next pointmarker
            temp = dtrack_findnextmarker(data, status.framenr, action, 'n');
            if ~isempty(temp), status.framenr = temp; redraw = 1; else, redraw = 0; end
            saveneeded = 0;
            
        case {'leftarrow'}
            % Move 50 frames forward
            status.framenr = status.framenr-5*para.gui.stepsize;
            redraw = 1;
            saveneeded = 0;
            
        case {'rightarrow'}
            % Move 50 frames back
            status.framenr = status.framenr+5*para.gui.stepsize;
            redraw = 1; 
            saveneeded = 0;
            
        case 'x'
            % Find all markers and display them with the corresponding framenumber
            disp('Searching for markers....');
            temp=dtrack_findnextmarker(data, status.framenr, 'all', 'all');
            if isempty(temp)
                fprintf('No markers found.\n');
            else
                %pad=ceil(log10(temp(end)));
                for i=1:length(temp)
                    fprintf('Frame %6d: %s\n', temp(i), [data.markers(temp(i)).m{:}]);
                end
            end
            redraw = 0;
            saveneeded = 0;
            
        otherwise
            status.currentaction = status.lastaction;
            redraw = 0;
            saveneeded = 0;
            
    end
else
    
%% 2. normal (single) keystrokes/button presses
    switch(action)
      %% Just redraw
        case 'loadonly_noref'
            % only load the frame without displaying it
            redraw = 31;    % this is used by autotracking and "Save as image sequence"
            saveneeded = 0;
            
        case 'loadonly'
            % only load the frame without displaying it
            redraw = 30;    % this is used by autotracking and "Save as image sequence"
            saveneeded = 0;
            
        case 'redraw'
            %  load the frame and display it
            redraw = 1;     % this is used by autotracking and "Save as image sequence"
            saveneeded = 0;
        
      %% Modifiers only (ignore) (I don't think this is ever executed)
        case {'shift', 'control', 'alt'}  
            status.currentaction = status.lastaction;
            redraw = 0; 
            saveneeded = 0;
            
      %% Resize
        case 'resize'
            if ishandle(gui.minimap.panel) % has to be checked because sometimes this is called before the main figure is drawn
                oldpos = get(gui.minimap.panel, 'position');
                minisize    = oldpos(3);
                axsize      = get(gui.f1, 'Position');
                axwidth     = axsize(3);
                axheight    = axsize(4);
                if ~isempty(para.forceaspectratio)
                    miniheight = minisize*axwidth/para.forceaspectratio(1)*para.forceaspectratio(2)/axheight;
                else
                    miniheight = minisize;
                end
                set(gui.minimap.panel, 'position', [1-minisize 0 minisize miniheight]);
            end
            redraw = 0;
            saveneeded = 0;
            
      %% Scroll
        case 'scrollup'
            axes(gui.ax1);
            zoom(gui.f1, 1.2);
            redraw = 0;
            saveneeded = 0;
            
        case 'scrolldown'
            axes(gui.ax1);
            zoom(gui.f1, 1/1.2);
            redraw = 0;
            saveneeded = 0;
            
            
      %% Mouse buttons
        case {'leftclick', 'doubleleftclick'}
            % Set current point
            switch para.trackingtype  % store data
                case 'point'
                    data.points(status.framenr, status.cpoint, 1:3) = [x y 1]; % 1 means manually tracked
                case 'line'
                    h  = imline(gui.ax1, 'PositionConstraintFcn', dtrack_roi_constrain(para, status));
                    cp = status.cpoint; % current POINT number (e.g. cp is 3 for line #2)
                    % store data
                    data.points(status.framenr, cp:cp+1, 1:2) = getPosition(h);
                    data.points(status.framenr, cp:cp+1, 3)   = 1; % 1 means manually tracked
                    delete(h); %HACK
            end
            % redraw will be set depending on autoforwarding (see bottom of this file)
            autoforward = true;
            saveneeded = 1;
            
        case 'rightclick'
            % Pan image to centre on cursor
            oldLim = axis;
            newLim = oldLim - [mean(oldLim(1:2)) mean(oldLim(1:2)) mean(oldLim(3:4)) mean(oldLim(3:4))] + [x x y y];
            axis(newLim);
            redraw = 0;
            saveneeded = 0;
            
        case 'doublerightclick'
            % Reset zoom to show full image
            redraw = 3;
            saveneeded = 0;
            
      %% Line or point dragged
        case 'linedragged'
            % This action is called often; should be as short as possible!
            % It is called, e.g. when the line is moved manually, but also when a new frame is created, or when a line is entered manually.
            % In that case, the old line might have been deleted, so be prepared here that empty handles might turn up.
            % A line or one of its end points was dragged to a new position. This can only happen in line-tracking mode. 
            % Find the line object
            hchild      = findobj('xdata', x, 'ydata', y);
            h           = get(hchild(2), 'parent');
            name        = get(h, 'tag'); % name of the line object, e.g. 'imline2'
            if isempty(name)
                error('Internal error: an empty line name has been returned; this happens when the line object was corrupted, e.g. when the frame was changed while Matlab was waiting for a line input (cross cursor). To fix this, select "Redraw lines" from the Debug menu.');
            end
            cp          = str2double(name(end));
            status.cpoint = 2*cp-1; % Set the first point of the line as the active point.
            data.points(status.framenr, 2*cp-1:2*cp, 1:3) = cat(3, x, y, [1;1]); % 1 means manually tracked (even if it was auto before, now it's manual)
            redraw      = 14;
            saveneeded  = 1/2; % 1/2 means that this will not increase the count of actions since last save, unless it is 0
            
        case 'pointdragged'
            % This action is called often; should be as short as possible!
            % A point object was dragged to a new position. This can only happen in point-tracking mode. 
            hchild      = findobj('xdata', x, 'ydata', y, '-not', 'tag', 'cpoint');
            h           = get(hchild(1), 'parent');
            name        = get(h, 'tag');
            cp          = str2double(name(end)); 
            if cp==0, cp = 10; end
            status.cpoint = cp;
            data.points(status.framenr, cp, 1:3) = [x y 1]; % 1 means manually tracked (even if it was auto before, now it's manual)
            redraw      = 14;
            saveneeded  = 1/2; % 1/2 means that this will not increase the count of actions since last save, unless it is 0
                        
      %% delete point
        case {'delete', 'backspace'}
            % Delete currrent point
            cp = status.cpoint;
            switch para.trackingtype
                case 'point'
                    data.points(status.framenr, cp, :) = 0;
                case 'line'
                    data.points(status.framenr, cp:cp+1, :) = 0;
            end
            redraw = 11; % refresh points only
            saveneeded = 1;
             
      %% Navigation
        case 'framenr'
            % Move to a certain frame number
            answer = inputdlg('Go to frame number:', '', 1, {num2str(status.framenr)});
            if ~isempty(answer)
                status.framenr = str2double(answer); 
            end
            redraw = 1;  
            saveneeded = 0;
            
        case 'frametime'
            % Move to a certain time in the video
            answer = inputdlg('Go to frame minute:', '', 1);
            if ~isempty(answer)
                status.framenr = round(str2double(answer)*status.FrameRate*60); 
                disp(['Jumping to frame ' num2str(status.framenr) ' (frame minute ' answer{1} ').']);
            end
            redraw = 1;  
            saveneeded = 0;  
            
        case 'stepsize'
            % Set the size for a large step (left/right arrow)
            answer = inputdlg('Please enter a new step size for large steps (left/right arrow keys):', '', 1, {num2str(para.gui.stepsize)});
            answer = abs(round(str2double(answer)));
            if ~isnan(answer)
                para.gui.stepsize = answer; 
                set(findobj('tag', 'stepsize'), 'string', ['step size ' num2str(answer)]);
            end
            redraw = 0;  
            saveneeded = 1;  
            
        case {'start', 's'}
            % Move to the first frame
            status.framenr = 1;
            redraw = 1;
            saveneeded = 0;  
            
        case {'backx', 'leftarrow'}
            % Move 10 frames back
            status.framenr = status.framenr-para.gui.stepsize;
            redraw = 1;
            saveneeded = 0;
            
        case {'back1', 'uparrow'}
            % Move 1 frame back
            status.framenr = status.framenr-1;
            redraw = 1;
            saveneeded = 0;
            
        case {'forw1', 'downarrow'}
            % Move 1 frames forward
            status.framenr = status.framenr+1;
            redraw = 1;
            saveneeded = 0;
            
        case {'forwx', 'rightarrow'}
            % Move 10 frames forward
            status.framenr = status.framenr+para.gui.stepsize;
            redraw = 1;
            saveneeded = 0;
            
        case {'pagedown'}
            % Move 200 frames back
            status.framenr = status.framenr+20*para.gui.stepsize;
            redraw = 1;
            saveneeded = 0;
            
        case {'pageup'}
            % Move 200 frames back
            status.framenr = status.framenr-20*para.gui.stepsize;
            redraw = 1;
            saveneeded = 0;
            
        case {'end', 'e'}
            % Move to the last frame
            status.framenr = status.nFrames;
            redraw = 1;
            saveneeded = 0;
            
      
       % Navigate to next pointmarker
        case {'d', 'r', 'p'}
            % Move to next point marker
            temp = dtrack_findnextmarker(data, status.framenr, action, 'n');
            if ~isempty(temp), status.framenr = temp; redraw = 1; else, redraw = 0; end 
            saveneeded = 0;
            
      % Modes
        case {'zoom', 'z'}
            % Switch to zoom mode
            pan(gui.f1, 'off');
            zoom(gui.f1, 'on');
            set(findobj('tag', 'zoom'), 'state', 'on'); % toggle the buttons
            set(findobj('tag', 'pan'), 'state', 'off'); % toggle the buttons
            set(findobj('tag', 'acquire'), 'state', 'off'); % toggle the buttons

            % replace default keypress callbacks
            hManager = uigetmodemanager(gui.f1);
            try
                set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1 (Matlab 2014a and before)
            catch
                [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (Matlab 2014b and after)
            end
            set(gui.f1, 'keypressfcn', status.maincb);

            status.acquire = 0;
            redraw = 0;
            saveneeded = 0;
            
            
        case {'acquire', 'v'}
            % Switch to acquisition mode
            zoom(gui.f1, 'off');
            pan(gui.f1, 'off');
            set(findobj('tag', 'zoom'), 'state', 'off'); % toggle the buttons
            set(findobj('tag', 'pan'), 'state', 'off'); % toggle the buttons
            set(findobj('tag', 'acquire'), 'state', 'on'); % toggle the buttons

            status.acquire = 1;
            redraw = 0;
            saveneeded = 0;
                        
        case {'pan', 'h'}
            % Switch to pan mode
            zoom(gui.f1, 'off');
            pan(gui.f1, 'on');
            set(findobj('tag', 'zoom'), 'state', 'off'); % toggle the buttons
            set(findobj('tag', 'pan'), 'state', 'on'); % toggle the buttons
            set(findobj('tag', 'acquire'), 'state', 'off'); % toggle the buttons

            % replace default keypress callbacks
            hManager = uigetmodemanager(gui.f1); %% NOTE: Does not work anymore in current Matlab version, but seems fine without
            try
                set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1 (Matlab 2014a and before)
            catch
                [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (Matlab 2014b and after)
            end
            set(gui.f1, 'keypressfcn', status.maincb);

            status.acquire = 0;
            redraw = 0;
            saveneeded = 0;
                        
        case 'colourgui'
            % Change point and line colours
            para = dtrack_colourgui(gui, status, para);
            redraw = 12;
            saveneeded = 1;
                        
      %% Point and marker selection
        case {'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10'}
            % Select which points are active
            status.trackedpoints = [];
            for i=1:para.pnr
                if get(findobj('tag', ['p' num2str(i)]), 'value')
                    status.trackedpoints = [status.trackedpoints i];
                end
            end
            % one point always has to be selected
            if isempty(status.trackedpoints)
                status.trackedpoints = 1;
                set(findobj('tag', 'p1'), 'value', 1);
            end
            returnfocus;
            redraw = 11;
            saveneeded = 1;            
        
        case {'ps1', 'ps2', 'ps3', 'ps4', 'ps5', 'ps6', 'ps7', 'ps8', 'ps9', 'ps10'}
            % Change current point through point sel panel (FIXME)
            switch para.trackingtype
                case 'point'
                    status.cpoint = str2double(action(3:end));
                    status.trackedpoints = status.cpoint;
                    for i = 1:para.pnr
                        set(findobj('tag', ['p' num2str(i)]), 'value', 0);
                    end
                    set(findobj('tag', ['p' num2str(status.cpoint)]), 'value', 1);
                case 'line'
                    % for lines, this sets the current line. The current point (in status) is always the POINT, however.
                    status.cpoint = 2*str2double(action(3:end))-1;
            end
            returnfocus;
            redraw = 11;
            saveneeded = 0;            
      
        case {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'}
            % Change current point / line
            n = str2double(action);
            if n==0, n = 10; end
            switch para.trackingtype
                case 'point'
                    if n<=para.pnr
                        status.cpoint = n; 
                        status.trackedpoints = status.cpoint;
                        for i = 1:para.pnr
                            set(findobj('tag', ['p' num2str(i)]), 'value', 0);
                        end
                        set(findobj('tag', ['p' num2str(status.cpoint)]), 'value', 1);
                        set(findobj('tag', 'pointselpanel'), 'selectedobject', findobj('tag', ['ps' num2str(n)]));
                    end
                case 'line'
                    % for lines, this sets the current line. The current point (in status) is always the POINT, however.
                    if n<=para.pnr/2
                        status.cpoint = 2*n-1; 
                        set(findobj('tag', 'pointselpanel'), 'selectedobject', findobj('tag', ['ps' num2str(n)]));
                    end
            end
            redraw = 11;
            saveneeded = 0;            
            
        case 'pointselpanel'
            % juts redraw points
            redraw = 11;
            saveneeded = 0;
            
        case {'marker_s', 'marker_e', 'marker_r', 'marker_d', 'marker_p'}
            % Using the marker buttons to add/remove frame markers
            if get(gcbo, 'value')
                data = dtrack_addmarker(data, status.framenr, action(end));
            else
                data = dtrack_removemarker(data, status.framenr, action(end));
            end
            returnfocus;
            redraw = 0;
            saveneeded = 1;
            
%% Menus            
      %% File menu
        case {'file_newfile', 'newfile', 'file_newfile2', 'newfile2'}
            % check if data is empty, otherwise confirm
            justsaved   = strcmp(status.lastaction, 'file_savefileas') || strcmp(status.lastaction, 'file_savefile') || strcmp(status.lastaction, 'savefile');
            confirm     = (any(data.points(:)) || ~isempty(data.markers)) && ~justsaved; %confirm only if there is something worth saving AND the last action was not a save %%TODO: Clumsy, replace
            same        = strcmp('file_newfile2', action) || strcmp('newfile2', action);
            [status, para, tempdata, success] = dtrack_fileio_new(status, para, confirm, same);
            if success
                %reset gui
                data    = tempdata;
                gui     = dtrack_gui(status, para);
                redraw  = 3;
                saveneeded = -1;
            else
                redraw = 0;
                saveneeded = 0;
            end
            
        case {'file_loadfile', 'loadfile'}
            justsaved   = strcmp(status.lastaction, 'file_savefileas') || strcmp(status.lastaction, 'file_savefile') || strcmp(status.lastaction, 'savefile');
            confirm     = (any(data.points(:)) || ~isempty(data.markers)) && ~justsaved; %confirm only if there is something worth saving AND the last action was not a save 
            [status, para, tempdata, success] = dtrack_fileio_load(status, para, confirm);
            if success
                %reset gui
                data    = tempdata;
                gui     = dtrack_gui(status, para);
                redraw  = 3;
                saveneeded = -1;
            else
                redraw = 0;
                saveneeded = 0;
            end
            
        case {'file_savefile', 'savefile'}
            [stat, para]=dtrack_fileio_save(status, para, data, 0, 1); % just calls saveres, that's it
            if stat
                helpdlg('Project saved successfully','');
                saveneeded = -1; 
            else
                status.currentaction='cancelledsave';
                saveneeded = 0; 
            end
            set(gui.f1, 'name', [para.theme.name ': ' para.paths.resname ' (' para.paths.movname ')']);
            redraw = 0;
            
        case 'file_savefileas'
            [stat, para]=dtrack_fileio_save(status, para, data, 1, 1); % just calls saveres, that's it
            if stat
                helpdlg('Project saved successfully','');
                saveneeded = -1;
            else
                status.currentaction='cancelledsave';
                saveneeded = 0;
            end
            set(gui.f1, 'name', [para.theme.name ': ' para.paths.resname ' (' para.paths.movname ')']);
            redraw = 0;
            
        case 'file_export'
            stat = dtrack_fileio_export(para, data);
            if stat
                helpdlg('Project exported successfully','');
            end
            redraw = 0;
            saveneeded = 0; 
            
        case {'file_setprefs', 'setprefs'}
            newpara = dtrack_editpreferences(para);
            if ~isempty(newpara)
                para = newpara;
                %to accommodate possibly changed resolution
                gui = dtrack_gui(status, para);
                dtrack_guivisibility(gui, para, status);
                redraw = 3;
                saveneeded = 1; 
            else
                redraw = 0;
                saveneeded = 0;
            end
            
        case 'file_exit'
            comingsoon;
            redraw = 0;
            saveneeded = 0;
            % TODO: check if data is empty, otherwise confirm
            
        case 'file_recent'
            %opening submenu, do nothing
            redraw = 0;
            saveneeded = 0;
            
        case 'file_recentx'
            justsaved = strcmp(status.lastaction, 'file_savefileas') || strcmp(status.lastaction, 'file_savefile') || strcmp(status.lastaction, 'savefile');
            confirm = (any(data.points(:)) || ~isempty(data.markers)) && ~justsaved; %confirm only if there is something worth saving AND the last action was not a save 
            [status, para, data, success] = dtrack_fileio_load(status, para, confirm, get(src, 'userdata'));
            if success
                %reset gui
                gui=dtrack_gui(status, para);
                redraw = 3;
                saveneeded = -1;
            else
                redraw = 0;
                saveneeded = 0;
            end
            
        case 'file_clearrecent'
            dtrack_fileio_setrecent('', 0);
            gui=dtrack_gui(status, para);
            redraw = 3;
            saveneeded = 0;
                
      %% Edit menu
        case 'edit_clearframe'
            data = dtrack_datafcns_clearrange(status, para, data, status.framenr, 1:size(data.points, 2));            
            redraw = 11;
            saveneeded = 1;
            
        case 'edit_clearrange'
            data = dtrack_datafcns_clearrange(status, para, data);            
            redraw = 11;
            saveneeded = 1;
            
      %% View menu
        case 'view_navitoolbar'
            para.gui.navitoolbar = support_togglechecked;
            dtrack_guivisibility(gui, para, status);
            redraw = 0;
            saveneeded = 1/2;
            
        case 'view_infopanel'
            para.gui.infopanel=support_togglechecked;
            dtrack_guivisibility(gui, para, status);
            redraw = 0; 
            saveneeded = 1/2; 
            
        case 'view_infopanel_points'
            para.gui.infopanel_points=support_togglechecked;
            dtrack_guivisibility(gui, para, status);
            redraw = 0;
            saveneeded = 1/2;
            
        case 'view_infopanel_mani'
            para.gui.infopanel_mani=support_togglechecked;
            dtrack_guivisibility(gui, para, status);
            redraw = 0;
            saveneeded = 1/2;
            
        case 'view_minimap'
            para.gui.minimap=support_togglechecked;
            dtrack_guivisibility(gui, para, status);
            redraw = 11;
            saveneeded = 1/2;
        % other entries are treated together with other image
        % manipulation functions below
        
      %% Image manipulation
        case {'rgb1', 'rgb2', 'rgb3'}
            if para.im.greyscale
                para.im.gs1 = get(findobj('tag', 'rgb1'), 'value');
                para.im.gs2 = get(findobj('tag', 'rgb2'), 'value');
                para.im.gs3 = get(findobj('tag', 'rgb3'), 'value');
            else
                para.im.rgb1 = get(findobj('tag', 'rgb1'), 'value');
                para.im.rgb2 = get(findobj('tag', 'rgb2'), 'value');
                para.im.rgb3 = get(findobj('tag', 'rgb3'), 'value');                
            end
            returnfocus; 
            redraw = 2;
            saveneeded = 1/2;
                        
            %%%%%
            %%% 2014/11/12: CONTINUE here with cleaning up and adding saveneeded = 0, 1/2, -1 or 1 to each case %%%
            %%%%%
            
        case 'manicheck'
            para.im.manicheck = get(findobj('tag', 'manicheck'), 'value');
            dtrack_guivisibility(gui, para, status);
            returnfocus; 
            redraw = 2; 
            saveneeded = 1/2;
            
        case 'rgbdef'
            if para.im.greyscale
                para.im.gs1=.2989; set(findobj('tag', 'rgb1'), 'value', .2989);
                para.im.gs2=.5870; set(findobj('tag', 'rgb2'), 'value', .5870);
                para.im.gs3=.1140; set(findobj('tag', 'rgb3'), 'value', .1140);
            else
                para.im.rgb1=1; set(findobj('tag', 'rgb1'), 'value', 1);
                para.im.rgb2=1; set(findobj('tag', 'rgb2'), 'value', 1);
                para.im.rgb3=1; set(findobj('tag', 'rgb3'), 'value', 1);                
            end
            returnfocus;
            redraw = 2;
            saveneeded = 1/2;
            
        case {'view_greyscale', 'info_greyscale'}
            if strcmp(action, 'view_greyscale')
                para.im.greyscale=support_togglechecked('view_greyscale');
            else %'info_greyscale'
                para.im.greyscale=get(gcbo, 'value');
            end
            dtrack_guivisibility(gui, para, status); %this toggles and activates gui elements
            returnfocus;
            redraw = 2;
            saveneeded = 1/2;
            
        case {'view_imagesc', 'info_imagesc'}
            if strcmp(action, 'view_imagesc')
                para.im.imagesc=support_togglechecked('view_imagesc');
            else %'info_imagesc'
                para.im.imagesc=get(gcbo, 'value');
            end
            dtrack_guivisibility(gui, para, status); %this toggles and activates gui elements
            returnfocus;
            redraw = 2;
            saveneeded = 1/2;
            
        case {'view_imadjust', 'info_imadjust'}
            if strcmp(action, 'view_imadjust')
                para.im.imadjust=support_togglechecked('view_imadjust');
            else %'info_imadjust'
                para.im.imadjust=get(gcbo, 'value');
            end
            dtrack_guivisibility(gui, para, status); %this toggles and activates gui elements
            returnfocus;
            redraw = 2;
            saveneeded = 1/2;
            
        case {'view_brighten', 'brighten', 'add'}
            brighten(0.1);status.graycm=brighten(status.graycm, 0.1);redraw = 0;
            saveneeded = 1/2;
            
        case {'view_darken', 'darken', 'subtract'}
            brighten(-0.1);status.graycm=brighten(status.graycm, -0.1);redraw = 0;
            saveneeded = 1/2;
            
        case {'view_defaultbrightness', 'defaultbrightness'}
            status.graycm=colormap(gray);redraw = 2;
            saveneeded = 1/2;
            
        case 'info_nightshot'
            %set to GS, 0.6/0/0
            para.im.greyscale=1; para.im.imagesc=1; para.im.imadjust=0; %set toggles
            para.im.gs1=.6; para.im.gs2=0; para.im.gs3=0; %set sliders
            dtrack_guivisibility(gui, para, status);
            returnfocus; redraw = 2;
            saveneeded = 1/2;
            
        case 'deinterlace'
            redraw = 1;
            saveneeded = 1/2;
            
      %% Analysis menu
        case 'ana_plotpaths'
            figure(2); clf; h=axes;hold on;
            dtrack_ana_plotpaths(h, data, status, para);
            redraw = 0;
            saveneeded = 0;
            title('Uncalibrated paths');
            set(gca, 'color', [.5 .5 .5], 'visible', 'on');
            xlabel('x (pixels)'); ylabel('y (pixels)');
            
        case 'ana_plotfootsteps'
            figure(2);clf;h=axes;hold on;
            dtrack_ana_plotfootsteps(h, data, status, para);
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plotcalib'
            figure(3);clf;hold on;
            colors={'b', 'g', 'r', 'c', 'm', 'y', 'k', 'w'};
            for i=1:size(data.points, 2)
                calibps=dtrack_calibrate(squeeze(data.points(:, i, 1:2)), para.paths.calibname);
                plot(calibps(:, 2), calibps(:, 1), [colors{i} '.'], 'markersize', 20);
            end
            axis equal; %axis([0 status.vidWidth 0 status.vidHeight]); 
            set(gca, 'YDir', 'reverse'); 
            %grid minor;
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_odometer_lengths'
            ss=dtrack_findnextmarker(data, 1, 's', 'all');
            ds=dtrack_findnextmarker(data, 1, 'd', 'all');
            ms=dtrack_findnextmarker(data, 1, 'm', 'all');
            es=dtrack_findnextmarker(data, 1, 'e', 'all');
            if length(ss)~=4 || length(ds)~=4 || length(ms)~=4 || length(es)~=4
                error('Wrong number of pointmarkers');
            end
            lengths=zeros(4, 3); %will hold path lengths for way out/back for all four conditions, and the difference
            %TODO: angles=zeros(4, 2); %will hold path lengths for way out/back for all four conditions
            for i=1:4
                calibps=dtrack_calibrate(squeeze(data.points(:, i, 1:2)), para.paths.calibname);
                lengths(i, 1)=norm(calibps(ds(i), :)-calibps(ss(i), :));
                lengths(i, 2)=norm(calibps(es(i), :)-calibps(ms(i), :));
            end
            lengths(:, 3)=lengths(:, 2)-lengths(:, 1);
            fprintf('Path lengths (mm):\nout \thome\tdiff\n');
            fprintf('%4.1f\t%4.1f\t%4.1f\n',lengths');
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plotpos'
            dtrack_ana_plotstrides(data, status, para);
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plotspeed'
            clear ps seglength segtime segspeed
            figure(6);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            colors={'b', 'r', 'g', 'c', 'm', 'y', 'k', 'w'};
            
            smfact=1; meth='moving';
            for jj=1:size(data.points, 2)
                ps{jj}=squeeze(data.points(data.points(:, jj, 3)~=0, jj, 1:2));
                if ~isempty(ps{jj})
                    seglength{jj}=sqrt(sum(diff(ps{jj}).^2, 2)); %in pixels
                    segx{jj}=find(data.points(:, jj, 3)~=0);
                    segtime{jj}=1000/status.FrameRate*diff(find(data.points(:, jj, 3)~=0)); % in ms
                    segspeed{jj}=seglength{jj}./segtime{jj}*1000;% in pixels/s %/18.22; %in cm/s for E3
                    plot(segx{jj}(1:end-1), smooth(segspeed{jj}, smfact), [colors{jj} '-']);
                    plot(segx{jj}(1:end-1), mean(smooth(segspeed{jj}, smfact)), [colors{jj} '--']);
                    mean(smooth(segspeed{jj}, smfact))
                    marks=dtrack_findnextmarker(data, 1, ['t';'g';'e'], 'all');
                    ts=dtrack_findnextmarker(data, 1, 't', 'all');
                    gs=dtrack_findnextmarker(data, 1, 'g', 'all');
                    for i=1:length(marks)-1
                        if ismember(marks(i), ts)
                            col='r';
                        elseif ismember(marks(i), gs)
                            col='g';
                        else
                            continue;
                        end
                        %FIXME: The mean should be calculated differently
                        %(take the position only once every second)
                        plot(marks(i):marks(i+1), mean(smooth(segspeed{jj}(segx{jj}(1:end-1)>marks(i) & segx{jj}(1:end-1)<marks(i+1)), smfact)), [col '--']);                        
                    end
                end
            end
            
            title(['speeds smoothed with window width ' num2str(smfact)]);
            set(gca, 'color', [.5 .5 .5]);
            xlabel('frame'); ylabel('speed (pix/s)');
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plotcalibspeed'
            calibps=dtrack_calibrate(squeeze(data.points(data.points(:, 1, 3)~=0, 1, 1:2)), para.paths.calibname);
            seglength=sqrt(sum(diff(calibps).^2, 2));
            segtime=1000/status.FrameRate*diff(find(data.points(:, 1, 3)~=0)); % in ms
            segspeed=seglength./segtime*100; %in cm/s
            figure(4);clf;
            hist(segspeed, 20);xlabel('speed [cm/s]');title({['mean ' num2str(mean(segspeed))], ['median ' num2str(median(segspeed))], ['mean >1 ' num2str(mean(segspeed(segspeed>1)))], ['median >1 ' num2str(median(segspeed(segspeed>1)))]});
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plotangles'
            switch para.trackingtype
                case 'line'
                    % this only makes sense for lines
                    figure(5); clf; hold on; set(gcf, 'name', 'Angles of tracked lines (0 = horizontal)');
                    
                    for cp = 1:2:size(data.points, 2)
                        sel = find(data.points(:, cp, 3));
                        dx  = data.points(sel, cp, 1) - data.points(sel, cp+1, 1);
                        dy  = - (data.points(sel, cp, 2) - data.points(sel, cp+1, 2)); 
                        plot(sel, atan2d(dy, dx), '.-', 'color', para.ls.p{cp}.col);
                    end
                    [allsel, ~] = find(data.points(:, :, 3));
                    axis([min(allsel) max(allsel) -180 180]);
                    xlabel('Frame number'); ylabel('Angle to horizontal (\circ)');
            end
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_plottemp'
            figure(8);clf;h=axes;hold on;
            dtrack_ana_plottemp(h, data, status, para);
            redraw = 0;
            saveneeded = 0;
            
        case 'ana_balltrace'
            figure(8);clf;h=axes;hold on;
            dtrack_ana_balltrace(h, data, status, para);
            redraw = 0;
            saveneeded = 0;
                       
      %% Calibration menu
        case 'calib_attach'
            filename=dtrack_fileio_opencalib(para.paths.movpath);
            if filename~=0
                para.paths.calibname=filename;
                set(findobj('tag', 'ana_plotcalib'), 'enable', 'on');
                set(findobj('tag', 'ana_plotspeed'), 'enable', 'on');
            end
            redraw = 0;
            saveneeded = 1;
            
      %% ROI&REF menu
        case 'roi_create_frominput'
            [~, filename] = dtrack_roi_create_frominput(status, fullfile(fileparts(para.paths.movpath), 'defaultroi.roi')); %creates and saves a new ROI
            if filename~=0
                para.paths.roiname=filename;
                status.roi=dtrack_fileio_loadroi(para.paths.roiname);
                para.im.roi=1;
                set(findobj('tag', 'roi_display'), 'enable', 'on', 'checked', 'on');
            end
            redraw = 2;
            saveneeded = 1;
            
        case 'roi_create_fromfile'
            if isempty(para.paths.respath)
                defload = para.paths.resdef;
            else
                defload = para.paths.respath;
            end
            filename = dtrack_roi_create_fromresfile(defload, fullfile(fileparts(para.paths.movpath), 'defaultroi.roi'), gui.ax1);
            if filename~=0
                para.paths.roiname=filename;
                status.roi = dtrack_fileio_loadroi(para.paths.roiname);
                para.im.roi = 1;
                set(findobj('tag', 'roi_display'), 'enable', 'on', 'checked', 'on');
            end
            redraw = 2;
            saveneeded = 1;
            
        case 'roi_attach'
            filename = dtrack_fileio_selectroi('load', fileparts(para.paths.movpath));
            if filename~=0
                para.paths.roiname = filename;
                status.roi = dtrack_fileio_loadroi(para.paths.roiname);
                para.im.roi = 1;
                set(findobj('tag', 'roi_display'), 'enable', 'on', 'checked', 'on');
            end
            redraw = 2;
            saveneeded = 1;
            
        case 'roi_display'
            para.im.roi = support_togglechecked('roi_display');
            redraw = 2;
            saveneeded = 1/2;
            
            
            
%     gui.menus.roi.entries.ref_set_none = uimenu(gui.menus.roi.set_menu, 'label', 'None', 'checked', 'on');
%     gui.menus.roi.entries.ref_set_static = uimenu(gui.menus.roi.set_menu, 'label', 'Static', 'checked', 'off');
%     gui.menus.roi.entries.ref_set_dynamic = uimenu(gui.menus.roi.set_menu, 'label', 'Dynamic', 'checked', 'off');
%     gui.menus.roi.entries.ref_set = uimenu(gui.menus.roi.menu, 'label', 'Use current frame as reference');
%     gui.menus.roi.entries.ref_frameDiff = uimenu(gui.menus.roi.menu, 'label', 'Set dynamic frame difference...');
            
        case 'ref_set_none'
            para.ref.use = 'none';
            dtrack_guivisibility(gui, para, status);
            redraw = 2;
            saveneeded = 1/2;
        case 'ref_set_static'
            para.ref.use = 'static';
            if isempty(para.ref.framenr)
                para.ref.framenr = status.framenr;
                [status, para] = dtrack_ref_prepare(status, para);
            end
            dtrack_guivisibility(gui, para, status);
            redraw = 2;
            saveneeded = 1/2;
        case 'ref_set_dynamic'
            para.ref.use = 'dynamic';
            dtrack_guivisibility(gui, para, status);
            redraw = 2;
            saveneeded = 1/2;
        case 'ref_set'
            para.ref.framenr = status.framenr;
            set(findobj('tag', 'refframe'), 'string', ['ref frame ' num2str(status.framenr)]);
            [status, para] = dtrack_ref_prepare(status, para);
            redraw = 2;
            saveneeded = 1/2;
        case 'ref_frameDiff' 
            answer = inputdlg('Please enter the desired frame subtraction distance:', 'New reference difference', 1, {num2str(para.ref.frameDiff)});
            if ~isempty(answer)
                answer = abs(round(str2double(answer{1})));
                answer = max([answer 0]); % minimum 0
                if ~isnan(answer)
                    para.ref.frameDiff = answer; 
                end
            end
            dtrack_guivisibility(gui, para, status);
            redraw = 2;
            saveneeded = 1;
        case 'refframe'
            % Set the reference frame (for static mode) OR frame difference (dynamic mode)
            switch para.ref.use
                case 'none'
                    % do nothing
                case 'static'
                    answer = inputdlg('Please enter a new reference frame number:', 'New reference frame', 1, {num2str(para.ref.framenr)});
                    if ~isempty(answer)
                        answer = abs(round(str2double(answer{1})));
                        answer = min([status.nFrames max([answer 1])]); % limit to valid frames
                        if ~isnan(answer)
                            para.ref.framenr = answer; 
                        end
                    end
                    [status, para] = dtrack_ref_prepare(status, para);
                    dtrack_guivisibility(gui, para, status);
                case {'dynamic', 'double_dynamic'}
                    answer = inputdlg('Please enter the desired frame subtraction distance:', 'New reference difference', 1, {num2str(para.ref.frameDiff)});
                    if ~isempty(answer)
                        answer = abs(round(str2double(answer{1})));
                        answer = max([answer 0]); % minimum 0
                        if ~isnan(answer)
                            para.ref.frameDiff = answer; 
                        end
                    end
                    dtrack_guivisibility(gui, para, status);
                otherwise
                    warning('Uncaptured case, please report this warning');
                    
            end
            redraw = 2;
            saveneeded = 1;
            
      %% Tools menu
        case 'tools_imageone_jpg'
            % dump frame as jpg in data folder
            dtrack_tools_imageone(status, para, 'jpg', false); 
            redraw = 0;
            saveneeded = 0;
            
        case 'tools_imageone_tif'
            % dump frame as jpg in data folder
            dtrack_tools_imageone(status, para, 'tif', false); 
            redraw = 0;
            saveneeded = 0;
            
        case 'tools_imageoneproc_jpg'
            % dump frame as jpg in data folder
            dtrack_tools_imageone(status, para, 'jpg', true); 
            redraw = 0;
            saveneeded = 0;
            
        case 'tools_imageoneproc_tif'
            % dump frame as jpg in data folder
            dtrack_tools_imageone(status, para, 'tif', true); 
            redraw = 0;
            saveneeded = 0;
            
        case 'tools_imageseq'
            % ask for parameters
            [success, savepara] = dtrack_tools_imageseq(status, para);
            if success
                dtrack_tools_imageseq_main(status, para, data, savepara); 
                [gui, status, para, data] = dtrack_action(gui, status, para, data, 'redraw');
            end
            redraw = 1;
            saveneeded = 0;
                      
        case 'tools_autotrack_bgs'
            % Autotracking using background subtraction
            %TODO: save last paras
            [success, autopara] = dtrack_tools_autotrack_select(status, para, data);
            if success
                [gui, status, para, data] = dtrack_tools_autotrack_main(gui, status, para, data, autopara);
            end
            redraw = 1;
            saveneeded = 1;
            
        case 'tools_autotrack_mts'
            % Autotracking using matching to sample
            comingsoon;
            redraw = 0;
            saveneeded = 0;
                
        case 'tools_laserscan'
            % REMOVED. Revert to Dungtrack 1.82 to find this method
            
        case {'vlc', 'm'}
            %First check whether you're on a PC
            if ~strncmpi(status.os, 'PC', 2) % if not on a PC
                warndlg('This function is currently only available for Windows.');
            elseif isempty(para.paths.vlcpath)
                warndlg('Please enter the path to VLC.EXE in File->Properties.');
            elseif ~exist(para.paths.vlcpath, 'file')
                warndlg('Invalid vlc path. Please enter the correct path to VLC.EXE in File->Properties.');
            else
                %vlcpath='C:\Program Files (x86)\VideoLAN\VLC\vlc.exe';
                dos(['"' para.paths.vlcpath '" "' para.paths.movpath '" --start-time=' num2str(status.framenr/status.FrameRate) ' &']);
            end
            redraw = 0;
            saveneeded = 0;
            
        case 'implay'
            implay(para.paths.movpath);
            redraw = 0;
            saveneeded = 0;
            
      %% Debug menu
        case 'debug_publish'
            assignin('base', 'status', status);
            assignin('base', 'gui', gui); % TODO add more
            assignin('base', 'para', para);
            assignin('base', 'data', data);
            redraw = 0;
            saveneeded = 0;
            
        case 'debug_import'
            evalin('base', 'assignin(''caller'', ''data'', data);');
            evalin('base', 'assignin(''caller'', ''status'', status);');
            evalin('base', 'assignin(''caller'', ''gui'', gui);'); %TODO add more
            evalin('base', 'assignin(''caller'', ''para'', para);');
            redraw = 0;
            saveneeded = 1;
            
        case 'debug_resetgui'
            %set(gui.f1, 'WindowButtonDownFcn', '', 'WindowKeyPressFcn', ''); %?
            gui=dtrack_gui(status, para);
            redraw = 3;
            saveneeded = 0;
            
        case 'debug_closeall'
            disp('Closing all other windows. If the main window is closed, try running dtrack_restore()');
            set(0,'ShowHiddenHandles','on');
            figs = get(0,'Children');
            delete(figs(figs~=1));
            redraw = 0;
            saveneeded = 0;
            
        case 'debug_redrawlines'
            disp('Redrawing all points and lines.');
            delete([status.ph{:}]);
            delete(status.cph);
            delete(status.lph);
            redraw = 1;
            saveneeded = 0;

      %% Help menu
        case 'help_shortcuts'
            open(fullfile(pwd, 'documentation', 'DTrack Keyboard Shortcuts.pdf'));
            redraw = 0;
            saveneeded = 0;
            
        case 'help_known'
            comingsoon;
            redraw = 0;
            saveneeded = 0;
            
        case 'help_aspectratio'
            para.forceaspectratio=[16 9];
            redraw = 3;
            saveneeded = 0;
            
%% Inset frames
      %% Info area
        case {'lastpoint'}
            para.showlast = get(gcbo, 'value');
            returnfocus; 
            redraw = 11;
            saveneeded = 1/2;
            
        case {'currpoint'}
            para.showcurr = get(gcbo, 'value');
            returnfocus; 
            redraw = 11;
            saveneeded = 1/2;
            
        case {'autoforw_1', 'autoforw_x'}
            para.autoforw = 0;
            if ismember(findobj('tag', 'autoforw_1'), get(findobj('tag', 'autoforwpanel'), 'selectedobject'))
                set(findobj('tag', 'autoforw_1'), 'cdata', 380-gui.icons.autoforw_1);
                para.autoforw = 1;
            else
                set(findobj('tag', 'autoforw_1'), 'cdata', gui.icons.autoforw_1-25);
            end
            if ismember(findobj('tag', 'autoforw_x'), get(findobj('tag', 'autoforwpanel'), 'selectedobject'))
                set(findobj('tag', 'autoforw_x'), 'cdata', 380-gui.icons.autoforw_x);
                para.autoforw = 2;
            else
                set(findobj('tag', 'autoforw_x'), 'cdata', gui.icons.autoforw_x-25);
            end
            returnfocus;
            redraw = 0;
            saveneeded = 1/2;
            
        otherwise
            %% call modules
            actionFound = false;
            for i = 1:length(para.modules)
                [gui, status, para, data, actionFound, redraw, saveneeded, autoforward] = feval([para.modules{i} '_action'], gui, status, para, data, action, src);
                if actionFound
                    break;
                end
            end
            if ~actionFound
                error(['Unknown action: ', action]);
            end
    end % switch
end % if

% it would be nice if returnfocus was here, but it only works after buttonpresses

% forward point or frame
if autoforward
    switch para.autoforw
        case 0
            redraw = 11; % do nothing except refresh points
        case {1, 2}
            % find next point in this frame
            switch para.trackingtype
                case 'point'
                    cp = min(status.trackedpoints(status.trackedpoints>status.cpoint));
                case 'line'
                    tp = 2*status.trackedpoints-1;
                    cp = min(tp(tp>status.cpoint+1));
                otherwise
                    error('error');
            end
            if ~isempty(cp) % go to this point
                switch para.trackingtype
                    case 'point'
                        [gui, status, para, data] = dtrack_action(gui, status, para, data, num2str(mod(cp, 10))); %mod(cp, 10) necessary to make 10 into 0
                    case 'line'
                        [gui, status, para, data] = dtrack_action(gui, status, para, data, num2str(mod((cp+1)/2, 10))); %mod(cp, 10) necessary to make 10 into 0
                end
            else % forward to next frame
                switch para.trackingtype
                    case 'point'
                        status.cpoint = min(status.trackedpoints);
                        set(findobj('tag', 'pointselpanel'), 'selectedobject', findobj('tag', ['ps' num2str(status.cpoint)]));
                    case 'line'
                        status.cpoint = min(2*status.trackedpoints-1);
                        set(findobj('tag', 'pointselpanel'), 'selectedobject', findobj('tag', ['ps' num2str((status.cpoint+1)/2)]));
                end
                
                if para.autoforw == 1 % forward 1
                    [gui, status, para, data] = dtrack_action(gui, status, para, data, 'forw1');
                else % forward x
                    [gui, status, para, data] = dtrack_action(gui, status, para, data, 'forwx');
                end
            end
            
            redraw = 0; % redrawing was already done in autoforward actions
        otherwise
            error('Internal error: unknown auto-forward mode');
    end
end

%% redraw image
if redraw
    [status, gui] = dtrack_image(gui, status, para, data, redraw); % redraw 1 draws image and all points
end

%% update number of actions since last save, and autosave if necessary
switch saveneeded
    case -1
        para.saveneeded = 0;
    case 0
        % do nothing
    case 1/2
        para.saveneeded = max([para.saveneeded 1]); % set to 1 if it was 0, otherwise leave it
    case 1
        para.saveneeded = para.saveneeded + 1;
    otherwise
        error('Internal error: unknown saveneeded value');
end

if para.saveneeded >= para.autosavethresh
    % TODO: Set save button to enabled/diabled
    % autosave
    [stat, para] = dtrack_fileio_autosave(status, para, data); % just calls saveres, that's it
    para.saveneeded = 0; %HACK, test here whether it was successful
    if stat
    else
    end
end

%fprintf('Finished action: %s.\n', action);

end %function
