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
        function  [ims, ts] = readFrameRange(obj, fnrs)
            % ImageSource.readFrameRange(fnrs) reads the frames fnrs(1) to fnrs(2) from an image source.
            % This default function works by loading each frame individually. 
            % Depending on the subclass, this can be overwritten with a more efficient implementation.
            %
            % Returns images ims as a HxWxCxF matrix, where H, W and C are image height, width and colour channels, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if length(fnrs)~=2 || fnrs(1)>fnrs(2)
                error('Input argument fnrs must have two elements indicating an (inclusive) range');
            end
            if any(fnrs<1 | fnrs>obj.NFrames)                
                error('Invalid frame range: %d-%d (frames 1-%d available)', fnrs(1), fnrs(2), obj.NFrames)
            end
                
            ims = zeros(obj.Height, obj.Width, obj.NChannels, fnrs(2)-fnrs(1)+1);
            ts = zeros(fnrs(2)-fnrs(1)+1, 1);
            for fnr = fnrs(1):fnrs(2)
                ind = fnr-fnrs(1)+1;
                [ims(:, :, :, ind), ts(ind)] = obj.readFrame(fnr);
            end
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

