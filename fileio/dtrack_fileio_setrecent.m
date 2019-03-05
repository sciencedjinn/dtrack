function dtrack_fileio_setrecent(newpath, maxrecent)
% dtrack_fileio_setrecent(newpath, maxrecent)
% set maxrecent to 0 to clear all recent files

if exist(fullfile(prefdir, 'dtrack_recent.dat'), 'file')
    load(fullfile(prefdir, 'dtrack_recent.dat'), '-mat'); % contains paths cell arrays
else
    paths = {};
end

paths(ismember(paths, newpath))     = [];               % delete previous entries of this path
paths{end+1}                        = newpath;          % add path to end of list
paths(1:(length(paths)-maxrecent))  = [];               % reduce to para.maxrecent elements

save(fullfile(prefdir, 'dtrack_recent.dat'), 'paths', '-mat');
