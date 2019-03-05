function [stat, para] = dtrack_fileio_saveres(status, para, data, ask, convert, auto) 

if nargin<6, auto = false; end % is this an autosave?
if nargin<5, convert = 1; end %convert to sparse
if nargin<4, ask = isempty(para.paths.respath); end %Save as...

%% get filepath
if auto
    if isfield(para.paths, 'autosavepath')
        savepath = para.paths.autosavepath;    
    else
        warning('No autosave path defined');
        stat = 0;
        return;
    end
elseif ask || isempty(para.paths.respath) %if there is no path, always ask. even if ask==0
    if isempty(para.paths.respath) 
        % find recently saved files
        [~, paths] = dtrack_fileio_getrecent(para.maxrecent);
        if ~isempty(paths)
            defpath = fileparts(paths{1});
        else
            defpath = '';
        end
        if exist(defpath, 'file')
            defaultpath = defpath;
        else
            defaultpath = para.paths.resdef;
        end
        % attach moviename as default resname
        defaultpath = fullfile(defaultpath, [para.paths.movname(1:end-4) '.res']);
    else % Save as...
        defaultpath = para.paths.respath; 
    end
    filename = dtrack_fileio_selectfile('save', defaultpath); % ask user to select path
    if filename
        para.paths.respath = filename;
    else
        stat = 0;
        errordlg('The project has NOT been saved!');
        return;
    end
    savepath = para.paths.respath;
else % normal Save
    savepath = para.paths.respath;
end

[p, f, e] = fileparts(savepath);
    
%% backup
if exist(savepath, 'file')
    % backup existing file
    stat = movefile(savepath, fullfile(p, [f '.backup']));
    disp(['Backing up ', savepath ' to ' fullfile(p, [f '.backup'])]);
else
    stat = 1;
end

%% save
if stat
    % remove unneccessary status data (handles take AGES)
    status.mh           = [];
    status.currim       = [];
    status.currim_ori   = [];
    status.ref.cdata    = [];
    status.maincb       = [];
    status.movecb       = [];
    status.resizecb     = [];
    status.ph           = {};
    status.cph          = [];
    status.lph          = [];
    status.pcb          = {};
    
    if convert
        xdata = sparse(data.points(:, :, 1)); %#ok<*NASGU>
        ydata = sparse(data.points(:, :, 2));
        tdata = sparse(data.points(:, :, 3));
        data.points = [];
        save(savepath, 'para', 'status', 'data', 'convert', 'xdata', 'ydata', 'tdata', '-mat');
    else
        save(savepath, 'para', 'status', 'data', 'convert', '-mat');
    end
    if auto
        disp(['Autosaving file ', savepath]);
    else
        dtrack_fileio_setrecent(savepath, para.maxrecent); % Save this to the recent files
        disp(['Saving file ', savepath]);
        para.paths.resname = [f e];
    end
else
    errordlg('The existing file could not be backed up. The project has NOT been saved!');
end






