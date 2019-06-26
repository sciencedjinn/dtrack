function holo_autotrack_plotdiag(diagims, cent, area, ah)

        [s1, s2] = size(diagims{1});
        

        cla(ah(1));
        imagesc(diagims{1}, 'parent', ah(1)); hold(ah(1), 'on');
        plot(ah(1), cent(1), cent(2) ,'or', 'markersize', 20);
        plot(ah(1), cent(1), cent(2) ,'.r');
        text(s2/2, s1, sprintf('difference frame (%d pixel object detected)', area), 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(1));
        colormap('gray')
                
        cla(ah(2));
        imagesc(diagims{2}, 'parent', ah(2)); hold(ah(2), 'on');
        text(s2/2, s1, 'thresholded difference frame', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(2));
        colormap('gray')
        
        cla(ah(3));
        imagesc(diagims{3}, 'parent', ah(3)); hold(ah(3), 'on');
        text(s2/2, s1, 'ROI applied', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(3));
        colormap('gray')
        
        cla(ah(4));
        imagesc(diagims{4}, 'parent', ah(4)); hold(ah(4), 'on');
        text(s2/2, s1, 'ROI and area threshold applied', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(4));
        axis(ah, 'image', 'off');       
        colormap('gray')