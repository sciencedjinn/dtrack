function dtrack_gui_setdefaults(para, gui)

% autoforward buttons
switch para.autoforw
    case 0
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', []);
        set(findobj('tag', 'autoforw_1'), 'cdata', gui.icons.autoforw_1);
        set(findobj('tag', 'autoforw_x'), 'cdata', gui.icons.autoforw_x);
    case 1
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', findobj('tag', 'autoforw_1'));
        set(findobj('tag', 'autoforw_1'), 'cdata', 380-gui.icons.autoforw_1);
        set(findobj('tag', 'autoforw_x'), 'cdata', gui.icons.autoforw_x);
    case 2
        set(findobj('tag', 'autoforwpanel'), 'selectedobject', findobj('tag', 'autoforw_x'));
        set(findobj('tag', 'autoforw_x'), 'cdata', 380-gui.icons.autoforw_x);
        set(findobj('tag', 'autoforw_1'), 'cdata', gui.icons.autoforw_1);
end

set(findobj('tag', 'currpoint'), 'value', para.showcurr);
set(findobj('tag', 'lastpoint'), 'value', para.showlast);
        
set(findobj('tag', 'info_greyscale'), 'value', para.im.greyscale);
set(findobj('tag', 'info_imagesc'), 'value', para.im.imagesc);
set(findobj('tag', 'info_imadjust'), 'value', para.im.imadjust);

if para.im.roi
    set(findobj('tag', 'roi_display'), 'checked', 'on');
else
    set(findobj('tag', 'roi_display'), 'checked', 'off');
end
if para.ref.use
    set(findobj('tag', 'ref_display'), 'checked', 'on');
else
    set(findobj('tag', 'ref_display'), 'checked', 'off');
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
if para.gui.infopanel_markers
    set(findobj('tag', 'view_infopanel_markers'), 'checked', 'on');
else
    set(findobj('tag', 'view_infopanel_markers'), 'checked', 'off');
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
