function status = dtrack_inistatus(status, para)

if para.imseq.isimseq
    status.framenr = para.imseq.from;
else
    status.framenr = 1;
end
status.acquire = 1; % set to acquisition mode
h = figure; status.graycm = colormap('gray'); close(h);
status.lastaction = '';