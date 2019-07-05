function out = dtrack_ana_rel2body(filename)
% Transforms a number of points (tracked legs) relative to an axis (longitudinal body axis) and calculates the mean backwards distance travelled by these points

close all;
if nargin <1, 
    [filename, filepath] = uigetfile('*.res');
    filename = fullfile(filepath, filename);    
    % filename = 'G:\Data and Documents\results\2016 Lisa respirometry tracking\44f_right_level.res';
end

%% ASSUMPTIONS
% All points must be tracked in the same frames! If any frames have some points but not all of them, there will be an error.

%% Variables 
ind_legs = 2; %[1 2 3]; % Which point numbers are legs?
ind_abdo = 4;       % Which point number if the abdomen?
ind_head = 5;       % Which point number is the head?
ind_all  = [ind_legs ind_abdo ind_head];
colors   = {'m', 'c', 'b', 'k', 'r'}; % plot colours for all points
calfac   = 1.822;   % calibration factor (pixels/mm)
smfact   = 3;       % smoothing factor, 1 means no smoothing
lw       = 2;       % line width for plotting
bgc      = [.5 .5 .5]; % background colour for plots

%% Load data
load(filename, '-mat');
if convert
    data.points(:, :, 1) = full(xdata);
    data.points(:, :, 2) = full(ydata);
    data.points(:, :, 3) = full(tdata);
end

[rootfold, rootname] = fileparts(filename);

%% Main function
% Collect all tracked points
for pnr = 1:size(data.points, 2)
    sel = data.points(:, pnr, 3)~=0;
    trackedpoints(pnr) = nnz(sel);
    x{pnr}  = data.points(sel, pnr, 1); 
    y{pnr}  = data.points(sel, pnr, 2); 
    f{pnr}  = find(sel); 
    t{pnr}  = 1000*f{pnr}/status.FrameRate;
end

% Create a useful error message if some points have different numbers of tracked points
if length(unique(trackedpoints(ind_all))) > 1
    [maxnum, ind] = max(trackedpoints);
    assignin('base', 'f', f)
    error('Object #%d has been tracked in %d frames, but some of the others only in fewer. Please check the variable f in your workspace to see which frames each object has been tracked in.', ind, maxnum);
end

% Find breaks > 1 frame in head tracking and assume they are valid for all points
changeinds      = find(abs(diff(diff(f{ind_head}))));
sectionstarts   = [1; changeinds(2:2:end)+1];
sectionends     = [sectionstarts(2:end)-1; length(f{ind_head})];

% Calculate body axis as vector from tail to head, and the body "centre" in each frame
bodyaxisx   = x{ind_head} - x{ind_abdo}; 
bodyaxisy   = y{ind_head} - y{ind_abdo}; 
bodycentrex = mean([x{ind_head} x{ind_abdo}], 2); 
bodycentrey = mean([y{ind_head} y{ind_abdo}], 2);

% Transform all movements to body coordinate system
for i = 1:length(f{ind_head})
    bodyaxis    = [bodyaxisx(i) bodyaxisy(i)];
    bodyaxis_n  = bodyaxis / norm(bodyaxis, 2); % unit vector from tail to head
    bodyperp_n  = null(bodyaxis_n(:)');         % The 'null' function needs size [1 2], so making sure here that bodyaxis is a row vector 
    bodytrans   = [bodyaxis_n', bodyperp_n];
    %quiver(bodycentrex(ii), bodycentrey(ii), bodyaxis_n(1), bodyaxis_n(2));
    %quiver(bodycentrex(ii), bodycentrey(ii), bodyperp_n(1), bodyperp_n(2));
    for pnr = ind_all
        ps_n{pnr}(i, :) = mldivide(bodytrans, [x{pnr}(i); y{pnr}(i)]);
    end
    temp = mldivide(bodytrans, [bodycentrex(i);bodycentrey(i)]);
    bodyx_n(i) = temp(1);
end

%% plot raw tracks in body coordinate system
for i = 1:length(sectionstarts)
    i1 = sectionstarts(i);
    i2 = sectionends(i);
    figure(i);
    clf;
    set(gca, 'color', [.5 .5 .5]);
    hold on;
    for pnr = ind_all % for each body part
        if ~isempty(f{pnr}) % if there are valid tracked frames
            yyraw = (ps_n{pnr}(i1:i2, 1) - bodyx_n(i1:i2)') / calfac;
            yy = smooth(yyraw, smfact); % smooth the track
            % calculate total backwards movement
            yy2 = diff(yy);
            yyraw2 = diff(yyraw);
            totalbackmove = abs(sum(yy2(yy2<0)));
            totalbackmoveraw = abs(sum(yyraw2(yyraw2<0)));
            totalbackspeed(pnr) = totalbackmove / (t{pnr}(i2)-t{pnr}(i1)) * 100; % cm/s
            totalbackspeedraw(pnr) = totalbackmoveraw / (t{pnr}(i2)-t{pnr}(i1)) * 100; % cm/s
            plot(t{pnr}(i1:i2)/1000, yyraw, [colors{pnr} '.'], 'linewidth', 2); % plot the unsmoothed data
            plot(t{pnr}(i1:i2)/1000, yy, [colors{pnr} '.-'], 'linewidth', 2); % plot the smoothed data
        end
    end
    meantotalspeed(i) = mean(totalbackspeed(ind_legs)) * 2; % multiply by two assuming a 50% duty cycle
    meantotalspeedraw(i) = mean(totalbackspeedraw(ind_legs)) * 2; % multiply by two assuming a 50% duty cycle
    set(gca, 'color', bgc);
    xlabel('time (s)'); 
    ylabel('position relative to body centre (mm)');
    title(sprintf('Estimated max. forward speed: %.1f (cm/s)', meantotalspeed(i)));
    figureoutname = fullfile(rootfold, sprintf('%s_%02d.pdf', rootname, i));
    pdfsave(i, figureoutname);
    
    % generate output matrix with three columns: time (s), raw speed (cm/s), smoothed speed (cm/s)
    out(i, :) = [t{ind_head}(i1) meantotalspeed(i) meantotalspeedraw(i)]; 
    
end
textoutname = fullfile(rootfold, sprintf('%s.speeds', rootname));
dlmwrite(textoutname, out);


