function [gui, status, para, data, redraw] = holo_image1(gui, status, para, data, redraw)
% Executed after frame number updates


if ismember(redraw, [1 2 3 11 30])
    if status.holo.link
        % displayed z-value should reflect current point's z-value
        if data.points(status.framenr, status.cpoint, 4) > 0 
            status.holo.z = data.points(status.framenr, status.cpoint, 4);
            set(findobj('tag', 'holo_zvalue_disp'), 'string', num2str(status.holo.z));
            if strcmp(status.holo.image_mode, 'holo')
                redraw = 1;
            end
        else
            % this point hasn't had a z-value assigned yet => keep the current value
        end
    else
        % keep the selected value
    end
    set(findobj('tag', 'holo_zvalue_point'), 'string', num2str(data.points(status.framenr, status.cpoint, 4))); % either way, set the gui value for the point's z-value
end        
