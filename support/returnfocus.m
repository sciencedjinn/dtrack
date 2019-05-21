function returnfocus(obj)
% returns the focus to current figure by disabling and re-enabling the last
% called uiobject. This is a workaround that will hopefully not be
% neccessary anymore in a future MATLAB version

if nargin<1
    obj = gcbo;
end
set(obj, 'enable', 'off');
drawnow;
set(obj, 'enable', 'on');