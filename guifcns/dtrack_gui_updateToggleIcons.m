function dtrack_gui_updateToggleIcons(cbo, gui) 
% DTRACK_GUI_UPDATETOGGLEICONS reverses and brightens the cdata of a 
% uicontrol toggle object, if the value is 1
%
% cbo - callback object handle, needs to be a uicontrol toggle object
% gui - dtrack gui stucture. Needs to contain cdata in a field gui.icons.(tag),
% where tag equals the 'tag' of the uicontrol object
 
    tag = get(cbo, 'tag');
    icon = gui.icons.(tag);
    
    if get(cbo, 'value')
        rev_icon = 380-icon;
        rev_icon(rev_icon>255) = 255;
        set(cbo, 'cdata', rev_icon);
    else
        set(cbo, 'cdata', icon);
    end
end