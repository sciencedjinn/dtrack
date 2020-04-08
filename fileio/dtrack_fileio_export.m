function stat = dtrack_fileio_export(para, data) 
% saves the data matrix in any desired format,
% the markers are currently not saved

%% get filepath
if isempty(para.paths.respath)
    %find recently saved files
    [liststring, paths]=dtrack_fileio_getrecent(para.maxrecent);
    if ~isempty(paths)
        defpath=fileparts(paths{end});
    else
        defpath='';
    end
    if exist(defpath, 'file')
        defaultpath=defpath;
    else
        defaultpath=para.paths.resdef;
    end
else
    defaultpath=[para.paths.respath(1:end-3) 'txt']; 
end

filename=dtrack_fileio_selectfile('export', defaultpath);

if filename==0
    stat=0;errordlg('The project has NOT been saved!');return;
end

[p, f, e]=fileparts(filename);
if isempty(e)
    e = '.txt';
end

%% ask for format
button = questdlg('Which data format would you like to save in?', ...
                         'Choose format', ...
                         'Full', 'Sparse', 'Cancel', 'Sparse');
if strcmp(button, 'Cancel')
    stat = 0; errordlg('The project has NOT been saved!'); return;
end

for i = 1:size(data.points, 2)
    currfile = fullfile(p, sprintf('%s_point%02.0f%s', f, i, e));
    %% backup
    if exist(currfile, 'file')
        % backup existing file
        stat = movefile(currfile, [currfile 'backup']);
        disp(['Backing up ', currfile ' to ' currfile 'backup.']);
    else
        stat = 1;
    end

    %% save
    if stat
        switch button
            case 'Full'
                dlmwrite(currfile, squeeze(data.points(:, i, :)), 'delimiter', '\t');
            case 'Sparse'
                ind = find(data.points(:, i, 3));
                sparsedata = [ind reshape(data.points(ind, i, :), [length(ind) size(data.points, 3)])]; % This used to use squeeze, but that creates an error when there is only a single point
                dlmwrite(currfile, sparsedata, 'delimiter', '\t');
        end
        disp(['Saving file ', currfile]);
    else
        errordlg('The existing file could not be backed up. The data has NOT been saved!');
    end
end

% also save frame markers
temp = dtrack_findnextmarker(data, 1, 'all', 'all');
allmarkers = [];
for i = 1:length(temp)
    allmarkers = [allmarkers data.markers(temp(i)).m{:}];
end
markertypes = unique(allmarkers);
for i = 1:length(markertypes)
    currfile = fullfile(p, sprintf('%s_marker_%c%s', f, markertypes(i), e));
    dlmwrite(currfile, dtrack_findnextmarker(data, 1, markertypes(i), 'all'));
end


