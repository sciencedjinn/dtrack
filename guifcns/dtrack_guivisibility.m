function dtrack_guivisibility(gui, para, status)
%called in dtrack_gui, dtrack_action, dtrack_tools_autotrack_main

% toolbar visibility
if para.gui.navitoolbar
    set(gui.controls.navi.toolbar, 'visible', 'on');
else
    set(gui.controls.navi.toolbar, 'visible', 'off');
end
if para.gui.infopanel
    set(gui.infoarea.info.panel, 'visible', 'on');
else
    set(gui.infoarea.info.panel, 'visible', 'off');
end
if para.gui.infopanel_points
    set(gui.infoarea.points.superpanel, 'visible', 'on');
else
    set(gui.infoarea.points.superpanel, 'visible', 'off');
end
if para.gui.infopanel_markers
    set(gui.infoarea.markers.panel, 'visible', 'on');
else
    set(gui.infoarea.markers.panel, 'visible', 'off');
end
if para.gui.infopanel_mani
    set(gui.infoarea.image.superpanel, 'visible', 'on');
else
    set(gui.infoarea.image.superpanel, 'visible', 'off');
end
if para.gui.minimap
    set(gui.minimap.panel, 'visible', 'on');
else
    set(gui.minimap.panel, 'visible', 'off');
end

% disable roi display
if isempty(para.paths.roiname)
    set(findobj('tag', 'roi_display'), 'enable', 'off');
end

% ref display
switch para.ref.use
    case 'none'
        set(findobj('tag', 'ref_set_none'), 'checked', 'on');
        set(findobj('tag', 'ref_set_static'), 'checked', 'off');
        set(findobj('tag', 'ref_set_dynamic'), 'checked', 'off');
        set(findobj('tag', 'ref_set'), 'enable', 'off');
        set(findobj('tag', 'ref_frameDiff'), 'enable', 'off');
        set(findobj('tag', 'refframe'), 'string', 'no ref frame');
    case 'static'
        set(findobj('tag', 'ref_set_none'), 'checked', 'off');
        set(findobj('tag', 'ref_set_static'), 'checked', 'on');
        set(findobj('tag', 'ref_set_dynamic'), 'checked', 'off');
        set(findobj('tag', 'ref_set'), 'enable', 'on');
        set(findobj('tag', 'ref_frameDiff'), 'enable', 'off');
        set(findobj('tag', 'refframe'), 'string', ['ref frame ' num2str(para.ref.framenr)]);
    case 'dynamic'
        set(findobj('tag', 'ref_set_none'), 'checked', 'off');
        set(findobj('tag', 'ref_set_static'), 'checked', 'off');
        set(findobj('tag', 'ref_set_dynamic'), 'checked', 'on');
        set(findobj('tag', 'ref_set'), 'enable', 'off');
        set(findobj('tag', 'ref_frameDiff'), 'enable', 'on');
        set(findobj('tag', 'refframe'), 'string', ['ref diff ' num2str(para.ref.frameDiff)]);
    otherwise
        error('Internal error: Incorrect para.ref.use value: %s', para.ref.use);
end
    
% disable calibrated plotting
if isempty(para.paths.calibname)
    set(findobj('tag', 'ana_plotcalib'), 'enable', 'off');
    set(findobj('tag', 'ana_plotcalibspeed'), 'enable', 'off');
end

% synchronise toggle states
set(findobj('tag', 'info_greyscale'), 'value', para.im.greyscale);
if para.im.greyscale
    set(findobj('tag', 'view_greyscale'), 'checked', 'on');
else
    set(findobj('tag', 'view_greyscale'), 'checked', 'off');
end

set(findobj('tag', 'info_imagesc'), 'value', para.im.imagesc);
set(findobj('tag', 'info_imadjust'), 'value', para.im.imadjust);
if para.im.imagesc
    set(findobj('tag', 'view_imagesc'), 'checked', 'on');
else
    set(findobj('tag', 'view_imagesc'), 'checked', 'off');
end
if para.im.imadjust
    set(findobj('tag', 'view_imadjust'), 'checked', 'on');
else
    set(findobj('tag', 'view_imadjust'), 'checked', 'off');
end
    
% image values
if para.im.greyscale
    set(findobj('tag', 'rgb1'), 'value', para.im.gs1);
    set(findobj('tag', 'rgb2'), 'value', para.im.gs2);
    set(findobj('tag', 'rgb3'), 'value', para.im.gs3);
else
    set(findobj('tag', 'rgb1'), 'value', para.im.rgb1);
    set(findobj('tag', 'rgb2'), 'value', para.im.rgb2);
    set(findobj('tag', 'rgb3'), 'value', para.im.rgb3);
end

% visibility of manipulation buttons
if para.im.manicheck
    set(get(gui.infoarea.image.panel, 'Children'), 'enable', 'on');
    if para.im.greyscale
        if status.GSImage
            set(findobj('tag', 'view_greyscale'), 'enable', 'off');
            set(findobj('tag', 'info_greyscale'), 'enable', 'off');
            set(findobj('tag', 'manicheck'), 'enable', 'off');
            set(findobj('tag', 'rgb1'), 'enable', 'off');
            set(findobj('tag', 'rgb2'), 'enable', 'off');
            set(findobj('tag', 'rgb3'), 'enable', 'off');
            set(findobj('tag', 'rgb1text'), 'enable', 'off');
            set(findobj('tag', 'rgb2text'), 'enable', 'off');
            set(findobj('tag', 'rgb3text'), 'enable', 'off');
            set(findobj('tag', 'rgbdef'), 'enable', 'off');
            set(findobj('tag', 'info_nightshot'), 'enable', 'off');
        else
            set(findobj('tag', 'view_greyscale'), 'enable', 'on');
            set(findobj('tag', 'info_greyscale'), 'enable', 'on');
            set(findobj('tag', 'info_manicheck'), 'enable', 'on');
            set(findobj('tag', 'rgb1'), 'enable', 'on');
            set(findobj('tag', 'rgb2'), 'enable', 'on');
            set(findobj('tag', 'rgb3'), 'enable', 'on');
            set(findobj('tag', 'rgb1text'), 'enable', 'on');
            set(findobj('tag', 'rgb2text'), 'enable', 'on');
            set(findobj('tag', 'rgb3text'), 'enable', 'on');
            set(findobj('tag', 'rgbdef'), 'enable', 'on');
            set(findobj('tag', 'info_nightshot'), 'enable', 'on');
        end
        set(findobj('tag', 'info_imagesc'), 'value', para.im.imagesc);
        set(findobj('tag', 'info_imadjust'), 'value', para.im.imadjust);
        set(findobj('tag', 'view_imagesc'), 'enable', 'on');
        set(findobj('tag', 'view_imadjust'), 'enable', 'on');
        set(findobj('tag', 'view_brighten'), 'enable', 'on');
        set(findobj('tag', 'view_defaultbrightness'), 'enable', 'on');
        set(findobj('tag', 'view_darken'), 'enable', 'on');
        set(findobj('tag', 'brighten'), 'enable', 'on');
        set(findobj('tag', 'defaultbrightness'), 'enable', 'on');
        set(findobj('tag', 'darken'), 'enable', 'on');
    else
        set(findobj('tag', 'info_imagesc'), 'value', 0);
        set(findobj('tag', 'info_imadjust'), 'value', 0);
        set(findobj('tag', 'view_imagesc'), 'enable', 'off');
        set(findobj('tag', 'view_imadjust'), 'enable', 'off');
        set(findobj('tag', 'info_imagesc'), 'enable', 'off');
        set(findobj('tag', 'info_imadjust'), 'enable', 'off');
        set(findobj('tag', 'view_brighten'), 'enable', 'off');
        set(findobj('tag', 'view_defaultbrightness'), 'enable', 'off');
        set(findobj('tag', 'view_darken'), 'enable', 'off');
        set(findobj('tag', 'brighten'), 'enable', 'off');
        set(findobj('tag', 'defaultbrightness'), 'enable', 'off');
        set(findobj('tag', 'darken'), 'enable', 'off');
    end
else
    set(get(gui.infoarea.image.panel, 'Children'), 'enable', 'off');
    set(findobj('tag', 'view_greyscale'), 'enable', 'off');
    set(findobj('tag', 'view_imagesc'), 'enable', 'off');
    set(findobj('tag', 'view_imadjust'), 'enable', 'off');
    set(findobj('tag', 'view_brighten'), 'enable', 'off');
    set(findobj('tag', 'view_defaultbrightness'), 'enable', 'off');
    set(findobj('tag', 'view_darken'), 'enable', 'off');
    set(findobj('tag', 'brighten'), 'enable', 'off');
    set(findobj('tag', 'defaultbrightness'), 'enable', 'off');
    set(findobj('tag', 'darken'), 'enable', 'off');
end
    
        

%% Check if the modules have anything to add
for i = 1:length(para.modules)
    feval([para.modules{i} '_guivisibility'], gui, para, status);
end