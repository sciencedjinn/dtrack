function [liststring, paths, howmany] = dtrack_fileio_getrecent(maxrecent)
% [liststring, paths, howmany] = dtrack_fileio_getrecent(maxrecent)
% paths and liststring begin with the most recent

if exist(fullfile(prefdir, 'dtrack_recent.dat'), 'file')
    load(fullfile(prefdir, 'dtrack_recent.dat'), '-mat'); %contains paths
 
    paths(1:(length(paths)-maxrecent))=[]; %reduce to para.maxrecent elements
    howmany=length(paths);
    
    if howmany
        %create liststring
        [~, f]=fileparts(paths{1}); 
        liststring=f;
        for i=2:length(paths)
            [~, f]=fileparts(paths{i});  
            liststring=[f '|' liststring]; %#ok<AGROW> %append to front!
        end
    else
        liststring='';
    end
    paths=fliplr(paths); %flip paths to get same order as liststring
else
    liststring='';
    paths={};
    howmany=0;
end