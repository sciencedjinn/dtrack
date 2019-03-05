function [status, para]=dtrack_roi_prepare(status, para)
    
%this has to go in between loading and gui preparation
if isempty(para.paths.roiname)
    filename=dtrack_roi_finddefault(para.paths.movpath);
    if filename~=0
        para.paths.roiname=filename;
        para.im.roi=1;
    end
end
status.roi=dtrack_fileio_loadroi(para.paths.roiname); %returns empty if roiname is empty
