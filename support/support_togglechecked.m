function val=support_togglechecked(tag)
% 
    
    if nargin<1
        h=gcbo;
    else
        h=findobj('tag', tag);
    end

    switch get(h, 'checked')
        case 'on'
            set(h, 'checked', 'off');
            val=0;
        case 'off'
            set(h, 'checked', 'on');
            val=1;
    end