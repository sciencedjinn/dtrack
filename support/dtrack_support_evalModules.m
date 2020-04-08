function [gui, status, para, data, redraw] = dtrack_support_evalModules(type, gui, status, para, data, redraw)
% Evaluates additional functions for modules. For example, after dtrack_defaults, it runs all the default functions for the modules
% Functions that will be called are _defaults, _image1, _imagefcn, _image_final

%% Load modules
for i = 1:length(para.modules)
    if exist([para.modules{i} type], 'file')
        if nargin<6
            [gui, status, para, data] = feval([para.modules{i} type], gui, status, para, data);
        else
            [gui, status, para, data, redraw] = feval([para.modules{i} type], gui, status, para, data, redraw);
        end
    end
end