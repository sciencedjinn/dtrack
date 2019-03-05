function outfnr=dtrack_findnextmarker(data, infnr, type, dir)
%returns an empty array if no suitable frame marker found
%type should be a string, e.g. 's' for the start marker; or a vector for
%  several markers, e.g. ['s';'r'] for start marker or run marker, or 'all'
%  for any letter
%dir can be 'n'/'nc'/'p'/'pc'/'f'/'l'/'all'
%infnr is the framenr from which to start, usually status.framenr

if strcmp(type, 'all')
    type=char(('a':'z')');
end
allmarkers=arrayfun(@(x) any(ismember(type, x.m)), data.markers);
%alltypes=arrayfun(@(x) any(ismember(type, x.m)), data.markers);

switch dir
    case 'n'
        outfnr=infnr+find(allmarkers(infnr+1:end), 1, 'first');
    case 'nc'
        outfnr=infnr-1+find(allmarkers(infnr:end), 1, 'first');
    case 'p'
        outfnr=find(allmarkers(1:infnr-1), 1, 'last');
    case 'pc'
        outfnr=find(allmarkers(1:infnr), 1, 'last');
    case 'f'
        outfnr=find(allmarkers, 1, 'first');
    case 'l'
        outfnr=find(allmarkers, 1, 'last');
    case 'all'
        outfnr=find(allmarkers);
    otherwise
        error('Internal error: Unknown direction');
end