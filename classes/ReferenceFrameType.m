classdef ReferenceFrameType
    % REFERENCEFRAMETYPE defines types of selection methods to pick frames that contribute to the reference frame.
    % Call obj.Fun(X, total_number_of_frames) to call the function and return the frame number array; an explanation is stored in obj.Tooltip

    properties (SetAccess=immutable, GetAccess=public)
        Fun(1,1)
        Tooltip(1,1) string
    end

    enumeration
        FirstX (@(x, nFrames) 1:min(x, nFrames), "The first X frames")
        LastX (@(x, nFrames) max(nFrames-x+1, 1):nFrames, "The last X frames")
        OneEveryX (@(x, nFrames) 1:x:nFrames, "One frame every X frames")
        XFramesEvenlySpaced (@(x, nFrames) round(linspace(1, nFrames, x)), "X frames, evenly spread across the video")
        FirstAndLastX (@(x, nFrames) [1:min(x, nFrames) max(nFrames-x+1, 1):nFrames], "The first and last X frames")
        All (@(x, nFrames) 1:nFrames, "All frames")
    end

    methods
        function obj = ReferenceFrameType(fun, tooltip)
            obj.Fun = fun;
            obj.Tooltip = tooltip;
        end
    end
end