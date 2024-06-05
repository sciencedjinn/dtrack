classdef VideoImageSource < ImageSource
    % VIDEOIMAGESOURCE handles a video as an image source
    
    properties
        NFrames
        Height
        Width
        NChannels
        FrameRate
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
                    error('Fatal error: Frame rate could not be determined due to codec issues. Try using mmread.');
                end
                % read first frame to get number of channels
                im = read(obj.FileHandle, 1);
                obj.NChannels = size(im, 3);

            else
                % store buffer parameters
                obj.BufferSize = para.mmreadsize;
                obj.BufferOverlap = para.mmreadoverlap;

                % read first frame to get meta data
                obj.Buffer.range = 1;
                video = mmread(obj.FileName, obj.Buffer.range, [], false, true);
                obj.Buffer.t = video.frames;
                obj.Buffer.images = video.frames;
    
                obj.NFrames = video.nrFramesTotal;
                if obj.NFrames==0
                    error('Fatal error: Number of frames could not be determined. Don''t even try tracking before this error is resolved!');
                elseif obj.NFrames<0
                    obj.NFrames=abs(obj.NFrames);
                    warning('Number of frames estimated from time and frame rate. This might be inaccurate. Enter an exact number into the parameter file if needed (not implemented yet).');
                end
                obj.Height    = video.height;
                obj.Width     = video.width;
                obj.NChannels = size(video.frames.cdata, 3);
                obj.FrameRate = video.rate;

                % Now load the first buffer
                obj.loadFrameIntoBuffer(1);
            end
        end

        function  [ims, ts] = readFrames(obj, fnrs)
            % VideoImageSource.readFrames(fnrs) reads the frames in frame number array fnrs from a video.
            % 
            % Returns images ims as a HxWxCxF matrix, where H, W and C are image height, width and colour channels, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if any(fnrs<1 | fnrs>obj.NFrames)                
                error('Invalid frames (frames 1-%d available)', obj.NFrames)
            end
            
            if ~obj.UseMMRead
                % use VideoReader, the internal MATLAB function
                [ims, ts] = readFrames@ImageSource(obj, fnrs); % use the superclass method to read frames one-by-one
            else
                % use mmread
                if all(ismember(fnrs, obj.Buffer.range))
                    sel = ismember(obj.Buffer.range, fnrs);
                    ims = obj.Buffer.data(sel).cdata;
                    ts  = obj.Buffer.t(sel);
                else
                    video = mmread(obj.FileName, fnrs, [], false, true);
                    ims   = video.frames;
                    ts    = video.times/1000;
                end
            end
        end

        function  [ims, ts] = readFrameRange(obj, fnRange)
            % VideoImageSource.readFrameRange(fnRange) reads the frames fnRange(1) to fnRange(2) from an image source. The buffer is not updated.
            % 
            % Returns images ims as a HxWxCxF matrix, where H, W and C are image height, width and colour channels, and F is the number of frames.
            % Returns timestamps ts as a vector in seconds. 

            if length(fnRange)~=2 || fnRange(1)>fnRange(2)
                error('Input argument fnRange must have two elements indicating an (inclusive) range');
            end
            if any(fnRange<1 | fnRange>obj.NFrames)                
                error('Invalid frame range: %d-%d (frames 1-%d available)', fnRange(1), fnRange(2), obj.NFrames)
            end
            
            if ~obj.UseMMRead
                % use VideoReader, the internal MATLAB function
                ims = read(obj.FileHandle, fnRange);
                ts  = (fnRange(1)-1:fnRange(2)-1)/obj.FrameRate;
            else
                % use mmread
                if all(ismember(fnRange, obj.Buffer.range))
                    sel = obj.Buffer.range>=fnRange(1) & obj.Buffer.range<=fnRange(2);
                    ims = obj.Buffer.data(sel).cdata;
                    ts  = obj.Buffer.t(sel);
                else
                    video = mmread(obj.FileName, fnRange(1):fnRange(2), [], false, true);
                    ims   = video.frames;
                    ts    = video.times/1000;
                end
            end
        end

        function [im, t] = readFrame(obj, fnr, updateBuffer)
            % VideoImageSource.readFrame(fnr, updateBuffer) reads the frame with number 'fnr' from an image source. If
            % updateBuffer is true (default), the function loads a new frame chunk into the buffer, if needed. 
            %
            % Returns image im as a HxWxC matrix, where H, W and C are image height, width and colour channels.
            % Returns timestamp t as a vector in seconds. 

            if fnr<1 || fnr>obj.NFrames
                error('Invalid frame number: %d (frames 1-%d available)', fnr, obj.NFrames)
            end
            if nargin<3
                updateBuffer = true; % set to false to load just the requested frames, e.g. for reference
            end
            if ~obj.UseMMRead
                % use VideoReader, the internal MATLAB function
                im = read(obj.FileHandle, fnr);
                t  = (fnr-1)/obj.FrameRate;
            else
                if ~ismember(fnr, obj.Buffer.range)
                    if ~updateBuffer
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
                video = mmread(obj.FileName, obj.Buffer.range, [], false, true);
                waitbar(1, hh);
                close(hh);
            catch me
                close(hh);
                rethrow(me);
            end
            obj.Buffer.data = video.frames;
            obj.Buffer.t    = video.times/1000;
        end
    end
end

