function [gui, status, para, data] = holo_guivisibility(gui, status, para, data)




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

if status.holo.link
    set(findobj('tag', 'holo_link'), 'cdata', gui.icons.link_on)
else
    set(findobj('tag', 'holo_link'), 'cdata', gui.icons.link_off)
end
    
switch status.holo.image_mode
    case {'camera', 'interference'}
        set(findobj('tag', 'holo_zvalue_minus5'), 'enable', 'off');
        set(findobj('tag', 'holo_zvalue_minus1'), 'enable', 'off');
        set(findobj('tag', 'holo_zvalue_disp'), 'enable', 'off');
        set(findobj('tag', 'holo_zvalue_plus1'), 'enable', 'off');
        set(findobj('tag', 'holo_zvalue_plus5'), 'enable', 'off');
    case {'holo', 'holo_mag'}
        if strcmp(status.holo.z_mode, 'single')
            set(findobj('tag', 'holo_zvalue_minus5'), 'enable', 'on');
            set(findobj('tag', 'holo_zvalue_minus1'), 'enable', 'on');
            set(findobj('tag', 'holo_zvalue_disp'), 'enable', 'on');
            set(findobj('tag', 'holo_zvalue_plus1'), 'enable', 'on');
            set(findobj('tag', 'holo_zvalue_plus5'), 'enable', 'on');
        else
            set(findobj('tag', 'holo_zvalue_minus5'), 'enable', 'off');
            set(findobj('tag', 'holo_zvalue_minus1'), 'enable', 'off');
            set(findobj('tag', 'holo_zvalue_disp'), 'enable', 'off');
            set(findobj('tag', 'holo_zvalue_plus1'), 'enable', 'off');
            set(findobj('tag', 'holo_zvalue_plus5'), 'enable', 'off');
        end
    otherwise
        warning('Internal warning: Unhandled image mode. Please report this warning.');
end