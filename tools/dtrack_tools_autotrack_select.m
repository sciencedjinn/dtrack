function [success, autopara] = dtrack_tools_autotrack_select(status, para, data)
% DTRACK_TOOLS_AUTOTRACK_SELECT opens a dialog to select parameters for autotracking
% Call: [success, autopara] = dtrack_tools_autotrack_select(status, para)
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_main

%% init parameters
gui          = [];
autopara     = [];
prevdata     = [];
success      = 0;
editcb       = @sub_callback;

% create
sub_loaddef_current;
autopara_def = autopara; % for restore
sub_creategui;
sub_setdef;

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




%% General callback
function sub_callback(src, varargin)
    switch get(src, 'tag')
        case {'autotrack_from', 'autotrack_to', 'autotrack_step', 'autotrack_ref'}
            newval = str2double(get(src, 'string'));
            limval = round(min([max([newval 1]) status.mh.NFrames])); % limit to possible frame numbers
            set(src, 'string', num2str(limval)); 
            switch get(src, 'tag')
                case 'autotrack_from'
                    autopara.from = limval;
                    sub_preview_update('im'); % TODO: Test frame should have its own control
                case 'autotrack_to'
                    autopara.to = limval;
                case 'autotrack_step'
                    autopara.step = limval;
                case 'autotrack_ref'
                    autopara.ref = limval;
                    sub_preview_update('ref');
            end
            
        case 'autotrack_pointnr'
            newval = str2double(get(src, 'string'));
            limval = round(min([max([newval 1]) status.trackedpoints]));
            set(src, 'string', num2str(limval));
            autopara.pointnr = limval;
            
        case 'autotrack_useref'
            set(gui.panel2.ref, 'string', num2str(para.ref.framenr));
            autopara.ref = para.ref.framenr;
            sub_preview_update('ref');
            
        case 'autotrack_areathresh'
            autopara.areathresh = str2double(get(src, 'string'));
            sub_preview_update('area');
            
        case 'autotrack_greythresh'
            autopara.greythresh = str2double(get(src, 'string'));
            sub_preview_update('grey');
            
        case 'autotrack_method'
            strings = get(src, 'string');
            autopara.method = strings{get(src, 'Value')};
            sub_preview_update('method');
            
        case 'autotrack_para4'
            
        case 'autotrack_showim'
            autopara.showim = get(src, 'value');
            
        case 'autotrack_useroi'
            autopara.useroi = get(src, 'value');
            sub_preview_update('roi');
            
        % plus/minus buttons
        case 'autotrack_from_minus'
            newval = str2double(get(gui.panel1.from, 'string')) - 1;
            limval = max([newval 1]); % limit to possible frame numbers
            set(gui.panel1.from, 'string', num2str(limval));
            autopara.from = limval;
            sub_preview_update('im');
            
        case 'autotrack_from_plus'
            newval = str2double(get(gui.panel1.from, 'string')) + 1;
            limval = min([newval status.mh.NFrames]); % limit to possible frame numbers
            set(gui.panel1.from, 'string', num2str(limval));
            autopara.from = limval;
            sub_preview_update('im');
            
        case 'autotrack_to_minus'
            newval = str2double(get(gui.panel1.to, 'string')) - 1;
            limval = max([newval 1]); % limit to possible frame numbers
            set(gui.panel1.to, 'string', num2str(limval));
            autopara.to = limval;
            
        case 'autotrack_to_plus'
            newval = str2double(get(gui.panel1.to, 'string')) + 1;
            limval = min([newval status.mh.NFrames]); % limit to possible frame numbers
            set(gui.panel1.to, 'string', num2str(limval));
            autopara.to = limval;
            
        case 'autotrack_step_minus'
            newval = str2double(get(gui.panel1.step, 'string')) - 1;
            limval = max([newval 1]); % limit to possible frame numbers
            set(gui.panel1.step, 'string', num2str(limval));
            autopara.step = limval;
            
        case 'autotrack_step_plus'
            newval = str2double(get(gui.panel1.step, 'string')) + 1;
            limval = min([newval status.mh.NFrames]); % limit to possible frame numbers
            set(gui.panel1.step, 'string', num2str(limval));
            autopara.step = limval;
            
        case 'autotrack_areathresh_minus'
            newval = str2double(get(gui.panel2.areathresh, 'string')) - 1;
            autopara.areathresh = newval;
            set(gui.panel2.areathresh, 'string', num2str(newval));
            sub_preview_update('area');
            
        case 'autotrack_areathresh_plus'
            newval = str2double(get(gui.panel2.areathresh, 'string')) + 1;
            autopara.areathresh = newval;
            set(gui.panel2.areathresh, 'string', num2str(newval));
            sub_preview_update('area');
            
        case 'autotrack_greythresh_minus'
            newval = str2double(get(gui.panel2.greythresh, 'string')) - 0.1;
            autopara.greythresh = newval;
            set(gui.panel2.greythresh, 'string', num2str(newval));
            sub_preview_update('grey');
            
        case 'autotrack_greythresh_plus'
            newval = str2double(get(gui.panel2.greythresh, 'string')) + 0.1;
            autopara.greythresh = newval;
            set(gui.panel2.greythresh, 'string', num2str(newval));
            sub_preview_update('grey');
            
        otherwise
            error('Internal error: Unknown caller %s', get(src, 'tag'));
    end
end

%% Button callbacks
function sub_revert(varargin)
    % REVERT: revert to original 
    autopara = autopara_def;
    sub_setdef;
    sub_preview_update('all');
end

function sub_default(varargin)
    % DEFAULT: save current values as new default
    save(fullfile(prefdir, 'dtrack_autopara_bgs.dtp'), 'autopara', '-mat');
    disp('Autotracking parameters saved to preferences directory.');
end

function sub_loaddefault(varargin)
    % LOADDEFAULT: load default values
    sub_loaddef;
    sub_setdef;
    sub_preview_update('all');
end

function sub_preview_gui(varargin)
    % PREVIEW: preview button callback
    gui.prev.fig   = uifigure(2973); clf;
    gui.prev.ph(1) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 .5 .5 .5]);
    gui.prev.ph(2) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 .5 .5 .5]);
    gui.prev.ph(3) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 0 .5 .5]);
    gui.prev.ph(4) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 0 .5 .5]);
    
    gui.prev.ah(1) = axes('parent', gui.prev.ph(1), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(2) = axes('parent', gui.prev.ph(2), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(3) = axes('parent', gui.prev.ph(3), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(4) = axes('parent', gui.prev.ph(4), 'units', 'normalized', 'position', [0 0 1 1]);
    sub_preview_update('all');

%         gui.prev.fig   = uifigure(2973); clf;
%     gui.prev.gh    = uigridlayout(gui.prev.fig, [2 2], 'RowSpacing', 0, 'ColumnSpacing', 0);
% %     gui.prev.ph(1) = uipanel(gui.prev.gh);
% %     gui.prev.ph(2) = uipanel(gui.prev.gh);
% %     gui.prev.ph(3) = uipanel(gui.prev.gh);
% %     gui.prev.ph(4) = uipanel(gui.prev.gh);
%     
%     gui.prev.ah(1) = uiaxes(gui.prev.gh, 'units', 'normalized', 'outerposition', [0 0 1 1]);
%     gui.prev.ah(2) = uiaxes(gui.prev.gh, 'units', 'normalized', 'outerposition', [0 0 1 1]);
%     gui.prev.ah(3) = uiaxes(gui.prev.gh, 'units', 'normalized', 'outerposition', [0 0 1 1]);
%     gui.prev.ah(4) = uiaxes(gui.prev.gh, 'units', 'normalized', 'outerposition', [0 0 1 1]);
%     sub_preview_update('all');
end

function sub_preview_update(type)
    if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
        % gather parameters
        if ismember(type, {'all', 'ref'}) % update reference frame
            status.framenr  = str2double(get(gui.panel2.ref, 'string'));
            [~, status]     = dtrack_action([], status, para, data, 'loadonly');
            prevdata.ref             = status.currim_ori;
        end
        if ismember(type, {'all', 'im'}) % update image frame
            status.framenr  = str2double(get(gui.panel1.from, 'string'));
            [~, status]     = dtrack_action([], status, para, data, 'loadonly');
            prevdata.im   = status.currim_ori;
        end
        if ismember(type, {'all', 'roi'}) % update ROI
            if get(gui.panel2.useroi, 'value') && ~isempty(status.roi)
                switch status.roi(1, 1)
                    case 0  % 0 indicates polygon vertices
                        [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                        prevdata.roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));   
                    case 1  % 1 indicates ellipse
                        [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                        prevdata.roimask = inellipse(Y, X, status.roi(2:end)); 
                    otherwise 
                        error('Internal error: Unknown ROI type');
                end
            else
                prevdata.roimask = [];
            end
        end
        if ismember(type, {'all', 'grey'}) % update grey threshold
            prevdata.greythr = str2double(get(gui.panel2.greythresh, 'string'));
        end
        if ismember(type, {'all', 'area'}) % update area threshold 
            prevdata.areathr = str2double(get(gui.panel2.areathresh, 'string'));
        end
        if ismember(type, {'all', 'method'}) % update method 
            strings = get(gui.panel2.method, 'string');
            prevdata.method = strings{get(gui.panel2.method, 'Value')};
        end
                
        % calculate centroids
        [outcentroid, outarea, diagims] = dtrack_tools_autotrack_detect(prevdata.ref, prevdata.im, prevdata.roimask, prevdata.greythr, prevdata.areathr, prevdata.method);
        
        % plot
        dtrack_tools_autotrack_plotdiag(prevdata.im, diagims, outcentroid, outarea, gui.prev.ah);        
    end
end

function sub_ok(varargin)
    success = 1;
    if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
        close(gui.prev.fig);
    end
    save(fullfile(prefdir, 'dtrack_autopara_bgs_current.dtp'), 'autopara', '-mat'); % save current settings
    uiresume;
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback finishes execution
    autopara = [];
    success  = 0;
    if isfield(gui, 'prev') && isfield(gui.prev, 'fig') && isvalid(gui.prev.fig)
        close(gui.prev.fig);
    end
    uiresume(gui.fig);
end

function sub_close(varargin)
    % CLOSE: close button callback
    button = questdlg('Cancel operation?', 'Cancel', 'Continue', 'Cancel', 'Continue');
    switch button
        case 'Cancel'
            sub_cancel();
    end
end

function sub_creategui
    screen  = get(0, 'screensize');
    figsize = [600 400];
    figpos  = [screen(3)/2-figsize(1)/2 screen(4)/2-figsize(2)/2 figsize(1) figsize(2)];
    %set up the figure
    gui.fig = figure(777); clf;
    set(gui.fig, 'outerposition', figpos, 'name', '', 'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @sub_close);

%% panels
    uicontrol(gui.fig, 'style', 'text', 'string', 'Autotracking parameters', 'units', 'normalized', 'position', [.02 .81 .96 .17], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 15, 'fontweight', 'bold');
    uicontrol(gui.fig, 'style', 'text', 'units', 'normalized', 'position', [.02 .84 .96 .06], 'string', 'Background subtraction method', 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 10);
    gui.panel1.panel = uipanel(gui.fig, 'position', [.02 .22 .32 .57]);
    gui.panel2.panel = uipanel(gui.fig, 'position', [.36 .22 .62 .57]);

%% panel 1
    opts = {'units', 'normalized', 'callback', editcb};
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .75 .5 .08], 'style', 'text', 'string', 'From frame', 'horizontalalignment', 'right');
    gui.panel1.from       = sub_plusminustext(gui.panel1.panel, [.68 .75 .2 .1], 'autotrack_from', 0.08);
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .6 .5 .08], 'style', 'text', 'string', 'to frame', 'horizontalalignment', 'right');
    gui.panel1.to         = sub_plusminustext(gui.panel1.panel, [.68 .6 .2 .1], 'autotrack_to', 0.08);
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .45 .5 .08], 'style', 'text', 'string', 'every', 'horizontalalignment', 'right');
    gui.panel1.step       = sub_plusminustext(gui.panel1.panel, [.68 .45 .2 .1], 'autotrack_step', 0.08);
                            uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .3 .5 .08], 'style', 'text', 'string', 'Save to point #', 'horizontalalignment', 'right');
    gui.panel1.pointnr    = uicontrol(gui.panel1.panel, opts{:}, 'position', [.68 .3 .2 .1], 'style', 'edit', 'horizontalalignment', 'center', 'tag', 'autotrack_pointnr');
    %                         uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .45 .5 .1], 'style', 'text', 'string', 'every', 'horizontalalignment', 'right');
    % gui.panel1.step       = uicontrol(gui.panel1.panel, opts{:}, 'position', [.63 .45 .2 .1], 'style', 'edit', 'tag', 'autotrack_step');

%% panel 2
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .79 .31 .1], 'style', 'text', 'string', 'Reference frame', 'horizontalalignment', 'left');
    gui.panel2.ref        = uicontrol(gui.panel2.panel, opts{:}, 'position', [.03 .69 .69 .1], 'style', 'edit', 'tag', 'autotrack_ref', 'tooltipstring', 'The frame number of a frame that contains only background. This frame will be subtracted from each frame for tracking.');
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.78 .69 .15 .1], 'style', 'pushbutton', 'string', 'Use Ref', 'tag', 'autotrack_useref', 'tooltipstring', 'Use the reference frame set previously in the main program.');
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
    gui.panel2.method     = uicontrol(gui.panel2.panel, opts{:}, 'position', [.28 .06 .2 .1], 'style', 'popupmenu', 'String', {'largest', 'nearest', 'absolute'}, 'tag', 'autotrack_method', 'enable', 'on', 'tooltipstring', 'NEAREST: Of all detected foreground objects, tracking will choose the one that is closest to the last tracked point.   LARGEST: Of all detected foreground objects, tracking will choose the largest one.');
                            uicontrol(gui.panel2.panel, opts{:}, 'position', [.53 .06 .31 .08], 'style', 'text', 'string', 'Parameter 4', 'horizontalalignment', 'left', 'enable', 'off');
    gui.panel2.para4      = uicontrol(gui.panel2.panel, opts{:}, 'position', [.8 .06 .13 .1], 'style', 'edit', 'tag', 'autotrack_para4', 'enable', 'off');

%% Control buttons
    opts = {'units', 'normalized', 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'style', 'pushbutton'}; 
    uicontrol(gui.fig, opts{:}, 'position', [.02 .07 .15 .1], 'string', 'Undo changes', 'callback', @sub_revert);
    uicontrol(gui.fig, opts{:}, 'position', [.18 .07 .15 .1], 'string', 'Save as default', 'callback', @sub_default);
    uicontrol(gui.fig, opts{:}, 'position', [.34 .07 .15 .1], 'string', 'Load default', 'callback', @sub_loaddefault);
    uicontrol(gui.fig, opts{:}, 'position', [.51 .07 .15 .1], 'string', 'Preview', 'callback', @sub_preview_gui);
    uicontrol(gui.fig, opts{:}, 'position', [.67 .07 .15 .1], 'string', 'Start',   'callback', @sub_ok);
    uicontrol(gui.fig, opts{:}, 'position', [.83 .07 .15 .1], 'string', 'Cancel',  'callback', @sub_cancel);

end %sub_creategui

function outh = sub_plusminustext(inp, pos, tag, w)
    % helper function for the gui, creates a text box with plus and minus buttons around it
    o = {'units', 'normalized', 'callback', editcb};
            uicontrol(inp, o{:}, 'position', [pos(1)-w-0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '-', 'horizontalalignment', 'right', 'tag', [tag '_minus']);
    outh  = uicontrol(inp, o{:}, 'position', pos, 'style', 'edit', 'horizontalalignment', 'center', 'tag', tag);
            uicontrol(inp, o{:}, 'position', [pos(1)+pos(3)+0.005 pos(2) w pos(4)], 'style', 'pushbutton', 'string', '+', 'horizontalalignment', 'right', 'tag', [tag '_plus']);
end    

function sub_loaddef_current
    %% load default autopara
    if exist(fullfile(prefdir, 'dtrack_autopara_bgs_current.dtp'), 'file')
        temp = load(fullfile(prefdir, 'dtrack_autopara_bgs_current.dtp'), 'autopara', '-mat');
        autopara = temp.autopara; %TODO: Check that from/to/step/ref are not too large
    else
        sub_loaddef;
    end
end %sub_loaddef_current

function sub_loaddef
    %% load default autopara
    if exist(fullfile(prefdir, 'dtrack_autopara_bgs.dtp'), 'file')
        temp = load(fullfile(prefdir, 'dtrack_autopara_bgs.dtp'), 'autopara', '-mat');
        autopara = temp.autopara; %TODO: Check that from/to/step/ref are not too large
    else
        autopara.from       = 1;
        autopara.to         = status.mh.NFrames;
        autopara.step       = 1;
        autopara.pointnr    = status.cpoint;
        switch para.ref.use
            case 'none'
                autopara.ref    = status.framenr;
            case 'static'
                autopara.ref    = para.ref.framenr;
            case 'dynamic'
                autopara.ref    = -para.ref.frameDiff; %TODO: Make use of this number
        end
        autopara.useroi     = 1;
        autopara.showim     = 1;
        autopara.areathresh = 50;
        autopara.greythresh = 3;
        autopara.method     = 'nearest';
        autopara.para4      = NaN;
    end
end %sub_loaddef

function sub_setdef
    %% set defaults
    set(gui.panel1.from,    'string', num2str(autopara.from));
    set(gui.panel1.to,      'string', num2str(autopara.to));
    set(gui.panel1.step,    'string', num2str(autopara.step));
    set(gui.panel1.pointnr, 'string', num2str(autopara.pointnr));
    set(gui.panel2.ref,     'string', num2str(autopara.ref));
    set(gui.panel2.useroi,  'value', autopara.useroi);
    set(gui.panel2.showim,  'value', autopara.showim);        
    set(gui.panel2.areathresh, 'string', num2str(autopara.areathresh));
    set(gui.panel2.greythresh, 'string', num2str(autopara.greythresh));
    strings = {'largest', 'nearest', 'absolute'};
    set(gui.panel2.method,  'value', find(strcmp(strings, autopara.method)));
    set(gui.panel2.para4,   'string', num2str(autopara.para4));
end %sub_setdef

end