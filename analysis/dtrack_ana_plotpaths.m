function dtrack_ana_plotpaths(h, data, status, para)
        
cla(h); hold(h, 'on');

switch para.trackingtype
    case 'point'
        sel = data.points(:, 1, 3)~=0;
        plot(h, data.points(sel, 1, 1), data.points(sel, 1, 2), '.-');
        plot(h, data.points(:, :, 1), data.points(:, :, 2), '.', data.points(status.framenr, :, 1), data.points(status.framenr, :, 2), 'yo');
        %aa=dtrack_findnextmarker(data, 1, 'a', 'all'); plot(h, data.points(aa, 4, 1), data.points(aa, 4, 2), 'ro');
    case 'line'
        for p = 1:2:size(data.points, 2)
            sel = data.points(:, p, 3)~=0;
            plot(h, data.points(status.framenr, p:p+1, 1)', data.points(status.framenr, p:p+1, 2)', 'yo-', 'linewidth', 2); %display current lines in yellow
            plot(h, data.points(sel, p:p+1, 1)', data.points(sel, p:p+1, 2)', '-', 'color', para.ls.p{p}.col);
            plot(h, data.points(sel, p, 1), data.points(sel, p, 2), 'linestyle', 'none', 'marker', para.ls.p{p}.shape, 'color', para.ls.p{p}.col);
        end
end
if para.im.roi
    switch status.roi(1, 1)
        case 0  %0 indicates polygon vertices
            roih=line(status.roi(2:end, 1), status.roi(2:end, 2), 'parent', h); 
            set(roih, 'marker', para.ls.roi.shape, 'markerfacecolor', 'none', 'color', para.ls.roi.col, 'markersize', para.ls.roi.size, 'linewidth', para.ls.roi.width);
        case 1
            roih=rectangle('parent', h, 'Position', status.roi(2:end, 1), 'Curvature', [1 1]);
            set(roih, 'edgecolor', para.ls.roi.col, 'linewidth', para.ls.roi.width);
        otherwise %old roi file
            disp('No ROI type indicator found, assuming old ROI file.');
            line(status.roi(:, 1), status.roi(:, 2), 'parent', h);   
    end
end 
axis(h, 'equal'); axis(h, [0 status.vidWidth 0 status.vidHeight]);
set(h, 'YDir', 'reverse', 'visible', 'off');