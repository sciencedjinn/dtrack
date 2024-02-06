function [success, autoPara] = holo_autotrack_select(status, para, data, continueMode)
% holo_autotrack_select opens a dialog to select parameters for autotracking
% Call: [success, autopara] = dtrack_tools_autotrack_select(status, para)
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_main
% Data paradigm: autopara contains the current representation of data at any time. GUI should be close to being controlled components.

if nargin<4, continueMode = false; end % continueMode just loads the last sessions settings, and continues tracking from the current frame

if continueMode
    autoPara      = [];
    sub_load('lastSession');
    autoPara.from = status.framenr;
    autoPara.to   = status.mh.NFrames;
    success       = true;
    return
end
    
%% init parameters
gui          = [];
autoPara     = [];
prevpara     = [];
success      = false;
editcb       = @sub_callback;

% load last session's parameters, and change the ones that depend on this dataset
sub_load('lastSession');
autoPara.from    = status.framenr;
autoPara.to      = status.mh.NFrames;
autoPara.pointNr = status.cpoint;
if isempty(status.roi)
    autoPara.useROI = 0;
end
sub_saveLastSession;



%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    % create GUI and set fields
    sub_createGui;
    sub_setDef;
    sub_limit_fnrs('all');

    % % set figure to modal late after you know there are no errors
    % set(gui.fig, 'windowStyle', 'modal');

    uiwait(gui.fig);
    delete(gui.fig);
catch anyerror
    delete(gui.fig); % delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%%%%%%%%%%%%%%%%%%%
%% Nested functions for callbacks, writing/drawing and panel creation



%% General callback: Updates autopara, and applies limits to all parameters
function sub_callback(src, varargin)
    switch get(src, 'tag')
        case 'autotrack_from'
            sub_limit_fnrs('from', 0);
            sub_updatePreview('im');
        case 'autotrack_to'
            sub_limit_fnrs('to', 0);
        case 'autotrack_step'
            sub_limit_fnrs('step', 0);
        case 'autotrack_refStep'
            sub_limit_fnrs('refstep', 0);
            sub_limit_fnrs('all');
            sub_updatePreview('im');         
            
        case 'autotrack_pointNr'
            autoPara.pointNr = get(src, 'value') - 1;
            sub_updatePreview('im');
            
        case 'autotrack_areaThr'
            autoPara.areaThr = str2double(get(src, 'string'));
            sub_updatePreview('area');
            
        case 'autotrack_greyThr'
            autoPara.greyThr = str2double(get(src, 'string'));
            sub_updatePreview('grey');
            
        case 'autotrack_findMethod'
            strings = get(src, 'string');
            autoPara.findMethod = strings{get(src, 'Value')};
            sub_limit_fnrs('all');
            sub_updatePreview('findMethod');
            
        case 'autotrack_refMethod'
            strings = get(src, 'string');
            autoPara.refMethod = strings{get(src, 'Value')};
            sub_limit_fnrs('all');
            sub_updatePreview('refMethod');
            
        case 'autotrack_para4'
            
        case 'autotrack_showIm'
            autoPara.showIm = get(src, 'value');
        case 'autotrack_showDiag'
            autoPara.showDiag = get(src, 'value');
        case 'autotrack_overwritePoints'
            autoPara.overwritePoints = get(src, 'value');
        case 'autotrack_skipGaps'
            autoPara.skipGaps = get(src, 'value');

        case 'autotrack_useROI'
            autoPara.useROI = get(src, 'value');
            sub_updatePreview('roi');
            
        % plus/minus buttons
        case 'autotrack_from_minus'
            sub_limit_fnrs('from', -1);
            sub_updatePreview('im');            
        case 'autotrack_from_plus'
            sub_limit_fnrs('from', +1);
            sub_updatePreview('im');
        case 'autotrack_to_minus'
            sub_limit_fnrs('to', -1);
        case 'autotrack_to_plus'
            sub_limit_fnrs('to', +1);
        case 'autotrack_step_minus'
            sub_limit_fnrs('step', -1);
        case 'autotrack_step_plus'
            sub_limit_fnrs('step', +1);
        case 'autotrack_refStep_minus'
            sub_limit_fnrs('refstep', -1);
            sub_limit_fnrs('all');
            sub_updatePreview('im');
        case 'autotrack_refStep_plus'
            sub_limit_fnrs('refstep', +1);
            sub_limit_fnrs('all');
            sub_updatePreview('im');

        case 'autotrack_areaThr_minus'
            newval = str2double(get(gui.panel2.areathr, 'string')) - 1;
            autoPara.areaThr = newval;
            set(gui.panel2.areathr, 'string', num2str(newval));
            sub_updatePreview('area');
            
        case 'autotrack_areaThr_plus'
            newval = str2double(get(gui.panel2.areathr, 'string')) + 1;
            autoPara.areaThr = newval;
            set(gui.panel2.areathr, 'string', num2str(newval));
            sub_updatePreview('area');
            
        case 'autotrack_greyThr_minus'
            newval = str2double(get(gui.panel2.greythr, 'string')) - 0.05;
            autoPara.greyThr = newval;
            set(gui.panel2.greythr, 'string', num2str(newval));
            sub_updatePreview('grey');
            
        case 'autotrack_greyThr_plus'
            newval = str2double(get(gui.panel2.greythr, 'string')) + 0.05;
            autoPara.greyThr = newval;
            set(gui.panel2.greythr, 'string', num2str(newval));
            sub_updatePreview('grey');
            
        otherwise
            error('Internal error: Unknown caller %s', get(src, 'tag'));
    end
end

%% Button callbacks
function sub_previewGui(varargin)
    % PREVIEW: preview button callback
    gui.prev.fig   = figure(2973); clf;
    gui.prev.ph(1) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 .5 .5 .5]);
    gui.prev.ph(2) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 .5 .5 .5]);
    gui.prev.ph(3) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 0 .5 .5]);
    gui.prev.ph(4) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 0 .5 .5]);
    
    gui.prev.ah(1) = axes('parent', gui.prev.ph(1), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(2) = axes('parent', gui.prev.ph(2), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(3) = axes('parent', gui.prev.ph(3), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(4) = axes('parent', gui.prev.ph(4), 'units', 'normalized', 'position', [0 0 1 1]);
    sub_updatePreview('all');
end

function sub_updatePreview(type)
    if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
        framenr         = str2double(get(gui.panel1.from, 'string'));
        pointnr         = get(gui.panel1.pointnr, 'value');
        refstep         = str2double(get(gui.panel1.refstep, 'string'));
        
        % load image and ref1
        if ismember(type, {'all', 'im'}) % update reference frames
            status.framenr  = framenr;
            [~, status]     = dtrack_action([], status, para, data, 'loadonly');
            image3d         = double(status.currim_ori);
            prevpara.im     = para.im.gs1 * image3d(:, :, 1) + para.im.gs2 * image3d(:, :, 2) + para.im.gs3 * image3d(:, :, 3);
            
            status.framenr  = framenr-refstep;
            [~, status]     = dtrack_action([], status, para, data, 'loadonly');
            image3d         = double(status.currim_ori);
            prevpara.ref1   = para.im.gs1 * image3d(:, :, 1) + para.im.gs2 * image3d(:, :, 2) + para.im.gs3 * image3d(:, :, 3);
        end
        
        % load ref2
        if ismember(type, {'all', 'im', 'findMethod', 'refMethod'})            
            if strcmp(autoPara.refMethod, 'double')
                status.framenr  = framenr + refstep;
                [~, status]     = dtrack_action([], status, para, data, 'loadonly');
                image3d         = double(status.currim_ori);
                prevpara.ref2   = para.im.gs1 * image3d(:, :, 1) + para.im.gs2 * image3d(:, :, 2) + para.im.gs3 * image3d(:, :, 3);
            else
                prevpara.ref2   = [];
            end
        end
        
        if ismember(type, {'all', 'roi'}) % update ROI
            if get(gui.panel2.useroi, 'value') && ~isempty(status.roi)
                switch status.roi(1, 1)
                    case 0  % 0 indicates polygon vertices
                        [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                        prevpara.roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
                    case 1  % 1 indicates ellipse
                        [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                        prevpara.roimask = inellipse(Y, X, status.roi(2:end)); 
                    otherwise 
                        error('Internal error: Unknown ROI type');
                end
            else
                prevpara.roimask = [];
            end
        end
        
        if ismember(type, {'all', 'grey', 'area', 'findMethod', 'refMethod'})
            prevpara.greythr    = autoPara.greyThr;
            prevpara.areathr    = autoPara.areaThr;
            prevpara.findMethod = autoPara.findMethod;
            prevpara.refMethod = autoPara.refMethod;
        end
        
        % find where this point was last tracked
        if status.framenr-refstep>0 && data.points(status.framenr-refstep, status.cpoint, 3)>0
            pos = data.points(status.framenr-refstep, status.cpoint, 1:2);
            lastPointType = 'lastframe';
        elseif data.points(status.framenr, status.cpoint, 3)>0
            pos = data.points(status.framenr, status.cpoint, 1:2);
            lastPointType = 'prediction';
        elseif size(data.points, 1)>=status.framenr+refstep && data.points(status.framenr+refstep, status.cpoint, 3)>0
            pos = data.points(status.framenr+refstep, status.cpoint, 1:2);
            lastPointType = 'nextframe';
        elseif any(data.points(max([1 status.framenr-100]):min([size(data.points, 1) status.framenr+100]), status.cpoint, 3)>0)
            allTrackedFrames = find(data.points(max([1 status.framenr-100]):min([size(data.points, 1) status.framenr+100]), status.cpoint, 3)>0);
            [~, i] = min(abs(allTrackedFrames-status.framenr));
            pos = data.points(allTrackedFrames(i), status.cpoint, 1:2);
            lastPointType = 'nearby';
        else
            warndlg('This object has to be tracked at least once within +-100 frames');
            return
        end
        
        % calculate centroids
        [res, diag] = holo_autotrack_detect(prevpara.im, prevpara.ref1, prevpara.ref2, prevpara, para.holo, pos, lastPointType);
        switch res.message
            case ''
                % all good
            case 'Invalid lastPoint'
                warndlg(sprintf('Auto tracking on this frame failed: %s', res.message));
                return
            otherwise
                warndlg(sprintf('Auto tracking on this frame failed: %s', res.message));
                return
        end
        
        diag.fnr = framenr;
        diag.pnr = pointnr;
        
        % plot
        holo_autotrack_plotdiag(diag, gui.prev.ah);        
    end
end


function sub_createGui
    screen  = get(0, 'screensize');
    figsize = [600 400];
    figpos  = [screen(3)/2-figsize(1)/2 screen(4)/2-figsize(2)/2 figsize(1) figsize(2)];
    %set up the figure
    gui.fig = figure(777); clf;
    set(gui.fig, 'outerposition', figpos, 'name', '', 'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @buttonCallback_close);

%% panels
    uicontrol(gui.fig, 'style', 'text', 'string', 'Autotracking parameters', 'units', 'normalized', 'position', [.02 .81 .96 .17], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 15, 'fontweight', 'bold');
    uicontrol(gui.fig, 'style', 'text', 'units', 'normalized', 'position', [.02 .84 .96 .06], 'string', 'Background subtraction method', 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 10);
    gui.panel1.panel = uipanel(gui.fig, 'position', [.02 .22 .32 .57]);
    gui.panel2.panel = uipanel(gui.fig, 'position', [.36 .22 .62 .57]);

%% panel 1
    opts = {'units', 'normalized', 'callback', editcb};
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .75 .5 .08], 'style', 'text', 'string', 'From frame', 'horizontalalignment', 'right');
    gui.panel1.from       = sub_plusminustext(gui.panel1.panel, [.68 .75 .2 .1], 'autotrack_from', 0.08, 'Which frame to start autotracking from');
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .6 .5 .08], 'style', 'text', 'string', 'to frame', 'horizontalalignment', 'right');
    gui.panel1.to         = sub_plusminustext(gui.panel1.panel, [.68 .6 .2 .1], 'autotrack_to', 0.08, 'Which frame to end autotracking on');
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .45 .5 .08], 'style', 'text', 'string', 'every', 'horizontalalignment', 'right');
    gui.panel1.step       = sub_plusminustext(gui.panel1.panel, [.68 .45 .2 .1], 'autotrack_step', 0.08, 'How many frames to jump after each tracked frame');
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .3 .5 .08], 'style', 'text', 'string', 'ref interval', 'horizontalalignment', 'right');
    gui.panel1.refstep    = sub_plusminustext(gui.panel1.panel, [.68 .3 .2 .1], 'autotrack_refStep', 0.08, 'Distance (in frames) between a frame and its reference frame(s)');
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .15 .5 .08], 'style', 'text', 'string', 'Tracked point', 'horizontalalignment', 'right');
    gui.panel1.pointnr    = uicontrol(gui.panel1.panel, opts{:}, 'position', [.68 .15 .2 .1], 'style', 'popupmenu', 'string', [{'all'}; cellstr(num2str((1:15)'))], 'horizontalalignment', 'center', 'tag', 'autotrack_pointNr');

%% panel 2
    gui.panel2.overwritePoints  = uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .7 .35 .1], 'style', 'checkbox', 'string', 'Overwrite tracked points', 'value', 0, 'tag', 'autotrack_overwritePoints', 'tooltipstring', 'Overwrite already tracked points');
    gui.panel2.skipGaps         = uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .7 .35 .1], 'style', 'checkbox', 'string', 'Skip gaps', 'value', 0, 'tag', 'autotrack_skipGaps', 'tooltipstring', 'Skip to next pre-tracked point when object is lost');

    gui.panel2.useroi           = uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .55 .35 .1], 'style', 'checkbox', 'string', 'Use ROI', 'value', 0, 'tag', 'autotrack_useROI');
    gui.panel2.showim           = uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .55 .35 .1], 'style', 'checkbox', 'string', 'Show tracking', 'value', 0, 'tag', 'autotrack_showIm', 'tooltipstring', 'Display the tracked points while they are calculated. This takes at least 3x longer!');
    gui.panel2.showdiag         = uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .45 .35 .1], 'style', 'checkbox', 'string', 'Show diagnostics', 'value', 0, 'tag', 'autotrack_showDiag', 'tooltipstring', 'Display diagnostic plots during tracking. This increases tracking time by about 50-100%!');
    %                         uicontrol(gui.panel2.panel, opts{:}, 'position', [.07 .55 .31 .1], 'style', 'text', 'string', 'Reference frame', 'horizontalalignment', 'left');
    % gui.panel2.ref        = uicontrol(gui.panel2.panel, opts{:}, 'position', [.07 .45 .69 .1], 'style', 'edit', 'tag', 'autotrack_ref', 'horizontalalignment', 'right');
    %                         uicontrol(gui.panel2.panel, opts{:}, 'position', [.78 .45 .15 .1], 'style', 'pushbutton', 'string', 'Use Ref', 'tag', 'autotrack_useref');
    
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .21 .31 .08], 'style', 'text', 'string', 'Area threshold', 'horizontalalignment', 'left');
    gui.panel2.areathr    = sub_plusminustext(gui.panel2.panel, [.3 .21 .13 .1], 'autotrack_areaThr', 0.04);
                            set(gui.panel2.areathr, 'tooltipstring', 'Smallest area (in square pixels) that will be accepted as a trackable object.');
                            
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .21 .31 .08], 'style', 'text', 'string', 'Grey threshold', 'horizontalalignment', 'left', 'enable', 'on');
    gui.panel2.greythr    = sub_plusminustext(gui.panel2.panel, [.8 .21 .13 .1], 'autotrack_greyThr', 0.04);
                            set(gui.panel2.greythr, 'tooltipstring', 'Grey threshold (0-1). The lower this value, the more different an object has to be from the background to be detected.');
                            
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .06 .31 .08], 'style', 'text', 'string', 'Ref frame', 'horizontalalignment', 'left', 'enable', 'on');
    gui.panel2.refMethod  = uicontrol(gui.panel2.panel, opts{:}, 'position', [.255 .06 .22 .1], 'style', 'popupmenu', 'String', {'double', 'single',}, 'tag', 'autotrack_refMethod', 'enable', 'on', ...
        'tooltipstring', sprintf(['DOUBLE (default): Use the last frame and the next frame as references.\n', ...
                                  'SINGLE (faster, less accurate): Use only the last frame as a reference.']'));
                      
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .06 .31 .08], 'style', 'text', 'string', 'Method', 'horizontalalignment', 'left', 'enable', 'on');
    gui.panel2.findMethod = uicontrol(gui.panel2.panel, opts{:}, 'position', [.755 .06 .22 .1], 'style', 'popupmenu', 'String', {'darkest', '2nd nearest', 'largest', 'middle of 3'}, 'tag', 'autotrack_findMethod', 'enable', 'on', ...
        'tooltipstring', sprintf(['DARKEST (default): Choose the darkest, most salient point.\n', ...
                                  '2ND NEAREST: Of all detected foreground objects, choose the 2nd closest to the last point (assuming that the closest equals the last point).\n', ...
                                  'LARGEST: Of all detected foreground objects, choose the largest one.\n', ...
                                  'MIDDLE OF 3 (slowest): Of the three most salient points, choose the central one.']'));
                      
%% Control buttons
    opts = {'units', 'normalized', 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'style', 'pushbutton'}; 
    uicontrol(gui.fig, opts{:}, 'position', [.02 .07 .15 .1], 'string', 'Undo changes', 'callback', @buttonCallback_revert);
    uicontrol(gui.fig, opts{:}, 'position', [.18 .07 .15 .1], 'string', 'Save as default', 'callback', @buttonCallback_default);
    uicontrol(gui.fig, opts{:}, 'position', [.34 .07 .15 .1], 'string', 'Load default', 'callback', @buttonCallback_loaddefault);
    uicontrol(gui.fig, opts{:}, 'position', [.51 .07 .15 .1], 'string', 'Preview', 'callback', @sub_previewGui);
    uicontrol(gui.fig, opts{:}, 'position', [.67 .07 .15 .1], 'string', 'Start',   'callback', @buttonCallback_ok);
    uicontrol(gui.fig, opts{:}, 'position', [.83 .07 .15 .1], 'string', 'Cancel',  'callback', @buttonCallback_cancel);

end % sub_creategui

function outh = sub_plusminustext(inp, pos, tag, w, tts)
    if nargin<5, tts = ''; end
    % helper function for the gui, creates a text box with plus and minus buttons around it
    o = {'units', 'normalized', 'callback', editcb};
            uicontrol(inp, o{:}, 'position', [pos(1)-w-0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '-', 'horizontalalignment', 'right', 'tag', [tag '_minus']);
    outh  = uicontrol(inp, o{:}, 'position', pos, 'style', 'edit', 'horizontalalignment', 'center', 'tag', tag, 'tooltipstring', tts);
            uicontrol(inp, o{:}, 'position', [pos(1)+pos(3)+0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '+', 'horizontalalignment', 'right', 'tag', [tag '_plus']);
end    

%% Defaults
    function sub_load(type)
        defaults.from               = 1;
        defaults.to                 = status.mh.NFrames;
        defaults.step               = 1;
        defaults.refStep            = para.ref.frameDiff;
        defaults.pointNr            = status.cpoint;
        defaults.useROI             = 1;
        defaults.showIm             = 1;
        defaults.showDiag           = 1;
        defaults.areaThr            = 3;
        defaults.greyThr            = 0.5;
        defaults.refMethod          = 'double';
        defaults.findMethod         = 'darkest';
        defaults.para4              = NaN;
        defaults.overwritePoints    = false;
        defaults.skipGaps           = true;
        
        switch type
            case 'lastSession'
                if exist(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'file')
                    temp = load(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'autoPara', '-mat');
                    if isfield(temp, 'autoPara')
                        autoPara = dtrack_support_compstruct(temp.autoPara, defaults);
                    else
                        autoPara = defaults;
                    end
                else
                    autoPara = defaults;
                end
            case 'savedDefaults'
                if exist(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'file')
                    temp = load(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'autopara', '-mat');
                    if isfield(temp, 'autoPara')
                        autoPara = dtrack_support_compstruct(temp.autoPara, defaults);
                    else
                        autoPara = defaults;
                    end
                else
                    autoPara = defaults;
                end
            case 'defaults'
                autoPara = defaults;
            otherwise
                error('Unknown type');
        end
    end

    function sub_saveDefaults
        save(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'autoPara', '-mat');
        disp('Autotracking parameters saved to preferences directory.');
    end

    function sub_saveLastSession
        save(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'autoPara', '-mat');
        disp('Current parameters saved to preferences directory.');
    end


%% Button callbacks
    function buttonCallback_revert(varargin)
        % REVERT: revert to original 
        sub_load('lastSession');
        sub_setDef;
        sub_limit_fnrs('all');
        sub_updatePreview('all');
    end

    function buttonCallback_default(varargin)
        % DEFAULT: save current values as new default
        sub_saveDefaults;
    end

    function buttonCallback_loaddefault(varargin)
        % LOADDEFAULT: load default values
        sub_load('savedDefaults');
        sub_setDef;
        sub_limit_fnrs('all');
        sub_updatePreview('all');
    end

    function buttonCallback_ok(varargin)
        success = true;
        if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
            close(gui.prev.fig);
        end
        sub_saveLastSession;
        uiresume;
    end

    function buttonCallback_cancel(varargin)
        % CANCEL: cancel button callback finishes execution
        autoPara = [];
        success  = false;
        if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
            close(gui.prev.fig);
        end
        uiresume(gui.fig);
        delete(gui.fig);
    end

    function buttonCallback_close(varargin)
        % CLOSE: close button callback
        button = questdlg('Cancel operation?', 'Cancel', 'Continue', 'Cancel', 'Continue');
        switch button
            case 'Cancel'
                buttonCallback_cancel();
        end
    end

%%
    function sub_setDef
        %% set defaults
        set(gui.panel1.from,    'string', num2str(autoPara.from));
        set(gui.panel1.to,      'string', num2str(autoPara.to));
        set(gui.panel1.step,    'string', num2str(autoPara.step));
        set(gui.panel1.pointnr, 'value',  autoPara.pointNr+1);
        set(gui.panel1.refstep, 'string', num2str(autoPara.refStep));
        set(gui.panel2.useroi,  'value',  autoPara.useROI);
        set(gui.panel2.showim,  'value',  autoPara.showIm);   
        set(gui.panel2.showdiag,'value',  autoPara.showDiag);         
        set(gui.panel2.areathr, 'string', num2str(autoPara.areaThr));
        set(gui.panel2.greythr, 'string', num2str(autoPara.greyThr));
        strings = get(gui.panel2.findMethod, 'string');
        set(gui.panel2.findMethod,  'value', find(strcmp(strings, autoPara.findMethod)));
        strings = get(gui.panel2.refMethod, 'string');
        set(gui.panel2.refMethod,  'value', find(strcmp(strings, autoPara.refMethod)));
        set(gui.panel2.overwritePoints, 'value', autoPara.overwritePoints)
        set(gui.panel2.skipGaps, 'value', autoPara.skipGaps)
    end % sub_setdef

    function sub_limit_fnrs(autotrack_field, offset)
        % clamps frame number indicators to within 1 and status.mh.NFrames
        % autotrack_field can be 'from'/'to'/'step'/'refstep'/'all'
        if strcmp(autotrack_field, 'all')
            sub_limit_fnrs('from', 0)
            sub_limit_fnrs('to', 0)
            sub_limit_fnrs('step', 0)
            return
        end
        
        newval = str2double(get(gui.panel1.(autotrack_field), 'string')) + offset;
        if ismember(autotrack_field, {'refstep', 'step'})
            limval = min([status.mh.NFrames max([newval 1])]); % limit to possible frame numbers
        else
            switch autoPara.refMethod
                case 'single'
                    minval = 1 + autoPara.refStep;
                    maxval = status.mh.NFrames;
                case 'double'
                    minval = 1 + autoPara.refStep;
                    maxval = status.mh.NFrames-autoPara.refStep;
            end
            limval = min([maxval max([newval minval])]); % limit to possible frame numbers
        end
        autoPara.(autotrack_field) = limval;
        set(gui.panel1.(autotrack_field), 'string', num2str(limval));
    end
end