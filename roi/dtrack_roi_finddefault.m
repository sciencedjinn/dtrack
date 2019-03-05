function outfilename=dtrack_roi_finddefault(defpath)

%has to return empty if not found
% See also: dtrack_roi_create, dtrack_fileio_openroi, dtrack_fileio_loadroi
testfilename=fullfile(fileparts(defpath), 'defaultroi.roi');
if exist(testfilename, 'file')
    outfilename=testfilename;
else
    outfilename=[];
end