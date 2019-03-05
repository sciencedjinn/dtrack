function filename=dtrack_fileio_selectroi(type, defaultpath, dlgstring, searchname)
% This function asks for user input to load a ROI file

% See also: dtrack_roi_create, dtrack_roi_finddefault, dtrack_fileio_loadroi

if nargin<4
    dlgfilter={'*.roi', 'ROI files (*.roi)'; 
    '*.*',  'All Files (*.*)'};
else
    dlgfilter={searchname, searchname; 
    '*.*',  'All Files (*.*)'};
end

if nargin<3
    dlgstring='Please select an Region Of Interest file';
end

if nargin<2
    defaultpath=pwd;
end

switch type
    case {'load'}
        [filename, pathname] = uigetfile(dlgfilter, dlgstring, defaultpath);
    case {'save'}
        [filename, pathname] = uiputfile(dlgfilter, dlgstring, defaultpath);
end

if filename==0
    disp('File selection aborted.');
else
    filename=fullfile(pathname, filename);
end