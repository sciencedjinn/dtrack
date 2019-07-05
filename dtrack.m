function dtrack(modules)
% DTRACK is a routine to track animals in HD videos. 
%   The program uses nested functions for a GUI application with 2 figures.
% 
% The inpur variable 'modules' (a cell of strings) can be used to load optional modules. They are loaded sequentially in the order that they are submitted.
% Therefore, later modules can potentially overload earlier modules' variables. The last of those modules also determines the GUI styling.
% For example 'dtrack({'holo'})' calls dtrack with the holo module, and the GUI will be holo-styled.
%
% It includes 4 running variables:
% - data contains all tracking data, frame markers, etc.
% - gui contains handles to all user interface objects (menus, toolbars,
%   figures, axes, ...)
% - para contains all user-set parameters, including all paths (obtained
%   from parameter file)
% - status contains temporary session variables that change frequently
%
% % Copyright 2010 - 2019 Jochen Smolka, ScienceDjinn 

v = 1.91;
fprintf('Starting DTrack %.2f\n', v);

if nargin<1, modules = {}; end

%% Defaults and paths
[status, para, data]  = dtrack_defaults(modules);
status.maincb         = @maincb;
status.movecb         = @movecb;
status.resizecb       = @resizecb;
status.scrollcb       = @scrollcb;
assignin('base', 'dtrack_restore', @nested_restore);

%% version check
[os, matlabv]         = dtrack_versioncheck; % 'PCWIN'/'PCWIN64'/'MACI'/'GLNX86'/'GLNXA64'

%% Start with a dialog box offering options:
[gui, status, para, data, loadaction] = dtrack_fileio_startdlg(status, para); % gui is created inside this function
% returns loadaction 'new'/'open'/'demol'/'demop'/'recent'/'canceled'

switch loadaction
    case 'canceled'
        % Quit button was pressed or window closed, close program
        disp('Program ended by user. Bye bye.'); return;
    case {'new', 'load'}
        % 1. New File: Open a brief parameter dialog with
        % the option of loading a more detailed parameter file
        % 2. Open File: Load the saved data (this includes the parameters, the parameter file is
        % not used again) and check the video. If the video can't be found, open a dialog box to select it. 
        % After loading, check the number of frames, if that's not correct, ERROR!
        % 3. Point demo opens a little demonstration video of a rolling beetle with already tracked points.
        % 4. Line demo opens a little demonstration video of a dancing beetle with already tracked lines.
        % 5. Recently used file: Same as Open
    otherwise
        error('Internal error: Invalid loadaction');
end

%% save version data
status.os         = os; % 'PCWIN'/'PCWIN64'/'MACI'/'GLNX86'/'GLNXA64'
status.matlabv    = matlabv;
status.dtrackv    = v; 
status.dtrackbase = mfilename('fullpath');

%% draw first video frame
[status, gui]   = dtrack_image(gui, status, para, data, 3);

% The rest is done via callbacks, mainly through @maincb -> dtrack_action, which is called after any button or keypress.

%%%%%%%%%%%%%%%%%%%
%% Nested callback functions
    function maincb(src, event, varargin)
        % This callback function is called for practically any callback occurring in DTrack
        % It collects information about the event, and then forwards this information to dtrack_action.
        % dtrack_action handles the event and then calls dtrack_image to update the display.
        
        switch get(src, 'type')
            case {'image', 'figure'} % key or click
                % a) mouse click
                %%%%%% 20150324: in 2014a and older, event is not empty, but EventName does not exist. Introduced "isfield(event, 'EventName') &&" %%%%%% below, which seems to fic it
                if isempty(event) || strcmp(event.EventName, 'Hit') %isfield(event, 'EventName') && strcmp(event.EventName, 'Hit') % empty happens before 2014b, 'Hit' from 2014b onwards
                    mod = {}; % This cell will collect all modifiers (Alt/Ctrl/Shift) that were pressed while the action happened.
                    switch get(gui.f1, 'selectiontype')
                        case 'normal'
                            action = 'leftclick';
                        case 'alt'
                            action = 'rightclick';
                        case 'open'
                            switch status.lastaction
                                case {'leftclick', 'doubleleftclick'}
                                    action = 'doubleleftclick';
                                case {'rightclick', 'doublerightclick'}
                                    action = 'doublerightclick';
                            end
                        case 'extend' %shift click
                            mod = {'shift'};
                    end
                
                % b) not a mouseclick
                else
                    action = event.Key; mod = event.Modifier;
                end
                pos = get(gui.ax1, 'currentpoint');
                x = pos(1,1); y = pos(1,2);
            
            otherwise
                action = get(src, 'tag');
                x = []; y = []; mod = {};
        end
        
        %fprintf('Entering action %s, with lastaction = %s\n', action, status.lastaction); % for debugging
        set(gui.f1, 'pointer', 'watch'); drawnow;
        status.currentaction      = action;
        [gui, status, para, data] = dtrack_action(gui, status, para, data, action, mod, x, y, src);
        status.lastaction         = status.currentaction;
        set(gui.f1, 'pointer', 'custom'); drawnow;
        %fprintf('Finishing action %s, saving it as lastaction = %s\n', action, status.lastaction); % for debugging
    end

    function movecb(newpos)
        %this function is called often; should be as short as possible!
        %executed when a point or line is dragged to a new position or created
        %fprintf('Move function called. Last action was %s.\n', status.lastaction);
        if size(newpos, 2)==2
            [gui, status, para, data] = dtrack_action(gui, status, para, data, [para.trackingtype 'dragged'], {}, newpos(:, 1), newpos(:, 2));
        end
    end

    function resizecb(src, varargin)
        % main figure window has been resized
        action = 'resize'; x = []; y = []; mod = {};
        status.lastaction = action;
        if exist('gui', 'var') %% don't know why, but this is sometimes called before gui is returned
            [gui, status, para, data] = dtrack_action(gui, status, para, data, action, mod, x, y, src);
        end
    end

    function scrollcb(src, callbackdata)
        % main figure window has had a scroll event
        if callbackdata.VerticalScrollCount > 0
            action = 'scrolldown';
        else
            action = 'scrollup';
        end
        x = []; y = []; mod = {};
        status.lastaction = action;
        [gui, status, para, data] = dtrack_action(gui, status, para, data, action, mod, x, y, src);
    end

    function nested_restore
        [gui, status, para, data] = dtrack_action(gui, status, para, data, 'debug_resetgui');
    end
        
%% terminate outermost function
end
