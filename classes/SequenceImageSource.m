classdef SequenceImageSource < ImageSource
    %SEQUENCEIMAGESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
% TODO: in saving, remember framerate for sequences

    properties
        NFrames
        Height
        Width
        FrameRate
        GreyScale = false; % by default, not a greyscale sequence
        ImPara % contains the fields .from, .to, .padding, and .ext describing the image sequence parameters
    end
    
    properties (Hidden, Access=protected)
        FileName
    end

    methods
        function obj = SequenceImageSource(para)
        % opens an image sequence
        %
        % use frame=read(mh, frame) to obtain frames
        
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
            switch info.ColorType
                case 'grayscale'
                    obj.GreyScale = true;
                case 'truecolor'
                    obj.GreyScale = false;
                case 'indexed'
                    obj.GreyScale = false;
                    warning('Indexed images have not been tested. Good luck!');
            end
            temp = inputdlg('Please enter the frame rate for this image sequence:', 'Frame rate', 1, {'25'});
            obj.FrameRate = str2double(temp{1});
        end

        function [im, t] = readFrame(obj, fnr, ~)
            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            im = imread(obj.getFileName(fnr));
            t  = 0;
        end
    end

    methods (Hidden, Access=protected)
        function fn = getFileName(obj, fnr)
            fn = sprintf(['%s%0' num2str(obj.ImPara.padding) '.0f%s'], obj.FileName, obj.ImPara.from+fnr-1, obj.ImPara.ext);
        end
    end
end

