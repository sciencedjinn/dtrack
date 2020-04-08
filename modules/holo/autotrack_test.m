% test script to optimise holo_autotrack_detect

if 1
    im = double(imread('G:\data\2019 Holography test video\190409-1 5 cells - stimulus_0501.tif'));
    ref1 = double(imread('G:\data\2019 Holography test video\190409-1 5 cells - stimulus_0491.tif'));
    ref2 = double(imread('G:\data\2019 Holography test video\190409-1 5 cells - stimulus_0511.tif'));

    im = im(:, :, 1);
    ref1 = ref1(:, :, 1);
    ref2 = ref2(:, :, 1);
    
    autopara = [];
    autopara.refMethod = 'double';
    autopara.findMethod = 'Middle of 3';%'2nd nearest';%'Max of 3'; % 
    autopara.greythr = 0.5;
    autopara.areathr = 2;
    autopara.roimask = [];

    holopara.pix_um = 0.0134;
    holopara.lambda_nm = 780;
    holopara.mag = 2;
    holopara.reconBoxSize_unmag = 64;
    holopara.reconBoxSize = holopara.holo.reconBoxSize_unmag * holopara.holo.mag;
    holopara.searchBoxSize = 1/4;
    holopara.zRange = [105 135];
    holopara.stepRange = [2 0.05];

    lastpoint = [672.9312 129.8621 1 102.15];
    lastpoint = [650 139.8621 1 102.15];

    gui.prev.fig   = figure(2973); clf;
    gui.prev.ph(1) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 .5 .5 .5]);
    gui.prev.ph(2) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 .5 .5 .5]);
    gui.prev.ph(3) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 0 .5 .5]);
    gui.prev.ph(4) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 0 .5 .5]);

    gui.prev.ah(1) = axes('parent', gui.prev.ph(1), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(2) = axes('parent', gui.prev.ph(2), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(3) = axes('parent', gui.prev.ph(3), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prev.ah(4) = axes('parent', gui.prev.ph(4), 'units', 'normalized', 'position', [0 0 1 1]);
end


% [outcentroid, outarea, outimages, allregions] = holo_autotrack_detect(im, ref1, ref2, autopara, holopara, lastpoint)
[res, diag] = holo_autotrack_detect(im, ref1, ref2, autopara, holopara, lastpoint, 'prediction');
diag.fnr = 501;
diag.pnr = 1;

holo_autotrack_plotdiag(diag, gui.prev.ah);
% axis(gui.prev.ah, [573 773 80 180]);