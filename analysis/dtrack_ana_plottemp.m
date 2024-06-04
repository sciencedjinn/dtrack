function dtrack_ana_plottemp(h, data, status, para)
%plot the temperature profile of all tracked points
%parts of this are currently very specific to the analysis of beetle body
%temperatures in hot and cold arena videos

    %% initialise
    cla(h);
    temper=nan(size(data.points, 1), size(data.points, 2)); %will hold averaged temperatures of frame,point
    
    %% variables
    mintemp=28; maxtemp=54; %min and max to plot
    filtering=[3 1 1 1 5 1]; %average pixel values over x-by-x pixels (default 1: no filtering, just take nearest neighbour). Works with odd numbers (rounded down when even)
    %1:ball, 2-3: legs, 4:abdomen, 5:ground, 6:head/thorax
    %col={'b', 'r', 'm', 'c', 'k', 'g', 'y'};while size(data.points, 2)>length(col),col=[col {'b', 'r', 'm', 'c', 'k', 'g', 'y'}];end %define colors for the different points
    col=[0 0 1;1 0 0;1 0 1;0 1 1;0 0 0;0 1 0;1 1 0];while size(data.points, 2)>size(col, 1),col=[col;col];end %define colors for the different points
    set(h, 'colororder', col); %set this as the default color order
    ts=(status.mh.Buffer.t-status.mh.Buffer.t(1)); %all timestamps in seconds normalised to start
    
    %% calculate temperatures
    for i=1:size(data.points, 2) %for each point number
        sel=find(data.points(:, i, 3)); %find all valid entries
        %if ~isempty(sel)
            for j=1:length(sel)
                f=floor(filtering/2); %how many pixels plus and minus to average
                thisset=status.mh.Buffer.data(round(data.points(sel(j), i, 2))-f:round(data.points(sel(j), i, 2))+f, round(data.points(sel(j), i, 1))-f:round(data.points(sel(j), i, 1))+f, sel(j));
                temper(sel(j), i)=mean(thisset(:))-273.15; %take the mean of temperature values and correct to Celsius
            end
            %plot(h, ts(sel), temper, ['.' col{i}]); hold all;%and plot the temperature values.
        %end
    end
    
    %% find all markers and plot them
    rs=dtrack_findnextmarker(data, 1, ['s';'r'], 'all'); %list of frames of all r (roll) markers
    ds=dtrack_findnextmarker(data, 1, 'd', 'all'); %list of frames of all d (dance) markers
    es=dtrack_findnextmarker(data, 1, 'e', 'all'); %list of frames of all d (dance) markers
    %e marker is added to whatever is missing
    if max([rs;ds])>es
        %do nothing
    elseif max(rs)>max(ds)
        ds=[ds;es];
    else %max(rs)<=max(ds)
        rs=[rs;es];
    end
    allfms=unique(sort([rs;ds])); %all frames that have any markers    
    % plot block borders
    for i=allfms'
        plot(h, [ts(i) ts(i)], [mintemp maxtemp], 'k'); %plot vetical lines at the block borders
        text(ts(i)+0.5, mintemp+1, data.markers(i).m, 'parent', h); %plot which marker it is
    end
    % plot block color lines
    if length(rs)>length(ds) %start and end on an r %TODO: this clause is still untested
        plot(h, [ts(rs(1:end-1));ts(ds)], maxtemp*ones(size([ts(rs(1:end-1));ts(ds)])), 'r', 'linewidth', 5); %red line for roll periods
        plot(h, [ts(ds);ts(rs(2:end))], maxtemp*ones(size([ts(ds);ts(rs(2:end))])), 'b', 'linewidth', 5); %blue line for dance periods
    elseif length(ds)==length(rs) %we end on a dance, normal situation
        plot(h, [ts(rs);ts(ds)], maxtemp*ones(size([ts(rs);ts(ds)])), 'r', 'linewidth', 5); %red line for roll periods
        plot(h, [ts(ds(1:end-1));ts(rs(2:end))], maxtemp*ones(size([ts(ds(1:end-1));ts(rs(2:end))])), 'b', 'linewidth', 5); %blue line for dance periods
    else
        error('More dance markers than roll markers');
    end
    
    %% now plot individual points 
    %ORIGINAL: just this: line(ts, temper, 'marker', '.', 'linestyle', 'none', 'parent', h); %plot all tracked points

%     legs=nanmean(temper(:, 2:3), 2);
%     wind=2; %average every time point plus/minus window
%     for i=1:length(legs)
%         legs_filt(i)=nanmean(legs(max([1 i-wind]):min([i+wind length(legs)])));
%     end
    line(ts, temper(:, 3), 'marker', '.', 'linestyle', 'none', 'parent', h, 'color', col(3, :)); %plot all tracked points
    line(ts, temper(:, 2), 'marker', '.', 'linestyle', 'none', 'parent', h, 'color', col(4, :)); %plot all tracked points
    line(ts, temper(:, 6), 'marker', '.', 'linestyle', 'none', 'parent', h, 'color', col(6, :)); %plot all tracked points
    
    %for M06_thorax data set: 1-6=ball/head/right leg/abdomen/ground/thorax
    
    %% and plot regression curves per segment
    % also collects all points during dances; these will be written to base
    % for later analysis over all setups
    alldances=[];
    for i=1:length(allfms)-1 %for each block
        for j=[2 3 6] %1:size(data.points, 2) %for each point number
            sel=find(~isnan(temper(allfms(i):allfms(i+1)-1, j)))+allfms(i)-1; %find all frames within the current roll or dance period
            x=ts(sel);x0=ts(allfms(i));
            y=temper(sel, j);
                      
            if ~isempty(sel) && ismember(j, [2 3]) && ismember(allfms(i), ds) %if this is a dance, and the point is a leg, enter data into average array
                alldances=[alldances;[(x-x0)' y]];
            end
            if nnz(sel)>=5 %only calculate a fit if 5 or more points were tracked in this block
                rfit=robustfit(x, y);
                line(x, rfit(1)+rfit(2)*x, 'color', col(j, :), 'parent', h); hold all; %and plot the temperature values.
            end
        end
    end
    
    disp(['Mean +- std ball temp: ' num2str(nanmean(temper(:, 1))) ' +- ' num2str(nanstd(temper(:, 1)))]);
    disp(['Mean +- std ground temp: ' num2str(nanmean(temper(:, 5))) ' +- ' num2str(nanstd(temper(:, 5)))]);
    
    %% plot maintenance
    xlabel('Time (s)');
    ylabel('Temperature (\circC)');
    axis([min(ts) max(ts) mintemp-5 maxtemp+5]);
    
    %% plot all dances normalised to start time in figure 9

%return;
    if ~isempty(alldances)    
        assignin('base', ['alld_' para.paths.movname(end-8:end-6)], alldances);
        figure(9);clf;plot(alldances(:, 1), alldances(:, 2)-273.15, 'b.'); hold all;
        rfit=robustfit(alldances(:, 1), alldances(:, 2)-273.15);
        plot(alldances(:, 1), rfit(1)+rfit(2)*alldances(:, 1), 'k'); 
        sel=alldances(:, 1)<=10;
        rfit2=robustfit(alldances(sel, 1), alldances(sel, 2)-273.15);
        plot(alldances(sel, 1), rfit2(1)+rfit2(2)*alldances(sel, 1), 'r'); 
        title(['Protibial temperature during dance (int:' num2str(rfit(1)) ', sl:' num2str(rfit(2)) ') (int:' num2str(rfit2(1)) ', sl:' num2str(rfit2(2)) ')']);
        xlabel('Time (s)');
        ylabel('Temperature (\circC)');
    end
return;

%% Do this after running all 7
alld=[alld_K05; alld_M02; alld_M06; alld_M11; alld_M51; alld_N05;alld_N08];
%save('alld', 'alld')
%sel=alld(:, 1)<20;
bw=0.233;
bins=0:bw:10;
for i=1:length(bins)
   sel=alld(:, 1)>=bins(i)-bw/2 & alld(:, 1)<bins(i)+bw/2;
   y(i)=nanmean(alld(sel, 2));
   n(i)=nnz(~isnan(alld(sel, 2)));
   ste(i)=nanstd(alld(sel, 2))/sqrt(n(i));
end

figure(10);clf;errorbar(bins, y, ste, ste, 'b.');hold on;
%figure(10);clf;plot(alld(sel, 1), alld(sel, 2)-273.15, 'b.');hold on;
rfit=robustfit(alld(:, 1), alld(:, 2));
%plot(0:10, rfit(1)+rfit(2)*(0:10), 'k');
axis([-0.1 10.1 40 51]);

sel=alld(:, 1)<=10+bw/2;
    rfit2=robustfit(alld(sel, 1), alld(sel, 2));
    plot(alld(sel, 1), rfit2(1)+rfit2(2)*alld(sel, 1), 'r'); 
    %title(['Protibial temperature during dance (int:' num2str(rfit(1)) ', sl:' num2str(rfit(2)) ') (int:' num2str(rfit2(1)) ', sl:' num2str(rfit2(2)) ')']);
xlabel('Time after dance start (s)');
ylabel('Protibial temperature (\circC)');
grid on;
corr(alld(sel, 1), alld(sel, 2))
figure(11); boxplot(alld(:, 2), round(1*alld(:, 1)))/1;%grid minor
