function dtrack_tools_autotrack_plotdiag(im, diagims, cent, area, ah)

        cla(ah(1));
        image(im, 'parent', ah(1)); hold(ah(1), 'on');
        plot(ah(1), cent(1), cent(2) ,'or', 'markersize', 20);
        plot(ah(1), cent(1), cent(2) ,'.r');
        text(size(im, 2)/2, size(im, 1), sprintf('original frame (%d pixel object detected)', area), 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(1));
        
        cla(ah(2));
        image(diagims{1}, 'parent', ah(2)); hold(ah(2), 'on');
        text(size(im, 2)/2, size(im, 1), 'difference frame', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(2));
        
        cla(ah(3));
        imagesc(diagims{2}, 'parent', ah(3)); hold(ah(3), 'on');
        text(size(im, 2)/2, size(im, 1), 'thresholded difference frame', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(3));
        
        cla(ah(4));
        imagesc(diagims{4}, 'parent', ah(4)); hold(ah(4), 'on');
        text(size(im, 2)/2, size(im, 1), 'ROI and area threshold applied', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(4));
        axis(ah, 'image', 'off');       