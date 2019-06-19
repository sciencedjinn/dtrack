function [gui, status, para, data, varargout] = dtrack_support_evalModules(type, gui, status, para, data, varargin)
% Evaluates additional functions for modules. For example, after dtrack_defaults, it runs all the default functions for the modules

%% Load modules
for i = 1:length(para.modules)
    if exist([para.modules{i} type], 'file')
        if isempty(varargin)
            [gui, status, para, data] = feval([para.modules{i} type], gui, status, para, data);
        else
            [gui, status, para, data, varargout{1:nargout-4}] = feval([para.modules{i} type], gui, status, para, data, varargin{:});
        end
    end
end