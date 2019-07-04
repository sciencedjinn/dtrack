function gui = dtrack_gui(status, para)
% dungtack_gui sets up figures, menus, buttons and contextmenus
% gui = dtrack_gui(para, status, status.maincb)

thispath = fileparts(mfilename('fullpath'));
iconpath = fullfile(thispath, '..', 'icons');

%% set up figure
gui.f1 = figure(1);clf;
set(gui.f1, 'ResizeFcn', []); %for resets
p = double(imread(fullfile(iconpath, 'crosshair1_16.tif')))+1;p(p==min(p(:))) = 1;p(p==max(p(:)))=2;p(p>2)=NaN;
gui.pointers.crosshair1_16 = p;
gui.pointers.crosshair1_32 = double(imread(fullfile(iconpath, 'crosshair1_32.tif'))) + 1; gui.pointers.crosshair1_32(gui.pointers.crosshair1_32==2) = NaN;
if isempty(para.gui.fig1pos)
    fig1pos = get(0, 'screensize');
else
    fig1pos = para.gui.fig1pos;
end
set(gui.f1, 'outerposition', fig1pos, 'name', [para.theme.name ': ' para.paths.resname ' (' para.paths.movname ')'], ...
     'numbertitle', 'off', 'menubar', 'none', 'keypressfcn', status.maincb,...
     'interruptible', 'off', 'pointer', 'custom', 'pointershapecdata', gui.pointers.crosshair1_16, 'pointershapehotspot', [8.5 8.5], ...
     'WindowScrollWheelFcn', status.scrollcb);
%try, drawnow; pause(3); maxfig; end %#ok<TRYNC,NOCOM> %This line has caused trouble on Windows and Mac: Mouse clicks would not register at the correct screen
% position until a gui reset was performed or the window minimised and then maximised again
set(gui.f1, 'ResizeFcn', status.resizecb);
gui.ax1 = axes('parent', gui.f1);set(gui.ax1, 'position', [0.001 0.001 1 1], 'buttondownfcn', status.maincb);
gui.im1 = [];

%% Info Area
% gui.infoarea.info.panel = uipanel(gui.f1, 'position', [.85 .94 .15 .06]);
gui.infoarea.info.tabgroup = uitabgroup(gui.f1, 'position', [.85 .94 .15 .06]); 
gui.infoarea.info.tab = uitab(gui.infoarea.info.tabgroup, 'title', 'Info'); 
    gui.infoarea.info.entries.framenr = uicontrol(gui.infoarea.info.tab, 'style', 'edit', 'string', ['frame ' num2str(status.framenr) '/' num2str(status.nFrames)], 'units', 'normalized', 'position', [0 .5 .5 .5], 'tag', 'framenr', 'enable', 'inactive', 'buttondownfcn', status.maincb);
    fth = floor(status.framenr/status.FrameRate/3600);
    ftm = floor(mod(status.framenr/status.FrameRate/60,3600));
    fts = floor(mod(status.framenr/status.FrameRate,60));
    ftms = mod(status.framenr/status.FrameRate, 1)*1000;
    gui.infoarea.info.entries.frametime = uicontrol(gui.infoarea.info.tab, 'style', 'edit', 'string', sprintf('time %02.0f:%02.0f:%02.0f.%03.0f', fth, ftm, fts, ftms), 'units', 'normalized', 'position', [0 0 .5 .5], 'tag', 'frametime', 'enable', 'inactive', 'buttondownfcn', status.maincb);
    gui.infoarea.info.entries.stepsize = uicontrol(gui.infoarea.info.tab, 'style', 'edit', 'string', ['step size ' num2str(para.gui.stepsize)], 'units', 'normalized', 'position', [.5 .5 .5 .5], 'tag', 'stepsize', 'enable', 'inactive', 'buttondownfcn', status.maincb);
    gui.infoarea.info.entries.refframe = uicontrol(gui.infoarea.info.tab, 'style', 'edit', 'string', '', 'units', 'normalized', 'position', [.5 0 .5 .5], 'tag', 'refframe', 'enable', 'inactive', 'buttondownfcn', status.maincb);

% gui.infoarea.points.superpanel = uipanel(gui.f1, 'position', [.85 .88 .15 .06]);
gui.infoarea.points.tabgroup = uitabgroup(gui.f1, 'position', [.85 .858 .15 .08]); 
gui.infoarea.points.tab = uitab(gui.infoarea.points.tabgroup, 'title', 'Points'); 
    gui.infoarea.points.panel = uipanel(gui.infoarea.points.tab, 'position', [0 .5 .8 .5], 'tag', 'pointspanel'); 
        for i = 1:para.pnr/(1+strcmp(para.trackingtype, 'line'))
            gui.infoarea.points.entries.(['p' num2str(i)]) = uicontrol(gui.infoarea.points.panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [(i-1)*0.1 0 .1 1], 'string', num2str(i), 'value', any(ismember(status.trackedpoints, i)));
        end

    gui.infoarea.autoforw.panel = uibuttongroup(gui.infoarea.points.tab, 'position', [.8 .5 .2 .5], 'tag', 'autoforwpanel'); 
        gui.icons.autoforw_1=imread(fullfile(iconpath, 'autoforw_1.tif'));
        gui.infoarea.autoforw.entries.autoforw_1 = uicontrol(gui.infoarea.autoforw.panel, 'units', 'normalized', 'style', 'togglebutton', 'position', [0 0 .5 1], 'cdata', gui.icons.autoforw_1, 'tooltipstring', 'Automatically forward 1 frame after leftclick'); 
        gui.icons.autoforw_x=imread(fullfile(iconpath, 'autoforw_x.tif'));
        gui.infoarea.autoforw.entries.autoforw_x = uicontrol(gui.infoarea.autoforw.panel, 'units', 'normalized', 'style', 'togglebutton', 'position', [.5 0 .5 1], 'cdata', gui.icons.autoforw_x, 'tooltipstring', 'Automatically forward x frames after leftclick'); 

    gui.infoarea.pointsel.panel = uibuttongroup(gui.infoarea.points.tab, 'position', [0 0 .8 .5], 'tag', 'pointselpanel', 'selectionchangefcn', status.maincb); 
        for i = 1:para.pnr/(1+strcmp(para.trackingtype, 'line'))
            gui.infoarea.pointsel.entries.(['ps' num2str(i)]) = uicontrol(gui.infoarea.pointsel.panel, 'style', 'radiobutton', 'units', 'normalized', 'position', [(i-1)*0.1 0 .1 1]);
        end
        switch para.trackingtype
            case 'point'
                set(gui.infoarea.pointsel.panel, 'selectedobject', gui.infoarea.pointsel.entries.(['ps' num2str(status.cpoint)]));
            case 'line'
                set(gui.infoarea.pointsel.panel, 'selectedobject', gui.infoarea.pointsel.entries.(['ps' num2str((status.cpoint+1)/2)]));
        end
                
    gui.infoarea.extrapoints.panel = uipanel(gui.infoarea.points.tab, 'position', [.8 0 .2 .5], 'tag', 'extrapointspanel'); 
        gui.icons.currpoint                         = imread(fullfile(iconpath, 'currpoint.tif'));
        gui.infoarea.extrapoints.entries.currpoint  = uicontrol(gui.infoarea.extrapoints.panel, 'units', 'normalized', 'style', 'togglebutton', 'position', [0 0 .5 1], 'cdata', gui.icons.currpoint, 'tooltipstring', 'Indicate current point by underlaying it with a light shadow'); 
        gui.icons.lastpoint                         = imread(fullfile(iconpath, 'lastpoint.tif'));
        gui.infoarea.extrapoints.entries.lastpoint  = uicontrol(gui.infoarea.extrapoints.panel, 'units', 'normalized', 'style', 'togglebutton', 'position', [.5 0 .5 1], 'cdata', gui.icons.lastpoint, 'tooltipstring', ['Indicate last position of this point within ' num2str(para.showlastrange) ' frames (can be changed in properties) as a thin grey ring']); 

gui.infoarea.markers.tab = uitab(gui.infoarea.points.tabgroup, 'title', 'Markers'); 
    gui.infoarea.markers.entries.marker_s       = uicontrol(gui.infoarea.markers.tab, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.001 0.51 .08 .48], 'string', 's', 'tooltipstring', 'start marker: first frame to be analysed (Alt + S)');
    gui.infoarea.markers.entries.marker_e       = uicontrol(gui.infoarea.markers.tab, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.001+1*0.08 0.51 .08 .48], 'string', 'e', 'tooltipstring', 'end marker: last frame to be analysed (Alt + E)');
    gui.infoarea.markers.entries.marker_r       = uicontrol(gui.infoarea.markers.tab, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.001+2*0.08 0.51 .08 .48], 'string', 'r', 'tooltipstring', 'roll marker: first frame of a rolling phase (lasts until p, d, or e) (Alt + R)');
    gui.infoarea.markers.entries.marker_p       = uicontrol(gui.infoarea.markers.tab, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.001+3*0.08 0.51 .08 .48], 'string', 'p', 'tooltipstring', 'pause marker: first frame of a pause phase (lasts until r, d, or e) (Alt + P)');
    gui.infoarea.markers.entries.marker_d       = uicontrol(gui.infoarea.markers.tab, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.001+4*0.08 0.51 .08 .48], 'string', 'd', 'tooltipstring', 'dance marker: first frame of a dance phase (lasts until r, p, or e) (Alt + D)');
    gui.infoarea.markers.entries.marker_other   = uicontrol(gui.infoarea.markers.tab, 'style', 'edit', 'units', 'normalized', 'position', [0.001+5*0.08 0.51 .23 .48], 'string', '', 'tooltipstring', 'other markers (Alt + letter)', 'enable', 'inactive');
    
% gui.infoarea.image.superpanel = uipanel(gui.f1, 'position', [.85 .70 .15 .155]);
gui.infoarea.image.tabgroup = uitabgroup(gui.f1, 'position', [.85 .701 .15 .155]); 
gui.infoarea.image.tab = uitab(gui.infoarea.image.tabgroup, 'title', 'Image manipulation'); 
    gui.infoarea.info.entries.manicheck = uicontrol(gui.infoarea.image.tab, 'style', 'checkbox', 'units', 'normalized', 'position', [0 .85 .08 .14], 'tooltip', 'Activate/Deactivate image manipulation', 'value', para.im.manicheck);

    gui.infoarea.image.panel = uipanel(gui.infoarea.image.tab, 'position', [.08 0 .92 1]); 
        gui.infoarea.image.entries.info_greyscale   = uicontrol(gui.infoarea.image.panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.01 .82 .12 .17], 'value', para.im.greyscale, 'string', 'GS', 'tooltipstring', 'Toggle gray scale mode');
        gui.infoarea.image.entries.info_imagesc     = uicontrol(gui.infoarea.image.panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.13 .82 .12 .17], 'value', para.im.imagesc, 'string', 'SC', 'tooltipstring', 'Toggle image scaling (gray scale only)');
        gui.infoarea.image.entries.info_imadjust    = uicontrol(gui.infoarea.image.panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.25 .82 .12 .17], 'value', para.im.imadjust, 'string', 'AD', 'tooltipstring', 'Toggle contrast boost (gray scale only)');
        gui.infoarea.image.entries.rgb1             = uicontrol(gui.infoarea.image.panel, 'style', 'slider', 'units', 'normalized', 'position', [.04 .22 .07 .57], 'min', 0, 'max', 2, 'value', para.im.rgb1);
        gui.infoarea.image.entries.rgb2             = uicontrol(gui.infoarea.image.panel, 'style', 'slider', 'units', 'normalized', 'position', [.16 .22 .07 .57], 'min', 0, 'max', 2, 'value', para.im.rgb2);
        gui.infoarea.image.entries.rgb3             = uicontrol(gui.infoarea.image.panel, 'style', 'slider', 'units', 'normalized', 'position', [.28 .22 .07 .57], 'min', 0, 'max', 2, 'value', para.im.rgb3);
        gui.infoarea.image.entries.rgb1text         = uicontrol(gui.infoarea.image.panel, 'style', 'text', 'units', 'normalized', 'position', [.04 .12 .07 .1], 'string', 'R');
        gui.infoarea.image.entries.rgb2text         = uicontrol(gui.infoarea.image.panel, 'style', 'text', 'units', 'normalized', 'position', [.16 .12 .07 .1], 'string', 'G');
        gui.infoarea.image.entries.rgb3text         = uicontrol(gui.infoarea.image.panel, 'style', 'text', 'units', 'normalized', 'position', [.28 .12 .07 .1], 'string', 'B');
        gui.infoarea.image.entries.rgbdef           = uicontrol(gui.infoarea.image.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.01 .03 .15 .1], 'string', 'def', 'tooltipstring', 'Restore default settings');
        gui.infoarea.image.entries.info_nightshot   = uicontrol(gui.infoarea.image.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.17 .03 .2 .1], 'string', 'night', 'tooltipstring', 'Nightshot mode. Uses only the red channel in greyscale mode. This setting often has the highest contrast in infrared videos.'); %set to GS, 0.6/0/0

%% Minimap
minisize=.2;
axsize = get(gui.f1, 'Position');
axwidth = axsize(3)-axsize(1)+1;axheight = axsize(4)-axsize(2)+1;
if ~isempty(para.forceaspectratio)
    miniheight = minisize*axwidth/para.forceaspectratio(1)*para.forceaspectratio(2)/axheight;
else
    miniheight = minisize;
end
gui.minimap.panel = uipanel(gui.f1, 'position', [1-minisize 0 minisize miniheight], 'backgroundcolor', [.5 .5 .5]);
    gui.minimap.axes = axes('parent', gui.minimap.panel, 'units', 'normalized', 'position', [0 0 1 1], 'tag', 'minimap_axes', 'buttondownfcn', status.maincb); 
    
%% Navigation toolbar
gui.controls.navi.toolbar = uitoolbar;

    %Block 1
    gui.controls.navi.entries.newfile = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Open video file for new project... (Ctrl + N)');
    gui.controls.navi.entries.newfile2 = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Create a new project with the same video file... (Ctrl + A)');
    gui.controls.navi.entries.loadfile = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Load project file... (Ctrl + L)');
    gui.controls.navi.entries.savefile = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Save project file (Ctrl + S)');
    gui.controls.navi.entries.setprefs = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Preferences... (Ctrl + P)');

    %Block 2
    gui.controls.navi.entries.start = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'go to first frame (S)', 'separator', 'on');
    gui.controls.navi.entries.backx = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'back x frames (Left arrow)');
    gui.controls.navi.entries.back1 = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'back one frame (Up arrow)');
    gui.controls.navi.entries.goto = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'go to frame ...');
    gui.controls.navi.entries.forw1 = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'advance one frame (Down arrow)');
    gui.controls.navi.entries.forwx = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'advance x frames (Right arrow)');
    gui.controls.navi.entries.end = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'go to last frame (E)');

    %Block 3
    gui.controls.navi.entries.zoom = uitoggletool(gui.controls.navi.toolbar, 'tooltipstring', 'Zoom (Z)', 'clickedcallback', status.maincb, 'separator', 'on');
    gui.controls.navi.entries.pan = uitoggletool(gui.controls.navi.toolbar, 'tooltipstring', 'Pan (H)', 'clickedcallback', status.maincb);
    gui.controls.navi.entries.acquire = uitoggletool(gui.controls.navi.toolbar, 'tooltipstring', 'Acquire (V)', 'clickedcallback', status.maincb);

    %Block 4
    gui.controls.navi.entries.darken = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Darker image (-)', 'clickedcallback', status.maincb, 'separator', 'on');
    gui.controls.navi.entries.defaultbrightness = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Default brightness', 'clickedcallback', status.maincb);
    gui.controls.navi.entries.brighten = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Brighter image(+)', 'clickedcallback', status.maincb);

    %Block 5
    gui.controls.navi.entries.colourgui = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Change point and line colours', 'clickedcallback', status.maincb, 'separator', 'on');

    %Block 6
    gui.controls.navi.entries.deinterlace = uitoggletool(gui.controls.navi.toolbar, 'tooltipstring', 'Deinterlace video (only keeps one frame)', 'clickedcallback', status.maincb, 'separator', 'on');
    
    %Block 7
    gui.controls.navi.entries.vlc = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Open this video at CURRENT frame in VLC (Windows only) (M)', 'clickedcallback', status.maincb, 'separator', 'on');
    gui.controls.navi.entries.implay = uipushtool(gui.controls.navi.toolbar, 'tooltipstring', 'Open this video in Matlab video tool', 'clickedcallback', status.maincb);

%% File menu
gui.menus.file.menu = uimenu(gui.f1, 'label', 'File');
    gui.menus.file.entries.file_newfile     = uimenu(gui.menus.file.menu, 'label', 'New project...', 'accelerator', 'N');
    gui.menus.file.entries.file_newfile2    = uimenu(gui.menus.file.menu, 'label', 'New project, same video...', 'accelerator', 'A');
    gui.menus.file.entries.file_loadfile    = uimenu(gui.menus.file.menu, 'label', 'Load project...', 'accelerator', 'L');
    gui.menus.file.entries.file_recent      = uimenu(gui.menus.file.menu, 'label', 'Recent files');
    gui.menus.file.entries.file_savefile    = uimenu(gui.menus.file.menu, 'label', 'Save', 'separator', 'on', 'accelerator', 'S');
    gui.menus.file.entries.file_savefileas  = uimenu(gui.menus.file.menu, 'label', 'Save as...');
    gui.menus.file.entries.file_export      = uimenu(gui.menus.file.menu, 'label', 'Export...', 'accelerator', 'E');
    gui.menus.file.entries.file_setprefs    = uimenu(gui.menus.file.menu, 'label', 'Preferences...', 'separator', 'on', 'accelerator', 'P');
    gui.menus.file.entries.file_exit        = uimenu(gui.menus.file.menu, 'label', 'Quit', 'accelerator', 'Q');
    %add recent files
    [~, paths, howmany] = dtrack_fileio_getrecent(para.maxrecent);
    if howmany==0
         gui.menus.file.entries.file_norecent = uimenu(gui.menus.file.entries.file_recent, 'label', 'No recent files found', 'enable', 'off');
    else
        for i = 1:howmany
            [~, name] = fileparts(paths{i});
            gui.menus.file.entries.(sprintf('file_recent_%02.0f', i)) = uimenu(gui.menus.file.entries.file_recent, 'tag', 'file_recentx', 'label', name, 'userdata', paths{i});
        end
    end
    gui.menus.file.entries.file_clearrecent = uimenu(gui.menus.file.entries.file_recent, 'label', 'Clear recent', 'separator', 'on');
    
%% Edit menu
gui.menus.edit.menu = uimenu(gui.f1, 'label', 'Edit');
    gui.menus.edit.entries.edit_clearframe = uimenu(gui.menus.edit.menu, 'label', 'Clear this frame''s data');
    gui.menus.edit.entries.edit_clearrange = uimenu(gui.menus.edit.menu, 'label', 'Clear data range...');
    
%% View menu
gui.menus.view.menu = uimenu(gui.f1, 'label', 'View');
    gui.menus.view.entries.view_navitoolbar = uimenu(gui.menus.view.menu, 'label', 'File and navigation toolbar');
    gui.menus.view.entries.view_infopanel = uimenu(gui.menus.view.menu, 'label', 'Info panel', 'separator', 'on');
    gui.menus.view.entries.view_infopanel_points = uimenu(gui.menus.view.menu, 'label', 'Points & Markers panel');
    gui.menus.view.entries.view_infopanel_mani = uimenu(gui.menus.view.menu, 'label', 'Image manipulation panel');
    gui.menus.view.entries.view_minimap = uimenu(gui.menus.view.menu, 'label', 'Mini plot window');
    gui.menus.view.entries.view_greyscale = uimenu(gui.menus.view.menu, 'label', 'Grey scale image', 'checked', 'off', 'separator', 'on');
    gui.menus.view.entries.view_imagesc = uimenu(gui.menus.view.menu, 'label', '    Scale image', 'checked', 'off');
    gui.menus.view.entries.view_imadjust = uimenu(gui.menus.view.menu, 'label', '    Contrast boost', 'checked', 'off');
    gui.menus.view.entries.view_brighten = uimenu(gui.menus.view.menu, 'label', '    Brighter image (+)', 'separator', 'on');
    gui.menus.view.entries.view_defaultbrightness = uimenu(gui.menus.view.menu, 'label', '    Default brightness');
    gui.menus.view.entries.view_darken = uimenu(gui.menus.view.menu, 'label', '    Darker image (-)');

%% Analysis menu
gui.menus.ana.menu = uimenu(gui.f1, 'label', 'Analysis');
    gui.menus.ana.entries.ana_plotpaths = uimenu(gui.menus.ana.menu, 'label', 'Plot paths');
    gui.menus.ana.entries.ana_plotfootsteps = uimenu(gui.menus.ana.menu, 'label', 'Plot foot steps');
    gui.menus.ana.entries.ana_plotpos = uimenu(gui.menus.ana.menu, 'label', 'Plot x position');
    gui.menus.ana.entries.ana_plotcalib = uimenu(gui.menus.ana.menu, 'label', 'Plot calibrated paths');
    gui.menus.ana.entries.ana_odometer_lengths = uimenu(gui.menus.ana.menu, 'label', 'Get odometer lengths');
    gui.menus.ana.entries.ana_plotspeed = uimenu(gui.menus.ana.menu, 'label', 'Plot speeds');
    gui.menus.ana.entries.ana_plotcalibspeed = uimenu(gui.menus.ana.menu, 'label', 'Plot calibrated speed histogram');
    gui.menus.ana.entries.ana_plotangles = uimenu(gui.menus.ana.menu, 'label', 'Plot angles');
%     gui.menus.ana.entries.ana_plottemp = uimenu(gui.menus.ana.menu, 'label', 'Plot temperature profile');
%     gui.menus.ana.entries.ana_balltrace = uimenu(gui.menus.ana.menu, 'label', 'Plot ball temperature trace');

%% Calibration menu
gui.menus.calib.menu = uimenu(gui.f1, 'label', 'Calibration');
    gui.menus.calib.entries.calib_attach = uimenu(gui.menus.calib.menu, 'label', 'Attach calibration file...');

%% ROI&REF menu
gui.menus.roi.menu = uimenu(gui.f1, 'label', 'RoI&&Ref');
    gui.menus.roi.entries.roi_create_frominput = uimenu(gui.menus.roi.menu, 'label', 'Create ROI inter-actively...');
    gui.menus.roi.entries.roi_create_fromfile = uimenu(gui.menus.roi.menu, 'label', 'Create ROI from results file...');
    gui.menus.roi.entries.roi_attach = uimenu(gui.menus.roi.menu, 'label', 'Load ROI file...');
    gui.menus.roi.entries.roi_display = uimenu(gui.menus.roi.menu, 'label', 'Display ROI file', 'checked', 'off');
    gui.menus.roi.set_menu = uimenu(gui.menus.roi.menu, 'label', 'Reference frame', 'separator', 'on');
    gui.menus.roi.entries.ref_set_none = uimenu(gui.menus.roi.set_menu, 'label', 'None', 'checked', 'on');
    gui.menus.roi.entries.ref_set_static = uimenu(gui.menus.roi.set_menu, 'label', 'Static', 'checked', 'off');
    gui.menus.roi.entries.ref_set_dynamic = uimenu(gui.menus.roi.set_menu, 'label', 'Dynamic', 'checked', 'off');
    gui.menus.roi.entries.ref_set_double_dynamic = uimenu(gui.menus.roi.set_menu, 'label', 'Double dynamic', 'checked', 'off');
    gui.menus.roi.entries.ref_set = uimenu(gui.menus.roi.menu, 'label', 'Use current frame as reference');
    gui.menus.roi.entries.ref_frameDiff = uimenu(gui.menus.roi.menu, 'label', 'Set dynamic frame difference...');
    
%% Tools menu
gui.menus.tools.menu = uimenu(gui.f1, 'label', 'Tools');
    gui.menus.tools.entries.tools_imageone_jpg = uimenu(gui.menus.tools.menu, 'label', 'Save original frame as jpg');
    gui.menus.tools.entries.tools_imageone_tif = uimenu(gui.menus.tools.menu, 'label', 'Save original frame as tif');
    gui.menus.tools.entries.tools_imageoneproc_jpg = uimenu(gui.menus.tools.menu, 'label', 'Save processed frame as jpg', 'accelerator', 'j');
    gui.menus.tools.entries.tools_imageoneproc_tif = uimenu(gui.menus.tools.menu, 'label', 'Save processed frame as tif');
    gui.menus.tools.entries.tools_imageseq = uimenu(gui.menus.tools.menu, 'label', 'Save as image sequence / video...');
%     gui.menus.tools.entries.tools_overlay = uimenu(gui.menus.tools.menu, 'label', 'Create video overlay...');
    gui.menus.tools.entries.tools_autotrack_bgs = uimenu(gui.menus.tools.menu, 'label', 'Autotracking (BGS) ...', 'separator', 'on');
    gui.menus.tools.entries.holo_autotrack_bgs = uimenu(gui.menus.tools.menu, 'label', 'Holo autotracking (BGS) ...');
    gui.menus.tools.entries.tools_autotrack_mts = uimenu(gui.menus.tools.menu, 'label', 'Autotracking (MTS) ...', 'enable', 'off');
    
%% Debugging menu
gui.menus.debug.menu = uimenu(gui.f1, 'label', 'Debug');
    gui.menus.debug.entries.debug_resetgui = uimenu(gui.menus.debug.menu, 'label', 'Reset GUI');
    gui.menus.debug.entries.debug_publish = uimenu(gui.menus.debug.menu, 'label', 'Publish data to base');
    gui.menus.debug.entries.debug_import = uimenu(gui.menus.debug.menu, 'label', 'Import data from base');
    gui.menus.debug.entries.debug_closeall = uimenu(gui.menus.debug.menu, 'label', 'Close orphaned windows', 'separator', 'on');
    gui.menus.debug.entries.debug_redrawlines = uimenu(gui.menus.debug.menu, 'label', 'Redraw lines');

%% Help menu
gui.menus.help.menu = uimenu(gui.f1, 'label', 'Help');
    gui.menus.help.entries.help_shortcuts = uimenu(gui.menus.help.menu, 'label', 'List of keyboard shortcuts');
    gui.menus.help.entries.help_known = uimenu(gui.menus.help.menu, 'label', 'Known bugs');
    gui.menus.help.entries.help_aspectratio = uimenu(gui.menus.help.menu, 'label', 'Fix my aspect ratio!');

%% Check if the modules have anything to add
gui = dtrack_support_evalModules('_gui', gui, status, para, []);
    
%% Add tags
types = {'menus', 'controls', 'infoarea'};%, 'contextmenus'};
for i = 1:length(types)
    names = fieldnames(gui.(types{i}));
    for j = 1:length(names)
        names2 = fieldnames(gui.(types{i}).(names{j}).entries);
        for k = 1:length(names2)
            thisobj = gui.(types{i}).(names{j}).entries.(names2{k}); % e.g. gui.menus.file.entries.fileopen
            if isempty(get(thisobj, 'tag'))
                set(thisobj, 'tag', names2{k});
            end
            switch get(thisobj, 'type')
                case {'uipushtool', 'uitoggletool'}
                    iconname = fullfile(iconpath, [names2{k}, '.tif']);
                    if ~exist(iconname, 'file')
                        iconname = fullfile(iconpath, 'missing.tif');
                    end
                    rgb=imread(iconname);
                    set(thisobj, 'cdata', rgb);
                                        %add callback
                    set(thisobj, 'clickedcallback', status.maincb);
                otherwise %'uimenu' and 'uicontrol'
                    set(thisobj, 'callback', status.maincb);
            end
        end
    end
end

%% set defaults and visibility
dtrack_gui_setdefaults(para, gui);
dtrack_guivisibility(gui, para, status);
