function outpara = dtrack_editpreferences(para)
%DTRACK_EDITPREFERENCES creates a gui for the user to change DTrack preferences.
%   By pressing the Default button, the preferences are saved to the Matlab preferences directory (from where they are loaded whenever a new project
%   is created). Pressing the "Revert" button resets all values to what they were when the Preferences window was opened.
% 
% Call sequence:    GUI (File -> Preferences, or Toolbar button) -> dtrack_action -> dtrack_editpreferences
% Uses:             None
% See also:         dtrack_action

%% init variables
inpara  = para; %for restore
gui     = [];
editcb  = @sub_callback;
outpara = [];

%create
sub_creategui;
sub_setdef;

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
end

function sub_default(varargin)
    % DEFAULT: save current values as new default
    clear savepara;
    savepara.paths.movdef           = para.paths.movdef;
    savepara.paths.resdef           = para.paths.resdef;
    savepara.paths.vlcpath          = para.paths.vlcpath;
    savepara.gui.fig1pos            = para.gui.fig1pos;
    savepara.showcurr               = para.showcurr;
    savepara.showlast               = para.showlast;
    savepara.showlastrange          = para.showlastrange;
    savepara.maxrecent              = para.maxrecent; 
    savepara.gui.stepsize           = para.gui.stepsize;
    savepara.autoforw               = para.autoforw; 
    savepara.gui.navitoolbar        = para.gui.navitoolbar;
    savepara.gui.infopanel          = para.gui.infopanel;
    savepara.gui.infopanel_points   = para.gui.infopanel_points;
    savepara.gui.infopanel_markers  = para.gui.infopanel_markers;
    savepara.gui.infopanel_mani     = para.gui.infopanel_mani;
    savepara.gui.minimap            = para.gui.minimap; %#ok<STRNU>
    save(fullfile(prefdir, 'dtrack_pref.dtp'), 'savepara', '-mat');
    disp('Local preferences saved to preferences directory.');
end

function sub_close(varargin)
    % CLOSE: close button callback
    button=questdlg('Do you want to save the changed values?', 'Save changes', 'Save', 'Don''t save', 'Cancel', 'Don''t save');
    switch button
        case 'Save'
            sub_OK();
        case 'Don''t save'
            sub_cancel();
    end
end

function sub_callback(src, varargin)
    switch get(src, 'tag')
        case 'editpref_movdef'
            if exist(get(src, 'string'), 'file')
                para.paths.movdef = get(src, 'string');
            else
                errordlg('Invalid directory path', 'Invalid entry', 'modal');
                set(src, 'string', para.paths.movdef);
            end
            
        case 'editpref_movdefbutton'
            dirname = uigetdir(para.paths.movdef);
            if dirname~=0
                para.paths.movdef = dirname;
                set(gui.panel1.movdef, 'string', dirname);
            end
            
        case 'editpref_resdef'
            if exist(get(src, 'string'), 'file')
                para.paths.resdef = get(src, 'string');
            else
                errordlg('Invalid directory path', 'Invalid entry', 'modal');
                set(src, 'string', para.paths.resdef);
            end
            
        case 'editpref_resdefbutton'
            dirname=uigetdir(para.paths.resdef);
            if dirname~=0
                para.paths.resdef=dirname;
                set(gui.panel1.resdef, 'string', dirname);
            end
            
        case 'editpref_vlcpath'
            if exist(get(src, 'string'), 'file')
                para.paths.vlcpath=get(src, 'string');
            else
                errordlg('Invalid directory path', 'Invalid entry', 'modal');
                set(src, 'string', para.paths.resdef);
            end
            
        case 'editpref_vlcpathbutton'
            [filename, pathname]=uigetfile('vlc.exe', 'Please enter the location of vlc.exe', para.paths.vlcpath);
            if filename~=0
                para.paths.vlcpath=fullfile(pathname, filename);
                set(gui.panel1.vlcpath, 'string', fullfile(pathname, filename));
            end
            
        case 'editpref_maxrecent'
            temp=round(str2double(get(src, 'string')));
            if temp>0
                para.maxrecent=temp;
            else
                set(src, 'string', num2str(para.maxrecent));
                errordlg('Invalid entry', 'Invalid entry', 'modal');
            end
            
        case 'editpref_fig1pos'
            temp = get(src, 'string');
            itemname = temp(get(src, 'value'), :);
            switch itemname
                case 'Fullscreen'
                    para.gui.fig1pos = [];
                otherwise
                    resolution = textscan(itemname, '%dx%d');
                    para.gui.fig1pos = [1 1 resolution{1} resolution{2}];
            end
            
        case 'editpref_showcurr'
            para.showcurr = get(src, 'value');
            
        case 'editpref_showlast'
            para.showlast = get(src, 'value');
            
        case 'editpref_showlastrange'
            temp=round(str2double(get(src, 'string')));
            if temp>0
                para.showlastrange=temp;
            else
                set(src, 'string', num2str(para.showlastrange));
                errordlg('Invalid entry', 'Invalid entry', 'modal');
            end
            
        case 'editpref_stepsize'
            temp = round(str2double(get(src, 'string')));
            if temp>0
                para.gui.stepsize = temp;
            else
                set(src, 'string', num2str(para.gui.stepsize));
                errordlg('Invalid entry', 'Invalid entry', 'modal');
            end
        case 'editpref_autoforw'
            para.autoforw = get(src, 'value')-1;
            
        case 'editpref_navitoolbar'
            para.gui.navitoolbar = get(src, 'value');
            
        case 'editpref_infopanel'
            para.gui.infopanel = get(src, 'value');
            
        case 'editpref_info_points'
            para.gui.infopanel_points = get(src, 'value');
            
        case 'editpref_info_markers'
            para.gui.infopanel_markers = get(src, 'value');
            
        case 'editpref_info_mani'
            para.gui.infopanel_mani = get(src, 'value');
            
        case 'editpref_minimap'
            para.gui.minimap = get(src, 'value');            
            
        otherwise
            error(['Internal error: unknown field ' get(src, 'tag') ' calling main callback']);
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
    uicontrol(gui.fig, 'style', 'text', 'string', 'DTrack preferences', 'units', 'normalized', 'position', [.02 .91 .96 .07], 'backgroundcolor', get(gui.fig, 'color'), 'fontsize', 15, 'fontweight', 'bold');
    gui.panel1.panel = uipanel(gui.fig, 'position', [.02 .71 .96 .18]);
    gui.panel2.panel = uipanel(gui.fig, 'position', [.02 .51 .96 .18]);
    gui.panel3.panel = uipanel(gui.fig, 'position', [.02 .12 .47 .37]);
    gui.panel4.panel = uipanel(gui.fig, 'position', [.51 .12 .47 .37]);

%% panel 1
    opts = {'units', 'normalized', 'callback', editcb};
                                uicontrol(gui.panel1.panel, opts{:}, 'position', [.01 .69 .18 .31], 'style', 'text', 'string', {'Default movie path:'}, 'HorizontalAlignment', 'left');
    gui.panel1.movdef         = uicontrol(gui.panel1.panel, opts{:}, 'position', [.20 .69 .699 .31], 'style', 'edit', 'HorizontalAlignment', 'left', 'tag', 'editpref_movdef', 'tooltipstring', 'Please enter the default path to start searching for data files.');
    gui.panel1.movdefbutton   = uicontrol(gui.panel1.panel, opts{:}, 'position', [.90 .69 .099 .31], 'style', 'pushbutton', 'string', 'Browse...', 'tag', 'editpref_movdefbutton');
    
                                uicontrol(gui.panel1.panel, opts{:}, 'position', [.01 .35 .18 .31], 'style', 'text', 'string', {'Default results path:'}, 'HorizontalAlignment', 'left');
    gui.panel1.resdef         = uicontrol(gui.panel1.panel, opts{:}, 'position', [.20 .35 .699 .31], 'style', 'edit', 'HorizontalAlignment', 'left', 'tag', 'editpref_resdef', 'tooltipstring', 'Please enter the default path to start searching for results files.');
    gui.panel1.resdefbutton   = uicontrol(gui.panel1.panel, opts{:}, 'position', [.90 .35 .099 .31], 'style', 'pushbutton', 'string', 'Browse...', 'tag', 'editpref_resdefbutton');
    
                                uicontrol(gui.panel1.panel, opts{:}, 'position', [.01 .02 .18 .31], 'style', 'text', 'string', {'VLC path:'}, 'HorizontalAlignment', 'left');
    gui.panel1.vlcpath        = uicontrol(gui.panel1.panel, opts{:}, 'position', [.20 .02 .699 .31], 'style', 'edit', 'HorizontalAlignment', 'left', 'tag', 'editpref_vlcpath', 'tooltipstring', 'To enable viewing videos in VLC, please enter the path of vlc.exe on your system (Windows only).');
    gui.panel1.vlcpathbutton  = uicontrol(gui.panel1.panel, opts{:}, 'position', [.90 .02 .099 .31], 'style', 'pushbutton', 'string', 'Browse...', 'tag', 'editpref_vlcpathbutton');
    
%% panel 2
    reslist = 'Fullscreen|640x480|800x600|1024x768|1280x1024|1440x900|1680x1050|1920x1080|1920x1200';
                                uicontrol(gui.panel2.panel, opts{:}, 'position', [.01 .52 .48 .31], 'style', 'text', 'string', {'Default resolution:'}, 'HorizontalAlignment', 'right');
    gui.panel2.fig1pos        = uicontrol(gui.panel2.panel, opts{:}, 'position', [.50 .52 .20 .37], 'style', 'popupmenu', 'string', reslist, 'tag', 'editpref_fig1pos');
    
                                uicontrol(gui.panel2.panel, opts{:}, 'position', [.01 .19 .48 .31], 'style', 'text', 'string', {'Maximum recent files to show in start dialog:'}, 'HorizontalAlignment', 'right');
    gui.panel2.maxrecent      = uicontrol(gui.panel2.panel, opts{:}, 'position', [.50 .19 .10 .31], 'style', 'edit', 'tag', 'editpref_maxrecent');
    
%% panel 3
    gui.panel3.showcurr       = uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .85 .9 .12], 'style', 'checkbox', 'string', 'Highlight current point', 'tag', 'editpref_showcurr');
    gui.panel3.showlast       = uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .7 .9 .12], 'style', 'checkbox', 'string', 'Show previous position for current point,', 'tag', 'editpref_showlast');
                                uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .6 .5 .08], 'style', 'text', 'string', 'if it was marked in the last', 'HorizontalAlignment', 'left');
    gui.panel3.showlastrange  = uicontrol(gui.panel3.panel, opts{:}, 'position', [.55 .57 .1 .12], 'style', 'edit', 'tag', 'editpref_showlastrange');
                                uicontrol(gui.panel3.panel, opts{:}, 'position', [.67 .6 .3 .08], 'style', 'text', 'string', 'frames.', 'HorizontalAlignment', 'left');
                                uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .33 .39 .13], 'style', 'text', 'string', 'Large step:', 'HorizontalAlignment', 'left');
    gui.panel3.stepsize       = uicontrol(gui.panel3.panel, opts{:}, 'position', [.5 .35 .4 .13], 'style', 'edit', 'tag', 'editpref_stepsize', 'tooltipstring', 'Select number of frames to jump in a large step (by default done with left/right arrow)');
                                uicontrol(gui.panel3.panel, opts{:}, 'position', [.05 .18 .39 .13], 'style', 'text', 'string', 'Autoforward mode:', 'HorizontalAlignment', 'left');
    gui.panel3.autoforw       = uicontrol(gui.panel3.panel, opts{:}, 'position', [.5 .2 .4 .13], 'style', 'popupmenu', 'string', 'nothing|small step|large step', 'tag', 'editpref_autoforw', 'tooltipstring', 'What to do after all points in a frame are marked?');
    
%% panel 4
                                uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .87 .5 .12], 'style', 'text', 'string', 'Show by default:', 'HorizontalAlignment', 'left');
    gui.panel4.navitoolbar    = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .74 .9 .12], 'style', 'checkbox', 'string', 'File and navigation toolbar', 'tag', 'editpref_navitoolbar');
    gui.panel4.infopanel      = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .61 .9 .12], 'style', 'checkbox', 'string', 'Info panel', 'tag', 'editpref_infopanel');
    gui.panel4.info_points    = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .48 .9 .12], 'style', 'checkbox', 'string', 'Points panel', 'tag', 'editpref_info_points');
    gui.panel4.info_markers   = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .35 .9 .12], 'style', 'checkbox', 'string', 'Marker panel', 'tag', 'editpref_info_markers');
    gui.panel4.info_mani      = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .22 .9 .12], 'style', 'checkbox', 'string', 'Image manipulation panel', 'tag', 'editpref_info_mani');
    gui.panel4.minimap        = uicontrol(gui.panel4.panel, opts{:}, 'position', [.05 .09 .9 .12], 'style', 'checkbox', 'string', 'Miniplot window', 'tag', 'editpref_minimap');

%% Control buttons
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Revert', 'callback', @sub_revert, ...
        'units', 'normalized', 'position', [.1 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpref_ok');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Save as default', 'callback', @sub_default, ...
        'units', 'normalized', 'position', [.3 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpref_cancel');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'OK', 'callback', @sub_OK, ...
        'units', 'normalized', 'position', [.5 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpref_ok');
    uicontrol(gui.fig, 'style', 'pushbutton', 'string', 'Cancel', 'callback', @sub_cancel, ...
        'units', 'normalized', 'position', [.7 .02 .19 .07], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'editpref_cancel');

end

function sub_setdef
%% set defaults
    % panel 1
    set(gui.panel1.movdef, 'string', para.paths.movdef);
    set(gui.panel1.resdef, 'string', para.paths.resdef);
    set(gui.panel1.vlcpath, 'string', para.paths.vlcpath);
    
    % panel 2
    if isempty(para.gui.fig1pos) || length(para.gui.fig1pos)<4 %Fullscreen
        set(gui.panel2.fig1pos, 'value', 1);
        para.gui.fig1pos=[];
    elseif all(para.gui.fig1pos(3:4)==[640 480])
        set(gui.panel2.fig1pos, 'value', 2);
    elseif all(para.gui.fig1pos(3:4)==[800 600])
        set(gui.panel2.fig1pos, 'value', 3);
    elseif all(para.gui.fig1pos(3:4)==[1024 768])
        set(gui.panel2.fig1pos, 'value', 4);
    elseif all(para.gui.fig1pos(3:4)==[1280 1024])
        set(gui.panel2.fig1pos, 'value', 5);
    elseif all(para.gui.fig1pos(3:4)==[1440 900])
        set(gui.panel2.fig1pos, 'value', 6);
    elseif all(para.gui.fig1pos(3:4)==[1680 1050])
        set(gui.panel2.fig1pos, 'value', 7);
    elseif all(para.gui.fig1pos(3:4)==[1920 1080])
        set(gui.panel2.fig1pos, 'value', 8);
    elseif all(para.gui.fig1pos(3:4)==[1920 1200])
        set(gui.panel2.fig1pos, 'value', 9);
    else
        %do nothing, it'll just set it to full screen
        para.gui.fig1pos=[];
    end
    set(gui.panel2.maxrecent, 'string', num2str(para.maxrecent));
    
    % panel 3
    set(gui.panel3.showcurr,        'value', para.showcurr);
    set(gui.panel3.showlast,        'value', para.showlast);
    set(gui.panel3.showlastrange,   'string', num2str(para.showlastrange));
    set(gui.panel3.stepsize,        'string', num2str(para.gui.stepsize));
    set(gui.panel3.autoforw,        'value', para.autoforw+1);
    
    % panel 4
    set(gui.panel4.navitoolbar,     'value', para.gui.navitoolbar);
    set(gui.panel4.infopanel,       'value', para.gui.infopanel);
    set(gui.panel4.info_points,     'value', para.gui.infopanel_points);
    set(gui.panel4.info_markers,    'value', para.gui.infopanel_markers);
    set(gui.panel4.info_mani,       'value', para.gui.infopanel_mani);
    set(gui.panel4.minimap,         'value', para.gui.minimap);

end
end