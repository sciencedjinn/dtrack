function data=dtrack_removemarker(data, fnr, marker)

if isfield(data.markers(fnr), 'm')
    if ~isempty(data.markers(fnr).m)
        if ismember(marker, data.markers(fnr).m)
            data.markers(fnr).m(ismember(data.markers(fnr).m, marker))=[]; %remove it
        else
            error('Internal error: marker was not in array');
        end
    else
        error('Internal error: array was empty');
    end
else
    error('Internal error: field m does not exist for this frame');
end