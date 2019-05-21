function [gui, status, para, data, actionFound, redraw, saveNeeded] = holo_action(gui, status, para, data, action, src)
% HOLO_ACTION is the holo module version of Dtrack's main callback function. It is called after all option in the main action function are exhausted.
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
    case 'holo_zvalue'
        status.holo.z = str2double(get(src, 'string'));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_zvalue_minus5'
        status.holo.z = status.holo.z - 5;
        set(findobj('tag', 'holo_zvalue'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_zvalue_minus1'
        status.holo.z = status.holo.z - 1;
        set(findobj('tag', 'holo_zvalue'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_zvalue_plus1'
        status.holo.z = status.holo.z + 1;
        set(findobj('tag', 'holo_zvalue'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_zvalue_plus5'
        status.holo.z = status.holo.z + 5;
        set(findobj('tag', 'holo_zvalue'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 2;
        saveNeeded = 1/2;
    case 'holo_mode'
        status.show_holo = true;
        returnfocus;
        redraw = 2;
        saveNeeded = 0;
    case 'interference_mode'
        status.show_holo = false;
        returnfocus;
        redraw = 2;
        saveNeeded = 0;
    case 'holo_findZ'        
        status.holo.z = holo_findFocus(status.diffim, para, data.points(status.framenr, status.cpoint, 1:2));
        set(findobj('tag', 'holo_zvalue'), 'string', num2str(status.holo.z));
        returnfocus;
        redraw = 1; % Could be 2, but then we have to save into currim_ori
        saveNeeded = 1/2;

    otherwise
        redraw = 0;
        saveNeeded = 0;
        actionFound = false;
end
