function [status, para, data]=dtrack_fileio_checkandloadfile(status, para, data)


% check if the filename exists (recent filename might be invalid)
if ~exist(para.paths.respath, 'file')
    [ps, ns, es]=fileparts(para.paths.respath); %search path and names
    filename=dtrack_fileio_selectfile('load', ps, ['Project file could not be found at ' para.paths.respath '. Please locate the file.'], [ns es]); %just acquires a file name, returns 0 if file selection is aborted
    if filename~=0
        para.paths.respath=filename;
        [path, name, ext]=fileparts(filename); %#ok<ASGLU>
        para.paths.resname=[name ext];
    else
        error(['Project file could not be found at ' para.paths.respath '.']);
    end
end
        
% load the project file
[status, para, data]=dtrack_fileio_loadres(status, para, data);

% check if the movie can be found
if ~exist(para.paths.movpath, 'file')
    [ps, ns, es]=fileparts(para.paths.movpath); %search path and names
    
    %first, try to find it on other drives (Win only)
    filename=0;
    syst=computer;
    if strncmpi(syst, 'PCWIN', 5)
        import java.io.*;
        f=File('');
        r=f.listRoots;
        for i=1:length(r)
            testfilename=fullfile(char(r(i)), para.paths.movpath(4:end));
            if exist(testfilename, 'file')
                fprintf('-----\n');
                fprintf('Movie file could not be found at %s,\nbut a file of that name exists on the same path on drive %s. Using that file now.\n', para.paths.movpath, char(r(i)));
                fprintf('-----\n');
                filename=testfilename;
            end
        end
    end
        
    %if unsuccessful, ask user
    if filename==0
        filename = dtrack_fileio_selectfile('new', ps, ['Movie file could not be found at ' para.paths.movpath '. Please locate the file.'], [ns es]); %just acquires a file name, returns 0 if file selection is aborted
    end
    %now replace filename in para
    if filename~=0
        para.paths.movpath = filename;
        [path, name, ext] = fileparts(filename); %#ok<ASGLU>
        if para.imseq.isimseq
            para.paths.movname = name(1:end-para.imseq.padding);
        else
            para.paths.movname = [name ext];
        end
    else
        error(['Movie file could not be found at ' para.paths.movpath '.']);
    end
end

%load movie
set(gcf, 'pointer', 'watch'); drawnow;
[status, para, success] = dtrack_fileio_openmovie(status, para); %success 0 means file not found. If mmreader can't read it, mmread will be tried (after dialog)
% check if this is a greyscale image sequence
if status.GSImage
    para.im.greyscale=1;
    para.im.manicheck=1;
    para.im.imagesc=1;
    set(findobj('tag', 'manicheck'), 'value', 1);
    % inappropriate controls will be inactivated in guivisibility
end
if ~success
    error('Internal error: File not found, although it was checked before'); 
end