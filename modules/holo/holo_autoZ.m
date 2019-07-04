function [gui, status, para, data] = holo_autoZ(gui, status, para, data)


for currframe = status.framenr:10:450
%     % advance waitbar
%     perc = (filenr-savepara.startfile+1)/((savepara.to-savepara.from+1)/savepara.step);waitbar(perc, hh);
%     filenr = filenr+1;

    % goto frame
    status.framenr = currframe;
    [~, status, para] = dtrack_action([], status, para, data, 'loadonly');
    [~, status, para, data] = dtrack_action(gui, status, para, data, 'holo_findZ');
end