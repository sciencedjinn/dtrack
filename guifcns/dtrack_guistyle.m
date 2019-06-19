function dtrack_guistyle(gui)
%% CURRENTLY UNUSED

% set(findobj('type', 'uitabgroup'), 'backgroundcolor', [.4 .4 .4])


set(findobj('type', 'uitab'), 'backgroundcolor', [.3 .3 .3])
set(findobj('type', 'uitab'), 'foregroundcolor', [0 0 0])




set(findobj('type', 'uipanel'), 'backgroundcolor', [.3 .3 .3])
set(findobj('type', 'uipanel'), 'bordertype', 'none')
set(findobj('type', 'uipanel'), 'shadowcolor', 'none')
set(findobj('type', 'uibuttongroup'), 'backgroundcolor', [.3 .3 .3])
set(findobj('type', 'uibuttongroup'), 'bordertype', 'none')
set(findobj('type', 'uibuttongroup'), 'shadowcolor', 'none')

set(findobj('type', 'uicontrol', 'style', 'radiobutton'), 'backgroundcolor', [.3 .3 .3])
set(findobj('type', 'uicontrol', 'style', 'edit', 'enable', 'inactive'), 'backgroundcolor', [.95 .95 .95])
set(findobj('type', 'uicontrol', 'style', 'edit', 'enable', 'inactive'), 'foregroundcolor', [1 1 1])
set(findobj('type', 'uicontrol', 'style', 'edit', 'enable', 'inactive'), 'extent', [0 0 0 0])
set(findobj('type', 'uicontrol', 'style', 'edit', 'enable', 'inactive'), 'bordertype', 'none')

set(findobj('type', 'uicontrol'), 'backgroundcolor', [.3 .3 .3])
set(findobj('type', 'uicontrol'), 'bordertype', 'none')
set(findobj('type', 'uicontrol'), 'foregroundcolor', [.9 .9 .9])