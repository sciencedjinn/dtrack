function [status, para, data, success] = dtrack_fileio_new(status, para, confirm, same)
%main new function, called from startdlg or file menu

success = 0;data = [];
if confirm
    button  =  questdlg('Another project is currently open. Are you sure you want to create a new one? Any unsaved changes will be lost!', 'Warning', 'Yes, discard unsaved changes', 'No, go back to the current project', 'No, go back to the current project');
    loadnew  =  strcmp(button, 'Yes, discard unsaved changes');
else 
    loadnew = 1;
end
if loadnew
    if same
        %same file, new project
        filename = para.paths.movpath;
    else
        % TODO: remember the last folder then reload from that
        if ~isempty(para.paths.movpath)
            defpath = fileparts(para.paths.movpath);
        else
            defpath = para.paths.movdef;
        end
        filename = dtrack_fileio_selectfile('new', defpath); % just acquires a file name, returns 0 if file selection is aborted
    end

    if filename~= 0
        % create defaults
        oldpara = para; oldstatus = status; % keep stuff
        [status, para, data] = dtrack_defaults(para.modules);
        status.maincb = oldstatus.maincb; status.movecb = oldstatus.movecb; status.resizecb = oldstatus.resizecb; status.scrollcb = oldstatus.scrollcb; % restore callbacks

        % save filenames
        [~, name, ext] = fileparts(filename); % #ok<ASGLU>
        para.paths.movpath = filename; para.paths.movname = [name ext]; para.paths.resname = 'Untitled';

        if same
            % restore some stuff
            % a) para
            para.paths.movdef = oldpara.paths.movdef;
            para.paths.resdef = oldpara.paths.resdef;
            para.paths.calibname = oldpara.paths.calibname;
            para.paths.roiname = oldpara.paths.roiname;
            para.im = oldpara.im;
            para.ref = oldpara.ref;
            para.thermal = oldpara.thermal;
            para.imseq = oldpara.imseq;
            
            % b) all status except 
            status.framenr  = oldstatus.framenr;
            status.graycm   = oldstatus.graycm;
            status.trackedpoints = oldstatus.trackedpoints;
            status.mh = oldstatus.mh;
            status.nFrames = oldstatus.nFrames;
            status.vidHeight = oldstatus.vidHeight;
            status.vidWidth = oldstatus.vidWidth;
            status.FrameRate = oldstatus.FrameRate;
            status.currim_ori = oldstatus.currim_ori;
            status.currim = oldstatus.currim;
            status.roi = oldstatus.roi;
            status.ref = oldstatus.ref;
%             status.os = oldstatus.os;
%             status.matlabv = oldstatus.matlabv;
%             status.dtrackbase = oldstatus.dtrackbase;
            success = 1;
        else         
            switch lower(ext)
                case '.mat' %potentially a thermal video, test again when loading
                    disp('Thermographic video detected.');
                    para.thermal.isthermal = 1;
                case {'.jpg', '.jpeg', '.tif', '.tiff', '.bmp', '.gif', '.pbm', '.png'}
                    disp('Image sequence detected.');
                    para.imseq.isimseq = 1;
                    para.imseq.ext = ext;
                    % detect numbering and padding
                    pad = 1;
                    while pad <= length(name) && ~isnan(str2double(name(end-pad+1:end)))
                        pad = pad+1;
                    end
                    para.imseq.padding = pad-1;
                    para.imseq.from = str2double(name(end-para.imseq.padding+1:end));
                    para.paths.movname = name(1:end-para.imseq.padding);
                    i = para.imseq.from;
                    while exist(fullfile(fileparts(para.paths.movpath), sprintf(['%s%0' num2str(para.imseq.padding) '.0f%s'], para.paths.movname, i, para.imseq.ext)), 'file')
                        i = i+1;
                    end
                    para.imseq.to = i-1;
                otherwise
            end
            para = dtrack_editparameters(para); %parameter dialog
            if isempty(para) %canceled
                return; %success is 0, so the output data will not be used
            end
            pause(0.1); %without this the parameter window doesnt close before the movie loads, which might crash matlab
            %load movie
            set(gcf, 'pointer', 'watch');drawnow;
            status = dtrack_inistatus(status, para);
            [status, para, success] = dtrack_fileio_openmovie(status, para); %success 0 means file not found, 2 means aborted by user. If mmreader can't read it, mmread will be tried (after dialog)
            [status, para] = dtrack_roi_prepare(status, para); %loads roi file, finding the default first if necessary
            [status, para] = dtrack_ref_prepare(status, para); %loads reference frame
            % check if this is a greyscale image sequence
            if status.GSImage
                para.im.greyscale = 1;
                para.im.manicheck = 1;
                para.im.imagesc = 1;
                set(findobj('tag', 'manicheck'), 'value', 1);
                % inappropriate controls will be inactivated in guivisibility
            end
            switch success
                case 0
                    error('Internal error: File not found, although it was checked before'); 
                case 2
                    return;
            end
        end
        
        %create empty data structure
        data.points = zeros(status.nFrames, para.pnr, 3);
        data.markers = struct('m', cell(status.nFrames, 1));
    end
end

