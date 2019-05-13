function [status, para] = dtrack_ref_prepare(status, para)
% loads reference frame

if ~isempty(para.ref.framenr)
    status.ref.cdata = double(readframe(status.mh, para.ref.framenr, para, status, 1));
end