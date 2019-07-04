function holo_autotrack_plotdiag(diag, ah)

        [s1, s2] = size(diag.images{1});
        

        cla(ah(1));
        imagesc(diag.images{1}, 'parent', ah(1)); hold(ah(1), 'on');
        plot(ah(1), diag.centroid(1), diag.centroid(2) ,'or', 'markersize', 20);
        plot(ah(1), diag.centroid(1), diag.centroid(2) ,'.r');
        text(s2/2, s1, sprintf('d-frame (%d-px object)', diag.area), 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(1));
        colormap('gray')
                
        cla(ah(2));
        imagesc(diag.images{2}, 'parent', ah(2)); hold(ah(2), 'on');
        text(s2/2, s1, sprintf('thresholded d-frame (%.2f)', diag.para.greythr), 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(2));
        colormap('gray')
        
        cla(ah(3));
        imagesc(diag.images{3}, 'parent', ah(3)); hold(ah(3), 'on');
        text(s2/2, s1, 'ROI applied', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(3));
        colormap('gray')
        
        cla(ah(4));
        imagesc(diag.images{4}, 'parent', ah(4)); hold(ah(4), 'on');
        text(s2/2, s1, 'ROI and area threshold applied', 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r', 'parent', ah(4));
        axis(ah, 'image', 'off');       
        colormap('gray')