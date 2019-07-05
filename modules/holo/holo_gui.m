function [gui, status, para, data] = holo_gui(gui, status, para, data)

thispath = fileparts(mfilename('fullpath'));
iconpath = fullfile(thispath, 'icons');

gui.infoarea.holo.tabgroup = uitabgroup(gui.f1, 'position', [.85 .756 .15 .1]); 
gui.infoarea.holo.tab = uitab(gui.infoarea.holo.tabgroup, 'title', 'Holo settings'); 
%     uicontrol(gui.infoarea.holo.panel, 'style', 'text', 'units', 'normalized', 'position', [.01 .82 .30 .17], 'string', 'HOLO z-distance (mm)')%, 'verticalalignment', 'center');
    
    uicontrol(gui.infoarea.holo.tab, 'style', 'edit', 'units', 'normalized', 'position', [0.005 .66 .23 .33], 'string', 'Mode: ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
    gui.infoarea.holo.mode_panel = uibuttongroup(gui.infoarea.holo.tab, 'position', [.24 .66 .3 .33]); 
        gui.icons.camera_mode = imread(fullfile(iconpath, 'camera.tif'));
        gui.infoarea.holo.entries.camera_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0 0 .25 1], 'cdata', gui.icons.camera_mode, 'tooltip', 'Show camera image');
        gui.icons.interference_mode = imread(fullfile(iconpath, 'interf.tif'));
        gui.infoarea.holo.entries.interference_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.25 0 .25 1], 'cdata', gui.icons.interference_mode, 'tooltip', 'Show interference patterns');
        gui.icons.holo_mode = imread(fullfile(iconpath, 'holo.tif'));
        gui.infoarea.holo.entries.holo_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.5 0 .25 1], 'cdata', gui.icons.holo_mode, 'tooltip', 'Show processed hologram');
        gui.icons.holo_mag_mode = imread(fullfile(iconpath, 'holo_mag.tif'));
        gui.infoarea.holo.entries.holo_mag_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.75 0 .25 1], 'cdata', gui.icons.holo_mag_mode, 'tooltip', 'Show processed hologram with enhanced area around selected point');
        switch status.holo.image_mode
            case 'camera'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.camera_mode);
            case 'interference'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.interference_mode);
            case 'holo'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mode);
            case 'holo_mag'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mag_mode);
        end
        
    gui.infoarea.holo.ref_mode_panel = uibuttongroup(gui.infoarea.holo.tab, 'position', [.57 .66 .15 .33]); 
        gui.icons.holo_ref_single = imread(fullfile(iconpath, 'holo_ref_single.tif'));
        gui.infoarea.holo.entries.holo_ref_single = uicontrol(gui.infoarea.holo.ref_mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0 0 .5 1], 'cdata', gui.icons.holo_ref_single, 'tooltip', 'Use only last frame as reference');
        gui.icons.holo_ref_double = imread(fullfile(iconpath, 'holo_ref_double.tif'));
        gui.infoarea.holo.entries.holo_ref_double = uicontrol(gui.infoarea.holo.ref_mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.5 0 .5 1], 'cdata', gui.icons.holo_ref_double, 'tooltip', 'Use last frame and next frame as references (slower)');
        switch para.ref.use
            case {'dynamic', 'static'}
                set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_single);
            case 'double_dynamic'
                set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_double);
        end
        
    gui.infoarea.holo.z_depth_panel = uibuttongroup(gui.infoarea.holo.tab, 'position', [.75 .66 .15 .33]); 
        gui.icons.holo_single_z_mode = imread(fullfile(iconpath, 'holo_single_z_mode.tif'));
        gui.infoarea.holo.entries.holo_single_z_mode = uicontrol(gui.infoarea.holo.z_depth_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0 0 .5 1], 'cdata', gui.icons.holo_single_z_mode, 'tooltip', 'Display frame for a single z-value');
        gui.icons.holo_mean_z_mode = imread(fullfile(iconpath, 'holo_mean_z_mode.tif'));
        gui.infoarea.holo.entries.holo_mean_z_mode = uicontrol(gui.infoarea.holo.z_depth_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.5 0 .5 1], 'cdata', gui.icons.holo_mean_z_mode, 'tooltip', 'Display mean of a full z-stack (SLOW!)');
        switch status.holo.z_mode
            case 'single'
                set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_single_z_mode);
            case 'mean'
                set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mean_z_mode);
        end
        
    gui.infoarea.holo.z_panel = uipanel(gui.infoarea.holo.tab, 'position', [0 0 1 .66]); 
%         axes(gui.infoarea.holo.z_panel, 'units', 'normalized', 'position', [0 0 .25 1]);
%         text(gca, 1, 0, 'z (mm)', 'horizontalalignment', 'right', 'verticalalignment', 'middle')
%         axis([0 1 -1 1]); axis off;
        gui.icons.link_on = imread(fullfile(iconpath, 'link_on.tif'));
        gui.icons.link_off = imread(fullfile(iconpath, 'link_off.tif'));
        gui.infoarea.holo.entries.holo_link            = uicontrol(gui.infoarea.holo.z_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0.005 .25 .08 .5], 'cdata', gui.icons.link_on, 'tooltipstring', 'Always display the z of the currently selected point');

        uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position', [0.09 .5 .23 0.5], 'string', 'Display z (mm): ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
        gui.infoarea.holo.entries.holo_zvalue_minus5   = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.33 .5 .06 .5], 'string', '-5', 'tooltipstring', 'Reduce displayed z-distance by 5 mm');
        gui.infoarea.holo.entries.holo_zvalue_minus1   = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.39 .5 .06 .5], 'string', '-1', 'tooltipstring', 'Reduce displayed z-distance by 1 mm');
        gui.infoarea.holo.entries.holo_zvalue_disp     = uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position',       [.45 .5 .12 .5], 'string', num2str(status.holo.z), 'tooltipstring', 'Enter z-value (mm) to display');
        gui.infoarea.holo.entries.holo_zvalue_plus1    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.57 .5 .06 .5], 'string', '+1', 'tooltipstring', 'Increase displayed z-distance by 1 mm');
        gui.infoarea.holo.entries.holo_zvalue_plus5    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.63 .5 .06 .5], 'string', '+5', 'tooltipstring', 'Increase displayed z-distance by 5 mm');
        uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position', [0.09 0 .23 .5], 'string', 'Point z (mm): ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
        gui.infoarea.holo.entries.holo_zvalue_point    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position',       [.45 0 .12 .5], 'string', '0', 'tooltipstring', 'z-position of current point (mm)', 'enable', 'inactive');
        
        gui.infoarea.holo.entries.holo_findXY          = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.70 .5 .30 .5], 'string', 'X/Y auto', 'tooltipstring', 'Auto-detect x/y-position of current point');
        gui.infoarea.holo.entries.holo_findZ           = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.70 0 .15 .5], 'string', 'Z auto', 'tooltipstring', 'Auto-detect z-position of current point');
        gui.infoarea.holo.entries.holo_findZ_local     = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.85 0 .15 .5], 'string', 'Z local', 'tooltipstring', 'Auto-detect z-position of current point, but only near closeby points');

%% Diagnostics panel
gui.diag.tabgroup = uitabgroup(gui.f1, 'position', [.85 .504 .15 .25]); 
gui.diag.tab = uitab(gui.diag.tabgroup, 'title', 'Diagnostics'); 
    gui.diag.ph(1) = uipanel('parent', gui.diag.tab, 'units', 'normalized', 'position', [0 .5 .5 .5]);
    gui.diag.ph(2) = uipanel('parent', gui.diag.tab, 'units', 'normalized', 'position', [.5 .5 .5 .5]);
    gui.diag.ph(3) = uipanel('parent', gui.diag.tab, 'units', 'normalized', 'position', [0 0 .5 .5]);
    gui.diag.ph(4) = uipanel('parent', gui.diag.tab, 'units', 'normalized', 'position', [.5 0 .5 .5]);

    gui.diag.ah(1) = axes('parent', gui.diag.ph(1), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.diag.ah(2) = axes('parent', gui.diag.ph(2), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.diag.ah(3) = axes('parent', gui.diag.ph(3), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.diag.ah(4) = axes('parent', gui.diag.ph(4), 'units', 'normalized', 'position', [0 0 1 1]);
    set(gui.diag.ah(1), 'YDir', 'reverse', 'visible', 'off');
    set(gui.diag.ah(2), 'YDir', 'reverse', 'visible', 'off');
    set(gui.diag.ah(3), 'YDir', 'reverse', 'visible', 'off');
    set(gui.diag.ah(4), 'YDir', 'reverse', 'visible', 'off');

%% Holo menu
gui.menus.holo.menu = uimenu(gui.f1, 'label', 'Holo');
    gui.menus.holo.entries.holo_autoXY    = uimenu(gui.menus.holo.menu, 'label', 'Autodetect X/Y-positions...');
    gui.menus.holo.entries.holo_autoXYcontinue = uimenu(gui.menus.holo.menu, 'label', 'Continue autotracking...', 'accelerator', 'D');
    gui.menus.holo.entries.holo_autoZ     = uimenu(gui.menus.holo.menu, 'label', 'Autodetect Z-positions...');
    gui.menus.holo.entries.holo_plot_speed_2d = uimenu(gui.menus.holo.menu, 'label', 'Plot 2D speeds', 'separator', 'on');
    gui.menus.holo.entries.holo_plot_speed_3d = uimenu(gui.menus.holo.menu, 'label', 'Plot 3D speeds');
    gui.menus.holo.entries.holo_plot_track_2d = uimenu(gui.menus.holo.menu, 'label', 'Plot 2D tracks');
    gui.menus.holo.entries.holo_plot_track_3d = uimenu(gui.menus.holo.menu, 'label', 'Plot 3D tracks');
        
        
% add a holo default button to the image manipulation panel
gui.infoarea.image.entries.info_holo   = uicontrol(gui.infoarea.image.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.38 .03 .2 .1], 'string', 'holo', 'tooltipstring', 'HOLO mode. Uses only the green channel in greyscale mode.');
