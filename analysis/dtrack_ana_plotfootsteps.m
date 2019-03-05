function dtrack_ana_plotpaths(h, data, status, para)
        
            colors={'b', 'b', 'b', 'r', 'r', 'r', 'k', 'w'};
            colors={'b', 'r', 'g', 'y', 'm', 'c', 'k', 'w'};
            smfact=20;
            for jj=1:size(data.points, 2)
                ps{jj}=squeeze(data.points(data.points(:, jj, 3)~=0, jj, 1:2)); %these are all the tracked points
                frame{jj}=find(data.points(:, jj, 3)~=0); %and their frame numbers
            end
            
            %calculate body axis
            bodyx=mean([ps{7}(1:end, 1),ps{8}(1:end, 1)], 2);
            bodyy=mean([ps{7}(1:end, 2),ps{8}(1:end, 2)], 2);
            bodyaxis=ps{7}-ps{8}; %vector from tail for head
            
            %extract stride periods
            stride{4}=[frame{4}(1);dtrack_findnextmarker(data, 1, 'a', 'all');frame{4}(end)]; %front left leg, point 4
            stride{5}=[frame{5}(1);dtrack_findnextmarker(data, 1, 'b', 'all');frame{5}(end)];
            stride{6}=[frame{6}(1);dtrack_findnextmarker(data, 1, 'c', 'all');frame{6}(end)];
            stride{1}=[frame{1}(1);dtrack_findnextmarker(data, 1, 'd', 'all');frame{1}(end)];
            stride{2}=[frame{2}(1);dtrack_findnextmarker(data, 1, 'e', 'all');frame{2}(end)];
            stride{3}=[frame{3}(1);dtrack_findnextmarker(data, 1, 'f', 'all');frame{3}(end)];
            stride{7}=[frame{7}(1);frame{7}(end)];
            stride{8}=[frame{8}(1);frame{8}(end)];
            
            %define striding/standing periods (1/0)
            for i=1:size(data.points, 2)
                if strcmp(para.paths.movname(12:13), 'E3')
                    phase=0; %all legs standing in first frame
                else
                    switch i
                        case {2,4,6}, phase=1; %nextphase is striding
                        case {1,3,5,7,8}, phase=0;
                    end
                end
                for j=1:length(stride{i})
                    striding{i}(j)=phase;  %is the next segment a stride? 1/0
                    phase=1-phase; %next phase is the opposite of this phase
                end
            end
            
            %calculate transformation to body coordinate system
            for ii=1:length(frame{7})
                %calculate transformation
                bodyaxis_n{ii}=bodyaxis(ii, :)/norm(bodyaxis(ii, :), 2);   %unit vector from tail for head
                bodyperp_n{ii}=null(bodyaxis_n{ii}); %needs size [1 2]
                bodytrans{ii}=[bodyaxis_n{ii}', bodyperp_n{ii}];
                %quiver(bodyx(ii), bodyy(ii), bodyaxis_n{ii}(1), bodyaxis_n{ii}(2));
                %quiver(bodyx(ii), bodyy(ii), bodyperp_n{ii}(1), bodyperp_n{ii}(2));
                for jj=1:size(data.points, 2)
                    ps_n{jj}(ii, :)=mldivide(bodytrans{ii}, ps{jj}(ii, :)');
                end
                temp=mldivide(bodytrans{ii}, [bodyx(ii);bodyy(ii)]);
                bodyx_n(ii)=temp(1);
            end
            
            %plot raw tracks
            figure(8);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            for jj=1:size(data.points, 2) %for each body part
                if ~isempty(frame{jj}) %if there are valid tracked frames
                    xx=smooth(ps{jj}(:, 1), smfact)/1.822; % smooth the track
                    yy=smooth(ps{jj}(:, 2), smfact)/1.822; % smooth the track
                    for j=1:length(stride{jj})-1 %plot striding and standing seperately
                        thisx=(stride{jj}(j):stride{jj}(j+1))-frame{jj}(1)+1; %these are the frame numbers used in this segment
                        plot(xx(thisx), yy(thisx), [colors{jj} '.-'], 'markersize', 1+striding{jj}(j), 'linewidth', 1+3*striding{jj}(j)); %1 means no smoothing
                    end
                end
            end
            set(gca, 'color', [.5 .5 .5], 'YDir', 'reverse');
            xlabel('x position (mm)'); ylabel('y position (mm)');axis equal

            %plot tracks with  footsteps
            figure(9);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            for jj=1:6 %for each leg
                if ~isempty(frame{jj}) %if there are valid tracked frames
                    xx=smooth(ps{jj}(:, 1), smfact)/1.822; % smooth the track
                    yy=smooth(ps{jj}(:, 2), smfact)/1.822; % smooth the track
                    for j=1:length(stride{jj})-1 %plot striding and standing seperately
                        thisx=(stride{jj}(j):stride{jj}(j+1))-frame{jj}(1)+1; %these are the frame numbers used in this segment
                        if striding{jj}(j)
                            %plot(xx(thisx), yy(thisx), [colors{jj} '.-'], 'markersize', 1+striding{jj}(j), 'linewidth', 1); %1 means no smoothing
                        elseif ismember(jj, [3,6]) && strcmp(para.paths.movname(12:13), 'E3')
                            %dragging hindlegs
                            plot(xx(thisx), yy(thisx), [colors{jj} '-'], 'markersize', 1, 'linewidth', 1); %1 means no smoothing
                        else
                            %average standing periods
                            plot(median(xx(thisx)), median(yy(thisx)), [colors{jj} '.'], 'markersize', 20, 'linewidth', 1); %1 means no smoothing
                        end
                    end
                end
            end
            %plot body axis every 15 frames
            xx=[smooth(ps{7}(:, 1), smfact),smooth(ps{8}(:, 1), smfact)]/1.822; % smooth the track
            yy=[smooth(ps{7}(:, 2), smfact),smooth(ps{8}(:, 2), smfact)]/1.822; % smooth the track
            
            thisx=frame{7}(1:15:end)-frame{7}(1)+1; %these are the frame numbers used for body axis plotting
            plot(xx(thisx, :)', yy(thisx, :)', [colors{7} '-'], 'markersize', 1, 'linewidth', 1); %1 means no smoothing
                      
            
            
            
            set(gca, 'color', [.5 .5 .5], 'YDir', 'reverse')%, 'visible', 'off');
            xlabel('x position (mm)'); ylabel('y position (mm)');axis equal
            
            
            
            
            
            
            