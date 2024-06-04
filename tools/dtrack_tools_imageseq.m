function [success, savepara] = dtrack_tools_imageseq(status, para)
% opens a dialog to save parts of the video as an image sequence
% See also: 

%% init parameters
gui = [];
autopara = [];
savepara = [];
success = 0;
editcb = @sub_callback;

%create
sub_loaddef_current;
autopara_def = autopara; % for restore
sub_creategui;
sub_setdef;

%% set figure to modal late after you know there are no errors
% set(gui.fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(gui.fig);
    delete(gui.fig);
catch anyerror
    delete(gui.fig); %delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%%%%%%%%%%%%%%%%%%%
%% Nested functions for callbacks, writing/drawing and panel creation
function sub_revert(varargin)
    % REVERT: revert to original 
    autopara = autopara_def;
    sub_setdef;
end

function sub_default(varargin)
    % DEFAULT: save current values as new default
    save(fullfile(prefdir, 'dtrack_imageseq.dtp'), 'autopara', '-mat');
    disp('Autotracking parameters saved to preferences directory.');
end

function sub_loaddefault(varargin)
    % LOADDEFAULT: load default values
    sub_loaddef;
    sub_setdef;
end

function sub_ok(varargin)
    % OK: ok button callback, returns the changed para and finishes execution
    savepara = autopara;
    success = 1;
    save(fullfile(prefdir, 'dtrack_imageseq_current.dtp'), 'autopara', '-mat'); % save current settings
    uiresume;
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback, returns unchanged para and finishes execution
    autopara = [];
    success  = 0;
    uiresume(gui.fig);
end

function sub_callback(src, varargin)
    switch get(src, 'tag')
        case {'imageseq_from', 'imageseq_to', 'imageseq_step'}
            newval = str2double(get(src, 'string'));
            limval = round(min([max([newval 1]) status.mh.NFrames])); % limit to valid numbers
            set(src, 'string', num2str(limval));
            switch get(src, 'tag')
                case 'imageseq_from'
                    autopara.from = limval;
                case 'imageseq_to'
                    autopara.to = limval;
                case 'imageseq_step'
                    autopara.step = limval;
            end
            
        case 'imageseq_format'
            newval = get(src, 'value');
            autopara.format = newval;
            sub_check_visibility();
            
        case 'imageseq_folder'
            autopara.folder = get(src, 'string');
            %TODO: check if the folder exists, otherwise confirm create
            
        case 'imageseq_basename'
            autopara.basename = get(src, 'string');
            
        case 'imageseq_browse'
            filename = dtrack_fileio_selectimageseq(get(gui.panel2.folder, 'string'));
            if filename~=0
                set(gui.panel2.folder, 'string', filename);
                autopara.folder = filename;
            end
            
        case 'imageseq_startfile'
            newval = str2double(get(src, 'string'));
            limval = max([round(newval) 0]);
            autopara.startfile = limval;
            set(src, 'string', num2str(limval));
            
        case 'imageseq_padding'
            newval = str2double(get(src, 'string'));
            limval = max([round(newval) 1]);
            autopara.padding = limval;
            set(src, 'string', num2str(limval));
            
        otherwise
            error('Internal error: Unknown caller');
    end
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
    screen = get(0, 'screensize');
    figsize = [screen(3)/2-300 screen(4)/2-200 600 400];
    %set up the figure
    gui.fig = figure(777);clf;

    set(gui.fig, 'outerposition', figsize, 'name', '', ...
    'backingstore', 'off', 'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @sub_close);

%% panels
    uicontrol(gui.fig, 'style', 'text', 'string', 'Save video as image sequence / video', ...
        'units', 'normalized', 'position', [.02 .81 .96 .17], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 18, 'fontweight', 'bold');
    gui.panel1.panel = uipanel(gui.fig, 'position', [.02 .22 .32 .57]);
    gui.panel2.panel = uipanel(gui.fig, 'position', [.36 .22 .62 .57]);

%% panel 1
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'Save from frame', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .6 .6 .1]);
    gui.panel1.from = uicontrol(gui.panel1.panel, 'style', 'edit', 'horizontalalignment', 'center', ...
        'units', 'normalized', 'position', [.73 .6 .2 .1], 'tag', 'imageseq_from', 'callback', editcb);
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'to frame', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .45 .6 .1]);
    gui.panel1.to = uicontrol(gui.panel1.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.73 .45 .2 .1], 'tag', 'imageseq_to', 'callback', editcb);
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'every', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .3 .6 .1]);
    gui.panel1.step = uicontrol(gui.panel1.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.73 .3 .2 .1], 'tag', 'imageseq_step', 'callback', editcb);

%% panel 2
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Format', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .825 .31 .1]);
    gui.panel2.format = uicontrol(gui.panel2.panel, 'style', 'popupmenu', 'string', 'Lossless TIFF (Default)|Compressed TIFF (10x smaller files)|JPEG, 75% (30x smaller files)|Motion JPEG AVI|MPEG-4', ...
        'units', 'normalized', 'position', [.07 .695 .86 .14], 'tag', 'imageseq_format', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Folder', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .55 .31 .1]);
    gui.panel2.folder = uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.07 .45 .69 .1], 'tag', 'imageseq_folder', 'horizontalalignment', 'right');
    uicontrol(gui.panel2.panel, 'style', 'pushbutton', 'string', 'Browse', ...
        'units', 'normalized', 'position', [.78 .45 .15 .1], 'tag', 'imageseq_browse', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Base name', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .31 .31 .1]);
    gui.panel2.basename = uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.07 .21 .86 .1], 'tag', 'imageseq_basename', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Start at', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.18 .06 .31 .1]);
    gui.panel2.startfile = uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.35 .06 .13 .1], 'tag', 'imageseq_startfile', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Padding', 'horizontalalignment', 'center', ...
        'units', 'normalized', 'position', [.52 .06 .16 .1]);
    gui.panel2.padding = uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.7 .06 .13 .1], 'tag', 'imageseq_padding', 'callback', editcb);

%% Control buttons    
    opts = {'units', 'normalized', 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'style', 'pushbutton'}; 
    uicontrol(gui.fig, opts{:}, 'position', [.03 .07 .18 .07], 'string', 'Undo changes', 'callback', @sub_revert);
    uicontrol(gui.fig, opts{:}, 'position', [.22 .07 .18 .07], 'string', 'Save as default', 'callback', @sub_default);
    uicontrol(gui.fig, opts{:}, 'position', [.41 .07 .18 .07], 'string', 'Load default', 'callback', @sub_loaddefault);
    uicontrol(gui.fig, opts{:}, 'position', [.60 .07 .18 .07], 'string', 'Start',   'callback', @sub_ok);
    uicontrol(gui.fig, opts{:}, 'position', [.79 .07 .18 .07], 'string', 'Cancel',  'callback', @sub_cancel);
    
end % sub_creategui

function sub_loaddef_current
    %% load default autopara
    if exist(fullfile(prefdir, 'dtrack_imageseq_current.dtp'), 'file')
        temp = load(fullfile(prefdir, 'dtrack_imageseq_current.dtp'), 'autopara', '-mat');
        autopara = temp.autopara; %TODO: Check that from/to/step/ref are not too large
    else
        sub_loaddef;
    end
end % sub_loaddef_current

function sub_loaddef
    %% load default autopara
    if exist(fullfile(prefdir, 'dtrack_imageseq.dtp'), 'file')
        temp = load(fullfile(prefdir, 'dtrack_imageseq.dtp'), 'autopara', '-mat');
        autopara = temp.autopara; %TODO: Check that from/to/step/ref are not too large
    else
        autopara.from       = 1;
        autopara.to         = status.mh.NFrames;
        autopara.step       = 1;
        autopara.format     = 1;
        if ~isempty(para.paths.respath)
            autopara.folder = fileparts(para.paths.respath);
        else
            autopara.folder = para.paths.resdef;
        end
        [~, movbase]        = fileparts(para.paths.movname);
        autopara.basename   = [movbase '_out'];
        autopara.startfile  = 1;
        autopara.padding    = 4;
    end
end % sub_loaddef
    
function sub_setdef
    %% set defaults
    set(gui.panel1.from,      'string', num2str(autopara.from));
    set(gui.panel1.to,        'string', num2str(autopara.to));
    set(gui.panel1.step,      'string', num2str(autopara.step));
    set(gui.panel2.format,    'value',  autopara.format);
    if ~isempty(para.paths.respath)
        autopara.folder = fileparts(para.paths.respath);
    else
        autopara.folder = para.paths.resdef;
    end
    [~, movbase]        = fileparts(para.paths.movname);
    autopara.basename   = [movbase '_out'];
    set(gui.panel2.folder,    'string', autopara.folder);
    set(gui.panel2.basename,  'string', autopara.basename);        
    set(gui.panel2.startfile, 'string', num2str(autopara.startfile));
    set(gui.panel2.padding,   'string', num2str(autopara.padding));
    sub_check_visibility();
end % sub_setdef

function sub_check_visibility
    switch autopara.format
        case {1, 2, 3}
            % image sequence formats
            set(findobj('tag', 'imageseq_startfile'), 'enable', 'on');
            set(findobj('tag', 'imageseq_padding'), 'enable', 'on');
        case {4, 5}
            % video formats
            set(findobj('tag', 'imageseq_startfile'), 'enable', 'off');
            set(findobj('tag', 'imageseq_padding'), 'enable', 'off');
    end
end
    
end