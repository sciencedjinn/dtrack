classdef ReferenceFrame < handle
    % REFERENCEFRAME represents the reference frame calculation for an image source.
    % Once ImageSource, Method and FrameNumbers have been set, read the resulting reference frame from obj.Frame.
    
    properties
        ImageSource(1,1) ImageSource = EmptyImageSource
    end

    properties
        FrameNumberMethod(1,1) ReferenceFrameType = ReferenceFrameType.XFramesEvenlySpaced
        FrameNumberX(1,1) {mustBePositive, mustBeInteger} = 10
        Method(1,1) ReferenceMethod = ReferenceMethod.MEDIAN
    end

    properties (Transient)
        FrameChangedFcn = @(x) disp('')
    end

    properties (Hidden, Access=protected, Transient)
        FrameNumbers(:,1) {mustBePositive, mustBeInteger} = []
        BufferedFrameNumbers(:,1) {mustBePositive, mustBeInteger} = []
        BufferedMethod(1,1) ReferenceMethod = ReferenceMethod.MEDIAN
        BufferedFrame double = []
        Gui
    end

    properties (Access=protected)
        Frame
    end

    % methods in other files
    methods
        createGui(obj, inputPanelHandle, outputPanelHandle)
    end

    methods
        function obj = ReferenceFrame(imSource, method, fnMethod, fnX, frameChangedFcn)
            % REFERENCEFRAME Constructor
            % obj = ReferenceFrame(imSource, method, fnMethod, fnX)
            % Inputs: 
            %     imSource - ImageSource object to base reference frame on
            %     method - ReferenceMethod object that determines the function used for reference frame calculation
            %              See enumeration('ReferenceMethod') for all supported methods; some commonly used examples include
            %                  ReferenceMethod.MEDIAN, ReferenceMethod.MIN, ReferenceMethod.MAX, ReferenceMethod.DIFF
            %     fnMethod - ReferenceFrameType object that determines how the frames are sampled.
            %              See enumeration('ReferenceFrameType') for all supported types; some commonly used examples include
            %                  ReferenceFrameType.XFramesEvenlySpaced, ReferenceFrameType.FirstX, ReferenceFrameType.LastX, 
            %                  ReferenceFrameType.OneEveryX, ReferenceFrameType.FirstAndLastX
            %     fnX - The X value for the fnMethod
            
            if nargin>0 && ~isempty(imSource), obj.ImageSource = imSource; end
            if nargin>1 && ~isempty(method), obj.Method = method; end
            if nargin>2 && ~isempty(fnMethod), obj.FrameNumberMethod = fnMethod; end
            if nargin>3 && ~isempty(fnX), obj.FrameNumberX = fnX; end
            if nargin>4, obj.FrameChangedFcn = frameChangedFcn; end
        end
    end

    methods
        function ref = get.Frame(obj)
            ref = getFrame(obj);
        end

        function ref = getFrame(obj, varargin)
            % gets the current reference frame
            % optional input d is a uiprogressdlg handle to pass to ImageSource
            % checks whether the buffer is up-to-date, otherwise recalculates
            obj.FrameNumbers = obj.FrameNumberMethod.Fun(obj.FrameNumberX, obj.ImageSource.NFrames);
            if isequal(obj.FrameNumbers, obj.BufferedFrameNumbers) && isequal(obj.Method, obj.BufferedMethod)
                Logger.log(LogLevel.DEBUG, 'Parameters have not changed, using buffered frame.\n')
                % no recalculation needed
            else
                Logger.log(LogLevel.DEBUG, 'Parameters HAVE changed, recalculating buffered frame.\n')
                try
                    newFrame = obj.Method.Fun(obj.ImageSource.readFrames(obj.FrameNumbers, varargin{:}));
                catch me
                    rethrow(me);
                end
                obj.BufferedFrame = newFrame;
                obj.BufferedFrameNumbers = obj.FrameNumbers;
                obj.BufferedMethod = obj.Method;
                obj.FrameChangedFcn();
            end
            ref = obj.BufferedFrame;
        end

        function updateGuiFields(obj)
            % updates the Gui fields after a change in object properties
            obj.Gui.method.Value = string(obj.Method);
            obj.Gui.frameNumberMethod.Value = string(obj.FrameNumberMethod);
            obj.Gui.frameNumberX.Value = obj.FrameNumberX;
        end
    
        function updateAxes(obj)
            % updates the reference frame display
            d = uiprogressdlg(ancestor(obj.Gui.ah, 'matlab.ui.Figure'), "Message", "Loading frames...");
            try
                ref = obj.getFrame(d);
            catch me
                close(d);
                rethrow(me)
            end
            close(d);
            imagesc(obj.Gui.ah, ref/max(ref(:)));
            axis(obj.Gui.ah, 'image', 'off')
        end
    end

end

