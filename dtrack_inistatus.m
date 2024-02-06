function status = dtrack_inistatus(status)

status.framenr = 1;
status.acquire = 1; % set to acquisition mode
h = figure; status.graycm = colormap('gray'); close(h);
status.lastaction = '';