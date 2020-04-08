function [gui, status, para, data] = holo_gui_setdefaults(gui, status, para, data)


set(gui.infoarea.image.tabgroup, 'visible', 'off');
% set(gui.infoarea.holo.superpanel, 'visible', 'on');

set(gui.menus.view.entries.view_infopanel_mani, 'visible', 'off');
set(gui.menus.view.entries.view_greyscale, 'visible', 'off');
set(gui.menus.view.entries.view_imagesc, 'visible', 'off');
set(gui.menus.view.entries.view_imadjust, 'visible', 'off');
set(gui.menus.view.entries.view_brighten, 'visible', 'off');
set(gui.menus.view.entries.view_defaultbrightness, 'visible', 'off');
set(gui.menus.view.entries.view_darken, 'visible', 'off');

set(gui.menus.ana.menu, 'visible', 'off');

set(gui.controls.navi.entries.darken, 'visible', 'off');
set(gui.controls.navi.entries.defaultbrightness, 'visible', 'off');
set(gui.controls.navi.entries.brighten, 'visible', 'off');
set(gui.menus.tools.entries.tools_autotrack_bgs, 'visible', 'off');
set(gui.menus.tools.entries.tools_autotrack_mts, 'visible', 'off');

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
dtrack_gui_updateTogglegroupIcons(findobj('tag', 'camera_mode'), gui)

switch para.ref.use
    case {'dynamic', 'static'}
        set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_single);
    case 'double_dynamic'
        set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_double);
end
dtrack_gui_updateTogglegroupIcons(findobj('tag', 'holo_ref_single'), gui)

switch status.holo.z_mode
    case 'single'
        set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_single_z_mode);
    case 'mean'
        set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mean_z_mode);
end
dtrack_gui_updateTogglegroupIcons(findobj('tag', 'holo_mean_z_mode'), gui)









