function gui = holo_gui(status, para, gui)

thispath = fileparts(mfilename('fullpath'));
iconpath = fullfile(thispath, 'icons');


gui.infoarea.holo.panel = uipanel(gui.f1, 'position', [.85 .70 .15 .155]);
%     uicontrol(gui.infoarea.holo.panel, 'style', 'text', 'units', 'normalized', 'position', [.01 .82 .30 .17], 'string', 'HOLO z-distance (mm)')%, 'verticalalignment', 'center');
    
    axes(gui.infoarea.holo.panel, 'units', 'normalized', 'position', [.01 .82 .25 .17]);
    text(gca, 1, 0, 'z (mm)', 'horizontalalignment', 'right', 'verticalalignment', 'middle')
    axis([0 1 -1 1]); axis off;
    gui.infoarea.holo.entries.holo_zvalue_minus5   = uicontrol(gui.infoarea.holo.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.28 .82 .12 .17], 'string', '-5', 'tooltipstring', 'Reduce z-distance by 5 mm');
    gui.infoarea.holo.entries.holo_zvalue_minus1   = uicontrol(gui.infoarea.holo.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.40 .82 .12 .17], 'string', '-1', 'tooltipstring', 'Reduce z-distance by 1 mm');
    gui.infoarea.holo.entries.holo_zvalue          = uicontrol(gui.infoarea.holo.panel, 'style', 'edit', 'units', 'normalized', 'position', [.52 .82 .12 .17], 'string', num2str(status.holo.z), 'tooltipstring', 'Enter z-value (mm) to display');
    gui.infoarea.holo.entries.holo_zvalue_plus1    = uicontrol(gui.infoarea.holo.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.64 .82 .12 .17], 'string', '+1', 'tooltipstring', 'Increase z-distance by 1 mm');
    gui.infoarea.holo.entries.holo_zvalue_plus5    = uicontrol(gui.infoarea.holo.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.76 .82 .12 .17], 'string', '+5', 'tooltipstring', 'Increase z-distance by 5 mm');
    gui.infoarea.holo.entries.holo_findZ           = uicontrol(gui.infoarea.holo.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.88 .82 .12 .17], 'string', 'Find', 'tooltipstring', 'Increase z-distance by 5 mm');

    gui.infoarea.holo.mode_panel = uibuttongroup(gui.infoarea.holo.panel, 'position', [0 .63 .2 .17], 'tag', 'holo_mode_panel'); 
        gui.icons.interference_mode = imread(fullfile(iconpath, 'interf.tif'));
        gui.infoarea.holo.entries.interference_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [0 0 .5 1], 'cdata', gui.icons.interference_mode, 'tooltip', 'Show interference patterns');
        gui.icons.holo_mode = imread(fullfile(iconpath, 'holo.tif'));
        gui.infoarea.holo.entries.holo_mode = uicontrol(gui.infoarea.holo.mode_panel, 'style', 'togglebutton', 'units', 'normalized', 'position', [.5 0 .5 1], 'cdata', gui.icons.holo_mode, 'tooltip', 'Show processed hologram');
        if status.show_holo
            set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mode);
        else
            set(gui.infoarea.holo.mode_panel, 'selectedobject', gui.infoarea.holo.entries.interference_mode);
        end    
        
% add a holo default button to the image manipulation panel
gui.infoarea.image.entries.info_holo   = uicontrol(gui.infoarea.image.panel, 'style', 'pushbutton', 'units', 'normalized', 'position', [.38 .03 .2 .1], 'string', 'holo', 'tooltipstring', 'HOLO mode. Uses only the green channel in greyscale mode.');
