function [status, para, data] = holo_defaults(status, para, data)
% HOLO_DEFAULTS Loads the default parameters for the HOLO module

disp('Loading holo module...');


para.im.manicheck           = true;   
para.im.greyscale           = true;
para.im.imadjust            = false;
para.im.imagesc             = true;
para.im.gs1 = .2989; para.im.gs2 = .5870; para.im.gs3 = .1140;

para.ref.use                = 'dynamic'; % can be 'none'/'static'/'dynamic'
para.ref.frameDiff          = 10; % when set to 0, para.gui.stepsize will be used instead

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HOLO theme
para.theme.name = 'HOLO';
