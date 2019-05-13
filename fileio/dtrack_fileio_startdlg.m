function [gui, status, para, data, loadaction] = dtrack_fileio_startdlg(status, para)
% Starts dtrack with a dialog box offering options:
% 1. New File: Open file dialog, then open a brief parameter dialog with
% the option of loading a more detailed parameter file
% 2. Open File: Open file dialog, this time for save files. Load the video,
% and the saved data (this includes the parameters, the parameter file is
% not used again). If the video can't be found, open a dialog box to select it. 
% After loading, check the number of frames, if that's not correct, ERROR!
% 3. Point demo opens a little demonstration video of a rolling beetle with already tracked points.
% 4. Line demo opens a little demonstration video of a dancing beetle with already tracked lines.
% 5. Recently used file: Same as Open

% returns 'new'/'load'/'canceled'
% for load it returns RESpaths, for new it returns MOVpaths

%% const
% change these parameters to alter the appearance of the dialog window

% figure colours
figcol          = [0.9 0.95 1];     % background colour
textcol         = 'k';              % title text colour
fontsize        = 10;               % default fontsize (should be 50% of std_height)

% margins inside the figure window
margin_left     = 0.05;  
margin_top      = 0.05;
std_dist_vert   = 0.05;             % vertical distance between buttons
std_dist_hor    = 0.05;             % horizontal dstance between buttons

button_nr       = 5;
button_height   = (1-margin_top-button_nr*std_dist_vert)/button_nr;
button_width    = (1-2*margin_left-std_dist_vert)/2;     % standard width of a button

% figure size (normalized, centred)
figw            = 0.3;
figh            = 0.4;

[liststring, paths, howmany] = dtrack_fileio_getrecent(para.maxrecent);

%% draw figure
figpos          = [0.5-figw/2 0.5-figh/2 figw figh];
fig             = dialog('Color', figcol, 'name', ['Welcome to ' para.theme.name], 'units', 'normalized', 'Position', figpos, 'CloseRequestFcn', @nested_cancel, 'windowstyle', 'normal');

%% create buttons
%col 2 (create first, so it doesnt have focus)
listh=5*button_height+4*std_dist_vert;
p=[margin_left+button_width+std_dist_hor 1-margin_top-listh button_width listh];
if ~isempty(liststring)
    uicontrol('parent', fig, 'units', 'normalized', 'style', 'listbox', 'position', p,...
          'horizontalalignment', 'left', 'string', liststring, 'callback', @nested_recent,...
          'fontsize', fontsize, 'tooltip', 'Open recent project.', 'Min', 1, 'Max', howmany);
else
    uicontrol('parent', fig, 'units', 'normalized', 'style', 'listbox', 'position', p,...
          'horizontalalignment', 'left', 'string', 'No recent files found', 'enable', 'on',...
          'fontsize', fontsize);
end

%col 1
p=[margin_left 1-std_dist_vert-button_height button_width button_height];

uicontrol('parent', fig, 'units', 'normalized', 'style', 'pushbutton', 'position', p, ...
      'horizontalalignment', 'center', 'string', 'New Project...', 'callback', @nested_new,...
      'fontsize', fontsize, 'tooltip', 'Create a new tracking project by selecting a video file.');
p(2)=p(2)-std_dist_vert-button_height;
uicontrol('parent', fig, 'units', 'normalized', 'style', 'pushbutton', 'position', p, ...
      'horizontalalignment', 'center', 'string', 'Open Project...', 'callback', @nested_open,...
      'fontsize', fontsize, 'tooltip', 'Open a previous tracking project by selecting its results file');
p(2)=p(2)-std_dist_vert-button_height;
uicontrol('parent', fig, 'units', 'normalized', 'style', 'pushbutton', 'position', p, ...
      'horizontalalignment', 'center', 'string', 'Line tracking demo', 'callback', @nested_demol,...
      'fontsize', fontsize, 'tooltip', 'Open a short demonstration video of a dancing beetle, demonstrating line tracking mode.', 'enable', 'off');
p(2)=p(2)-std_dist_vert-button_height;
uicontrol('parent', fig, 'units', 'normalized', 'style', 'pushbutton', 'position', p, ...
      'horizontalalignment', 'center', 'string', 'Point tracking demo', 'callback', @nested_demop,...
      'fontsize', fontsize, 'tooltip', 'Open a short demonstration video of a rolling beetle, demonstrating point tracking mode.', 'enable', 'off');
p(2)=p(2)-std_dist_vert-button_height;
uicontrol('parent', fig, 'units', 'normalized', 'style', 'pushbutton', 'position', p, ...
      'horizontalalignment', 'center', 'string', ['Quit ' para.theme.name], 'callback', @nested_cancel,...
      'fontsize', fontsize, 'tooltip', 'Quit program');
  


%% set figure to modal late after you know there are no errors
set(fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(fig);
    delete(fig);
catch anyerror
    delete(fig);        %delete the modal figure, otherwise we'll be stuck in it forever
    uiresume(fig);
    rethrow(anyerror);
end

%% Nested functions for callbacks, writing/drawing and panel creation
    function nested_new(varargin)
        set(fig, 'visible', 'off');
        tic;
        [status, para, data, success] = dtrack_fileio_new(status, para, 0, 0);
        if toc<1
            [status, para, data, success] = dtrack_fileio_new(status, para, 0, 0);
        end
        switch success
            case 1
                %TODO: could this be in dtrack?
                gui = dtrack_gui(status, para);
                loadaction = 'new';
                uiresume(fig);
            otherwise %2 for user canceled or 0
                set(fig, 'visible', 'on');
        end
    end

    function nested_open(varargin)
        set(fig, 'visible', 'off');
        tic;
        [status, para, data, success]=dtrack_fileio_load(status, para, 0);
        if toc<3
            [status, para, data, success]=dtrack_fileio_load(status, para, 0);
        end
        if success
            gui = dtrack_gui(status, para);
            loadaction = 'load';
            uiresume(fig);
        else
            set(fig, 'visible', 'on');
        end
    end

    function nested_demol(varargin)
        coomingsoon;
        %set(fig, 'visible', 'off');
        %[status, para, data, success]=dtrack_fileio_load(status, para, 0, 'demo/linedemo.res');
        %if success
        %    gui=dtrack_gui(status, para);
        %    loadaction='load';
        %    uiresume(fig);
        %else
        %    set(fig, 'visible', 'on');
        %end
    end

    function nested_demop(varargin)
        coomingsoon;
        %set(fig, 'visible', 'off');
        %[status, para, data, success]=dtrack_fileio_load(status, para, 0, 'demo/pointdemo.res');
        %if success
        %    gui=dtrack_gui(status, para);
        %    loadaction='load';
        %    uiresume(fig);
        %else
        %    set(fig, 'visible', 'on');
        %end
    end

    function nested_cancel(varargin)
        gui=[];data=[];
        loadaction='canceled';
        uiresume;
    end

    function nested_recent(varargin)
        set(fig, 'visible', 'off');
        [status, para, data, success]=dtrack_fileio_load(status, para, 0, paths{get(gcbo, 'value')});
        if success
            gui=dtrack_gui(status, para);
            loadaction='load';
            uiresume(fig);
        else
            set(fig, 'visible', 'on');
        end
    end

end




