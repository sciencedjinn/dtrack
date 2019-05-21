function [imout, h, timeout] = readframe(h, framenr, para, status, justoneframe)

if nargin<5
    justoneframe=0; %used to load just one frame, e.g. for reference
end

if para.thermal.isthermal
    imout = h.data(:, :, framenr);
    timeout = 0;
elseif para.imseq.isimseq
    imout = imread([h.filename, sprintf(['%0' num2str(para.imseq.padding) '.0f'], framenr), para.imseq.ext]);
    timeout = 0;
else
    if ~para.usemmread
        %use VideoReader, the internal MATLAB function
        imout = read(h, framenr);
        timeout = 0;
    else
        if ~ismember(framenr, h.range)
            if justoneframe
                hh = waitbar(0, 'Reading frame...', 'windowstyle', 'modal');
                h.range = framenr;
                disp(['Reading frame ' num2str(framenr) '.']);
            else
                hh = waitbar(0, 'Reading new frame block...', 'windowstyle', 'modal');
                % determine new range and read new chunk
                x1 = floor((framenr-1)/para.mmreadsize)*para.mmreadsize+1-para.mmreadoverlap;
                x2 = floor((framenr-1)/para.mmreadsize+1)*(para.mmreadsize)+para.mmreadoverlap;
                x1 = max([1 x1]); x2=min([status.nFrames x2]);
                h.range = x1:x2;
                disp(['Reading new frame block from frame ' num2str(x1) ' to frame ', num2str(x2) '.']);
            end
            video = mmread(h.filename, h.range, [], false, true, '', 1, 1);
            waitbar(1, hh);
            close(hh);
            h.data = video.frames;
            h.times = video.times;
    %         %alternative version with continuous waitbar; takes about 3 times as long
    %         for i=x1:x2
    %             video = mmread(h.filename, i, [], false, true, '', 1, 1);
    %             h.data(i-x1+1) = video.frames;
    %             waitbar((i-x1+1)/(x2-x1+1), hh);
    %         end
    %         close(hh);toc
        else

        end
        imout = h.data(h.range==framenr).cdata;
        timeout = h.times(h.range==framenr);
    end
end