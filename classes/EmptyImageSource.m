classdef EmptyImageSource < ImageSource
    % EMPTYIMAGESOURCE serves as a default object for ImageSource properties in other classes
    
    properties
        NFrames
        Height
        Width
        NChannels
        FrameRate
    end

    properties (Hidden, Access=protected)
        FileName
    end
    
    methods
        function obj = EmptyImageSource(~)
        end

        function [im, t] = readFrame(~, ~, ~)
            im = [];
            t = [];
        end
    end
end

