function holo_guivisibility(gui, para, status)




set(gui.infoarea.image.panel, 'visible', 'off');
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