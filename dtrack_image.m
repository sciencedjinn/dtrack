function [status, gui] = dtrack_image(gui, status, para, data, redraw)

% redraw 1: new frame (this is the default while navigating -> should be fast!)
% redraw 2: same frame with changes
% redraw 3: new frame plus axis reset (e.g. after bad zoom or gui reset)
% redraw 11: points only
% redraw 12: only recolor points
% redraw 14: only current point, will also use uistack to bring impoints/lines to front
% redraw 20: markers only
% redraw 30: load only, don't display (gui and data can be empty)
% redraw 31: load only main image, not references; don't display (gui and data can be empty)

%fprintf('     Image function with redraw mode: %d.\n', redraw);

%% set frame number and frame time displays
% calculate framenr
if para.imseq.isimseq
    status.framenr = min([max([status.framenr para.imseq.from]) status.nFrames]); % restrict range of framenrs, in case it was set out of bounds
else
    status.framenr = min([max([status.framenr 1]) status.nFrames]); % restrict range of framenrs, in case it was set out of bounds
end
if redraw==1 || redraw==3
    % set framenr display
    set(findobj('tag', 'framenr'), 'string', ['frame ', num2str(status.framenr), '/', num2str(status.nFrames)]);
    
    % set frametime display
    if para.thermal.isthermal
        timeNumber = status.mh.ts(status.framenr) - status.mh.ts(1);
    else
        timeNumber = status.framenr / status.FrameRate; % time in seconds
    end
    set(findobj('tag', 'frametime'), 'string', datestr(timeNumber/24/3600,'HH:MM:SS.FFF'));
end

%% Module display updates
[~, status, para, data, redraw] = dtrack_support_evalModules('_image1', [], status, para, data, redraw); % redraw might need to be changed here, e.g. for module holo: when z-value has changed, frame needs to be redrawn

%% load new image
if ismember(redraw, [1 3 30 31]) % new frame actions
    % read new frame (this takes more than 95% of the whole function time)
    [status.currim_ori, status.mh, status.timestamp] = readframe(status.mh, status.framenr, para, status); % this timestamp seems to start at 0, as well. So it's no use.
    
    % deinterlace
   if ~isempty(gui) && strcmp(get(gui.controls.navi.entries.deinterlace, 'State'), 'on') % TODO: This should get an entry in para, which should be remembered between sessions
       hfm = repmat(rot90([0, 1]), status.vidHeight/2, status.vidWidth);
       output = cat(3, hfm, hfm, hfm);
       status.currim_ori = imresize(reshape(status.currim_ori(output>0), [], status.vidWidth, 3), [status.vidHeight status.vidWidth]);
   end
end

%% image manipulation
if ismember(redraw, [1 2 3 30])
    if ~para.thermal.isthermal
        % now stuff for non-thermal images
        status.currim = status.currim_ori; % reset to original, unaltered image
        
        % subtract reference frame
        switch para.ref.use
            case 'static'
                status.currim = uint8(125+0.5*(double(status.currim)-status.ref.cdata));
            case 'dynamic'
                if para.ref.frameDiff > 0
                    % frame diff was set in parameter file, use this
                    para.ref.framenr = max([1 status.framenr - para.ref.frameDiff]);
                else
                    % frame diff was not set in parameter file, use the step size
                    para.ref.framenr = max([1 status.framenr - para.gui.stepsize]);
                end
                [status, para] = dtrack_ref_prepare(status, para); % load new ref image
                status.currim = - double(status.currim) + double(status.ref.cdata); %%TODO uint8 and 125+0.5*I %%FIXME
%                 maxval = max(abs(status.currim(:)));
%                 status.currim = (255*(0.5 + status.currim / maxval / 2));
            case 'double_dynamic'
                if para.ref.frameDiff > 0
                    % frame diff was set in parameter file, use this
                    para.ref.framenr = max([1 status.framenr - para.ref.frameDiff]);
                    para.ref2.framenr = min([status.framenr + para.ref.frameDiff status.nFrames]);
                else
                    % frame diff was not set in parameter file, use the step size
                    para.ref.framenr = max([1 status.framenr - para.gui.stepsize]);
                    para.ref2.framenr = min([status.framenr + para.gui.stepsize status.nFrames]);
                end
                [status, para] = dtrack_ref_prepare(status, para); % load new ref image
                status.currim = - double(status.currim) + 0.5*double(status.ref.cdata) + 0.5*double(status.ref2.cdata);
        end
        
        if para.im.manicheck
            if para.im.greyscale
                if ismatrix(status.currim)
                    % already a greyscale image, do nothing
                else
                    status.currim = para.im.gs1 * status.currim(:, :, 1) + para.im.gs2 * status.currim(:, :, 2) + para.im.gs3 * status.currim(:, :, 3);
                end
                if para.im.imadjust
                    status.currim = imadjust(status.currim);
                end
                colormap(status.graycm);
            else
                if ismatrix(status.currim) 
                    % already a greyscale image, this shouldnt even happen
                else
                    status.currim = cat(3, para.im.rgb1*status.currim(:,:,1), para.im.rgb2*status.currim(:,:,2), para.im.rgb3*status.currim(:,:,3));
                    colormap('default');
                end
            end
        end
    end
end

%% Module image manipulation
if ismember(redraw, [1 2 3 30])
    [~, status, para, data] = dtrack_support_evalModules('_imagefcn', [], status, para, data);
end

if ismember(redraw, [30 31]) % load only, don't display
    return;
end

%% display image
if ismember(redraw, [1 2 3])
    % before drawing
    status.zoomaxis = axis(gui.ax1); % save zoom before redrawing image

    if para.thermal.isthermal
        status.currim = status.currim_ori - 273; % reset to original, unaltered image
        gui.im1 = [];
        imagesc(status.currim, 'parent', gui.ax1, 'buttondownfcn', status.maincb);
        set(gui.ax1, 'yDir', 'normal');
        colormap('default');
        if verLessThan('matlab', '8.4.0')
            gui.cb = colorbar('peer', gui.ax1, 'units', 'normalized', 'position', [.95 .4 .01 .2]); % execute code for R2014a or earlier
        else
            gui.cb = colorbar(gui.ax1, 'units', 'normalized', 'position', [.95 .4 .01 .2]); % execute code for R2014b or later
        end        
    else
        if para.im.imagesc && para.im.greyscale
            gui.im1 = []; imagesc(status.currim, 'parent', gui.ax1, 'buttondownfcn', status.maincb);
        else
            if isempty(gui.im1)
                gui.im1 = image(status.currim, 'parent', gui.ax1, 'buttondownfcn', status.maincb);
            else
                set(gui.im1, 'cdata', status.currim);
            end
        end
    end
end

%% draw ROI, region of interest
if ismember(redraw, [1 2 3])
    status.roih = [];
    delete(findobj('tag', 'roiline'));
    if para.im.roi && ~isempty(status.roi) % status.roi might be empty after reloading if the roi file has not been found
        switch status.roi(1, 1)
            case 0  % 0 indicates polygon vertices
                status.roih = line(status.roi(2:end, 1), status.roi(2:end, 2), 'parent', gui.ax1, 'tag', 'roiline');    
            case 1
                status.roih = rectangle('parent', gui.ax1, 'Position', status.roi(2:end, 1), 'Curvature', [1 1], 'tag', 'roiline');   
            otherwise % old roi file
                disp('No ROI type indicator found, assuming old ROI file.');
                status.roih = line(status.roi(:, 1), status.roi(:, 2), 'tag', 'roiline');   
        end
    end
end

%% set gui marker values
if ismember(redraw, [1 2 3 20])
    m_dat = data.markers(status.framenr).m;
    m_but = findobj('-regexp', 'tag', 'marker_[a-z]');
    for i = 1:length(m_but)
        m_name = get(m_but(i), 'tag');
        set(m_but(i), 'value', any(ismember(m_name(end), m_dat)));
    end
    others='';
    for i=1:length(m_dat)
        if ~ismember(m_dat{i}, {'s', 'e', 'd', 'r', 'p'})
            others = [others m_dat{i}];
        end
    end    
    set(findobj('tag', 'marker_other'), 'string', others);
end

%% draw or move current point/line
if ismember(redraw, [1 2 3 11 14])
    if para.showcurr
        switch para.trackingtype
            case 'point'
                %first, determine whether this point has been tracked in this frame
                if data.points(status.framenr, status.cpoint, 3)
                    x = data.points(status.framenr, status.cpoint, 1); %load data
                    y = data.points(status.framenr, status.cpoint, 2); %load data
                    vis = 'on';
                else
                    x = -10; y = -10; vis = 'off';
                end

                %second, determine whether you have to draw the point (if ph is empty; only on first frame after loading) 
                if isempty(status.cph) || ~ishghandle(status.cph)    
                    status.cph = line(x, y, 'parent', gui.ax1, 'tag', 'cpoint');  
                else
                    set(status.cph, 'xdata', x, 'ydata', y);
                end
                set(status.cph, 'visible', vis); %turning a 'visible on' back into 'visible on' adds almost no time
            case 'line'
                %first, determine whether this point has been tracked in this frame
                i = status.cpoint; 
                if data.points(status.framenr, i, 3)
                    x1 = data.points(status.framenr, i, 1); %load data
                    y1 = data.points(status.framenr, i, 2); %load data
                    x2 = data.points(status.framenr, i+1, 1); %load data
                    y2 = data.points(status.framenr, i+1, 2); %load data
                    vis = 'on';
                else
                    x1=-10; y1=-10; x2=-10; y2=-10; vis='off';
                end
                
                %second, determine whether you have to draw the point (if ph is empty; only on first frame after loading)
                if isempty(status.cph)  || ~ishghandle(status.cph)   
                    status.cph=line([x1 x2], [y1 y2], 'parent', gui.ax1, 'tag', 'cline');  
                else
                    set(status.cph, 'xdata', [x1 x2], 'ydata', [y1 y2]);
                end
                set(status.cph, 'visible', vis); %turning a 'visible on' back into 'visible on' adds almost no time
        end
    else
        try %FIXME
            set(status.cph, 'visible', 'off');
        end
    end
    
    if redraw==14
        uistack(gco, 'top');
    end
end

%% draw or move last point/line
if ismember(redraw, [1 2 3 11])
    if para.showlast
        switch para.trackingtype
            case 'point'
                % first, determine whether this point has been tracked in this frame
                range = max([1 status.framenr-para.showlastrange]):max([1 status.framenr-1]);
                sel = find(data.points(range, status.cpoint, 3)>0, 1, 'last');
                if ~isempty(sel)
                    x = data.points(range(1)+sel-1, status.cpoint, 1);
                    y = data.points(range(1)+sel-1, status.cpoint, 2);
                    vis = 'on';
                else
                    x = -10; y = -10; vis = 'off';
                end

                % second, determine whether you have to draw the point (if ph is empty; only on first frame after loading) 
                if isempty(status.lph) || ~ishghandle(status.lph)
                    status.lph=line(x, y, 'parent', gui.ax1, 'tag', 'lpoint');  
                else
                    set(status.lph, 'xdata', x, 'ydata', y);
                end
                set(status.lph, 'visible', vis); % turning a 'visible on' back into 'visible on' adds almost no time
            case 'line'
                % first, determine whether this point has been tracked in this frame
                i = status.cpoint;
                range = max([1 status.framenr-para.showlastrange]):max([1 status.framenr-1]);
                sel = find(data.points(range, i, 3)>0, 1, 'last');
                if ~isempty(sel)
                    x1 = data.points(range(1)+sel-1, i, 1); % load data
                    y1 = data.points(range(1)+sel-1, i, 2); % load data
                    x2 = data.points(range(1)+sel-1, i+1, 1); % load data
                    y2 = data.points(range(1)+sel-1, i+1, 2); % load data
                    vis = 'on';
                else
                    x1 = -10; y1 = -10; x2 = -10; y2 = -10; vis='off';
                end
                
                % second, determine whether you have to draw the point (if ph is empty; only on first frame after loading)
                if isempty(status.lph) || ~ishghandle(status.lph)
                    status.lph = line([x1 x2], [y1 y2], 'parent', gui.ax1, 'tag', 'lline');  
                else
                    set(status.lph, 'xdata', [x1 x2], 'ydata', [y1 y2]);
                end
                set(status.lph, 'visible', vis); % turning a 'visible on' back into 'visible on' adds almost no time
        end
    else
        try % FIXME
            set(status.lph, 'visible', 'off');
        end
    end
end

%% draw or move points/lines
if ismember(redraw, [1 2 3 11])
    % status.ph is initialised to empty arrays.
    % later, all points are always drawn. They are just moved to -10/-10 when there is no tracked point
    switch para.trackingtype
        case 'point'
            for i = 1:para.pnr
                %first, determine whether this point has been tracked in this frame
                if data.points(status.framenr, i, 3)
                    x = data.points(status.framenr, i, 1); %load data
                    y = data.points(status.framenr, i, 2); %load data
                    vis = 'on';
                else
                    x = -10; y = -10; vis = 'off';
                end
                
                %second, determine whether you have to draw the point (if ph is empty; only on first frame after loading oder after gui reload) 
                if length(status.ph)<i || isempty(status.ph{i}) || ~isvalid(status.ph{i}) %this has to be isobject, not ishghandle, because it is an impoint object
                    status.ph{i} = impoint(gui.ax1, x, y); %, 'PositionConstraintFcn', dtrack_roi_constrain(para, status)); %This function is a bottleneck
                    set(status.ph{i}, 'tag', ['impoint' num2str(i)]);
                else
                    removeNewPositionCallback(status.ph{i}, status.pcb{i}); %add callbacks for position change
                    setPosition(status.ph{i}, round(x), round(y)); %% FOR SOME REASON, this does not accept fractional numbers
                end
                status.pcb{i} = addNewPositionCallback(status.ph{i}, status.movecb); %add callbacks for position change
                set(status.ph{i}, 'visible', vis); %turning a 'visible on' back into 'visible on' adds almost no time
            end
            
        case 'line' %%same as for point basically
            for i=1:2:para.pnr
                %first, determine whether this line has been tracked in this frame
                if data.points(status.framenr, i, 3)
                    x1 = data.points(status.framenr, i, 1); %load data
                    y1 = data.points(status.framenr, i, 2); %load data
                    x2 = data.points(status.framenr, i+1, 1); %load data
                    y2 = data.points(status.framenr, i+1, 2); %load data
                    vis = 'on';
                else
                    x1 = -10; y1 = -10; x2 = -10; y2 = -10; vis = 'off';
                end
                %second, determine whether you have to draw the line (if ph is empty; only on first frame after loading) 
                if length(status.ph)<i || isempty(status.ph{i}) || ~isvalid(status.ph{i})
                    status.ph{i} = imline(gui.ax1, [x1 x2], [y1 y2]);%, 'PositionConstraintFcn', dtrack_roi_constrain(para, status)); 
                    set(status.ph{i}, 'tag', ['imline' num2str((i+1)/2)]);
                else
                    removeNewPositionCallback(status.ph{i}, status.pcb{i}); %add callbacks for position change
                    setPosition(status.ph{i}, [x1 x2], [y1 y2]);
                end     
                status.pcb{i} = addNewPositionCallback(status.ph{i}, status.movecb); %add callbacks for positionchange
                set(status.ph{i}, 'visible', vis); %turning a 'visible on' back into 'visible on' adds almost no time
            end
    end
end

%% ROI colour
if ismember(redraw, [1 2 3 12])
    if isfield(status, 'roih') && ~isempty(status.roih)
        switch status.roi(1, 1)
            case 0  %0 indicates polygon vertices
                set(status.roih, 'marker', para.ls.roi.shape, 'markerfacecolor', 'none', 'color', para.ls.roi.col, 'markersize', para.ls.roi.size, 'linewidth', para.ls.roi.width);
            case 1  %1 indicates ellipse
                set(status.roih, 'edgecolor', para.ls.roi.col, 'linewidth', para.ls.roi.width);
        end
    end
end

%% current point/line colour
if ismember(redraw, [1 2 3 11 12]) && para.showcurr
    if ~isempty(status.cph) 
        if strcmp(para.trackingtype, 'point')
            set(status.cph, 'marker', para.ls.p{status.cpoint}.shape, 'markerfacecolor', 'none', 'color', para.ls.cp.col, 'markersize', para.ls.p{status.cpoint}.size, 'linewidth', 2*para.ls.p{status.cpoint}.width);
        else
            cp = status.cpoint;
            set(status.cph, 'marker', para.ls.p{cp+1}.shape, 'markerfacecolor', 'none', 'color', para.ls.cp.col, 'markersize', para.ls.p{cp+1}.size, 'linewidth', 2*para.ls.p{cp+1}.width);
        end
    end
end

%% last point/line colour
if ismember(redraw, [1 2 3 11 12]) && para.showlast
    if ~isempty(status.lph)
        set(status.lph, 'marker', para.ls.lp.shape, 'markerfacecolor', 'none', 'color', para.ls.lp.col, 'markersize', para.ls.lp.size, 'linewidth', para.ls.lp.width);
    end
end

%% point and line colour
if ismember(redraw, [1 2 3 11 12])
    switch para.trackingtype
        case 'point'
            for i = 1:para.pnr
                if length(status.ph)>=i && isobject(status.ph{i})
                    h2 = get(status.ph{i}, 'children'); % Children has 2 objects: cross, circle
                    set(h2(1:2), 'marker', para.ls.p{i}.shape, 'markerfacecolor', 'none', 'color', para.ls.p{i}.col, 'markersize', para.ls.p{i}.size, 'linewidth', para.ls.p{i}.width);
                end
            end
        case 'line'
            for i = 1:2:para.pnr
                if length(status.ph)>=i && isobject(status.ph{i})
                    h2 = get(status.ph{i}, 'children'); % Children has 4 objects: point 2, point 1, coloured line, thick back line (note inverse order of points!)
                    % each imline has its own context menu, but all 4 points have
                    % the same one, even after moving/dragging
                    if ~isempty(h2)
                        set(h2(2), 'marker', para.ls.p{i}.shape, 'markerfacecolor', 'none', 'color', para.ls.p{i}.col, 'markersize', para.ls.p{i}.size, 'linewidth', para.ls.p{i}.width);
                        set(h2(1), 'marker', para.ls.p{i+1}.shape, 'markerfacecolor', 'none', 'color', para.ls.p{i+1}.col, 'markersize', para.ls.p{i+1}.size, 'linewidth', para.ls.p{i+1}.width);
                        set(h2(3), 'color', para.ls.p{i}.col, 'linewidth', para.ls.p{i}.width);
                    end
                end
            end
    end
end

%% re-set zoom and aspect ratio
if ismember(redraw, [1 2 3])
    if ismember(redraw, [1 2])
        % after drawing
        axis(gui.ax1, status.zoomaxis); % re-set zoom
    end
    if ~isempty(para.forceaspectratio)
        set(gui.ax1, 'dataaspectratiomode', [para.forceaspectratio 1]);
    else
        set(gui.ax1, 'dataaspectratio', [1 1 1]);
    end
    
    
    set(gui.ax1, 'visible', 'off');
end

%% draw minimap
if ismember(redraw, [1 2 3 11 12])
    if para.gui.minimap
        if para.thermal.isthermal
            dtrack_ana_plottemp(gui.minimap.axes, data, status, para);
        else
            dtrack_ana_plotpaths(gui.minimap.axes, data, status, para);
        end
    end
end
        
%% Final module contributions
[~, status] = dtrack_support_evalModules('_image_final', gui, status, para, data, redraw); % redraw might need to be changed here, e.g. for module holo: when z-value has changed, frame needs to be redrawn

        

