classdef (Abstract) ImageSource < handle
    %IMAGESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        NFrames(1,1) double
        Height(1,1) double
        Width(1,1) double
        FrameRate(1,1) double
        GreyScale(1,1) logical
    end
    
    properties (Abstract, Hidden, Access=protected)
        FileName
    end

    methods (Abstract)
        [im, t] = readFrame(obj, fnr, justOneFrame)
    end

    %%%%%%%%%%%%%%%%%%%%%%%
    %% Super-constructor %%
    %%%%%%%%%%%%%%%%%%%%%%%
    % This constructor chooses the right subclass. Use this as obj = ImageSource.create(para)

    methods (Static)
        function obj = create(para)
            if isfield(para, 'thermal') && isfield(para.thermal, 'isthermal') && para.thermal.isthermal
                obj = ThermalImageSource(para);
            elseif isfield(para, 'imseq') && isfield(para.thermal, 'isimseq') && para.imseq.isimseq
                obj = SequenceImageSource(para);
            else
                obj = VideoImageSource(para);
            end
        end
    end

    methods
        function obj = ImageSource(~)
            %IMAGESOURCE Construct an instance of this class
            %   Detailed explanation goes here
        end
    end
end

