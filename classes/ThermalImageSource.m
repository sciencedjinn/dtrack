classdef ThermalImageSource < ImageSource
    %THERMALIMAGESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        NFrames
        Height
        Width
        FrameRate
        GreyScale = false; % by default, not a greyscale sequence
    end

    properties (Hidden, Access=protected)
        FileName
        Buffer
    end

    methods
        function obj = ThermalImageSource(para)
            % opens a thermal camera file
            %
            % use frame=read(mh, frame) to obtain frames
        
            obj.GreyScale  = 0; % by default, not a greyscale sequence
            obj.FileName   = para.paths.movpath;
            disp(['Opening FLIR video file ', obj.FileName]);
            temp = load(obj.FileName, '-mat');
            if isfield(temp, 'data') && isfield(temp, 'ts')
                obj.Buffer.data = temp.data;
                obj.Buffer.t    = temp.ts;
                if length(obj.Buffer.t)~=size(obj.Buffer.data, 3)
                    error('Data and time stamp lengths are unequal');
                end
                [obj.Height, obj.Width, obj.NFrames] = size(obj.Buffer.data);
                obj.FrameRate = (obj.NFrames-1) / ((obj.Buffer.t(end)-obj.Buffer.t(1))*24*60*60);     
            else
                error('Unknown file format (needs to contain fields ''data'' and ''ts'').');
            end
            
        end

        function [im, t] = readFrame(obj, fnr, ~)
            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            im = obj.Buffer.data(:, :, fnr);
            t  = 0;
        end
    end
end

