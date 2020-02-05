function [gui, status, para, data] = holo_guivisibility(gui, status, para, data)

if status.holo.link
    set(findobj('tag', 'holo_link'), 'cdata', gui.icons.link_on, 'value', 1)
else
    set(findobj('tag', 'holo_link'), 'cdata', gui.icons.link_off, 'value', 0)
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

% switch para.ref.use
%     case {'dynamic', 'static'}
%         set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_single);
%     case 'double_dynamic'
%         set(gui.infoarea.holo.ref_mode_panel, 'selectedobject', gui.infoarea.holo.entries.holo_ref_double);
% end
% switch status.holo.z_mode
%     case 'single'
%         set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_single_z_mode);
%     case 'mean'
%         set(gui.infoarea.holo.z_depth_panel, 'selectedobject', gui.infoarea.holo.entries.holo_mean_z_mode);
% end