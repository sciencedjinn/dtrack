function [success, atp] = dtrack_tools_autotrack_select(status, para, data)
% DTRACK_TOOLS_AUTOTRACK_SELECT opens a dialog to select parameters for autotracking
% Call: [success, autopara] = dtrack_tools_autotrack_select(status, para)
%
% Call sequence: dtrack_action -> dtrack_tools_autotrack_select
%                              -> dtrack_tools_autotrack_main -> dtrack_tools_autotrack_detect
% See also: dtrack_tools_autotrack_detect, dtrack_tools_autotrack_main

%% init parameters
atp     = AutoTrackerPara(status.mh, @(x) cb_updatePreview([], [], x));
atp     = atp.loadSettings;
atp.PointNr = status.cpoint;
success = 0;
gui     = sub_createGui;
drawnow;

% ATP Gui
atp.createGui(gui.atpPanel);
atp.updateGui;

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(gui.fig);
    delete(gui.fig);
catch anyerror
    delete(gui.fig); % delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Nested functions for callbacks, writing/drawing and panel creation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gui = sub_createGui
    % Create figure and panels
    screen  = get(0, 'screensize');
    figSizeMult = 2/3;
    figpos  = [(1/figSizeMult-1)*screen(3)/2 (1/figSizeMult-1)*screen(4)/2 screen(3) screen(4)] * figSizeMult;
    gui.fig = uifigure("Position", figpos, "Name", "Autotracking parameters", "NumberTitle", "off", "MenuBar", "none", "Interruptible", "off", "Pointer", "arrow", "CloseRequestFcn", @cb_close);
    gui.gh1 = uigridlayout(gui.fig, [2 2], "RowHeight", {'1x', 'fit'}, 'ColumnWidth', {'fit', '1x'}, 'RowSpacing', 2);
    gui.atpPanel = uipanel(gui.gh1, "BorderType", "none");
    gui.buttonPanel = uipanel(gui.gh1, "BorderType", "none");
    gui.buttonPanel.Layout.Column = 1;
    gui.buttonPanel.Layout.Row = 2;
    gui.axesPanel = uipanel(gui.gh1);
    gui.axesPanel.Layout.Column = 2;
    gui.axesPanel.Layout.Row = [1 2];

    % Create buttons
    gui.buttonGrid = uigridlayout(gui.buttonPanel, [2 5], Padding=3, ColumnSpacing=1, ColumnWidth={'fit', 'fit', '1x', 'fit', 'fit'});

    opts = {'Fontweight', 'bold'}; 
    gui.previewButton = uibutton(gui.buttonGrid, "state", opts{:}, Text='Preview', ValueChangedFcn={@cb_updatePreview, 'all'});
    gui.previewButton.Layout.Column = [2 4];
    temp = uibutton(gui.buttonGrid, opts{:}, Text='Save as default', ButtonPushedFcn=@cb_saveAsDefault);
    temp.Layout.Row = 2;
    temp.Layout.Column = 1;
    uibutton(gui.buttonGrid, opts{:}, Text='Load default', ButtonPushedFcn=@cb_loadDefault);
    temp = uibutton(gui.buttonGrid, opts{:}, Text='Start', ButtonPushedFcn=@cb_ok);
    temp.Layout.Column = 4;
    uibutton(gui.buttonGrid, opts{:}, Text='Cancel', ButtonPushedFcn=@cb_cancel);
    
    % Create Preview GUI
    gui.axesGrid = uigridlayout(gui.axesPanel, [2, 2], 'Padding', 0, 'RowSpacing', 0, 'ColumnSpacing', 0);
    gui.prevPh(1) = uipanel(gui.axesGrid);
    gui.prevPh(2) = uipanel(gui.axesGrid);
    gui.prevPh(3) = uipanel(gui.axesGrid);
    gui.prevPh(4) = uipanel(gui.axesGrid);
    
    gui.prevAh(1) = axes(gui.prevPh(1), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prevAh(2) = axes(gui.prevPh(2), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prevAh(3) = axes(gui.prevPh(3), 'units', 'normalized', 'position', [0 0 1 1]);
    gui.prevAh(4) = axes(gui.prevPh(4), 'units', 'normalized', 'position', [0 0 1 1]);

    
end

%% Button callbacks

    function cb_saveAsDefault(~, ~)
        % SAVEASDEFAULT: save current values as new default
        atp.saveAsDefault;
    end

    function cb_loadDefault(~, ~)
        % LOADDEFAULT: load default values
        atp = atp.loadDefault;
        atp.updateGui;
        atp.updatePreview(gui.previewButton.Value, 'all', gui.prevAh, status, para, data)
    end

    function cb_updatePreview(~, ~, type) 
        atp.updatePreview(gui.previewButton.Value, type, gui.prevAh, status, para, data)
    end

    function cb_ok(~, ~)
        success = 1;
        atp.saveSettings;
        uiresume(gui.fig);
    end

    function cb_cancel(~, ~)
        % CANCEL: cancel button callback finishes execution
        success = false;
        uiresume(gui.fig);
    end

    function cb_close(~, ~)
        % CLOSE: close button callback
        button = questdlg('Cancel autotracking?', 'Cancel', 'No, continue', 'Yes, cancel', 'No, continue');
        switch button
            case 'Yes, cancel'
                cb_cancel();
        end
    end






end