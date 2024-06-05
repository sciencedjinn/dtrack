classdef ReferenceMethod
    % REFERENCEMETHOD defines methods to calculate a reference image from a 4d image stack.
    % Call obj.Fun(ImageStack) to call the function and return a reference image; an explanation is stored in obj.Tooltip

    properties (SetAccess=immutable, GetAccess=public)
        Fun(1,1)
        Tooltip(1,1) string
    end

    enumeration
        MIN (@(x) min(x, [], 4), "The minimum value for each pixel")
        MAX (@(x) max(x, [], 4), "The maximum value for each pixel")
        MEAN (@(x) mean(x, 4), "The mean value for each pixel")
        MEDIAN (@(x) median(x, 4), "The median value for each pixel")
        RANGE (@(x) max(x, [], 4)-min(x, [], 4), "The maximum - minimum for each pixel")
        DIFF (@(x) x(:, :, :, end)-x(:, :, :, 1), "The last image minus the first image")
        ABSDIFF (@(x) abs(x(:, :, :, end)-x(:, :, :, 1)), "The absolute difference between the first and last image")
    end

    methods
        function obj = ReferenceMethod(fun, tooltip)
            obj.Fun = fun;
            obj.Tooltip = tooltip;
        end
    end
end
