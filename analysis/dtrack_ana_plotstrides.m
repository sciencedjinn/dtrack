function dtrack_ana_plotstrides(data, status, para)

%% THIS FUNCTION WAS USED FOR PACHYSOMA STRIDE TRACKING (Smolka et al 2014), BUT IS NOW REPLACED BY REL2BODY
warning('THIS FUNCTION WAS USED FOR PACHYSOMA STRIDE TRACKING (Smolka et al 2014), BUT IS NOW REPLACED BY REL2BODY');
 %This only works if all points have the same number of tracks
            clear ps frame bodyaxis bodyx bodyy ps_n
            %figure(5);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            %colors={'b', 'r', 'g', 'c', 'm', 'y', 'k', 'w'};
            colors={'b', 'b', 'b', 'r', 'r', 'r', 'k', 'w'};
            smfact=10;
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
            
            %plot raw tracks in body coordinate system
            figure(6);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            for jj=1:size(data.points, 2) %for each body part
                if ~isempty(frame{jj}) %if there are valid tracked frames
                    yy=smooth(ps_n{jj}(:, 1)-bodyx_n', smfact)/1.822; % smooth the track
                    for j=1:length(stride{jj})-1
                        thisx=(stride{jj}(j):stride{jj}(j+1)); %these are the frame numbers used in this segment
                        plot((thisx-frame{jj}(1))/0.3, yy(thisx-frame{jj}(1)+1), [colors{jj} '.-'], 'markersize', 1+striding{jj}(j), 'linewidth', 1+3*striding{jj}(j)); %1 means no smoothing
                    end
                end
            end
            set(gca, 'color', [.5 .5 .5]);
            xlabel('time (ms)'); ylabel('position relative to body centre (mm)');
            
            %find period
            figure(7);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            periods=[];
            for jj=[1 2 4 5] %leave out head and bum and back legs
                if ~isempty(frame{jj})
                    x=(frame{jj}-frame{jj}(1));
                    t=(frame{jj}-frame{jj}(1))/0.3;
                    y=(ps_n{jj}(:, 1)-bodyx_n')/1.822;
                    ys=smooth(ps_n{jj}(:, 1)-bodyx_n', 20)/1.822;
                    plot(t,ys)
                    [ymax,xmax,ymin,xmin] = extrema(ys);
                    periods=[periods diff(sort(xmax))' diff(sort(xmin))'];
                    plot(t(xmax),ymax,'r*',t(xmin),ymin,'g*')
                end
            end
            medperiod1=median(periods)
            medperiod=median(periods(periods>0.9*medperiod1 & periods<1.1*medperiod1)) %do this twice for better period finding
            %figure(8);hist(periods, 30);
            
            %find average stride positions
            for jj=1:6
                mins=[];maxs=[];
                if ~isempty(frame{jj})
                    ys=smooth(ps_n{jj}(:, 1)-bodyx_n', 20)/1.822;
                    [ymax,xmax,ymin,xmin] = extrema(ys);
                    for i=2:length(stride{jj})-1 %first and last are just sequence beginning and end, so ignore
                        %find the closest maximum to this stride point
                        allmins=frame{jj}(xmin)-stride{jj}(i);
                        [~, closestmin_ind]=min(abs(allmins));
                        closestmin_dist=allmins(closestmin_ind);
                        allmaxs=frame{jj}(xmax)-stride{jj}(i);
                        [~, closestmax_ind]=min(abs(allmaxs));
                        closestmax_dist=allmaxs(closestmax_ind);
                        if abs(closestmin_dist)<abs(closestmax_dist)
                            %this is closest to a function minimum
                            mins=[mins closestmin_dist];
                        else
                            maxs=[maxs closestmax_dist];
                        end
                    end
                    minstridepos{jj}=circ_mean(mins'./medperiod*2*pi)/2/pi*medperiod;
                    maxstridepos{jj}=circ_mean(maxs'./medperiod*2*pi)/2/pi*medperiod;
                end
            end
            
           
            
            %average over period
            figure(8);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            figure(9);clf;set(gca, 'color', [.5 .5 .5]);hold on;
            for jj=1:size(data.points, 2)
                if ~isempty(frame{jj})
                    xr=1; %running time variable, use this to set a start point of the period
                    ally=[];allstride=[];
                    x=(frame{jj}-frame{jj}(1));
                    t=(frame{jj}-frame{jj}(1))/0.3;
                    y=(ps_n{jj}(:, 1)-bodyx_n')/1.822;
                    ys=smooth(ps_n{jj}(:, 1)-bodyx_n', 10)/1.822;
                    while xr+medperiod<max(x)
                        ally=[ally y(xr:xr+medperiod-1)];
%                         ind=find(stride{jj}>=frame{jj}(1)+xr-1 & stride{jj}<=frame{jj}(1)+xr+medperiod-2); %which stride markers are in this period
%                         switch length(ind)
%                             case 0
%                                 newstride=[0;medperiod];
%                             case 1
%                                 temp=stride{jj}(ind)-frame{jj}(xr);
%                                 newstride=[min([temp 0]);max([temp medperiod-1])];
%                             case 2
%                                 newstride=stride{jj}(ind)-frame{jj}(xr);
%                         end
%                         allstride=[allstride newstride];
                        xr=xr+medperiod; 
                    end
                    
                    %allstride
                    averagey=mean(ally, 2);
                    averagex=(0:medperiod-1)/0.3;
                    figure(8);
                    plot(averagex, ally);
                    figure(9);
                    %avgstride=mean(allstride, 2)
                    %stdstride=std(allstride, 0, 2)
                    %%%plot(averagex, ally, [colors{jj} '--'])
                    plot(averagex, smooth(averagey, smfact), [colors{jj} '-'], 'linewidth', 1.5)
                    
                    if (jj<7 && strcmp(para.paths.movname(12:13), 'S3')) || (jj<6 && jj~=3 && strcmp(para.paths.movname(12:13), 'E3'))
                        xxx=averagex;
                        yyy=smooth(averagey, smfact);
                        [ymax,xmax,ymin,xmin] = extrema(yyy);
                        if length(ymax>1), [ymax, ind]=max(ymax); xmax=xmax(ind);end
                        if length(ymin>1), [ymin, ind]=min(ymin); xmin=xmin(ind);end
                        
                        %plot strides over the top
                        stridestart=mod(round(xmin-minstridepos{jj}), medperiod);
                        strideend=mod(round(xmax-maxstridepos{jj}), medperiod);
                        if stridestart<strideend
                            plot(xxx(stridestart:strideend), yyy(stridestart:strideend), [colors{jj} '.-'], 'linewidth', 4);
                        else
                            plot(xxx(stridestart:end), yyy(stridestart:end), [colors{jj} '.-'], xxx(1:strideend), yyy(1:strideend), [colors{jj} '.-'], 'linewidth', 4);
                        end
                        %plot(xxx(xmin), ymin, 'k.', xxx(xmax), ymax, 'k.', xxx(mod(round(xmin-minstridepos{jj}), medperiod)), ymin, 'rx', xxx(mod(round(xmax-maxstridepos{jj}), medperiod)), ymax, 'bx');
                    end
%                     y=smooth(averagey, smfact)
%                     plot(averagex(1:avgstride(1)+1), y(1:avgstride(1)+1), [colors{jj} '.-'], 'linewidth', 1)
%                     plot(averagex(avgstride(1)+2:avgstride(2)+1), y(avgstride(1)+2:avgstride(2)+1), [colors{jj} '.-'], 'linewidth', 3)
%                     plot(averagex(avgstride(2)+2:end), y(avgstride(2)+2:end), [colors{jj} '.-'], 'linewidth', 1)
                    %%%plot([averagex averagex+medperiod], smooth([averagey; averagey], smfact), [colors{jj} '.'], 'linewidth', 2)
                end
            end
            set(gca, 'color', [.5 .5 .5]);
            xlabel('time (ms)'); ylabel('position relative to body centre (mm)');
            pdfsave(9, 'xpos');