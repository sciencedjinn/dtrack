function medtemper=dtrack_ana_balltrace(h, data, status, para)

% ball is in dance position from d to r marker, inclusively

%% initialise
    filtering=1; %f, averages temperatures over an fxf window
    f=floor(filtering/2); %how many pixels plus and minus to average
    fr=100;

%% find markers
    rs=dtrack_findnextmarker(data, 1, 'r', 'all'); %list of frames of all r (roll) markers
    ds=dtrack_findnextmarker(data, 1, 'd', 'all'); %list of frames of all d (dance) markers
    
    [ds rs rs-ds [ds(2:end)-rs(1:end-1);0]]
    
%% extract ball positions
    x=data.points(:, 1, 2);
    y=data.points(:, 1, 1);
    frames=find(data.points(:, 1, 3)); %find all valid entries
    for i=1:length(ds) %take out the ball positions during the dance, and just before/after
        frames(ismember(frames, ds(i)-2:rs(i)+2))=[];
    end
    length(frames)
    
%% create a temp array, which for each position has the fr frames before and after
    
    for j=1:length(frames)
        framerange=max([1 frames(j)-fr]):min([frames(j)+fr status.mh.NFrames]) %FIXME: currently only works if the whole 2*fr+1 frames are present
        
        thisset=status.mh.Buffer.data(round(x(frames(j))-f:x(frames(j))+f), round(y(frames(j))-f:y(frames(j))+f), framerange);
        for i=framerange
            %calculate the pixel distance between the ball position in this frame, and every other frame
            if i<frames(j) %if past frame
                dist(i-frames(j)+fr+1, j)=-norm([x(frames(j))-x(i) y(frames(j))-y(i)]);
            else %if future frame
                dist(i-frames(j)+fr+1, j)=norm([x(frames(j))-x(i) y(frames(j))-y(i)]);
            end
        end
        %if frames(j)<fr+1
            temper(:, j)=[nan(fr-frames(j)+1, 1);squeeze(mean(mean(thisset, 1), 2)-273.15);nan(fr-(status.mh.NFrames-frames(j)), 1)]; %mssing frames at the beginning
        %end
        %if frames(j)>status.mh.NFrames-fr
        %    temper(:, j)=[squeeze(mean(mean(thisset, 1), 2)-273.15);nan(fr-(status.mh.NFrames-frames(j)), 1)]; %mssing frames at the end
        %end
        %if frames(j)>=fr+1 && frames(j)>status.mh.NFrames-fr  %otherwise
        %    temper(:, j)=mean(mean(thisset, 1), 2)-273.15;
        %end
        %normalise to -5:10
        %temper(:, j)=temper(:, j)-mean(temper(fr+1-10:fr+1-5, j));
    end
    
    %% create a temp array only containing the dance points
    %TODO
    
    %% plot this
    plot(h, dist, temper, '.-'); hold all;%and plot the temperature values. 
    figure(9);clf;
    temper(abs(dist)<3)=NaN; %remove anythin where the ball is still closer than 1
    plot(-100:100, temper, '.-'); hold on;%and plot the temperature values over time. 
    medtemper=nanmedian(temper, 2);
    plot(-100:100, medtemper, 'r-', 'linewidth', 3); %and plot the temperature values. 
    xlabel('frame');ylabel('Temp(\circC');
    save([para.paths.respath(1:end-4) '_balltrace'], 'temper', 'medtemper', 'dancetemper');
    
%% do this after all are done
alltemps={'ct_120206_0002_X01_c', ...
'ct_120206_0003_X01_h', ...
'ct_120206_0004_X02_n', ...
'ct_120206_0005_D11_c', ...
'ct_120206_0006_D11_h', ...
'ct_120206_0007_D11_n', ...
'ct_120206_0009_D12_n', ...
'ct_120206_0012_F01_n', ...
'ct_120206_0020_D26_n', ...
'ct_120206_0022_F02_n'};
allcols={'b.-', 'r.-', 'k.-', 'b.-', 'r.-', 'k.-', 'k.-', 'k.-', 'k.-', 'k.-'};
figure(10);clf;hold on;
for i=1:length(alltemps)
    load(['J:\Data and Documents\results\2011 Kheper thermal dance\BallTraces\' alltemps{i} '_balltrace']);
    t(:, i)=medtemper-mean(medtemper(91:97)); %normalise to temp average of frames -10 to -4
    plot((-100:100)/4.3, t(:, i), 'k.-');%allcols{i});
end
plot((-100:100)/4.3, mean(t, 2), 'r-', 'linewidth', 2);
xlabel('rel. time (s)');ylabel('Temp (\circ C)');%legend('cold ball', 'normal ball', 'hot ball', 'location', 'SE');
axis([-4 10 -4 1]);grid on;grid minor
        
        
end