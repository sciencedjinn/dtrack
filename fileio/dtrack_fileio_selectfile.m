function filename=dtrack_fileio_selectfile(type, defaultpath, dlgstring, searchname)
% this function asks the user to select a file; type can be 'load' or
% 'save' or 'new' or 'export'

if nargin<4
    if strcmp(type, 'new')
        dlgfilter={'*.avi;*.mpg;*.wmv;*.asf;*.asx;*.mj2;*.mp4;*.m4v;*.mov;*.ogg;*.mts;*.m2t;*.m2ts;*.mat;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.gif;*.pbm;*.png', ...
            'All movie and image files (*.avi;*.mpg;*.wmv;*.asf;*.asx;*.mj2;*.mp4;*.m4v;*.mov;*.ogg;*.mts;*.m2t;*.m2ts;*.mat;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.gif;*.pbm;*.png)'; 
        '*.avi', 'AVI files (*.avi)'; 
        '*.wmv;*.asf;*.asx', 'Windows Media Video files (Win only) (*.wmv;*.asf;*.asx)'; 
        '*.mj2', 'Motion JPEG 2000 (*.mj2)'; 
        '*.mpg', 'MPEG-1 files (*.mpg)'; 
        '*.mp4;*.m4v', 'MPEG-4 files (Mac only) (*.mp4;*.m4v)';
        '*.mov', 'Apple QuickTime Movie files (Mac only) (*.mov)';
        '*.ogg', 'Ogg Theora files (Linux only) (*.ogg)'; 
        '*.mts;*.m2t;*.m2ts', 'AVCHD files (mmread only) (*.mts;*.m2t;*.m2ts)';
        '*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.gif;*.pbm;*.png', ...
            'Image files (*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.gif;*.pbm;*.png)'; 
        '*.mat', 'FLIR videos (*.mat)';         
        '*.*',  'All Files (*.*)'};
    elseif strcmp(type, 'export')
        dlgfilter={'*.*',  'All Files (*.*)'};
    else
        dlgfilter={'*.res', 'dtrack project file (*.res)';
        '*.*',  'All Files (*.*)'};
    end
else
    dlgfilter={searchname, searchname; 
    '*.*',  'All Files (*.*)'};
end
if nargin<3 || isempty(dlgstring)
    if strcmp(type, 'save')
        dlgstring='Save as';
    elseif strcmp(type, 'export')
        dlgstring='Save as text file';
    elseif strcmp(type, 'new')
        dlgstring='Please select a video file';
    else %must be load
        dlgstring='Please select a project result file';
    end
end
if nargin<2
    defaultpath=pwd;
end

switch type
    case {'new', 'load'}
        [filename, pathname] = uigetfile(dlgfilter, dlgstring, defaultpath);
    case {'save', 'export'}
        [filename, pathname] = uiputfile(dlgfilter, dlgstring, defaultpath);
end
if filename==0
    disp('File selection aborted.');
else
    filename=fullfile(pathname, filename);
end