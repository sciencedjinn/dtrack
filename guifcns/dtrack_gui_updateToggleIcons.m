 function dtrack_gui_updateToggleIcons(cbo, gui) 
    tag = get(cbo, 'tag');
    if get(cbo, 'value')
        set(cbo, 'cdata', 380-gui.icons.(tag));
    else
        set(cbo, 'cdata', gui.icons.(tag));
    end
end