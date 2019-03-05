function dtrack_tools_imageseq_main(status, para, savepara)
%dtrack module that saves a video as an image sequence, 
%does not return status or para, so it shouldn't make any changes!

%init
overwrite=0;                
filenr=savepara.startfile-1;

hh=waitbar(0, 'Saving video as image sequence...', 'windowstyle', 'modal');

for currframe=savepara.from:savepara.step:savepara.to
    %advance waitbar
    perc=(filenr-savepara.startfile+1)/((savepara.to-savepara.from+1)/savepara.step);waitbar(perc, hh);

    filenr=filenr+1;

    %goto frame
    status.framenr=currframe;
    [junk, status, para]=dtrack_action([], status, para, [], 'loadonly');
    %create filename
    switch savepara.format
        case {1, 2}
            filename_short=[savepara.basename, sprintf(['%0' num2str(savepara.padding) '.0f'], filenr) '.tif'];
        case 3
            filename_short=[savepara.basename, sprintf(['%0' num2str(savepara.padding) '.0f'], filenr) '.jpg'];
        otherwise
            error('Internal error: Unknown format');
    end
    filename=fullfile(savepara.folder, filename_short);
    %check if exists
    if exist(filename, 'file') && ~overwrite
        button=questdlg(['The file ' filename_short ' (and possibly all following files) already exists. Do you want to overwrite it?'], 'Warning', 'Overwrite all', 'Skip', 'Cancel', 'Skip');
        switch button
            case 'Overwrite all'
                overwrite=1;
            case 'Skip'
                continue;
            case 'Cancel'
                disp('Operation canceled: Save as image sequence');
                break;
            otherwise
                error('Internal error: Unknown button name');
        end
    end                    
    %save buffer to file
    switch savepara.format
        case 1 %Lossless TIFF
            imwrite(status.currim_ori, filename, 'tif', 'compression', 'packbits');
        case 2 %Lossy TIFF
            imwrite(status.currim_ori, filename, 'tif', 'compression', 'jpeg', 'rowsperstrip', 8); %picked this value randomly
        case 3 %75% JPG
            imwrite(status.currim_ori, filename, 'jpg', 'mode', 'lossy', 'quality', 75);
    end
end
close(hh);