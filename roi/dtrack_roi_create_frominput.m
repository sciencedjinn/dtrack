function [outpos, outfilename, success]=dtrack_roi_create_frominput(status, defsavepath)
% lets the user create a region of interest interactively
% See also: dtrack_roi_finddefault, dtrack_fileio_openroi, dtrack_fileio_loadroi

%% init parameters
gui=[];
outpos=[];
roih=[];
success=0;
outfilename=0;
type=[];

%create
sub_creategui;
sub_drawimage;

%% set figure to modal late after you know there are no errors
set(gui.fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(gui.minifig);
    delete(gui.minifig);
    delete(gui.fig);
catch anyerror
    delete(gui.fig);
    delete(gui.minifig);        %delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%%%%%%%%%%%%%%%%%%%
%% Nested functions for callbacks, writing/drawing and panel creation
function sub_OK(varargin)
    % OK: ok button callback, returns the changed para and finishes execution
    if ~isempty(roih)
        switch type
            case 'imrect'
                % getPosition(h) returns the current position of the rectangle h. The returned position, pos, is a 1-by-4 array [xmin ymin width height].
                pos=getPosition(roih);
                outpos=[0 0;pos(1) pos(2) ; pos(1) pos(2)+pos(4) ; pos(1)+pos(3) pos(2)+pos(4) ; pos(1)+pos(3) pos(2) ; pos(1) pos(2)]; %0 indicates polygon vertices
            case 'imellipse'
                %getVertices(h) returns a set of vertices which lie along the perimeter of the ellipse h. vert is a N-by-2 array
                pos=getPosition(roih);
                outpos=[1 1;pos' pos']; %1 indicates ellipse
            case 'impoly'
                %getPosition(h) returns the current position of the polygon h. The returned position, pos, is an N-by-2 array [X1 Y1;...;XN YN]. 
                pos=getPosition(roih);
                outpos=[0 0;pos;pos(1, :)]; %0 indicates polygon vertices
            otherwise
                error('Internal error: Unknown handle type');
        end
        % Save
        filename=dtrack_fileio_selectroi('save', defsavepath);
        if filename==0
            success=0;
        else
            success=dtrack_fileio_saveroi(filename, outpos(:, 1), outpos(:, 2));
        end
        if success
            outfilename=filename;
            disp(['ROI file was created and saved as ' filename]);
        else
            outfilename=0;
            disp('No ROI file was created');
        end
        uiresume(gui.minifig);
    else
        outfilename=0;
        disp('No ROI file was created');
        sub_cancel();
    end
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback, returns unchanged para and finishes execution
    uiresume(gui.minifig);
end

function sub_circ(varargin)
    % CIRC: get roi from circle 
    if ~isempty(roih)
        delete(roih);roih=[];
    end
    roih=imellipse(gui.imax);
    type='imellipse';
end

function sub_rect(varargin)
    % RECT: get roi from rectangle
    if ~isempty(roih)
        delete(roih);roih=[];
    end
    roih=imrect(gui.imax);
    type='imrect';
end

function sub_poly(varargin)
    % POLY: get roi from polygon 
    if ~isempty(roih)
        delete(roih);roih=[];
    end
    roih=impoly(gui.imax);
    type='impoly';
end

function sub_close(varargin)
    % CLOSE: close button callback
    if ~isempty(roih)
        button=questdlg('Do you want to save this Region of Interest?', 'Save ROI', 'Save', 'Don''t save', 'Cancel', 'Don''t save');
        switch button
            case 'Save'
                sub_OK();
            case 'Don''t save'
                sub_cancel();
        end
    else
        sub_cancel();
    end
end

function sub_drawimage
    imagesc(status.currim_ori, 'parent', gui.imax);
end %sub_drawimage


function sub_creategui
    %create invisible mini figure to attach the uiwait to
    gui.minifig = figure(776);clf;
    set(gui.minifig, 'outerposition', [0 0 0.01 0.01], 'name', '', ...
     'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'visible', 'off');
    
    
    %create main figure
    screen=get(0, 'screensize');
    figsize=screen;
    %set up the figure
    gui.fig = figure(777);clf;
    set(gui.fig, 'outerposition', figsize, 'name', '', ...
     'numbertitle', 'off', 'menubar', 'none',...
    'interruptible', 'off', 'pointer', 'arrow', 'CloseRequestFcn', @sub_close);

%% panels
    gui.imax=axes('parent', gui.fig, 'position', [.02 .02 .86 .96]);
    gui.panel=uipanel(gui.fig, 'position', [.92 .02 .06 .96]);

%% panel
    uicontrol(gui.panel, 'style', 'pushbutton', 'string', 'Rectangle', 'callback', @sub_rect, ...
        'units', 'normalized', 'position', [.1 .85 .8 .1], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'roi_rect');
    uicontrol(gui.panel, 'style', 'pushbutton', 'string', 'Ellipse', 'callback', @sub_circ, ...
        'units', 'normalized', 'position', [.1 .75 .8 .1], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'roi_circ');
    uicontrol(gui.panel, 'style', 'pushbutton', 'string', 'Polygon', 'callback', @sub_poly, ...
        'units', 'normalized', 'position', [.1 .65 .8 .1], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'roi_poly');
    uicontrol(gui.panel, 'style', 'pushbutton', 'string', 'Accept', 'callback', @sub_OK, ...
        'units', 'normalized', 'position', [.1 .45 .8 .1], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'roi_ok');
    uicontrol(gui.panel, 'style', 'pushbutton', 'string', 'Cancel', 'callback', @sub_cancel, ...
        'units', 'normalized', 'position', [.1 .35 .8 .1], 'backgroundcolor', [.7 .7 .7], 'Fontweight', 'bold', 'tag', 'roi_cancel');

end %sub_creategui

end