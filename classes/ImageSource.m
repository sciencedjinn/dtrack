classdef (Abstract) ImageSource < handle
    % IMAGESOURCE represents a source of video, photo or thermal images for dtrack
    %   Subclasses must implement the specific functions to open and read from an image source.
    %
    %   Usage (the correct class will be selected based on the data in para): 
    %       obj = ImageSource.create(para)

    % Examples for debugging and testing:
    % 1. Video source (w/o mmread)
    %     [status, para, data] = dtrack_defaults;
    %     para.paths.movpath = 'D:\matlab\dtrack\tests\00176.avi';
    %     I = ImageSource.create(para)
    %
    % 2. Video source (with mmread)
    %     [status, para, data] = dtrack_defaults;
    %     para.usemmread = true;
    %     para.paths.movpath = 'D:\matlab\dtrack\tests\00176.avi';
    %     I = ImageSource.create(para)
    %
    % 3. Image sequence source
    %     [status, para, data] = dtrack_defaults;
    %     para.imseq.isimseq = true;
    %     para.imseq.from    = 1;
    %     para.imseq.to      = 100;
    %     para.imseq.padding = 3;
    %     para.imseq.ext     = '.jpg';
    %     para.paths.movpath = 'D:\matlab\dtrack\tests\00176_imseq\';
    %     para.paths.movname = '00176_';
    %     I = ImageSource.create(para)
    %
    % 4. Thermal video source
    %     [status, para, data] = dtrack_defaults;
    %     para.thermal.isthermal = true;
    %     para.paths.movpath = 'D:\matlab\dtrack\tests\HvC_110223_0031_U04_c.mat';
    %     I = ImageSource.create(para)
    
    properties (Abstract)
        NFrames(1,1) double   % the total number of frames available
        Height(1,1) double    % image height, in pixels
        Width(1,1) double     % image width, in pixels
        NChannels(1,1) double % number of colour channels, e.g. 3 for RGB images, or 1 for grayscale
        FrameRate(1,1) double % frame rate, in frames per second
    end

    properties (Dependent)
        GreyScale(1,1) logical % whether this is a greyscale
    end

    properties (Abstract, Hidden, Access=protected)
        FileName
    end

    methods (Abstract)
        [im, t] = readFrame(obj, fnr, updateBuffer)
    end

    %%%%%%%%%%%%%%%%%%%%%%%
    %% Super-constructor %%
    %%%%%%%%%%%%%%%%%%%%%%%
    % This constructor chooses the right subclass. Use this as obj = ImageSource.create(para)

    methods (Static)
        function obj = create(para)
            if isfield(para, 'thermal') && isfield(para.thermal, 'isthermal') && para.thermal.isthermal
                obj = ThermalImageSource(para);
            elseif isfield(para, 'imseq') && isfield(para.imseq, 'isimseq') && para.imseq.isimseq
                obj = SequenceImageSource(para);
            else
                obj = VideoImageSource(para);
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%
    %% Public methods %%
    %%%%%%%%%%%%%%%%%%%%%%%
    methods
        function [ims, ts] = readFrames(obj, fnrs)
            % ImageSource.readFrames(fnrs) reads the frames in frame number array fnrs from an image source.
            % This default function works by loading each frame individually. 
            % Depending on the subclass, this can be overwritten with a more efficient implementation.
            %
            % Returns images ims as a HxWxCxF matrix, where H, W and C are image height, width and colour channels, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 
            
            if any(fnrs<1 | fnrs>obj.NFrames)                
                error('Invalid frames (frames 1-%d available)', obj.NFrames)
            end
                
            ims = zeros(obj.Height, obj.Width, obj.NChannels, length(fnrs));
            ts  = zeros(length(fnrs), 1);
            for ind = 1:length(fnrs)
                [ims(:, :, :, ind), ts(ind)] = obj.readFrame(fnrs(ind));
            end
        end

        function [ims, ts] = readFrameRange(obj, fnRange)
            % ImageSource.readFrameRange(fnRange) reads the frames fnRange(1) to fnRange(2) from an image source.
            % This default function works by loading each frame individually. 
            % Depending on the subclass, this can be overwritten with a more efficient implementation.
            %
            % Returns images ims as a HxWxCxF matrix, where H, W and C are image height, width and colour channels, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if length(fnRange)~=2 || fnRange(1)>fnRange(2)
                error('Input argument fnRange must have two elements indicating an (inclusive) range');
            end
            if any(fnRange<1 | fnRange>obj.NFrames)                
                error('Invalid frame range: %d-%d (frames 1-%d available)', fnRange(1), fnRange(2), obj.NFrames)
            end
                
            [ims, ts] = obj.readFrames(obj, fnRange(1):fnRange(2));
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get methods for dependent properties %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function gs = get.GreyScale(obj)
            gs = obj.NChannels==1;
        end
    end
end

