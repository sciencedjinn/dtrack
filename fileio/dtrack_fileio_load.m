function [status, para, data, success] = dtrack_fileio_load(status, para, confirm, filename)
%main load function, called from startdlg or file menu

data = [];
success = false;
% If a project is currently open, confirm
if confirm
    button = questdlg('Another project is currently open. Are you sure you want to load a different one? Any unsaved changes will be lost!', 'Warning', 'Yes, discard unsaved changes', 'No, go back to the current project', 'No, go back to the current project');
    loadnew = strcmp(button, 'Yes, discard unsaved changes');
else 
    loadnew = true;
end
if loadnew
    if nargin<4 || isempty(filename)
        % Ask user for the filename to load.
        % Find the default path either a) from where this project is saved, or b) from
        % recently saved files or c) from defaults
        defpath = fileparts(para.paths.respath); %a)
        if isempty(defpath)
            [~, paths] = dtrack_fileio_getrecent(para.maxrecent);
            if ~isempty(paths)
                dpath = fileparts(paths{1});
            else
                dpath = '';
            end
            if exist(defpath, 'file')
                defpath = dpath; %b)
            else
                defpath = para.paths.resdef; %c)
            end
        end
        % now ask the user to select the file to load
        filename = dtrack_fileio_selectfile('load', defpath); %just acquires a file name, returns 0 if file selection is aborted
    end
    if filename~=0
        fprintf('\n----------\n\n');
        % create defaults (includes loading para/pref files)
        maincb = status.maincb; movecb = status.movecb; resizecb = status.resizecb;
        [status, para, data] = dtrack_defaults(para.modules);
        status.maincb = maincb; status.movecb = movecb; status.resizecb = resizecb;
        % save filenames
        [path, name, ext] = fileparts(filename); %#ok<ASGLU>
        para.paths.respath = filename; para.paths.resname = [name ext];
        % load data (checks if file exists, locates it if necessary, then calls loadres, then does the same for the movie)
        [status, para, data] = dtrack_fileio_checkandloadfile(status, para, data); 
        [status, para] = dtrack_roi_prepare(status, para); % loads roi file, finding the default first if necessary
        [status, para] = dtrack_ref_prepare(status, para); % loads ref file, finding the default first if necessary
        success = true;
    end
end





