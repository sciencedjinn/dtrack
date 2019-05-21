function outpara=dtrack_colourgui(gui, status, para)
% COLOURGUI interactively changes marker shape and colour for all points
% outpara=dtrack_colourgui(gui, status, para)
% the function creates a modal window, in which several panels are created
% using the nested function colourgui_panel(one panel for each marker type). After each
% value change these panels write their changes to para.ls in the
% colourgui-workspace using the nested function n_wad. A preview is drawn
% into the tracking  window. When OK is pressed the changes are written to
% outpara, the window is closed and the tracker window redrawn with the correct new
% settings.


%% Init
% save the original para, in case execution is canceled
outpara=para;
% now change current point, last point and roi to normally numbered points
para.ls.p{para.pnr+1}=para.ls.cp;
para.ls.p{para.pnr+2}=para.ls.lp;
para.ls.p{para.pnr+3}=para.ls.roi;

%% const
% change these parameters to alter the appearance of the dialog window

% how many rows and columns of panels and within panels
rows=para.pnr+4;        % number of rows of panels
cols=1;                 % number of columns of panels
rowsp=1;                % number of rows of buttons per panel
colsp=13;               % number of buttons per panel
nsymb=10;               % number of symbols for point markers

% figure colours
figcol=[0.9 0.95 1];    % background colour
textcol='k';            % title text colour

% panel parameters
fontsize=10;            % default fontsize (should be 50% of std_height)
button_height=20;       % standard height of a button
button_width=25;        % standard width of a button
std_oh=30;              % overhead for the panel title
std_height=rowsp*button_height+std_oh;  %panelheight
std_width=colsp*button_width;           %panelwidth
std_dist_vert=2;        % vertical distance between panels
std_dist_hor=10;        % horizontal dstance between panels

% margins inside the figure window
margin_left=10;     
margin_right=10;
margin_top=10;
margin_bottom=10;

%% draw gui
colourgui_gui();

%% set figure to modal late after you know there are no errors
set(fig, 'windowStyle', 'modal');

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(fig);
    %gdata(outs, [], 'repeatframe2');
    delete(fig);
catch anyerror
    delete(fig);        %delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%% Nested functions for callbacks, writing/drawing and panel creation
    function colourgui_gui
    
        % positioning of the figure window on the screen
        figwidth=margin_left+margin_right+cols*std_width+(cols-1)*std_dist_hor;
        figheight=margin_bottom+margin_top+rows*std_height+(rows-1)*std_dist_vert;
        scrsize=get(0, 'screenSize');
        figmargleft=round(scrsize(3)/2-figwidth/2);
        figmargbottom=round(scrsize(4)/2-figheight/2);

        %% draw figure
        figpos=[figmargleft figmargbottom figwidth figheight];
        fig=dialog('Color', figcol, 'name', 'Markers', 'Position', figpos, 'CloseRequestFcn', @nested_close);
        assignin('base', 'fig', fig); % write to base workspace to be able to delete after error
        
        %% create panels
        %point rows
        p(1)=margin_left+1;p(4)=std_height;p(3)=std_width;
        p(2)=figpos(4)-margin_top+std_dist_vert;
        for i=1:para.pnr
            p(2)=p(2)-p(4)-std_dist_vert;colourgui_gui_panel(i, ['Point #' num2str(i)]);
        end

        %current point
        p(2)=p(2)-p(4)-std_dist_vert;colourgui_gui_panel(i+1, 'Current point');
        
        %last point
        p(2)=p(2)-p(4)-std_dist_vert;colourgui_gui_panel(i+2, 'Last point');
        
        %roi
        p(2)=p(2)-p(4)-std_dist_vert;colourgui_gui_panel(i+3, 'Region of Interest (ROI)');
        
        %% create OK/Cancel buttons
        p(3)=std_width/3; 
        p(1)=margin_left+1+p(3)/3;
        p(4)=p(4)/2;
        p(2)=p(2)-8*std_dist_vert-p(4);
        uicontrol('parent', fig, 'style', 'pushbutton', 'position', p, ...
              'horizontalalignment', 'center', 'string', 'OK', 'callback', @nested_OK,...
              'fontsize', fontsize, 'tooltip', 'Save new values.');
        p(1)=p(1)+p(3)*4/3;
        uicontrol('parent', fig, 'style', 'pushbutton', 'position', p, ...
              'horizontalalignment', 'center', 'string', 'Cancel', 'callback', @nested_cancel,...
              'fontsize', fontsize, 'tooltip', 'Cancel and reverse value changes.');
                
        function colourgui_gui_panel(fieldnum, title)
            % COLOURGUI_PANEL creates a ui panel object
            % fieldname: the name of the field this panel represents in s
            % title: panel title string
            % Example:
            %   colourgui_panel('currentring.manual', 'current ring manual');

            %% Init
            p2(1)=0; p2(3)=1/colsp; p2(4)=1/rowsp; p2(2)=0+(rowsp-1)*p2(4);

            %% draw gui elements
            panelhandle=uipanel('Title', title, 'fontsize', fontsize, 'Units', 'pixels', 'BackgroundColor', figcol, 'ForegroundColor', textcol, 'Position', p);
            colourbutton = uicontrol('units', 'normalized', 'parent', panelhandle, 'style', 'pushbutton', 'position', p2, ...
                    'callback', @nested_changecolour, 'tooltip', ['Colour of ', title,], 'tag', 'colourbutton');
            p2(1)=p2(1)+p2(3); p2(3)=nsymb*p2(3);
            symbolgroup = uibuttongroup('tag', 'symbolgroup', 'Parent', panelhandle, 'Position', p2, 'SelectionChangeFcn', @nested_valuechange);
            p3(1)=0; p3(2)=0; p3(3)=1/nsymb; p3(4)=1;

                function togh=uitoggle(str, tag)
                    if nargin<2;tag=str;end
                    togh=uicontrol('units', 'normalized', 'position', p3, 'style', 'togglebutton', 'fontname', 'fixedwidth', 'fontsize', fontsize, 'tag', tag, 'parent', symbolgroup, 'cdata', imread(fullfile('icons', [str, '.tif'])));p3(1)=p3(1)+p3(3);
                end
            bh{1}=uitoggle('s'); bh{2}=uitoggle('d'); bh{3}=uitoggle('v'); bh{4}=uitoggle('t', '^'); bh{5}=uitoggle('o'); bh{6}=uitoggle('st', '*'); bh{7}=uitoggle('dot', '.'); bh{8}=uitoggle('pl', '+'); bh{9}=uitoggle('x'); bh{10}=uitoggle('none', 'none');%#ok<NASGU>
            p2(1)=p2(1)+p2(3); p2(3)=p2(3)/nsymb;
            size  = uicontrol('style', 'edit', 'tag', 'size', 'units', 'normalized', 'position', p2, 'tooltip', ['Marker size for ', lower(title)], ...
                'parent', panelhandle, 'callback', @nested_valuechange, 'fontsize', fontsize);
            p2(1)=p2(1)+p2(3);
            width = uicontrol('style', 'edit', 'tag', 'width', 'units', 'normalized', 'position', p2, 'tooltip', ['Line width for ', lower(title)], ...
                    'parent', panelhandle, 'callback', @nested_valuechange, 'fontsize', fontsize);            

            %% set to defaults
            set(colourbutton, 'BackgroundColor', para.ls.p{fieldnum}.col);
            set(symbolgroup, 'SelectedObject', findobj(symbolgroup, 'tag', para.ls.p{fieldnum}.shape));
            set(size, 'String', num2str(para.ls.p{fieldnum}.size));
            set(width, 'String', num2str(para.ls.p{fieldnum}.width));

            %% Nested functions for callbacks
                function nested_changecolour(obj, event)
                    % CHANGECOLOUR interactively change background colour of colourbutton
                    % callback function of colour button

                    C=get(obj, 'BackgroundColor');
                    c=uisetcolor(C);
                    if length(c)>1
                        set(obj, 'BackgroundColor', c);
                    end
                    nested_valuechange(obj, event);
                end

                function nested_valuechange(obj, varargin)
                    % VALUECHANGE callback function for all gui elements
                    % writes changed values to para.ls.p
                    switch get(obj, 'tag')
                        case 'colourbutton'
                            para.ls.p{fieldnum}.col=get(obj, 'BackgroundColor');
                        case 'symbolgroup'
                            para.ls.p{fieldnum}.shape=get(get(obj, 'SelectedObject'), 'Tag');
                        case 'size'
                            para.ls.p{fieldnum}.size=str2double(get(obj, 'String'));
                        case 'width'
                            para.ls.p{fieldnum}.width=str2double(get(obj, 'String'));
                    end
                    dtrack_image(gui, status, para, [], 12);
                end     %colourgui_panel/nested_valuechange end
        end     %colourgui_panel end
    
    end %colourgui_gui

    function nested_OK(varargin)
        % OK: ok button callback, returns the changed s and finishes execution
        for i=1:para.pnr
            outpara.ls.p{i}=para.ls.p{i};
        end
        % now save current point, last point and roi (from normally
        % numbered points)
        outpara.ls.cp=para.ls.p{para.pnr+1};
        outpara.ls.lp=para.ls.p{para.pnr+2};
        outpara.ls.roi=para.ls.p{para.pnr+3};
        uiresume;
    end

    function nested_cancel(varargin)
        % CANCEL: cancel button callback, returns unchanged s and finishes execution
        uiresume;
    end

    function nested_close(varargin)
        % CLOSE: close button callback
        try
            button=questdlg('Do you want to save the changed values?', 'Save changes', 'Save', 'Don''t save', 'Cancel', 'Don''t save');
            switch button
                case 'Save'
                    nested_OK();
                case 'Don''t save'
                    nested_cancel();
            end
        catch
           closereq; % make sure you close the window.
        end
    end


end     %colourgui end




