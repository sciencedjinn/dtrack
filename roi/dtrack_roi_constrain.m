function fcn=dtrack_roi_constrain(para, status)

if ~isempty(para.roix)
    fcn=makeConstrainToRectFcn(['im' para.trackingtype],para.roix, para.roiy);
else
    fcn=makeConstrainToRectFcn(['im' para.trackingtype],[0 status.vidWidth], [0 status.vidHeight]);
end