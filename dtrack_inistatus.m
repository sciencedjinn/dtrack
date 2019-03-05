function status=dtrack_inistatus(status, para)

status.cpoint=1; %the currently tracked point
if para.imseq.isimseq
    status.framenr=para.imseq.from;
else
    status.framenr=1;
end
status.acquire=1; %set to acquisition mode
h=figure;status.graycm=colormap('gray');close(h);
status.trackedpoints=1:para.pnr;
status.lastaction='';