function [status, para, data] = holo_defaults(status, para, data)
% HOLO_DEFAULTS Loads the default parameters for the HOLO module

disp('Loading holo module...');

status.diffim = [];

para.im.manicheck           = true;   
para.im.greyscale           = true;
para.im.imadjust            = false;
para.im.imagesc             = true;
para.im.gs1 = .2989; para.im.gs2 = .5870; para.im.gs3 = .1140;

para.ref.use                = 'dynamic'; % can be 'none'/'static'/'dynamic'
para.ref.frameDiff          = 10; % when set to 0, para.gui.stepsize will be used instead
para.forceaspectratio       = [];%[1 1];

status.holo.z = 120;
status.show_holo = false;

para.holo.mag        = 2;
para.holo.lambda_nm  = 780; 
para.holo.pix_um     = 0.0052*5.15/para.holo.mag; % 0.0052*5.15 % 0.0052*4.5/4

para.holo.zRange = [105 135];   % min and max acceptable z position (mm)
para.holo.stepRange = [2 0.05]; % mm step size in z [coarse fine]
para.holo.boxSize = 128*para.holo.mag; % box size to draw around point for z-finding

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HOLO theme
para.theme.name = 'HOLO';
