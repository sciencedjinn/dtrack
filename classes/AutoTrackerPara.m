classdef AutoTrackerPara < handle
    %AUTOTRACKERPARA contains the parameters for autotracking
    %   Detailed explanation goes here
    
    properties
        From(1,1) double {mustBePositive, mustBeInteger} = 1
        To(1,1) double {mustBePositive, mustBeInteger} = 1
        Step(1,1) double {mustBePositive, mustBeInteger} = 1
        PointNr(1,1) double {mustBePositive, mustBeInteger} = 1
        UseRoi(1,1) logical = true
        ShowIm(1,1) logical = true
        AreaThresh(1,1) double {mustBePositive} = 50
        GreyThresh(1,1) double {mustBePositive} = 1
        Method(1,1) string = "nearest"
        Para4 = -1
        RefFrame(1,1) ReferenceFrame
    end

    properties (Transient)
        Gui
        PrevData
        PreviewFcn = @(x) disp('')
    end
    
    properties (Dependent)
        NFrames
    end

    methods
        function obj = AutoTrackerPara(imageSource, previewFcn)
            %AUTOTRACKERPARA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin>1, obj.PreviewFcn = previewFcn; end
            obj.RefFrame = ReferenceFrame(imageSource, [], [], [], @(x) obj.PreviewFcn('all'));
        end
    end

    methods
        function val = get.NFrames(obj)
            val = obj.RefFrame.ImageSource.NFrames;
        end
    end

    methods
        function createGui(obj, ph)
            

            %% panels
            gui.gh1 = uigridlayout(ph, [2 1], RowHeight={'fit', '1x', 'fit'}, ColumnWidth={'1x'}, RowSpacing=2, Padding=0);
            gui.ph1 = uipanel(gui.gh1, Title="Tracking Parameters");
            gui.ph2 = uipanel(gui.gh1, Title="Reference Frame");
        
            %% panel 1
            gui.gh2     = uigridlayout(gui.ph1, [7 4], RowHeight={'1x', '1x', '1x', '1x', '1x', '1x', 'fit'}, ColumnWidth={'1x', 'fit', '1x', 'fit'}, RowSpacing=2);
                        uilabel(gui.gh2, Text='From frame', HorizontalAlignment="Right");
            gui.from    = sub_plusminustext(gui.gh2, 'autotrack_from');
                        uilabel(gui.gh2, Text='to frame', HorizontalAlignment="Right");
            gui.to      = sub_plusminustext(gui.gh2, 'autotrack_to');
                        uilabel(gui.gh2, Text='every', HorizontalAlignment="Right");
            gui.step    = sub_plusminustext(gui.gh2, 'autotrack_step');
                        uilabel(gui.gh2, Text='Save to point #', HorizontalAlignment="Right");
            gui.pointnr = uieditfield(gui.gh2, "numeric", HorizontalAlignment="Center", Tag='autotrack_pointnr', ValueChangedFcn=@obj.callback);
        
            gui.useroi     = uicheckbox(gui.gh2, ValueChangedFcn=@obj.callback, Text="Use ROI", Tag='autotrack_useroi');
            gui.useroi.Layout.Row = 4;
            gui.useroi.Layout.Column = [1 2];
            gui.showim     = uicheckbox(gui.gh2, ValueChangedFcn=@obj.callback, Text='Show tracking', Tag='autotrack_showim', Tooltip='Display the tracked points while they are calculated. This takes at least 3x longer!');
            gui.showim.Layout.Column = [3 4];
                           uilabel(gui.gh2, Text='Area threshold', HorizontalAlignment="Left");
            gui.areathresh = sub_plusminustext(gui.gh2, 'autotrack_areathresh');
                             set(gui.areathresh, Tooltip='Smallest area (in square pixels) that will be accepted for tracking.');
                           uilabel(gui.gh2, Text='Grey threshold', HorizontalAlignment="Left", Enable='on');
            gui.greythresh = sub_plusminustext(gui.gh2, 'autotrack_greythresh');
                             set(gui.greythresh, Tooltip='Multiplier for the grey threshold. The higher this value, the more different an object has to be from the background to be detected.');
                           uilabel(gui.gh2, Text='Method', HorizontalAlignment="Left", Enable='on');
            gui.method     = uidropdown(gui.gh2, ValueChangedFcn=@obj.callback, Items={'largest', 'nearest', 'absolute'}, Tag='autotrack_method', Tooltip='NEAREST: Of all detected foreground objects, tracking will choose the one that is closest to the last tracked point.   LARGEST: Of all detected foreground objects, tracking will choose the largest one.');
                           uilabel(gui.gh2, Text='Parameter 4', HorizontalAlignment="Left", Enable='off');
            gui.para4      = uieditfield(gui.gh2, "numeric", ValueChangedFcn=@obj.callback, Tag='autotrack_para4', Enable='off');
        
            %% Reference panel
            obj.RefFrame.createGui(gui.ph2);
                
            obj.Gui = gui;

            function outh = sub_plusminustext(gh, tag)
                % helper function for the gui, creates a text box with plus and minus buttons around it
                subgh = uigridlayout(gh, [1 3], ColumnWidth={'fit', '1x', 'fit'}, ColumnSpacing=1, Padding=0);
                uibutton(subgh, Text="-", HorizontalAlignment="right", Tag=[tag '_minus'], ButtonPushedFcn=@obj.callback);
                outh = uieditfield(subgh, "numeric", HorizontalAlignment="Center", Tag=tag, ValueChangedFcn=@obj.callback);
                uibutton(subgh, Text="+", HorizontalAlignment="right", Tag=[tag '_plus'], ButtonPushedFcn=@obj.callback);
            end
        end

        %% General callback
        function callback(obj, src, varargin)
            disp(src)
            switch get(src, "Tag")
                case {'autotrack_from', 'autotrack_to', 'autotrack_step', 'autotrack_ref'}
                    newval = get(src, 'Value');
                    limval = round(min([max([newval 1]) obj.NFrames])); % limit to possible frame numbers
                    set(src, 'Value', limval);
                    switch get(src, "Tag")
                        case 'autotrack_from'
                            obj.From = limval;
                            obj.PreviewFcn('im');
                        case 'autotrack_to'
                            obj.To = limval;
                        case 'autotrack_step'
                            obj.Step = limval;
                    end

                case 'autotrack_pointnr'
                    newval = src.Value;
                    limval = round(max([newval 1]));
                    src.Value = limval;
                    obj.PointNr = limval;

                case 'autotrack_areathresh'
                    obj.AreaThresh = src.Value;
                    obj.PreviewFcn('area');

                case 'autotrack_greythresh'
                    obj.GreyThresh = src.Value;
                    obj.PreviewFcn('grey');

                case 'autotrack_method'
                    obj.Method = src.Value;
                    obj.PreviewFcn('method');

                case 'autotrack_para4'

                case 'autotrack_showim'
                    obj.ShowIm = get(src, 'value');

                case 'autotrack_useroi'
                    obj.UseRoi = get(src, 'value');
                    obj.PreviewFcn('roi');

                    % plus/minus buttons
                case 'autotrack_from_minus'
                    newval = obj.Gui.from.Value - 1;
                    limval = max([newval 1]); % limit to possible frame numbers
                    obj.Gui.from.Value = limval;
                    obj.From = limval;
                    obj.PreviewFcn('im');

                case 'autotrack_from_plus'
                    newval = obj.Gui.from.Value + 1;
                    limval = min([newval obj.NFrames]); % limit to possible frame numbers
                    obj.Gui.from.Value = limval;
                    obj.From = limval;
                    obj.PreviewFcn('im');

                case 'autotrack_to_minus'
                    newval = obj.Gui.to.Value - 1;
                    limval = max([newval 1]); % limit to possible frame numbers
                    obj.Gui.to.Value = limval;
                    obj.To = limval;

                case 'autotrack_to_plus'
                    newval = obj.Gui.to.Value + 1;
                    limval = min([newval obj.NFrames]); % limit to possible frame numbers
                    obj.Gui.to.Value = limval;
                    obj.To = limval;

                case 'autotrack_step_minus'
                    newval = obj.Gui.step.Value - 1;
                    limval = max([newval 1]); % limit to possible frame numbers
                    obj.Gui.step.Value = limval;
                    obj.Step = limval;

                case 'autotrack_step_plus'
                    newval = obj.Gui.step.Value + 1;
                    limval = min([newval obj.NFrames]); % limit to possible frame numbers
                    obj.Gui.step.Value = limval;
                    obj.Step = limval;

                case 'autotrack_areathresh_minus'
                    newval = obj.Gui.areathresh.Value - 1;
                    obj.AreaThresh = newval;
                    obj.Gui.areathresh.Value = newval;
                    obj.PreviewFcn('area');

                case 'autotrack_areathresh_plus'
                    newval = obj.Gui.areathresh.Value + 1;
                    obj.AreaThresh = newval;
                    obj.Gui.areathresh.Value = newval;
                    obj.PreviewFcn('area');

                case 'autotrack_greythresh_minus'
                    newval = obj.Gui.greythresh.Value - 0.1;
                    obj.GreyThresh = newval;
                    obj.Gui.greythresh.Value = newval;
                    obj.PreviewFcn('grey');

                case 'autotrack_greythresh_plus'
                    newval = obj.Gui.greythresh.Value + 0.1;
                    obj.GreyThresh = newval;
                    obj.Gui.greythresh.Value = newval;
                    obj.PreviewFcn('grey');

                otherwise
                    error('Internal error: Unknown caller %s', get(src, "Tag"));
            end
        end

        function updatePreview(obj, value, type, ah, status, para, data)
            % gather parameters
            if value
                obj.PrevData.ref = obj.RefFrame.getFrame();
                if ismember(type, {'all', 'im'}) % update image frame
                    status.framenr  = obj.Gui.from.Value;
                    [~, status]     = dtrack_action([], status, para, data, 'loadonly');
                    obj.PrevData.im           = status.currim_ori;
                end
                if ismember(type, {'all', 'roi'}) % update ROI
                    if obj.Gui.useroi.Value && ~isempty(status.roi)
                        switch status.roi(1, 1)
                            case 0  % 0 indicates polygon vertices
                                [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                                obj.PrevData.roimask = inpolygon(Y, X, status.roi(2:end, 1), status.roi(2:end, 2));
                            case 1  % 1 indicates ellipse
                                [X,Y]   = ndgrid(1:status.mh.Height, 1:status.mh.Width);
                                obj.PrevData.roimask = inellipse(Y, X, status.roi(2:end));
                            otherwise
                                error('Internal error: Unknown ROI type');
                        end
                    else
                        obj.PrevData.roimask = [];
                    end
                end
                if ismember(type, {'all', 'grey'}) % update grey threshold
                    obj.PrevData.greythr = obj.Gui.greythresh.Value;
                end
                if ismember(type, {'all', 'area'}) % update area threshold
                    obj.PrevData.areathr = obj.Gui.areathresh.Value;
                end
                if ismember(type, {'all', 'method'}) % update method
                    obj.PrevData.method = obj.Gui.method.Value;
                end

                % calculate centroids
                [outcentroid, outarea, diagims] = dtrack_tools_autotrack_detect(obj.PrevData.ref, obj.PrevData.im, obj.PrevData.roimask, obj.PrevData.greythr, obj.PrevData.areathr, obj.PrevData.method);
    
                % plot
                dtrack_tools_autotrack_plotdiag(obj.PrevData.im, diagims, outcentroid, outarea, ah);
            else
                for i = 1:length(ah)
                    cla(ah(i))
                end
            end
        end

        function saveAsDefault(obj)
            % SAVEASDEFAULT: save current values as new default
            save(fullfile(prefdir, 'dtrack_autopara_bgs.dtp'), 'obj', '-mat');
            Logger.log(LogLevel.INFO, 'Autotracking parameters saved to preferences directory.\n');
        end

        function obj = loadDefault(obj)
            % LOADDEFAULT: load default values
            try
                temp = load(fullfile(prefdir, 'dtrack_autopara_bgs.dtp'), 'obj', '-mat');
                obj = updateLoadedObject(obj, temp.obj);
                Logger.log(LogLevel.INFO, 'Autotracking parameters loaded from preferences directory.\n');
            catch
                % If no default exists, create a new object with default values
                defObj = AutoTrackerPara(obj.RefFrame.ImageSource);
                obj = updateLoadedObject(obj, defObj);
                Logger.log(LogLevel.INFO, 'Autotracking parameters set to class defaults.\n');
            end
        end
        
        function saveSettings(obj)
            % save current settings for next session
            save(fullfile(prefdir, 'dtrack_autopara_bgs_current.dtp'), 'obj', '-mat'); % save current settings
            Logger.log(LogLevel.DEBUG, 'Current parameters saved to preferences directory.\n');
        end

        function obj = loadSettings(obj)
            % load settings from last session
            try
                temp = load(fullfile(prefdir, 'dtrack_autopara_bgs_current.dtp'), 'obj', '-mat');
                obj = updateLoadedObject(obj, temp.obj);
                obj.To = obj.NFrames;
                Logger.log(LogLevel.INFO, 'Last parameters loaded from preferences directory.\n');
            catch
                obj = obj.loadDefault;
            end           
        end

        function obj = updateLoadedObject(obj, loadObject)
            obj.From = min([loadObject.From obj.NFrames]);
            obj.To = min([loadObject.To obj.NFrames]);
            obj.Step = loadObject.Step;
            obj.PointNr = loadObject.PointNr;
            obj.UseRoi = loadObject.UseRoi;
            obj.ShowIm = loadObject.ShowIm;
            obj.AreaThresh = loadObject.AreaThresh;
            obj.GreyThresh = loadObject.GreyThresh;
            obj.Method = loadObject.Method;
            obj.Para4 = loadObject.Para4;
            obj.RefFrame.FrameNumberMethod = loadObject.RefFrame.FrameNumberMethod;
            obj.RefFrame.FrameNumberX = loadObject.RefFrame.FrameNumberX;
            obj.RefFrame.Method = loadObject.RefFrame.Method;
        end

        function updateGui(obj)
            %% write object properties to GUI
            obj.Gui.from.Value = obj.From;
            obj.Gui.to.Value = obj.To;
            obj.Gui.step.Value = obj.Step;
            obj.Gui.pointnr.Value = obj.PointNr;
            obj.Gui.useroi.Value = obj.UseRoi;
            obj.Gui.showim.Value = obj.ShowIm;        
            obj.Gui.areathresh.Value = obj.AreaThresh;
            obj.Gui.greythresh.Value = obj.GreyThresh;
            obj.Gui.method.Value = obj.Method;
            obj.Gui.para4.Value = obj.Para4;
            obj.RefFrame.updateGuiFields;
            obj.RefFrame.updateAxes;
        end 

    end
end

