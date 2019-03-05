function filename=dtrack_fileio_opencalib(defaultpath, dlgstring, searchname)
% lets the user open a new project by opening a movie file

if nargin<3
    dlgfilter={'*.calib', 'Calibration files (*.calib)'; 
    '*.mat', 'MATLAB files (*.avi)';
    '*.*',  'All Files (*.*)'};
else
    dlgfilter={searchname, searchname; 
    '*.*',  'All Files (*.*)'};
end
if nargin<2
    dlgstring='Please select an extrinsic calibration file';
end
if nargin<1
    defaultpath=pwd;
end

[filename, pathname] = uigetfile( ...
    dlgfilter, ...
    dlgstring, defaultpath);

if filename==0
    disp('File selection aborted.');
else
    filename=fullfile(pathname, filename);
end