function dtrack_tools_imageone(status, para, type)
%dtrack module that saves a frame as an image, 
%does not return status or para, so it shouldn't make any changes!

%create filename
[a,b]=fileparts(para.paths.movpath);
padding=ceil(log10(status.nFrames));
switch type
    case {'tif', 'comptif'}
        filename_short=[b, sprintf(['_%0' num2str(padding) '.0f'], status.framenr) '.tif'];
    case 'jpg'
        filename_short=[b, sprintf(['_%0' num2str(padding) '.0f'], status.framenr) '.jpg'];
    otherwise
        error('Internal error: Unknown format');
end
filename=fullfile(a, filename_short);
      
%save buffer to file
switch type
    case 'tif'
        imwrite(status.currim_ori, filename, 'tif', 'compression', 'packbits');
    case 'comptif'
        imwrite(status.currim_ori, filename, 'tif', 'compression', 'jpeg', 'rowsperstrip', 8); %picked this value randomly
    case 'jpg'
        imwrite(status.currim_ori, filename, 'jpg', 'mode', 'lossy', 'quality', 75);
end