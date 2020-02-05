function dtrack_gui_updateTogglegroupIcons(cbo, gui)
% DTRACK_GUI_UPDATETOGGLEGROUPICONS reverses and brightens the cdata of all 
% uicontrol toggle objects in a uibuttongroup, if the value is 1
 %
 % cbo - callback object handle, needs to be a uicontrol toggle object
 % whose parent is a uibuttongroup
 % gui - dtrack gui stucture. Needs to contain cdata in a field gui.icons.(tag),
 % where tag equals the 'tag' of each uicontrol object
 
    bg = get(cbo, 'parent');
    buttons = get(bg, 'children');
    for button = buttons(:)'
        tag = get(button, 'tag');
        icon = gui.icons.(tag);
        if button == get(bg, 'SelectedObject')
            rev_icon = 380-icon;
            rev_icon(rev_icon>255) = 255;
            set(button, 'cdata', rev_icon);
        else
            set(button, 'cdata', icon);
        end
    end
end