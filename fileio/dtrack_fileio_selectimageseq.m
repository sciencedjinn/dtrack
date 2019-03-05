function pathname=dtrack_fileio_selectimageseq(defaultpath, dlgstring)
% This function asks for user input to load an image sequence

% See also: 

if nargin<2
    dlgstring='Please select a folder to save the image sequence in';
end

if nargin<1
    defaultpath=pwd;
end

pathname = uigetdir(defaultpath, dlgstring);

if pathname==0
    disp('Folder selection aborted.');
end