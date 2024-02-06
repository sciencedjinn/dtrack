function [status, para, success]=dtrack_fileio_openmovie(status, para)

success=1;
try
    status.mh = ImageSource.create(para);

catch movie_loaderror
    if strcmp(movie_loaderror.identifier, 'MATLAB:mmreader:fileNotFound')
        success=0;
    elseif strcmp(movie_loaderror.identifier, 'MATLAB:mmreader:initializationError')
        options.Interpreter='tex';options.Default='Yes';
        choice = questdlg(['The default function mmreader cannot read this filetype. You can try to use mmread instead. However, '...
        'this might cause Matlab to crash. Also, the video will be read in several chunks for faster execution and you will experience a short reload time '...
        'every ' num2str(para.mmreadsize) ' frames (can be changed in the parameter file). Would you like to try using mmread?'], ...
        'Difficult file type', 'Yes', 'Cancel', options);
        switch choice
            case 'Yes'
                para.usemmread=1;
                status.mh = ImageSource.create(para);
            case 'Cancel'
                disp('Program execution aborted by user. You can try to convert your files to a simpler file type, e.g. avi, mpg, wmv, mov (Mac only).');
                success=2;
                return;
        end
    else
        rethrow(movie_loaderror);
    end
end