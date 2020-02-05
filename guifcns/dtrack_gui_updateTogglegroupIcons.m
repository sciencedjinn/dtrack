function dtrack_gui_updateTogglegroupIcons(cbo, gui)
    bg = get(cbo, 'parent');
    buttons = get(bg, 'children');
    for button = buttons(:)'
        tag = get(button, 'tag');
        if button == get(bg, 'SelectedObject')
            set(button, 'cdata', 380-gui.icons.(tag));
        else
            set(button, 'cdata', gui.icons.(tag));
        end
    end
end