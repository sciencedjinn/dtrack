function [gui, status, para, data] = holo_autoZ(gui, status, para, data)

autowbh = waitbar(0, 'Automatic z-tracking...', 'CreateCancelBtn', 'setappdata(gcbf, ''canceling'', 1)');
setappdata(autowbh, 'canceling', 0);
a = get(autowbh, 'OuterPosition');
set(autowbh, 'OuterPosition', [a(1) a(2)+a(4) a(3) a(4)]);

cancelled = false;
tic
disp([datestr(now, 13) ' - Z-autotracking started']);
waitbar(0, autowbh, 'Automatic z-tracking...');

startframe = status.framenr;
endframe   = status.nFrames;
stepsize   = para.gui.stepsize;
for currframe = startframe:stepsize:endframe
    if getappdata(autowbh, 'canceling')
        cancelled = true;
        break;
    end
    
    try
        % goto frame
        if data.points(currframe, status.cpoint, 3)>0 && data.points(currframe, status.cpoint, 3)~=43
            status.framenr = currframe;
            [~, status, para] = dtrack_action([], status, para, data, 'loadonly');
            [~, status, para, data] = dtrack_action(gui, status, para, data, 'holo_findZ');
        end
        if mod((currframe-startframe)/stepsize, 1)==0 % set to higher numbers to reduce waitbar update frequency
            waitbar((currframe-startframe+1)/(endframe-startframe+1), autowbh);
        end
    catch me
        warndlg(sprintf('Z-autotracking stopped with a %s error: %s.', me.identifier, me.message))
        cancelled = true;
        break;
    end
end

try
    delete(autowbh);  % DELETE the waitbar; don't try to CLOSE it.

    %% exit
    if cancelled
        disp([datestr(now, 13) ' - Z-autotracking canceled after ' num2str(toc) ' seconds after frame ' num2str(currframe-stepsize) '.']);
    else
        disp([datestr(now, 13) ' - Z-autotracking finished after ' num2str(toc) ' seconds.']);
    end
catch
    warning('Internal error while closing auto-Z function.');
end