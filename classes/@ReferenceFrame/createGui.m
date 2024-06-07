function createGui(obj, ph)
% ReferenceFrame.createGui creates a GUI to change parameters and display results of reference frame calculation
%   Detailed explanation goes here

    if nargin<2
        fh = uifigure();
        ph = uipanel(uigridlayout(fh, [1 1]), "Title", "Reference Frame parameters");
    end
    
    %% parameters
    gh = uigridlayout(ph, [3 4], "ColumnWidth", {'fit', '1x', 'fit', 'fit'}, "RowHeight", {'1x', 'fit', 'fit'}, "RowSpacing", 3);
    obj.Gui.ah = axes(gh);
    obj.Gui.ah.Layout.Column = [1 4];
    axis(obj.Gui.ah, 'image', 'off')

    vals = enumeration('ReferenceMethod');
    valNames = string(vals);
    valTooltips = arrayfun(@(x) sprintf("%s: %s", string(vals(x)), vals(x).Tooltip), 1:length(vals));
    uilabel(gh, "Text", "Method");
    obj.Gui.method = uidropdown(gh, "Items", valNames, "Value", string(obj.Method), "Tooltip", valTooltips, "ValueChangedFcn", @(src, evt) valueChangedFcn("Method", src.Value));
    obj.Gui.method.Layout.Column = [2 4];

    vals = enumeration('ReferenceFrameType');
    valNames = string(vals);
    valTooltips = arrayfun(@(x) sprintf("%s: %s", string(vals(x)), vals(x).Tooltip), 1:length(vals));
    uilabel(gh, "Text", "Frames");
    obj.Gui.frameNumberMethod = uidropdown(gh, "Items", valNames, "Value", string(obj.FrameNumberMethod), "Tooltip", valTooltips, "ValueChangedFcn", @(src, evt) valueChangedFcn("FrameNumberMethod", src.Value));
    uilabel(gh, "Text", "X");
    obj.Gui.frameNumberX = uieditfield(gh, "numeric", "Value", obj.FrameNumberX, "ValueChangedFcn", @(src, evt) valueChangedFcn("FrameNumberX", src.Value));
    obj.updateAxes();

    function valueChangedFcn(field, value)
        obj.(field) = value;
        obj.updateAxes();
    end
end

