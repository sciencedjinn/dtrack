function dtrack_tools_imageseq_main(status, para, data, savepara)
% dtrack_tools_imageseq_main saves dtrack frames as a video or an image sequence.
% 
% This does not return status or para, so it shouldn't make any changes!

% para
asVideo = savepara.format>3;

% init
overwrite = false;                
filenr = savepara.startfile-1;
colors = {[0 0 1], [0 1 0], [1 0 0], [1 1 0], [1 0 1], [0 1 1], [0 0 0], [1 1 1], [.5 0 1], [0 .5 1]};

if asVideo, waitbarText = 'Saving frames as video...'; else, waitbarText = 'Saving frames as image sequence...'; end
hh = waitbar(0, waitbarText, 'windowstyle', 'modal');

if asVideo
    filename = fullfile(savepara.folder, [savepara.basename, '.avi']);
    if exist(filename, 'file') && ~overwrite
        button = questdlg(['The file ' [savepara.basename, '.avi'] ' already exists. Do you want to overwrite it?'], 'Warning', 'Overwrite', 'Cancel', 'Skip');
        switch button
            case 'Overwrite'
                % continue to overwrite file
            case 'Cancel'
                disp('Operation canceled: Save as image sequence');
                return
            otherwise
                error('Internal error: Unknown button name');
        end
    end             
    v = VideoWriter(filename));
    v.FrameRate = 3*status.FrameRate/savepara.step;
    open(v);
end

try
    for currframe = savepara.from:savepara.step:savepara.to
        % advance waitbar
        perc = (filenr-savepara.startfile+1)/((savepara.to-savepara.from+1)/savepara.step); waitbar(perc, hh);
        filenr = filenr+1;

        % goto frame
        status.framenr = currframe;
        [~, status, para] = dtrack_action([], status, para, data, 'loadonly');
        
        % extract frame
        frame = status.currim;
        
        % draw a circle on the current point 1
        for i = 1:para.pnr
            if data.points(currframe, i, 3)>0
                frame = sub_insertPoint(frame, squeeze(data.points(currframe, i, 1:2)), colors{i});
            end
        end
        
        if asVideo
            writeVideo(v, frame);
        else
            % create filename
            switch savepara.format
                case {1, 2}
                    filename_short = [savepara.basename, sprintf(['%0' num2str(savepara.padding) '.0f'], filenr) '.tif'];
                case 3
                    filename_short = [savepara.basename, sprintf(['%0' num2str(savepara.padding) '.0f'], filenr) '.jpg'];
                otherwise
                    error('Internal error: Unknown format');
            end
            filename = fullfile(savepara.folder, filename_short);
            % check if exists
            if exist(filename, 'file') && ~overwrite
                button = questdlg(['The file ' filename_short ' (and possibly all following files) already exists. Do you want to overwrite it?'], 'Warning', 'Overwrite all', 'Skip', 'Cancel', 'Skip');
                switch button
                    case 'Overwrite all'
                        overwrite = 1;
                    case 'Skip'
                        continue;
                    case 'Cancel'
                        disp('Operation canceled: Save as image sequence');
                        break;
                    otherwise
                        error('Internal error: Unknown button name');
                end
            end                    
            % save buffer to file
            switch savepara.format
                case 1 % Lossless TIFF
                    imwrite(frame, filename, 'tif', 'compression', 'packbits');
                case 2 % Lossy TIFF
                    imwrite(frame, filename, 'tif', 'compression', 'jpeg', 'rowsperstrip', 8); % picked this value randomly
                case 3 % 75% JPG
                    imwrite(frame, filename, 'jpg', 'mode', 'lossy', 'quality', 75);
            end
        end
    end
catch me
    if asVideo, close(v); end
    close(hh);
    rethrow(me)
end

if asVideo, close(v); end
close(hh);




function outframe = sub_insertPoint(frame, point, col)
%% insert a point by directly overwriting image pixels

[x, y] = meshgrid(1:size(frame, 2), 1:size(frame, 1));
dist = sqrt((x - point(1)).^2 + (y - point(2)).^2);
mask1 = dist>18&dist<22;
mask2 = dist>19&dist<21;

switch size(frame, 3)
    case 1
        frame1 = frame;
        frame2 = frame;
        frame3 = frame;
        frame1(mask1) = 1/2 + col(1)/2;
        frame2(mask1) = 1/2 + col(2)/2;
        frame3(mask1) = 1/2 + col(3)/2;
        frame1(mask2) = col(1);
        frame2(mask2) = col(2);
        frame3(mask2) = col(3);
        outframe = cat(3, frame1, frame2, frame3);
    case 3
        frame1 = frame(:, :, 1);
        frame2 = frame(:, :, 2);
        frame3 = frame(:, :, 3);
        frame1(mask1) = 1/2 + col(1)/2;
        frame2(mask1) = 1/2 + col(2)/2;
        frame3(mask1) = 1/2 + col(3)/2;
        frame1(mask2) = col(1);
        frame2(mask2) = col(2);
        frame3(mask2) = col(3);
        outframe = cat(3, frame1, frame2, frame3);
    otherwise 
        error('Unknown image size');
end




