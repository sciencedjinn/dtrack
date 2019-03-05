function dtrack_paths

thispath = fileparts(mfilename('fullpath'));

addpath(thispath);
addpath(fullfile(thispath, 'support'));
addpath(fullfile(thispath, 'roi'));
addpath(fullfile(thispath, 'mmread'));
addpath(fullfile(thispath, 'fileio'));
addpath(fullfile(thispath, 'datafcns'));
addpath(fullfile(thispath, 'guifcns'));
addpath(fullfile(thispath, 'calib'));
addpath(fullfile(thispath, 'tools'));
addpath(fullfile(thispath, 'analysis'));
addpath(fullfile(thispath, 'navig'));

addpath(fullfile(fileparts(thispath), 'useful'));