function data=dtrack_addmarker(data, fnr, marker)

if isfield(data.markers(fnr), 'm') && ~isempty(data.markers(fnr).m)
    if ismember(marker, data.markers(fnr).m)
        %already in there, do nothing
    else
        %add
        data.markers(fnr).m=[data.markers(fnr).m, marker];
    end
else
    data.markers(fnr).m={marker};
end