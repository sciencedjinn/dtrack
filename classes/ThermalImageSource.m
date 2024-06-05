classdef ThermalImageSource < ImageSource
    %THERMALIMAGESOURCE handles a thermal video as an image source
    
    properties
        NFrames
        Height
        Width
        NChannels = 1;
        FrameRate
        Buffer
    end

    properties (Hidden, Access=protected)
        FileName
    end

    methods
        function obj = ThermalImageSource(para)
            % opens a thermal camera file
            %
            % use obj.readFrame(fnr) or obj.readFrameRange([fnr1 fnr2]) to obtain frames
        
            obj.FileName   = para.paths.movpath;
            disp(['Opening FLIR video file ', obj.FileName]);
            temp = load(obj.FileName, '-mat');
            if isfield(temp, 'data') && isfield(temp, 'ts')
                obj.Buffer.data = temp.data;
                obj.Buffer.t    = temp.ts*24*60*60; % in seconds
                if length(obj.Buffer.t)~=size(obj.Buffer.data, 3)
                    error('Data and time stamp lengths are unequal');
                end
                [obj.Height, obj.Width, obj.NFrames] = size(obj.Buffer.data);
                obj.FrameRate = (obj.NFrames-1) / ((obj.Buffer.t(end)-obj.Buffer.t(1)));     
            else
                error('Unknown file format (needs to contain fields ''data'' and ''ts'').');
            end
            
        end

        function  [ims, ts] = readFrames(obj, fnrs)
            % ThermalImageSource.readFrames(fnrs) reads the frames in frame number array fnrs. 
            % 
            % Returns images ims as a HxWx1xF matrix, where H and W are image height and width, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if any(fnrs<1 | fnrs>obj.NFrames)                
                error('Invalid frames (frames 1-%d available)', obj.NFrames)
            end
            
            ims = obj.Buffer.data(:, :, fnrs);
            ims = reshape(ims, [size(ims, 1), size(ims, 2), 1, size(ims, 3)]);
            ts  = obj.Buffer.t(fnrs);
        end

        function  [ims, ts] = readFrameRange(obj, fnrs)
            % ThermalImageSource.readFrameRange(fnrs) reads the frames fnrs(1) to fnrs(2). 
            % 
            % Returns images ims as a HxWx1xF matrix, where H and W are image height and width, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if length(fnrs)~=2 || fnrs(1)>fnrs(2)
                error('Input argument fnrs must have two elements indicating an (inclusive) range');
            end
            if any(fnrs<1 | fnrs>obj.NFrames)                
                error('Invalid frame range: %d-%d (frames 1-%d available)', fnrs(1), fnrs(2), obj.NFrames)
            end
            
            ims = obj.Buffer.data(:, :, fnrs(1):fnrs(2));
            ims = reshape(ims, [size(ims, 1), size(ims, 2), 1, size(ims, 3)]);
            ts  = obj.Buffer.t(fnrs(1):fnrs(2));
        end

        function [im, t] = readFrame(obj, fnr, ~)
            % ThermalImageSource.readFrame(fnr, updateBuffer) reads the frame with number 'fnr'.
            %
            % Returns image im as a HxW matrix, where H and W image height and width.
            % Returns timestamp t as a vector in seconds. 

            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            im = obj.Buffer.data(:, :, fnr);
            t  = obj.Buffer.t(fnr);
        end
    end
end

