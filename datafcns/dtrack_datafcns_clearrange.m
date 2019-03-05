function data=dtrack_datafcns_clearrange(status, para, data, frange, prange)

if nargin<4
    % ask for data range
    prompt = {'Frame range','Point range'};
    dlg_title = 'Clear data range';
    num_lines = 1;
    def = {['1:' num2str(status.nFrames)],num2str(status.cpoint)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);

    % cancel
    if isempty(answer) %canceled
        return;
    end

    % extract range
    frange=eval(answer{1});
    prange=eval(answer{2});
else
    answer={num2str(frange), 'all'};
end

frange_c=frange(ismember(frange, 1:status.nFrames))';
prange_c=prange(ismember(prange, 1:size(data.points, 2)))';

if isempty(frange_c)
    errordlg(['Frames ' answer{1} ' are outside the range of the current video file.']);uiwait;
    return;
end
if isempty(prange_c)
    errordlg(['None of these points are tracked in this video (' answer{2} ')']);uiwait;
    return;
end

num2del=zeros(max(prange_c), 1);
for i=prange_c
    num2del(i)=nnz(data.points(frange_c, i, 3));
end

if ~any(num2del)
    errordlg(['No points were tracked in the given range (frames ' answer{1} ', points ' answer{2} ')']);uiwait;
    return;
end

% confirm
prompt = {'The following numbers of positions have been tracked in the given range:', ''};
for i=prange_c
    prompt=[prompt, ['     Point ' num2str(i), ': ' num2str(num2del(i)) ' positions.']];
end
prompt=[prompt, {''}];
prompt=[prompt, 'Do you really want to delete these entries?'];
button = questdlg(prompt, 'Confirm delete', 'Yes, delete', 'No, cancel', 'No, cancel');

% delete
switch button
    case 'Yes, delete'
        data.points(frange_c, prange_c, 1:3)=0;
        helpdlg([num2str(sum(num2del)) ' points successfully deleted.'],'Points deleted');uiwait;
    case {'No, cancel', ''}
        disp('Delete operation canceled');
    otherwise
        error('Internal error: Unknown dialog response');
end



