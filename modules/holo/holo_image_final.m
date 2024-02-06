function [gui, status, para, data, redraw] = holo_image_final(gui, status, para, data, redraw)
% Executed after all image updates

if ismember(redraw, [1 2 3 11 30])
    if para.gui.minimap
        axis(gui.minimap.axes, 'equal'); axis(gui.minimap.axes, [0 status.mh.Width*para.holo.mag 0 status.mh.Height*para.holo.mag]);
    % set(h, 'YDir', 'reverse', 'visible', 'off');
    end
end