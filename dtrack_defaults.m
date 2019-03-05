function [status, para, data] = dtrack_defaults(status, para, data)
% Fields that CAN be empty, MUST be empty in the defaults

%% set the search path
dtrack_paths;

%% paths
para.paths.movpath          = '';
para.paths.movname          = '';
para.paths.movdef           = ''; % (can be changed through the preferences menu)
para.paths.respath          = '';
para.paths.resname          = '';
para.paths.resdef           = ''; % (can be changed through the preferences menu)
para.paths.calibname        = [];
para.paths.roiname          = [];
para.paths.vlcpath          = ''; % (can be changed through the preferences menu)

%% parameters that are specific to each sequence
para.thermal.isthermal      = false;
para.imseq.isimseq          = false;
para.imseq.padding          = 0;
para.imseq.ext              = '';
para.imseq.from             = 0;
para.imseq.to               = 0;

%% preferences (can be changed through the preferences menu)
para.maxrecent              = 20;
para.showcurr               = true;
para.showlast               = true;
para.showlastrange          = 20;
para.autoforw               = 2;
para.gui.fig1pos            = [];
para.gui.stepsize           = 10;

para.gui.navitoolbar        = true;
para.gui.infopanel          = true;
para.gui.infopanel_points   = true;
para.gui.infopanel_markers  = true;
para.gui.infopanel_mani     = true;
para.gui.minimap            = true;

%%
para.im.roi                 = false;
para.im.manicheck           = false;   
para.im.greyscale           = false;
para.im.imadjust            = false;
para.im.imagesc             = false;
para.im.rgb1 = 1; para.im.rgb2 = 1; para.im.rgb3 = 1;
para.im.gs1 = .2989; para.im.gs2 = .5870; para.im.gs3 = .1140;

%% Tracking parameters (have to be set when the project is first created)
para.trackingtype           = 'point'; % 'point'/'line' 
para.pnr                    = 1; % how many points should be tracked; if trackingtype is 'line', pnr MUST be a multiple of 2
para.usemmread              = 0;
para.mmreadsize             = 500; %frame chunk size
para.mmreadoverlap          = 20;
para.forceaspectratio       = [];
para.saveneeded             = 0;
para.autosavethresh         = 10;

%% point marker style and colours (can be changed using the colourgui button)
para.ls.p{1}.col  = [0 0 1];    para.ls.p{1}.shape  = 'o';    para.ls.p{1}.size  = 10; para.ls.p{1}.width  = 1.5;
para.ls.p{2}.col  = [0 0 1];    para.ls.p{2}.shape  = '*';    para.ls.p{2}.size  = 5; para.ls.p{2}.width  = 1.5;
para.ls.p{3}.col  = [0 1 0];    para.ls.p{3}.shape  = 'o';    para.ls.p{3}.size  = 10; para.ls.p{3}.width  = 1.5;
para.ls.p{4}.col  = [0 1 0];    para.ls.p{4}.shape  = '*';    para.ls.p{4}.size  = 5; para.ls.p{4}.width  = 1.5;
para.ls.p{5}.col  = [1 0 1];    para.ls.p{5}.shape  = 'o';    para.ls.p{5}.size  = 10; para.ls.p{5}.width  = 1.5;
para.ls.p{6}.col  = [0 1 1];    para.ls.p{6}.shape  = 'o';    para.ls.p{6}.size  = 10; para.ls.p{6}.width  = 1.5;
para.ls.p{7}.col  = [0 0 0];    para.ls.p{7}.shape  = 'o';    para.ls.p{7}.size  = 10; para.ls.p{7}.width  = 1.5;
para.ls.p{8}.col  = [1 1 1];    para.ls.p{8}.shape  = 'o';    para.ls.p{8}.size  = 10; para.ls.p{8}.width  = 1.5;
para.ls.p{9}.col  = [.5 0 1];   para.ls.p{9}.shape  = 'o';    para.ls.p{9}.size  = 10; para.ls.p{9}.width  = 1.5;
para.ls.p{10}.col = [0 .5 1];   para.ls.p{10}.shape = 'o';    para.ls.p{10}.size = 10; para.ls.p{10}.width = 1.5;
para.ls.cp.col    = [1 1 .5];   para.ls.cp.shape    = 'o';    para.ls.cp.size    = 20; para.ls.cp.width    = 1;
para.ls.lp.col    = [.8 .8 .8]; para.ls.lp.shape    = 'none';    para.ls.lp.size    = 20; para.ls.lp.width    = 1;
para.ls.roi.col   = [.8 .8 .8]; para.ls.roi.shape   = 'none'; para.ls.roi.size   = 10; para.ls.roi.width   = 1;

%% ROI and reference frame parameters
para.roix                   = [];
para.roiy                   = [];
para.ref.framenr            = [];
para.ref.use                = false;

%% load local parameter and preferences files
if exist(fullfile(prefdir, 'dtrack_para.dtp'), 'file')
    load(fullfile(prefdir, 'dtrack_para.dtp'), '-mat')
    para = dtrack_support_compstruct(savepara, para, [], false); % non-verbose
    disp('Local default parameters loaded.');
end
if exist(fullfile(prefdir, 'dtrack_pref.dtp'), 'file')
    load(fullfile(prefdir, 'dtrack_pref.dtp'), '-mat');
    para = dtrack_support_compstruct(savepara, para, [], false); % non-verbose
    disp('Local preferences loaded.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%% create status variable
status.cpoint           = 1; % the currently tracked point
status.framenr          = 1;
status.acquire          = 1; % set to acquisition mode
h = figure; status.graycm  = colormap('gray'); close(h);
status.trackedpoints    = 1:para.pnr;
status.currentaction    = 'init';
status.lastaction       = '';
status.roi              = []; % loaded after new/open
status.ref.cdata        = []; % loaded after new/open
status.GSImage          = 0;
status.ph               = {}; % This will be extended to an empty array for each point later (first time image is called
status.cph              = [];
status.lph              = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize data structure
data.points             = [];
data.markers            = [];


