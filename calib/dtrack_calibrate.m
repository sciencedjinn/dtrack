function data_calibrated = dtrack_calibrate(data, intfilename, extfilename)

% This is how calibration file was saved:
% save('calib_ext.calib', 'Tc_ext', 'Rc_ext', 'fc', 'cc', 'alpha_c', 'kc');

%% Check inputs
%if only one file is provided, use it for internal and external clibration
if nargin<3
    extfilename=intfilename;
end
if size(data,2)~=2
  error('Data must have exactly two columns');
end

%% load calib files
load(intfilename, '-mat', 'fc', 'cc', 'alpha_c', 'kc');
load(extfilename, '-mat', 'Tc_ext', 'Rc_ext');

Tc_ext = Tc_ext(:)';%#ok<NODEF> % should be 1x3;

%% Calculate calibration
np_im = [0;0]; %nodal point
np_rw = sub_imtorw(np_im, Rc_ext, Tc_ext, 0); %nodal point real world (0 image zdist)

% principal point
pp_im = [0; 0];
pp_rw = sub_imtorw(pp_im, Rc_ext, Tc_ext, 1);
% on the ground (or height)

pp_ground = projecttoground(pp_rw,np_rw);
% on the ground with pp at origin
% pp_ground1=setpp2zero(pp_ground, pp_ground);

% tranform to toolbox coordinates
data = data-0.5;

% undistort (units relative to focal length, so z=1)
dat_im = normalize(data', fc, cc, kc, alpha_c);
dat_rw = sub_imtorw(dat_im, Rc_ext, Tc_ext, 1);

dat_ground = projecttoground(dat_rw,np_rw);
data_calibrated = setpp2zero(dat_ground, pp_ground);


function dat_rw = sub_imtorw(dat_im, Rc_ext, Tc_ext, zdist)
dat_im = [dat_im' zdist*ones(size(dat_im,2),1)];
dat_rw = (Rc_ext\(dat_im-Tc_ext(ones(size(dat_im,1),1),:))')';
%dat_rw = (inv(Rc_ext)*(dat_im-Tc_ext(ones(size(dat_im,1),1),:))')';

function dat_ground = projecttoground(dat_rw, np_rw)
L = (-np_rw(3))./(dat_rw(:,3)-np_rw(3));
dat_ground = np_rw(ones(size(dat_rw,1),1),:)-L(:,ones(3,1)).*(np_rw(ones(size(dat_rw,1),1),:)-dat_rw);

function dat_ground1 = setpp2zero(dat_ground, pp_ground)
dat_ground1 = dat_ground;
dat_ground1(:,1:2) = dat_ground1(:,1:2)-pp_ground(ones(size(dat_ground,1),1),1:2);



