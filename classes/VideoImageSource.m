classdef VideoImageSource < ImageSource
    %VIDEOIMAGESOURCE Summary of this class goes here
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
        FileHandle
        UseMMRead(1,1) logical
        BufferSize(1,1) double
        BufferOverlap(1,1) double
        Buffer
    end
    
    methods
        function obj = VideoImageSource(para)
            % opens a high definition video file            
            disp(['Opening hd video file ', para.paths.movpath]);
    
            obj.UseMMRead = para.usemmread;
            obj.FileName  = para.paths.movpath;

            if ~obj.UseMMRead
                % use VideoReader, the internal MATLAB function
                obj.FileHandle = VideoReader(obj.FileName);
                obj.NFrames    = obj.FileHandle.NumberOfFrames;
                obj.Height     = obj.FileHandle.Height;
                obj.Width      = obj.FileHandle.Width;
                obj.FrameRate  = obj.FileHandle.FrameRate;
                if isempty(obj.FrameRate)
                    error('Fatal error: Number of frames could not be determined due to codec issues. Try using mmread.');
                end
            else
                % store buffer parameters
                obj.BufferSize = para.mmreadsize;
                obj.BufferOverlap = para.mmreadoverlap;

                % and first frame to get meta data
                obj.Buffer.range = 1;
                video = mmread(obj.FileName, obj.Buffer.range, [], false, true);%, '', 1, 1);
                obj.Buffer.t = video.frames;
                obj.Buffer.images = video.frames;

    
                obj.NFrames = video.nrFramesTotal;
                if obj.NFrames==0
                    error('Fatal error: Number of frames could not be determined. Don''t even try tracking before this error is resolved!');
                elseif obj.NFrames<0
                    obj.NFrames=abs(obj.NFrames);
                    warning('Number of frames estimated from time and frame rate. This might be inaccurate. Enter an exact number into the parameter file if needed (not implemented yet).');
                end
                obj.Height = video.height;
                obj.Width = video.width;
                obj.FrameRate = video.rate;

                % Now load the first buffer
                obj.loadFrameIntoBuffer(1);
            end
        end

        function [im, t] = readFrame(obj, fnr, justOneFrame)
            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            if nargin<3
                justOneFrame = false; % used to load just one frame, e.g. for reference
            end
            if ~obj.UseMMRead
                % use VideoReader, the internal MATLAB function
                im = read(obj.FileHandle, fnr);
                t  = 0;
            else
                if ~ismember(fnr, obj.Buffer.range)
                    if justOneFrame
                        % Just read a single frame; leave the buffer untouched
                        video = mmread(obj.FileName, fnr, [], false, true);%, '', 1, 1);
                        im    = video.frames;
                        t     = video.times;
                        return
                    else
                        obj.loadFrameIntoBuffer(fnr);
                    end
                else
                    % this frame is already in the buffer
                end

                % return requested frame from buffer
                im = obj.Buffer.data(obj.Buffer.range==fnr).cdata;
                t  = obj.Buffer.t(obj.Buffer.range==fnr);
            end
        end
    end

    methods (Hidden, Access=protected)
        function loadFrameIntoBuffer(obj, fnr)
            % Loads the frame chunk that a given frame number belongs to

            hh = waitbar(0, 'Reading new frame block...', 'windowstyle', 'modal');
            % determine new range and read new chunk
            
            try
                x1 = floor((fnr-1)/obj.BufferSize)*obj.BufferSize+1-obj.BufferOverlap;
                x2 = floor((fnr-1)/obj.BufferSize+1)*(obj.BufferSize)+obj.BufferOverlap;
                x1 = max([1 x1]); 
                x2 = min([obj.NFrames x2]);
                obj.Buffer.range = x1:x2;
                disp(['Reading new frame block from frame ' num2str(x1) ' to frame ', num2str(x2) '.']);
                video = mmread(obj.FileName, obj.Buffer.range, [], false, true);%, '', 1, 1);
                waitbar(1, hh);
                close(hh);
            catch me
                close(hh);
                rethrow(me);
            end
            obj.Buffer.data = video.frames;
            obj.Buffer.t = video.times;
        end
    end
end

