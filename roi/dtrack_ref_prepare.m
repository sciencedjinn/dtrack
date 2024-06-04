function [status, para] = dtrack_ref_prepare(status, para)
% loads reference frame

if ~isempty(para.ref.framenr)
    status.ref.cdata = double(status.mh.readFrame(para.ref.framenr, 0));
end
if strcmp(para.ref.use, 'double_dynamic')
    if ~isempty(para.ref2.framenr)
        status.ref2.cdata = double(status.mh.readFrame(para.ref2.framenr, 0));
    end
end