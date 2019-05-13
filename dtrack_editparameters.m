function outpara = dtrack_editparameters(para)
%DTRACK_EDITPARAMETERS creates a gui for the user to set DTrack parameters when a new project is created.
%   By pressing the Default button, the parameters are saved to the Matlab preferences directory (from where they are loaded whenever a new project
%   is created). Pressing the "Revert" button resets all values to what they were when the Parameters window was opened.
% 
% Call sequence:    GUI (File -> New OR File -> Same video, new project OR Toolbar button) OR dtrack_fileio_startdlg -> dtrack_fileio_new -> dtrack_editparamaters
% Uses:             None
% See also:         dtrack_fileio_new, dtrack_fileio_startdlg

% TODO: could also use and check status.os and status.matlabv here ('PCWIN'/'PCWIN64'/'MACI'/'GLNX86'/'GLNXA64')

% Convention: for lines, para.pnr should be 2 for a single line. However, the 'value' of the popup menu would be 1 for a single line

[~, ~, movtype] = fileparts(para.paths.movname);
switch lower(movtype)
    case {'.mts'} %this list should eventually contain all file types known to require mmread
        forcemmread     = 1;
        para.usemmread  = 1;
    otherwise
        forcemmread     = 0;
end

%% init variables
inpara  = para; %for restore
gui     = [];
editcb  = @sub_callback;
outpara = [];

%create
sub_creategui;
sub_setdef;
sub_setvis;

%% set figure to modal late after you know there are no errors
%set(gui.fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(gui.fig);
    delete(gui.fig);
catch anyerror
    delete(gui.fig);        %delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%%%%%%%%%%%%%%%%%%%

%% Nested functions for callbacks, writing/drawing and panel creation
function sub_OK(varargin)
    % OK: ok button callback, returns the changed para and finishes execution
    outpara = para;
    uiresume;
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback, returns unchanged para and finishes execution
    uiresume;
end

function sub_revert(varargin)
    % REVERT: revert to original 
    para = inpara;
    sub_setdef;
    sub_setvis;
end

function sub_default(varargin)
    % DEFAULT: save current values as new default
    clear savepara;
    savepara.trackingtype       = para.trackingtype;
    savepara.pnr                = para.pnr;
    savepara.usemmread          = para.usemmread;
    savepara.mmreadsize         = para.mmreadsize;
    savepara.mmreadoverlap      = para.mmreadoverlap;
    savepara.forceaspectratio   = para.forceaspectratio; %#ok<STRNU>
    save(fullfile(prefdir, 'dtrack_para.dtp'), 'savepara', '-mat');
    disp('Local parameter defaults saved to preferences directory.');
end

function sub_close(varargin)
    % CLOSE: close button callback
    button = questdlg('Do you want to save the changed values?', 'Save changes', 'Save', 'Don''t save', 'Cancel', 'Don''t save');
    switch button
        case 'Save'
            sub_OK();
        case 'Don''t save'
            sub_cancel();
    end
end

function sub_callback(src, varargin)
    switch get(src, 'tag')
        case 'editpara_trackingtype'
            switch get(get(src, 'selectedobject'), 'tag')
                case 'editpara_point'
                    para.trackingtype = 'point';
                    
                case 'editpara_line'
                    para.trackingtype = 'line';
                    para.pnr = 2 * round(para.pnr/2); % round up to next even number
                    
                otherwise, error('Internal error: bla');
            end
            sub_creategui;
            sub_setdef;
            
        case {'editpara_point', 'editpara_line'}
            % This is called when point or line is pressed, but already selected.
            % Do nothing.            
            
        case 'editpara_pnr'
            temp = get(src, 'string');
            para.pnr = round(str2double(temp{get(src, 'value')}));
            
        case 'editpara_usemmread'
            para.usemmread = 2-get(src, 'value');
            
        case 'editpara_mmreadsize'
            temp = round(str2double(get(src, 'string')));
            if temp>0
                para.mmreadsize=temp;
            else
                set(src, 'string', num2str(para.mmreadsize));
                errordlg('Invalid entry', 'Invalid entry', 'modal');
            end
            
        case 'editpara_mmreadoverlap'
            temp = round(str2double(get(src, 'string')));
            if temp>0
                para.mmreadoverlap=temp;
            else
                set(src, 'string', num2str(para.mmreadoverlap));
                errordlg('Invalid entry', 'Invalid entry', 'modal');
            end
            
        case 'editpara_forceaspectratio'
            switch get(src, 'value')
                case 1 %default
                    para.forceaspectratio=[];
                case 2 %1:1
                    para.forceaspectratio=[1 1];
                case 3 %
                    para.forceaspectratio=[4 3];
                case 4 %
                    para.forceaspectratio=[16 9];
                case 5 %
                    para.forceaspectratio=[16 10];
                case 6 %
                    para.forceaspectratio=[2.21 1];
                case 7 %
                    para.forceaspectratio=[5 4];
            end
        otherwise
            error(['Internal error: unknown field ' get(src, 'tag') ' calling main callback']);
    end
    sub_setvis;
end


function sub_creategui
    
    screen = get(0, 'screensize');
    figsize = [600 400];
    figpos = [screen(3)/2-figsize(1)/2 screen(4)/2-figsize(2)/2 figsize(1) figsize(2)];
    %set up the figure
    gui.fig = figure(777); clf;
    set(gui.fig, 'outerposition', figpos, 'name', '', 'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @sub_close);

%% panels
    uicontrol(gui.fig, 'style', 'text', 'units', 'normalized', 'position', [.02 .91 .96 .07], 'string', [para.theme.name ' parameters'], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 15, 'fontweight', 'bold');
    uicontrol(gui.fig, 'style', 'text', 'units', 'normalized', 'position', [.02 .84 .96 .06], 'string', ['Opening movie file ' para.paths.movname], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 10);
    gui.panel1.panel = uibuttongroup(gui.fig, 'position', [.02 .54 .96 .28], 'tag', 'editpara_trackingtype', 'selectionchangefcn', editcb);
    gui.panel2.panel = uipanel(gui.fig,       'position', [.02 .12 .47 .40]);
    gui.panel3.panel = uipanel(gui.fig,       'position', [.51 .12 .47 .40]);

%% panel 1
    opts = {'units', 'normalized', 'callback', editcb};
    gui.panel1.pointsbutton       = uicontrol(gui.panel1.panel, opts{:}, 'position', [.1 .45 .3 .5], 'style', 'toggle', 'string', 'POINTS', 'tag', 'editpara_point');
    gui.panel1.linesbutton        = uicontrol(gui.panel1.panel, opts{:}, 'position', [.6 .45 .3 .5], 'style', 'toggle', 'string', 'LINES',  'tag', 'editpara_line');
                                    uicontrol(gui.panel1.panel, opts{:}, 'position', [.05 .05 .4 .35], 'style', 'text', 'string', {'Use this setting to track individual points,', 'e.g. body centres of one or several animals.'});
                                    uicontrol(gui.panel1.panel, opts{:}, 'position', [.55 .05 .4 .35], 'style', 'text', 'string', {'Use this to track lines (pairs of points),', 'e.g. body axes of one or several animals'});
    gui.panel1.arrowax            = axes('parent', gui.panel1.panel, 'units', 'normalized', 'position', [.45 .45 .1 .5]);
    
    plot([0 .1 0 .1 0 1 .9 1 .9], [.5 .6 .5 .4 .5 .5 .6 .5 .4], 'k', 'linewidth', 2); axis([0 1 .2 .8]);axis off;

%% panel 2
    switch para.trackingtype
        case 'line',  pnrlist = {'2', '4', '6', '8', '10'};
        case 'point', pnrlist = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10'};
    end
                                    uicontrol(gui.panel2.panel, opts{:}, 'position', [.01 .5 .78 .3], 'style', 'text', 'string', {'How many points do you want to track?' '(A line counts as two points)'});
    gui.panel2.pnr                = uicontrol(gui.panel2.panel, opts{:}, 'position', [.8 .5 .15 .3], 'style', 'popupmenu', 'horizontalalignment', 'center', 'string', pnrlist, 'tag', 'editpara_pnr');

%% panel 3
                                    uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .76 .5  .24], 'style', 'text', 'string', {'Use mmread (More file' 'types, but maybe slower)'});
    gui.panel3.usemmread          = uicontrol(gui.panel3.panel, opts{:}, 'position', [.6  .76 .35 .19], 'style', 'popupmenu', 'string', 'Yes|No (Default)', 'tag', 'editpara_usemmread');
                                    uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .51 .5  .24], 'style', 'text', 'string', {'mmread: How many frames per block?'});
    gui.panel3.mmreadsize         = uicontrol(gui.panel3.panel, opts{:}, 'position', [.6  .51 .35 .23], 'style', 'edit', 'tag', 'editpara_mmreadsize');
                                    uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .26 .5  .24], 'style', 'text', 'string', {'mmread: How many frames overlap?'});
    gui.panel3.mmreadoverlap      = uicontrol(gui.panel3.panel, opts{:}, 'position', [.6  .26 .35 .23], 'style', 'edit', 'tag', 'editpara_mmreadoverlap');
                                    uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .01 .5  .24], 'style', 'text', 'string', {'Force aspect ratio', '(Use if video is distorted)'});
    gui.panel3.forceaspectratio   = uicontrol(gui.panel3.panel, opts{:}, 'position', [.6  .01 .35 .19], 'style', 'popupmenu', 'string', 'Default|1:1|4:3|16:9|16:10|2.21:1|5:4', 'tag', 'editpara_forceaspectratio');
    
%% Control buttons
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Revert', 'callback', @sub_revert, ...
        'units', 'normalized', 'position', [.1 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_ok');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Save as default', 'callback', @sub_default, ...
        'units', 'normalized', 'position', [.3 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_cancel');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'OK', 'callback', @sub_OK, ...
        'units', 'normalized', 'position', [.5 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_ok');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Cancel', 'callback', @sub_cancel, ...
        'units', 'normalized', 'position', [.7 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpara_cancel');

end

function sub_setdef
%% set defaults
    % panel 1 & 2
    switch para.trackingtype
        case 'point'
            set(gui.panel1.panel, 'selectedobject', gui.panel1.pointsbutton);
            set(gui.panel2.pnr, 'value', para.pnr);
        case 'line'
            set(gui.panel1.panel, 'selectedobject', gui.panel1.linesbutton);
            set(gui.panel2.pnr, 'value', para.pnr/2);
    end
        
    % panel 3
    set(gui.panel3.usemmread, 'value', 2-para.usemmread);
    set(gui.panel3.mmreadsize, 'string', num2str(para.mmreadsize));
    set(gui.panel3.mmreadoverlap, 'string', num2str(para.mmreadoverlap));
    if isempty(para.forceaspectratio)
        set(gui.panel3.forceaspectratio, 'value', 1);
    elseif all(para.forceaspectratio==[1 1]) || all(para.forceaspectratio==[1 1])
        set(gui.panel3.forceaspectratio, 'value', 2);
    elseif all(para.forceaspectratio==[4 3]) || all(para.forceaspectratio==[3 4])
        set(gui.panel3.forceaspectratio, 'value', 3);
    elseif all(para.forceaspectratio==[16 9]) || all(para.forceaspectratio==[9 16])
        set(gui.panel3.forceaspectratio, 'value', 4);
    elseif all(para.forceaspectratio==[16 10]) || all(para.forceaspectratio==[10 16])
        set(gui.panel3.forceaspectratio, 'value', 5);
    elseif all(para.forceaspectratio==[2.21 1]) || all(para.forceaspectratio==[1 2.21])
        set(gui.panel3.forceaspectratio, 'value', 6);
    elseif all(para.forceaspectratio==[5 4]) || all(para.forceaspectratio==[4 5])
        set(gui.panel3.forceaspectratio, 'value', 7);
    end
end %sub_setdef

function sub_setvis
%% set gui element visibility
    if forcemmread
        set(gui.panel3.usemmread, 'enable', 'off', 'tooltipstring', 'This file type can only be read by mmread.');
    end
    if para.usemmread
        set(gui.panel3.mmreadsize, 'enable', 'on');
        set(gui.panel3.mmreadoverlap, 'enable', 'on');
    else
        set(gui.panel3.mmreadsize, 'enable', 'off');
        set(gui.panel3.mmreadoverlap, 'enable', 'off');
    end
end %sub_setvis
end