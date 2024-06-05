classdef ReferenceFrame < handle
    % REFERENCEFRAME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        ImageSource(1,1) ImageSource = EmptyImageSource
    end

    properties
        FrameNumbers(:,1) {mustBePositive, mustBeInteger}
        Method(1,1) ReferenceMethod = ReferenceMethod.MEDIAN
    end
    
    properties (Hidden)
        BufferedFrameNumbers
        BufferedMethod
        BufferedFrame double = []
    end
    
    properties
        Frame
    end

    methods
        function obj = ReferenceFrame(imSource, fnrs, method)
            % REFERENCEFRAME Constructor
            obj.ImageSource = imSource;
            obj.FrameNumbers = fnrs;
            if nargin>2, obj.Method = method; end
        end
    end

   methods
      function ref = get.Frame(obj)
         % gets the current reference frame
         % checks whether the buffer is up-to-date, otherwise recalculates
         if isequal(obj.FrameNumbers, obj.BufferedFrameNumbers) && isequal(obj.Method, obj.BufferedMethod)
             Logger.log(LogLevel.INFO, 'Parameters have not changed, using buffered frame.\n')
             % no recalculation needed
         else
%              Logger.log(LogLevel.INFO, 'Old Method: %s\n', obj.BufferedMethod)
%              Logger.log(LogLevel.INFO, 'New Method: %s\n', obj.Method)
%              Logger.log(LogLevel.INFO, 'Parameters HAVE changed, recalculating buffered frame.\n')
%              Logger.log(LogLevel.INFO, 'Parameters HAVE changed, recalculating buffered frame.\n')
             Logger.log(LogLevel.INFO, 'Parameters HAVE changed, recalculating buffered frame.\n')
             try
                newFrame = obj.Method.Fun(obj.ImageSource.readFrames(obj.FrameNumbers));
             catch me
                 rethrow(me);
             end
             obj.BufferedFrame = newFrame;
             obj.BufferedFrameNumbers = obj.FrameNumbers;
             obj.BufferedMethod = obj.Method;
         end
         ref = obj.BufferedFrame;
      end
   end

end

