function dtrack_tools_imageone(status, para, type, proc)
% dtrack module that saves a frame as an image, 
% does not return status or para, so it shouldn't make any changes!
% parameter proc can be used to save the processed image rather than the original one

if nargin < 4, proc = false; end

% create filename
[a, b] = fileparts(para.paths.movpath);
padding = ceil(log10(status.nFrames));
switch type
    case {'tif', 'comptif'}
        filename_short = [b, sprintf(['_%0' num2str(padding) '.0f'], status.framenr) '.tif'];
    case 'jpg'
        filename_short = [b, sprintf(['_%0' num2str(padding) '.0f'], status.framenr) '.jpg'];
    otherwise
        error('Internal error: Unknown format');
end
filename = fullfile(a, filename_short);
      
% save buffer to file
if proc
    saveImage = status.currim;
else
    saveImage = status.currim_ori;
end
switch type
    case 'tif'
        imwrite(saveImage, filename, 'tif', 'compression', 'packbits');
    case 'comptif'
        imwrite(saveImage, filename, 'tif', 'compression', 'jpeg', 'rowsperstrip', 8); % picked this value randomly
    case 'jpg'
        imwrite(saveImage, filename, 'jpg', 'mode', 'lossy', 'quality', 75);
end