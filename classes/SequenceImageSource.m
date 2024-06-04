classdef SequenceImageSource < ImageSource
    %SEQUENCEIMAGESOURCE handles an image sequence (consecutively numbered) as an image source
    
% TODO: in saving, remember framerate for sequences

    properties
        NFrames
        Height
        Width
        NChannels
        FrameRate
        ImPara % contains the fields .from, .to, .padding, and .ext describing the image sequence parameters
    end
    
    properties (Hidden, Access=protected)
        FileName
    end

    methods
        function obj = SequenceImageSource(para)
            % opens an image sequence
            %
            % use obj.readFrame(fnr) or obj.readFrameRange([fnr1 fnr2]) to obtain frames
        
            if isempty(para.paths.movpath) % image names are numbers only
                obj.FileName = sprintf('%s%s', fileparts(para.paths.movpath), filesep);
            else
                obj.FileName = fullfile(fileparts(para.paths.movpath), para.paths.movname);
            end
            obj.ImPara = para.imseq;
            disp(['Opening image sequence ', obj.FileName, ', file numbers ' num2str(obj.ImPara.from), ' to ', num2str(obj.ImPara.to), ', padding ', num2str(obj.ImPara.padding), '.']);
            info = imfinfo(obj.getFileName(1));
            obj.NFrames = obj.ImPara.to - obj.ImPara.from + 1;
            obj.Height  = info.Height;
            obj.Width   = info.Width;
            obj.NChannels = info.NumberOfSamples;
            temp = inputdlg('Please enter the frame rate for this image sequence:', 'Frame rate', 1, {'25'});
            obj.FrameRate = str2double(temp{1});
        end

        function [im, t] = readFrame(obj, fnr, ~)
            % SequenceImageSource.readFrame(fnr, updateBuffer) reads the frame with number 'fnr' from an image sequence.
            %
            % Returns image im as a HxWxC matrix, where H, W and C are image height, width and colour channels.
            % Returns timestamp t as a vector in seconds, relative to the video start (based on framerate). 

            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            im = imread(obj.getFileName(fnr));
            t  = (fnr-1)/obj.FrameRate;
        end
    end

    methods (Hidden, Access=protected)
        function fn = getFileName(obj, fnr)
            fn = sprintf(['%s%0' num2str(obj.ImPara.padding) '.0f%s'], obj.FileName, obj.ImPara.from+fnr-1, obj.ImPara.ext);
        end
    end
end

