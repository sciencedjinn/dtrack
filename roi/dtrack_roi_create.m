function outfilename=dtrack_roi_create(defloadpath, defsavepath, axhandle)
% axis handle must be provided to show preview
% See also: dtrack_roi_finddefault, dtrack_fileio_openroi, dtrack_fileio_loadroi

% let the user select a file
filename=dtrack_fileio_selectfile('load', defloadpath);
if filename==0 %file selection aborted
    outfilename=0;
    disp('No ROI file was created');
    return;
end
% load the file data
Q=load(filename, '-mat');
if Q.convert
    points(:, :, 1)=full(Q.xdata);
    points(:, :, 2)=full(Q.ydata);
else
    points(:, :, 1:2)=Q.data.points(1:2);
end

% select which point, and conversion method
happy = 0;
while ~happy
    answer = inputdlg({sprintf('Which point (1-%0.0f)?', size(points, 2)), 'Which method (e=exact, other=convex hull)?'}, '', 1, {'1', 'c'});
    if isempty(answer)
        happy = 2;
    else
        x=points(:, str2double(answer{1}), 1);y=points(:, str2double(answer{1}), 2);
        sel=x&y; x=x(sel); y=y(sel);
        switch answer{2}
            case {'e', 'exact'}
                %use points exactly as they are
            otherwise
                %use convex hull method
                K=convhull(x, y);
                x=x(K); y=y(K);
        end
        hold(axhandle, 'on');
        temph=plot(axhandle, x, y, 'b.-');
        button=questdlg('Accept this choice?', '', 'Yes', 'No', 'Cancel', 'Yes');
        delete(temph);
        hold(axhandle, 'off');
        switch button
            case 'Yes'
                happy=1;
            case 'No'
                happy=0;
            case 'Cancel'
                happy=2;
        end
    end
end
switch happy
    case 1
        % Accept and save
        filename=dtrack_fileio_selectroi('save', defsavepath);
        if filename==0
            success=0;
        else
            success=dtrack_fileio_saveroi(filename, x, y);
        end
        if success
            outfilename=filename;
            disp(['ROI file was created and saved as ' filename]);
        else
            outfilename=0;
            disp('No ROI file was created');
        end
    case 2
        % Abort
        outfilename=0;
        disp('No ROI file was created');
end
