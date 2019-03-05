function roi=dtrack_fileio_loadroi(filename)
%This function load a ROI file for the current sequence
%has to accept empty

% See also: dtrack_roi_create, dtrack_fileio_openroi, dtrack_roi_finddefault

if isempty(filename)
    roi=[];
else
    if ~exist(filename, 'file')
        warning(['ROI file could not be found at ' filename '.']);
        roi=[];
    else
        roi=dlmread(filename);
    end
end