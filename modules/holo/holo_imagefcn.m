function [status, para, data] = holo_imagefcn(status, para, data)

temp = holo_recon(double(status.currim));
status.currim = temp.*conj(temp);