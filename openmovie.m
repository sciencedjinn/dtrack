function [mh, nFrames, vidHeight, vidWidth, fRate, gs]=openmovie(para)
% opens a high definition video file, thermal camera file, or image
% sequence
%
% [mh, nFrames, vidHeight, vidWidth, FrameRate]=openmovie(filename)
% use frame=read(mh, frame) to obtain frames

    gs=0; %by default, not a greyscale sequence
    if para.thermal.isthermal
        disp(['Opening FLIR video file ', para.paths.movpath]);
        temp=load(para.paths.movpath, '-mat');
        if isfield(temp, 'data') && isfield(temp, 'ts')
            mh.data=temp.data;
            mh.ts=temp.ts;
            if length(mh.ts)~=size(mh.data, 3)
                error('Data and time stamp lengths are unequal');
            end
            vidHeight=size(mh.data, 1);
            vidWidth=size(mh.data, 2);
            nFrames=size(mh.data, 3);
            fRate=(nFrames-1) / ((mh.ts(end)-mh.ts(1))*24*60*60);     
        else
            error('Unknown file content (needs to contain fields ''data'' and ''ts'').');
        end
    elseif para.imseq.isimseq
        if isempty(para.paths.movname) %image names are numbers only
            mh.filename=[fileparts(para.paths.movpath) filesep];
        else
            mh.filename=fullfile(fileparts(para.paths.movpath), para.paths.movname);
        end
        disp(['Opening image sequence ', mh.filename, ', file numbers ' num2str(para.imseq.from), ' to ', num2str(para.imseq.to), ', padding ', num2str(para.imseq.padding), '.']);
        mh.range=para.imseq.from:para.imseq.to;
        nFrames=para.imseq.to;
        info=imfinfo([mh.filename, sprintf(['%0' num2str(para.imseq.padding) '.0f'], para.imseq.from), para.imseq.ext]);
        vidHeight=info.Height;
        vidWidth=info.Width;
        switch info.ColorType
            case 'grayscale'
                gs=1;
            case 'truecolor'
                gs=0;
            case 'indexed'
                gs=0;
                warning('Indexed images have not been tested. Good luck!');
        end
        fRate=NaN; %this is set after returning from this function in dtrack_fileio_openmovie
        
    else
        disp(['Opening hd video file ', para.paths.movpath]);

        if ~para.usemmread
            mh=VideoReader(para.paths.movpath); %was mmreader
            nFrames = mh.NumberOfFrames;
            vidHeight = mh.Height;
            vidWidth = mh.Width;
            fRate=mh.FrameRate;
            if isempty(nFrames)
                error('Fatal error: Number of frames could not be determined due to codec issues. Try using mmread.');
            end
        else
            mh.filename=para.paths.movpath;
            mh.range=1:para.mmreadsize;
            video = mmread(para.paths.movpath, mh.range, [], false, true, '', 1, 1);
            mh.data = video.frames;
            mh.times = video.times;

            nFrames = video.nrFramesTotal;
            if nFrames==0
                error('Fatal error: Number of frames could not be determined. Don''t even try tracking before this error is resolved!');
            elseif nFrames<0
                nFrames=abs(nFrames);
                warning('Number of frames estimated from time and frame rate. This might be inaccurate. Enter an exact number into the parameter file if needed (not implemented yet).');
            end
            vidHeight = video.height;
            vidWidth = video.width;
            fRate=video.rate;
        end
    end
end
