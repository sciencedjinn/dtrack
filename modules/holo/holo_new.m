function [gui, status, para, data] = holo_new(gui, status, para, data)
% Contains extra commands for HOLO module to run after dtrack_fileio_new

if size(data.points, 3) < 4
    data.points(1, 1, 4) = 0; % extend data.points to include z-position of each point
    data.points(1, 1, 5) = 0; % extend data.points to include area of each point
else
    error('Error in module HOLO: data.points already has a z-position (presumably from another module');
end