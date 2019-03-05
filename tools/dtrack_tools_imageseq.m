function [success, savepara]=dtrack_tools_imageseq(status, para)
% opens a dialog to save parts of the video as an image sequence
% See also: 

%% init parameters
gui=[];
savepara=[];
success=0;
editcb=@sub_callback;

%create
sub_creategui;
sub_setdef;

%% set figure to modal late after you know there are no errors
set(gui.fig, 'windowStyle', 'modal');

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
function sub_OK(varargin)
    % OK: ok button callback, returns the changed para and finishes execution
    savepara.from=str2double(get(gui.panel1.from, 'string'));
    savepara.to=str2double(get(gui.panel1.to, 'string'));
    savepara.step=str2double(get(gui.panel1.step, 'string'));
    savepara.format=get(gui.panel2.format, 'value');
    savepara.folder=get(gui.panel2.folder, 'string');
    savepara.basename=get(gui.panel2.basename, 'string');
    savepara.startfile=str2double(get(gui.panel2.startfile, 'string'));
    savepara.padding=str2double(get(gui.panel2.padding, 'string'));
    success=1;
    uiresume;
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback, returns unchanged para and finishes execution
    uiresume(gui.fig);
end

function sub_callback(src, varargin)
    switch get(src, 'tag')
        case {'imageseq_from', 'imageseq_to', 'imageseq_step'}
            newval=str2double(get(src, 'string'));
            set(src, 'string', num2str(min([max([newval 1]) status.nFrames])));
        case 'imageseq_format'
        case 'imageseq_folder'
            %TODO: check if the folder exists, otherwise confirm create
        case 'imageseq_basename'
        case 'imageseq_browse'
            filename=dtrack_fileio_selectimageseq(get(gui.panel2.folder, 'string'));
            if filename~=0
                set(gui.panel2.folder, 'string', filename);
            end
        case 'imageseq_startfile'
            newval=str2double(get(src, 'string'));
            set(src, 'string', num2str(max([newval 0])));
        case 'imageseq_padding'
            newval=str2double(get(src, 'string'));
            set(src, 'string', num2str(max([newval 1])));
        otherwise
            error('Internal error: Unknown caller');
    end
end

function sub_close(varargin)
    % CLOSE: close button callback
    button=questdlg('Cancel operation?', 'Cancel', 'Continue', 'Cancel', 'Continue');
    switch button
        case 'Cancel'
            sub_cancel();
    end
end

function sub_creategui
    
    screen=get(0, 'screensize');
    figsize=[screen(3)/2-300 screen(4)/2-200 600 400];
    %set up the figure
    gui.fig = figure(777);clf;

    set(gui.fig, 'outerposition', figsize, 'name', '', ...
    'backingstore', 'off', 'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @sub_close);

%% panels
    uicontrol(gui.fig, 'style', 'text', 'string', 'Save video as image sequence', ...
        'units', 'normalized', 'position', [.02 .81 .96 .17], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 18, 'fontweight', 'bold');
    gui.panel1.panel=uipanel(gui.fig, 'position', [.02 .22 .32 .57]);
    gui.panel2.panel=uipanel(gui.fig, 'position', [.36 .22 .62 .57]);

%% panel 1
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'Save from frame', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .6 .6 .1]);
    gui.panel1.from=uicontrol(gui.panel1.panel, 'style', 'edit', 'horizontalalignment', 'center', ...
        'units', 'normalized', 'position', [.73 .6 .2 .1], 'tag', 'imageseq_from', 'callback', editcb);
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'to frame', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .45 .6 .1]);
    gui.panel1.to=uicontrol(gui.panel1.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.73 .45 .2 .1], 'tag', 'imageseq_to', 'callback', editcb);
    uicontrol(gui.panel1.panel, 'style', 'text', 'string', 'every', 'horizontalalignment', 'right', ...
        'units', 'normalized', 'position', [.05 .3 .6 .1]);
    gui.panel1.step=uicontrol(gui.panel1.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.73 .3 .2 .1], 'tag', 'imageseq_step', 'callback', editcb);

%% panel 2
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Format', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .825 .31 .1]);
    gui.panel2.format=uicontrol(gui.panel2.panel, 'style', 'popupmenu', 'string', 'Lossless TIFF (Default)|Compressed TIFF (10x smaller files)|JPEG, 75% (30x smaller files)', ...
        'units', 'normalized', 'position', [.07 .695 .86 .14], 'tag', 'imageseq_format', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Folder', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .55 .31 .1]);
    gui.panel2.folder=uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.07 .45 .69 .1], 'tag', 'imageseq_folder', 'horizontalalignment', 'right');
    uicontrol(gui.panel2.panel, 'style', 'pushbutton', 'string', 'Browse', ...
        'units', 'normalized', 'position', [.78 .45 .15 .1], 'tag', 'imageseq_browse', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Base name', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.07 .31 .31 .1]);
    gui.panel2.basename=uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.07 .21 .86 .1], 'tag', 'imageseq_basename', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Start at', 'horizontalalignment', 'left', ...
        'units', 'normalized', 'position', [.18 .06 .31 .1]);
    gui.panel2.startfile=uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.35 .06 .13 .1], 'tag', 'imageseq_startfile', 'callback', editcb);
    uicontrol(gui.panel2.panel, 'style', 'text', 'string', 'Padding', 'horizontalalignment', 'center', ...
        'units', 'normalized', 'position', [.52 .06 .16 .1]);
    gui.panel2.padding=uicontrol(gui.panel2.panel, 'style', 'edit', ...
        'units', 'normalized', 'position', [.7 .06 .13 .1], 'tag', 'imageseq_padding', 'callback', editcb);

%% Control buttons
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Go', 'callback', @sub_OK, ...
        'units', 'normalized', 'position', [.28 .07 .2 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_ok');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Cancel', 'callback', @sub_cancel, ...
        'units', 'normalized', 'position', [.52 .07 .2 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_cancel');

end %sub_creategui

function sub_setdef
%% set defaults
    %panel 1
    set(gui.panel1.from, 'string', '1');%num2str(status.framenr));
    set(gui.panel1.to, 'string', num2str(status.nFrames));
    set(gui.panel1.step, 'string', '1');
    %panel 2
    set(gui.panel2.format, 'value', 1);
    if ~isempty(para.paths.respath)
        set(gui.panel2.folder, 'string', fileparts(para.paths.respath));
    else
        set(gui.panel2.folder, 'string', para.paths.resdef);
    end
    [junk, movbase]=fileparts(para.paths.movname);
    set(gui.panel2.basename, 'string', [movbase '_']);
    set(gui.panel2.startfile, 'string', '1');
    set(gui.panel2.padding, 'string', num2str(ceil(log10(status.nFrames))));
end %sub_setdef

end