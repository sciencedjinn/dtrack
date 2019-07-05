function [gui, status, para, data, actionFound, redraw, saveNeeded, autoForward] = holo_action(gui, status, para, data, action, src)
% HOLO_ACTION is the holo module version of Dtrack's main callback function. It is called after all options in the main action function are exhausted.
% See dtrack_action for more information.

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Find the right action %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
autoForward = false;

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
        
%% Z Navigation
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
        
%% Modes
    case {'camera_mode', 'holo_mode', 'interference_mode', 'holo_mag_mode'} %status.show_holo
        status.holo.image_mode = action(1:end-5);
        dtrack_guivisibility(gui, para, status);
        returnfocus;
        redraw = 2;
        saveNeeded = 0;
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
    case 'holo_link'
        status.holo.link = get(src, 'Value');
        holo_guivisibility(gui, status, para, data)
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    
%% Analysis functions
        
    case 'holo_plot_speed_2d'
        figure(274); clf; hold on;
        for p = 1:para.pnr
            sel = data.points(:, p, 3)>0 & data.points(:, p, 3)~=43; % select all successfully tracked frames
            xy = squeeze(data.points(sel, p, 1:2));
            f = find(sel); % selected frame numbers
            t = (f-1)/status.FrameRate; % time in seconds for each selected frame
            speed = sqrt(sum(diff(xy, 1).^2, 2))./diff(t(:)); % pixels/s
            speed = speed*para.holo.pix_um;        % um/s
            plot(f(2:end), speed, '.-', 'color', para.ls.p{p}.col)
        end
        xlabel('Frame number')
        ylabel('2D Movement speed (mm/s)');
        legend(num2str((1:para.pnr)'))
        
        redraw = 0; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 0;
        
    case 'holo_plot_speed_3d'
        figure(275); clf; hold on;
        for p = 1:para.pnr
            sel = data.points(:, p, 3)>0 & data.points(:, p, 3)~=43 & data.points(:, p, 4)>0; % select all successfully tracked and z-tracked frames
            xyz = squeeze(data.points(sel, p, [1:2 4]));
            xyz(:, 1:2) = xyz(:, 1:2)*para.holo.pix_um; % um
            f = find(sel); % selected frame numbers
            t = (f-1)/status.FrameRate; % time in seconds for each selected frame
            speed = sqrt(sum(diff(xyz, 1).^2, 2))./diff(t(:)); % um/s
            plot(f(2:end), speed, '.-', 'color', para.ls.p{p}.col)
        end
        xlabel('Frame number')
        ylabel('3D Movement speed (mm/s)');
        legend(num2str((1:para.pnr)'))
        
        redraw = 0; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 0;
            
    case 'holo_plot_track_2d'
        figure(276); clf; hold on;
        for p = 1:para.pnr
            sel = data.points(:, p, 3)>0 & data.points(:, p, 3)~=43; % select all successfully tracked frames
            xy = squeeze(data.points(sel, p, 1:2))*para.holo.pix_um;
            f{p} = find(sel);
            line(xy(:, 1), xy(:, 2), 'marker', '.', 'linestyle', '-', 'color', para.ls.p{p}.col, 'tag', num2str(p))
        end
        xlabel('x (mm)');
        ylabel('y (mm)');
        set(gca, 'YDir', 'reverse');
        axis equal;
        legend(num2str((1:para.pnr)'))
        
        dcm_obj = datacursormode(276);
        set(dcm_obj, 'UpdateFcn',{@plot2d_updatefcn, f})
        
        redraw = 0; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 0;
        
    case 'holo_plot_track_3d'
        figure(277); clf; hold on;
        for p = 1:para.pnr
            sel = data.points(:, p, 3)>0 & data.points(:, p, 3)~=43; % select all successfully tracked frames
            xyz = squeeze(data.points(sel, p, [1:2 4]));
            xyz(:, 1:2) = xyz(:, 1:2)*para.holo.pix_um; % um
            f{p} = find(sel);
            line(xyz(:, 1), xyz(:, 2), xyz(:, 3), 'marker', '.', 'linestyle', '-', 'color', para.ls.p{p}.col, 'tag', num2str(p))
        end
        xlabel('x (mm)');
        ylabel('y (mm)');
        zlabel('z (mm)');
        set(gca, 'YDir', 'reverse');
        legend(num2str((1:para.pnr)'))
        axis equal;
        
        dcm_obj = datacursormode(277);
        set(dcm_obj, 'UpdateFcn',{@plot3d_updatefcn, f})

        redraw = 0; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 0;
        
%%
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
        autopara.findMethod = 'darkest'; % 
        autopara.greythr = 0.5;
        autopara.areathr = 3;
        autopara.roimask = [];
        
        im = double(readframe(status.mh, status.framenr, para, status));
        ref1 = double(readframe(status.mh, status.framenr-para.ref.frameDiff, para, status));
        ref2 = double(readframe(status.mh, status.framenr+para.ref.frameDiff, para, status));

        [res, diag] = holo_autotrack_detect(im, ref1, ref2, autopara, para.holo, data.points(status.framenr-para.ref.frameDiff, status.cpoint, :), 'lastframe');
        if isempty(res.message)
            diag.fnr = status.framenr;
            diag.pnr = status.cpoint;
            holo_autotrack_plotdiag(diag, gui.diag.ah);
    
            data.points(status.framenr, status.cpoint, 1:2) = res.centroid; % assign this found position to the current point
            data.points(status.framenr, status.cpoint, 3) = 42; % assign this found position to the current point
        else 
            errordlg(res.message);
        end
        returnfocus;
        autoForward = true;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;
    
    case 'holo_autoXY'
        % Autotracking using background subtraction
        [success, autopara] = holo_autotrack_select(status, para, data);
        if success
            [gui, status, para, data] = holo_autotrack_main(gui, status, para, data, autopara);
        end
        redraw = 1;
        saveNeeded = 1;
        
    case 'holo_autoXYcontinue'
        % Autotracking using background subtraction
        [success, autopara] = holo_autotrack_select(status, para, data, true); % just loads last session's data
        if success
            [gui, status, para, data] = holo_autotrack_main(gui, status, para, data, autopara);
        end
        redraw = 1;
        saveNeeded = 1;
        
     case 'holo_autoZ'
        % TODO: ask for parameters
        [gui, status, para, data] = holo_autoZ(gui, status, para, data); 
        [gui, status, para, data] = dtrack_action(gui, status, para, data, 'redraw');
        returnfocus;
        redraw = 1;
        saveNeeded = 1;
        
    
    case 'holo_help_gettingstarted'
        open(fullfile(pwd, 'documentation', 'Getting Started With HOLO.pdf'));
        redraw = 0;
        saveNeeded = 0;
        
    otherwise
        redraw = 0;
        saveNeeded = 0;
        actionFound = false;
end
end % main

function txt = plot2d_updatefcn(~, event_obj, f)
    % Customizes text of data tips
    pos = get(event_obj, 'Position');
    I = get(event_obj, 'DataIndex');
    p = str2double(get(get(event_obj, 'Target'), 'tag'));
    txt = {['X: ', num2str(pos(1))],...
           ['Y: ', num2str(pos(2))],...
           ['point: ', num2str(p)],...
           ['frame: ', num2str(f{p}(I))]};
end

function txt = plot3d_updatefcn(~, event_obj, f)
    % Customizes text of data tips
    pos = get(event_obj, 'Position');
    I = get(event_obj, 'DataIndex');
    p = str2double(get(get(event_obj, 'Target'), 'tag'));
    txt = {['X: ', num2str(pos(1))],...
           ['Y: ', num2str(pos(2))],...
           ['Z: ', num2str(pos(3))],...
           ['point: ', num2str(p)],...
           ['frame: ', num2str(f{p}(I))]};
end