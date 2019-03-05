function [stat, para] = dtrack_fileio_autosave(status, para, data)
% auto save function, called automatically

[stat, para] = dtrack_fileio_saveres(status, para, data, 0, 1, 1);