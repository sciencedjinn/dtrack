function [status, para, data] = dtrack_fileio_loadres(status, para, data)

% called by checkandloadres

% check if data is empty
if any(data.points(:)) || ~isempty(data.markers)
    button = questdlg('Another project is currently open. Are you sure you want to load a different one? Any unsaved changes will be lost!', 'Warning', 'Yes, discard unsaved changes', 'No, go back to the current project', 'No, go back to the current project');
    switch button
        case 'Yes, discard unsaved changes'
            %go on with function
        case 'No, go back to the current project'
            return;
        otherwise
            error('Internal error: Unexpected button response');
    end
end
% first, load the data into quarantine
Q = load(para.paths.respath, '-mat');
if Q.convert
    Q.data.points(:, :, 1) = full(Q.xdata);
    Q.data.points(:, :, 2) = full(Q.ydata);
    Q.data.points(:, :, 3) = full(Q.tdata);
    % xdata, ydata tdata and convert are later automatically ignored
    if isfield(Q, 'zdata')
        Q.data.points(:, :, 4) = full(Q.zdata);
    end
end

%% overwrite a few variables that should not be carried over between sessions
Q.para.paths.respath = para.paths.respath; % might be necessary if file was moved
Q.para.paths.resname = para.paths.resname; % might be necessary if file was renamed
Q.para.paths.default = para.paths.resdef;
Q.para.paths.default = para.paths.movdef;
Q.para.gui.fig1pos = para.gui.fig1pos;
Q.para.maxrecent = para.maxrecent;
Q.status.acquire = 1;
Q.status.maincb = status.maincb;
Q.status.movecb = status.movecb;
Q.status.scrollcb = status.scrollcb;

%% check which fields exist, fill others with defaults
data = Q.data; 
para = dtrack_support_compstruct(Q.para, para, 'para'); % if fields in Q.para don't exist, replace them with fields in para, save into para
status = dtrack_support_compstruct(Q.status, status, 'status');

%% Backward compatibility checks
% Changed May 2019 (holo update)
if isnumeric(para.ref.use)
    disp('Updating reference image format to version 1.9')
    if para.ref.use==1
        para.ref.use = 'static';
    else
        para.ref.use = 'none';
    end
end