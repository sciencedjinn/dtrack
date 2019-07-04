function [gui, status, para, data, actionFound, redraw, saveNeeded] = holo_action(gui, status, para, data, action, src)
% HOLO_ACTION is the holo module version of Dtrack's main callback function. It is called after all options in the main action function are exhausted.
% See dtrack_action for more information.

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Find the right action %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

actionFound = true;
switch(action)
    %% 
    case 'info_holo'
        % set to GS, 0/1/0
        para.im.greyscale = 1; 
        para.im.imagesc = 1; 
        para.im.imadjust = 0;
        para.im.gs1 = 0; 
        para.im.gs2 = 1; 
        para.im.gs3 = 0;
        dtrack_guivisibility(gui, para, status);
        returnfocus; 
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_zvalue_disp'
        status.holo.z = str2double(get(src, 'string'));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case {'holo_zvalue_minus5', 'holo_zvalue_minus1', 'holo_zvalue_plus1', 'holo_zvalue_plus5'}
        switch(action)
            case 'holo_zvalue_minus5'
                status.holo.z = status.holo.z - 5;
            case 'holo_zvalue_minus1'
                status.holo.z = status.holo.z - 1;
            case 'holo_zvalue_plus1'
                status.holo.z = status.holo.z + 1;
            case 'holo_zvalue_plus5'
                status.holo.z = status.holo.z + 5;
        end
        set(findobj('tag', 'holo_zvalue_disp'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case {'camera_mode', 'holo_mode', 'interference_mode', 'holo_mag_mode'} %status.show_holo
        status.holo.image_mode = action(1:end-5);
        dtrack_guivisibility(gui, para, status);
        returnfocus;
        redraw = 2;
        saveNeeded = 0;
    case 'holo_findZ'
        bestZ = holo_findFocus(status.diffim, para, data.points(status.framenr, status.cpoint, 1:2)); % find the best z-position for current point
        data.points(status.framenr, status.cpoint, 4) = bestZ; % assign this found position to the current point
        status.holo.z = bestZ; % view this new position
        set(findobj('tag', 'holo_zvalue_disp'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    case 'holo_findZ_local'
        bestZ = holo_findFocus(status.diffim, para, data.points(status.framenr, status.cpoint, 1:2), status.holo.z); % find the best z-position for current point
        data.points(status.framenr, status.cpoint, 4) = bestZ; % assign this found position to the current point
        status.holo.z = bestZ; % view this new position
        set(findobj('tag', 'holo_zvalue_disp'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    case 'holo_findXY'
        autopara = [];
        autopara.refMethod = 'double';
        autopara.findMethod = 'brightest'; % 
        autopara.greythr = 0.5;
        autopara.areathr = 5;
        autopara.roimask = [];

        gui.prev.fig   = figure(2973); clf;
        gui.prev.ph(1) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 .5 .5 .5]);
        gui.prev.ph(2) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 .5 .5 .5]);
        gui.prev.ph(3) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [0 0 .5 .5]);
        gui.prev.ph(4) = uipanel('parent', gui.prev.fig, 'units', 'normalized', 'position', [.5 0 .5 .5]);

        gui.prev.ah(1) = axes('parent', gui.prev.ph(1), 'units', 'normalized', 'position', [0 0 1 1]);
        gui.prev.ah(2) = axes('parent', gui.prev.ph(2), 'units', 'normalized', 'position', [0 0 1 1]);
        gui.prev.ah(3) = axes('parent', gui.prev.ph(3), 'units', 'normalized', 'position', [0 0 1 1]);
        gui.prev.ah(4) = axes('parent', gui.prev.ph(4), 'units', 'normalized', 'position', [0 0 1 1]);
        
        im = double(readframe(status.mh, status.framenr, para, status));
        ref1 = double(readframe(status.mh, status.framenr-10, para, status));
        ref2 = double(readframe(status.mh, status.framenr+10, para, status));

        [res, diag] = holo_autotrack_detect(im, ref1, ref2, autopara, para.holo, data.points(status.framenr-10, status.cpoint, :), 'lastframe');
        holo_autotrack_plotdiag(diag, gui.prev.ah);
    
        data.points(status.framenr, status.cpoint, 1:2) = res.centroid; % assign this found position to the current point
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    case 'holo_link'
        status.holo.link = get(src, 'Value');
        holo_guivisibility(gui, status, para, data)
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    case 'holo_ref_single'
        para.ref.use = 'dynamic';
        dtrack_guivisibility(gui, para, status)
        returnfocus;
        redraw = 1; 
        saveNeeded = 1/2;
    case 'holo_ref_double'
        para.ref.use = 'double_dynamic';
        dtrack_guivisibility(gui, para, status)
        returnfocus;
        redraw = 1; 
        saveNeeded = 1/2;
    case 'holo_mean_z_mode'
        status.holo.z_mode = 'mean';
        holo_guivisibility(gui, status, para, data)
        returnfocus;
        redraw = 1; 
        saveNeeded = 1/2;
    case 'holo_single_z_mode'
        status.holo.z_mode = 'single';
        holo_guivisibility(gui, status, para, data)
        returnfocus;
        redraw = 1; 
        saveNeeded = 1/2;
    case 'holo_autoXY'
        returnfocus;
        redraw = 1;
        saveNeeded = 0;
    case 'holo_autoZ'
        % ask for parameters
%         [success, savepara] = dtrack_tools_imageseq(status, para);
%         if success
            [gui, status, para, data] = holo_autoZ(gui, status, para, data); 
            [gui, status, para, data] = dtrack_action(gui, status, para, data, 'redraw');
%         end
        returnfocus;
        redraw = 1;
        saveNeeded = 0;
    otherwise
        redraw = 0;
        saveNeeded = 0;
        actionFound = false;
end
