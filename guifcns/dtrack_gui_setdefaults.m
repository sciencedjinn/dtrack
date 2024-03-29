function dtrack_gui_setdefaults(gui, status, para)

% autoforward buttons
switch para.autoforw
    case 0
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', []);
    case 1
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', findobj('tag', 'autoforw_1'));
    case 2
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', findobj('tag', 'autoforw_x'));
end
dtrack_gui_updateTogglegroupIcons(findobj('tag', 'autoforw_x'), gui)

set(findobj('tag', 'currpoint'), 'value', para.showcurr);
dtrack_gui_updateToggleIcons(findobj('tag', 'currpoint'), gui)
set(findobj('tag', 'lastpoint'), 'value', para.showlast);
dtrack_gui_updateToggleIcons(findobj('tag', 'lastpoint'), gui)
        
set(findobj('tag', 'info_greyscale'), 'value', para.im.greyscale);
set(findobj('tag', 'info_imagesc'), 'value', para.im.imagesc);
set(findobj('tag', 'info_imadjust'), 'value', para.im.imadjust);

if para.im.roi
    set(findobj('tag', 'roi_display'), 'checked', 'on');
else
    set(findobj('tag', 'roi_display'), 'checked', 'off');
end
if para.gui.navitoolbar
    set(findobj('tag', 'view_navitoolbar'), 'checked', 'on');
else
    set(findobj('tag', 'view_navitoolbar'), 'checked', 'off');
end
if para.gui.infopanel
    set(findobj('tag', 'view_infopanel'), 'checked', 'on');
else
    set(findobj('tag', 'view_infopanel'), 'checked', 'off');
end
if para.gui.infopanel_points
    set(findobj('tag', 'view_infopanel_points'), 'checked', 'on');
else
    set(findobj('tag', 'view_infopanel_points'), 'checked', 'off');
end
if para.gui.infopanel_mani
    set(findobj('tag', 'view_infopanel_mani'), 'checked', 'on');
else
    set(findobj('tag', 'view_infopanel_mani'), 'checked', 'off');
end
if para.gui.minimap
    set(findobj('tag', 'view_minimap'), 'checked', 'on');
else
    set(findobj('tag', 'view_minimap'), 'checked', 'off');
end

%% Check if the modules have anything to add
dtrack_support_evalModules('_gui_setdefaults', gui, status, para, []);
    
