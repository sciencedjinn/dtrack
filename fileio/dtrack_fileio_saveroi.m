function success=dtrack_fileio_saveroi(filename, x, y)

%% backup
if exist(filename, 'file')
    % backup existing file
    [p, f, e]=fileparts(filename);
    success=movefile(filename, fullfile(p, [f '.roibackup']));
    disp(['Backing up ', filename ' to ' fullfile(p, [f '.roibackup'])]);
else
    success=1;
end
dlmwrite(filename, [x(:) y(:)]);
