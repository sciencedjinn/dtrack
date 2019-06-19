function [gui, status, para, data] = holo_gui(gui, status, para, data)

thispath = fileparts(mfilename('fullpath'));
iconpath = fullfile(thispath, 'icons');

gui.infoarea.holo.tabgroup = uitabgroup(gui.f1, 'position', [.85 .701 .15 .155]); 
gui.infoarea.holo.tab = uitab(gui.infoarea.holo.tabgroup, 'title', 'Holo settings'); 
%     uicontrol(gui.infoarea.holo.panel, 'style', 'text', 'units', 'normalized', 'position', [.01 .82 .30 .17], 'string', 'HOLO z-distance (mm)')%, 'verticalalignment', 'center');
    
    uicontrol(gui.infoarea.holo.tab, 'style', 'edit', 'units', 'normalized', 'position', [0.005 .82 .23 .17], 'string', 'Mode: ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
    gui.infoarea.holo.mode_panel = uibuttongroup(gui.infoarea.holo.tab, 'position', [.24 .82 .3 .17]); 
        gui.icons.camera_mode = imread(fullfile(iconpath, 'camera.tif'));
        gui.infoarea.holo.entries.camera_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0 0 .333 1], 'cdata', gui.icons.camera_mode, 'tooltip', 'Show camera image');
        gui.icons.interference_mode = imread(fullfile(iconpath, 'interf.tif'));
        gui.infoarea.holo.entries.interference_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.333 0 .333 1], 'cdata', gui.icons.interference_mode, 'tooltip', 'Show interference patterns');
        gui.icons.holo_mode = imread(fullfile(iconpath, 'holo.tif'));
        gui.infoarea.holo.entries.holo_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.666 0 .333 1], 'cdata', gui.icons.holo_mode, 'tooltip', 'Show processed hologram');
        switch status.holo.image_mode
            case 'camera'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.camera_mode);
            case 'interference'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.interference_mode);
            case 'holo'
                set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mode);
        end

    gui.infoarea.holo.z_panel = uipanel(gui.infoarea.holo.tab, 'position', [0 .48 1 .34]); 
%         axes(gui.infoarea.holo.z_panel, 'units', 'normalized', 'position', [0 0 .25 1]);
%         text(gca, 1, 0, 'z (mm)', 'horizontalalignment', 'right', 'verticalalignment', 'middle')
%         axis([0 1 -1 1]); axis off;
        uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position', [0.005 .5 .23 0.5], 'string', 'Display z (mm): ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
        gui.infoarea.holo.entries.holo_zvalue_minus5   = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.24 .5 .08 .5], 'string', '-5', 'tooltipstring', 'Reduce displayed z-distance by 5 mm');
        gui.infoarea.holo.entries.holo_zvalue_minus1   = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.32 .5 .08 .5], 'string', '-1', 'tooltipstring', 'Reduce displayed z-distance by 1 mm');
        gui.infoarea.holo.entries.holo_zvalue_disp     = uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position',       [.40 .5 .12 .5], 'string', num2str(status.holo.z), 'tooltipstring', 'Enter z-value (mm) to display');
        gui.infoarea.holo.entries.holo_zvalue_plus1    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.52 .5 .08 .5], 'string', '+1', 'tooltipstring', 'Increase displayed z-distance by 1 mm');
        gui.infoarea.holo.entries.holo_zvalue_plus5    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.60 .5 .08 .5], 'string', '+5', 'tooltipstring', 'Increase displayed z-distance by 5 mm');
        uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position', [0.005 0 .23 .5], 'string', 'Point z (mm): ', 'horizontalalignment', 'right', 'enable', 'inactive', 'backgroundcolor', [.95 .95 .95]);
        gui.infoarea.holo.entries.holo_zvalue_point    = uicontrol(gui.infoarea.holo.z_panel, 'style', 'edit', 'units', 'normalized', 'position',       [.40 0 .12 .5], 'string', '0', 'tooltipstring', 'z-position of current point (mm)', 'enable', 'inactive');
        gui.infoarea.holo.entries.holo_findZ           = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.52 0 .16 .5], 'string', 'Find', 'tooltipstring', 'Auto-detect z-position of current point');
        gui.infoarea.holo.entries.holo_findZ_local     = uicontrol(gui.infoarea.holo.z_panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.68 0 .16 .5], 'string', 'Find local', 'tooltipstring', 'Auto-detect z-position of current point');

        gui.icons.link_on = imread(fullfile(iconpath, 'link_on.tif'));
        gui.icons.link_off = imread(fullfile(iconpath, 'link_off.tif'));
        gui.infoarea.holo.entries.holo_link            = uicontrol(gui.infoarea.holo.z_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.84 .25 .08 .5], 'cdata', gui.icons.link_on, 'tooltipstring', 'Always display the z of the currently selected point');

        
% add a holo default button to the image manipulation panel
gui.infoarea.image.entries.info_holo   = uicontrol(gui.infoarea.image.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.38 .03 .2 .1], 'string', 'holo', 'tooltipstring', 'HOLO mode. Uses only the green channel in greyscale mode.');
