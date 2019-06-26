function [success, autopara] = holo_autotrack_select(status, para, data)
% holo_autotrack_select opens a dialog to select parameters for autotracking
% Call: [success, autopara] = dtrack_tools_autotrack_select(status, para)
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_main
% Data paradigm: autopara contains the current representation of data at any time. GUI should be close to being controlled components.

%% init parameters
gui          = [];
autopara     = [];
prevpara     = [];
success      = 0;
editcb       = @sub_callback;

% load last session's parameters, and change the ones that depend on this dataset
sub_loadLastSession;
autopara.pointnr = status.cpoint;
if isempty(status.roi)
    autopara.useroi = 0;
end
sub_saveLastSession;

% create GUI and set fields
sub_createGui;
sub_setDef;
sub_limit_fnrs('all');

%% set figure to modal late after you know there are no errors
%set(gui.fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
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
        case 'autotrack_refstep'
            sub_limit_fnrs('refstep', 0);
            sub_limit_fnrs('all');
            sub_updatePreview('im');         
            
        case 'autotrack_pointnr'
            autopara.pointnr = get(src, 'value');
            sub_updatePreview('im');
            
        case 'autotrack_areathresh'
            autopara.areathresh = str2double(get(src, 'string'));
            sub_updatePreview('area');
            
        case 'autotrack_greythresh'
            autopara.greythresh = str2double(get(src, 'string'));
            sub_updatePreview('grey');
            
        case 'autotrack_method'
            strings = get(src, 'string');
            autopara.method = strings{get(src, 'Value')};
            sub_limit_fnrs('all');
            sub_updatePreview('method');
            
        case 'autotrack_para4'
            
        case 'autotrack_showim'
            autopara.showim = get(src, 'value');
            
        case 'autotrack_useroi'
            autopara.useroi = get(src, 'value');
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
        case 'autotrack_refstep_minus'
            sub_limit_fnrs('refstep', -1);
            sub_limit_fnrs('all');
            sub_updatePreview('im');
        case 'autotrack_refstep_plus'
            sub_limit_fnrs('refstep', +1);
            sub_limit_fnrs('all');
            sub_updatePreview('im');

        case 'autotrack_areathresh_minus'
            newval = str2double(get(gui.panel2.areathresh, 'string')) - 1;
            autopara.areathresh = newval;
            set(gui.panel2.areathresh, 'string', num2str(newval));
            sub_updatePreview('area');
            
        case 'autotrack_areathresh_plus'
            newval = str2double(get(gui.panel2.areathresh, 'string')) + 1;
            autopara.areathresh = newval;
            set(gui.panel2.areathresh, 'string', num2str(newval));
            sub_updatePreview('area');
            
        case 'autotrack_greythresh_minus'
            newval = str2double(get(gui.panel2.greythresh, 'string')) - 0.1;
            autopara.greythresh = newval;
            set(gui.panel2.greythresh, 'string', num2str(newval));
            sub_updatePreview('grey');
            
        case 'autotrack_greythresh_plus'
            newval = str2double(get(gui.panel2.greythresh, 'string')) + 0.1;
            autopara.greythresh = newval;
            set(gui.panel2.greythresh, 'string', num2str(newval));
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
        if ismember(type, {'all', 'im', 'method'})            
            if ismember(autopara.method, {'Max of 3', 'Centre of 3'})
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
                        [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
                        prevpara.roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
                    case 1  % 1 indicates ellipse
                        [X,Y]   = ndgrid(1:status.vidHeight, 1:status.vidWidth);
                        prevpara.roimask = inellipse(Y, X, status.roi(2:end)); 
                    otherwise 
                        error('Internal error: Unknown ROI type');
                end
            else
                prevpara.roimask = [];
            end
        end
        if ismember(type, {'all', 'grey', 'area', 'method'})
            prevpara.greythr = autopara.greythresh;
            prevpara.areathr = autopara.areathresh;
            prevpara.method  = autopara.method;
        end
                
        % calculate centroids
        [outcentroid, outarea, diagims] = holo_autotrack_detect(prevpara.im, prevpara.ref1, prevpara.ref2, prevpara, para, data.points(framenr, pointnr, :)); % FIXME: This is the current point, should be last point
        
        % plot
        holo_autotrack_plotdiag(diagims, outcentroid, outarea, gui.prev.ah);        
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
    gui.panel1.refstep    = sub_plusminustext(gui.panel1.panel, [.68 .3 .2 .1], 'autotrack_refstep', 0.08, 'Distance (in frames) between a frame and its reference frame(s)');
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .15 .5 .08], 'style', 'text', 'string', 'Tracked point', 'horizontalalignment', 'right');
    gui.panel1.pointnr    = uicontrol(gui.panel1.panel, opts{:}, 'position', [.68 .15 .2 .1], 'style', 'popupmenu', 'string', num2str((1:para.pnr)'), 'horizontalalignment', 'center', 'tag', 'autotrack_pointnr');
    %                         uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .45 .5 .1], 'style', 'text', 'string', 'every', 'horizontalalignment', 'right');
    % gui.panel1.step       = uicontrol(gui.panel1.panel, opts{:}, 'position', [.63 .45 .2 .1], 'style', 'edit', 'tag', 'autotrack_step');

%% panel 2
    gui.panel2.useroi     = uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .55 .35 .1], 'style', 'checkbox', 'string', 'Use ROI', 'value', 0, 'tag', 'autotrack_useroi');
    gui.panel2.showim     = uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .55 .35 .1], 'style', 'checkbox', 'string', 'Show tracking', 'value', 0, 'tag', 'autotrack_showim', 'tooltipstring', 'Display the tracked points while they are calculated. This takes at least 3x longer!');
    %                         uicontrol(gui.panel2.panel, opts{:}, 'position', [.07 .55 .31 .1], 'style', 'text', 'string', 'Reference frame', 'horizontalalignment', 'left');
    % gui.panel2.ref        = uicontrol(gui.panel2.panel, opts{:}, 'position', [.07 .45 .69 .1], 'style', 'edit', 'tag', 'autotrack_ref', 'horizontalalignment', 'right');
    %                         uicontrol(gui.panel2.panel, opts{:}, 'position', [.78 .45 .15 .1], 'style', 'pushbutton', 'string', 'Use Ref', 'tag', 'autotrack_useref');
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .21 .31 .08], 'style', 'text', 'string', 'Area threshold', 'horizontalalignment', 'left');
    gui.panel2.areathresh = sub_plusminustext(gui.panel2.panel, [.3 .21 .13 .1], 'autotrack_areathresh', 0.04);
                            set(gui.panel2.areathresh, 'tooltipstring', 'Smallest area (in square pixels) that will be accepted for tracking.');
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .21 .31 .08], 'style', 'text', 'string', 'Grey threshold', 'horizontalalignment', 'left', 'enable', 'on');
    gui.panel2.greythresh = sub_plusminustext(gui.panel2.panel, [.8 .21 .13 .1], 'autotrack_greythresh', 0.04);
                            set(gui.panel2.greythresh, 'tooltipstring', 'Multiplier for the grey threshold. The higher this value, the more different an object has to be from the background to be detected.');
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .06 .31 .08], 'style', 'text', 'string', 'Method', 'horizontalalignment', 'left', 'enable', 'on');
    gui.panel2.method     = uicontrol(gui.panel2.panel, opts{:}, 'position', [.28 .06 .2 .1], 'style', 'popupmenu', 'String', {'2nd nearest', 'Max of 3', 'Centre of 3'}, 'tag', 'autotrack_method', 'enable', 'on', ...
        'tooltipstring', sprintf(['2ND NEAREST: Of all detected foreground objects, choose the 2nd closest to the last point (the closest equals the last point).\n', ...
                          'MAX OF 3: Take into account last and next frame as reference, then choose the darkest point.\n', ...
                          'MIDDLE OF 3: Take into account last and next frame as reference, then choose the central point.']'));
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .06 .31 .08], 'style', 'text', 'string', 'Parameter 4', 'horizontalalignment', 'left', 'enable', 'off');
    gui.panel2.para4      = uicontrol(gui.panel2.panel, opts{:}, 'position', [.8 .06 .13 .1], 'style', 'edit', 'tag', 'autotrack_para4', 'enable', 'off');

%% Control buttons
    opts = {'units', 'normalized', 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'style', 'pushbutton'}; 
    uicontrol(gui.fig, opts{:}, 'position', [.02 .07 .15 .1], 'string', 'Undo changes', 'callback', @buttonCallback_revert);
    uicontrol(gui.fig, opts{:}, 'position', [.18 .07 .15 .1], 'string', 'Save as default', 'callback', @buttonCallback_default);
    uicontrol(gui.fig, opts{:}, 'position', [.34 .07 .15 .1], 'string', 'Load default', 'callback', @buttonCallback_loaddefault);
    uicontrol(gui.fig, opts{:}, 'position', [.51 .07 .15 .1], 'string', 'Preview', 'callback', @sub_previewGui);
    uicontrol(gui.fig, opts{:}, 'position', [.67 .07 .15 .1], 'string', 'Start',   'callback', @buttonCallback_ok);
    uicontrol(gui.fig, opts{:}, 'position', [.83 .07 .15 .1], 'string', 'Cancel',  'callback', @buttonCallback_cancel);

end %sub_creategui

function outh = sub_plusminustext(inp, pos, tag, w, tts)
    if nargin<5, tts = ''; end
    % helper function for the gui, creates a text box with plus and minus buttons around it
    o = {'units', 'normalized', 'callback', editcb};
            uicontrol(inp, o{:}, 'position', [pos(1)-w-0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '-', 'horizontalalignment', 'right', 'tag', [tag '_minus']);
    outh  = uicontrol(inp, o{:}, 'position', pos, 'style', 'edit', 'horizontalalignment', 'center', 'tag', tag, 'tooltipstring', tts);
            uicontrol(inp, o{:}, 'position', [pos(1)+pos(3)+0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '+', 'horizontalalignment', 'right', 'tag', [tag '_plus']);
end    

%% Defaults
    function sub_loadDefaults
        if exist(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'file')
            temp = load(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'autopara', '-mat');
            autopara = temp.autopara;
        else
            autopara.from       = 1;
            autopara.to         = status.nFrames;
            autopara.step       = 1;
            autopara.refstep    = para.ref.frameDiff;
            autopara.pointnr    = status.cpoint;
            autopara.useroi     = 1;
            autopara.showim     = 1;
            autopara.areathresh = 50;
            autopara.greythresh = 3;
            autopara.method     = '2nd nearest';
            autopara.para4      = NaN;
        end
    end

    function sub_saveDefaults
        save(fullfile(prefdir, 'holo_autopara_bgs.dtp'), 'autopara', '-mat');
        disp('Autotracking parameters saved to preferences directory.');
    end

    function sub_loadLastSession
        if exist(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'file')
            temp = load(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'autopara', '-mat');
            autopara = temp.autopara;
        else
            sub_loadDefaults;
        end
    end

    function sub_saveLastSession
        save(fullfile(prefdir, 'holo_autopara_bgs_current.dtp'), 'autopara', '-mat'); % save current settings
    end


%% Button callbacks
    function buttonCallback_revert(varargin)
        % REVERT: revert to original 
        sub_loadLastSession;
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
        sub_loadDefaults;
        sub_setDef;
        sub_limit_fnrs('all');
        sub_updatePreview('all');
    end

    function buttonCallback_ok(varargin)
        success = 1;
        if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
            close(gui.prev.fig);
        end
        sub_saveLastSession;
        uiresume;
    end

    function buttonCallback_cancel(varargin)
        % CANCEL: cancel button callback finishes execution
        autopara = [];
        success  = 0;
        if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
            close(gui.prev.fig);
        end
        uiresume(gui.fig);
    end

    function buttonCallback_close(varargin)
        % CLOSE: close button callback
        button = questdlg('Cancel operation?', 'Cancel', 'Continue', 'Cancel', 'Continue');
        switch button
            case 'Cancel'
                buttonCallback_cancel();
        end
    end

function sub_setDef
    %% set defaults
    set(gui.panel1.from,    'string', num2str(autopara.from));
    set(gui.panel1.to,      'string', num2str(autopara.to));
    set(gui.panel1.step,    'string', num2str(autopara.step));
    set(gui.panel1.pointnr, 'value',  autopara.pointnr);
    set(gui.panel1.refstep, 'string', num2str(autopara.refstep));
    set(gui.panel2.useroi,  'value',  autopara.useroi);
    set(gui.panel2.showim,  'value',  autopara.showim);        
    set(gui.panel2.areathresh, 'string', num2str(autopara.areathresh));
    set(gui.panel2.greythresh, 'string', num2str(autopara.greythresh));
    strings = {'2nd nearest', 'Max of 3', 'Middle of 3'};
    set(gui.panel2.method,  'value', find(strcmp(strings, autopara.method)));
    set(gui.panel2.para4,   'string', num2str(autopara.para4));
end % sub_setdef

function sub_limit_fnrs(autotrack_field, offset)
    if strcmp(autotrack_field, 'all')
        sub_limit_fnrs('from', 0)
        sub_limit_fnrs('to', 0)
        sub_limit_fnrs('step', 0)
        return
    end
    newval = str2double(get(gui.panel1.(autotrack_field), 'string')) + offset;
    if ismember(autotrack_field, {'refstep', 'step'})
        limval = min([status.nFrames max([newval 1])]); % limit to possible frame numbers
    else
        switch autopara.method
            case '2nd nearest'
                minval = 1 + autopara.refstep;
                maxval = status.nFrames;
            case {'Max of 3', 'Centre of 3'}
                minval = 1 + autopara.refstep;
                maxval = status.nFrames-autopara.refstep;
        end
        limval = min([maxval max([newval minval])]); % limit to possible frame numbers
    end
    autopara.(autotrack_field) = limval;
    set(gui.panel1.(autotrack_field), 'string', num2str(limval));
end
end