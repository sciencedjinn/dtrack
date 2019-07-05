function [gui, status, para, data] = holo_autoZ(gui, status, para, data)


for currframe = status.framenr:para.gui.stepsize:status.nFrames

    % goto frame
    status.framenr = currframe;
    [~, status, para] = dtrack_action([], status, para, data, 'loadonly');
    if data.points(status.framenr, status.cpoint, 3)>0 && data.points(status.framenr, status.cpoint, 3)~=43
        [~, status, para, data] = dtrack_action(gui, status, para, data, 'holo_findZ');
    end
end