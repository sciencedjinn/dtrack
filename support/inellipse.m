function out=inellipse(inx, iny, el)
%el is given as [x y width height]

%shift inx and iny to center ellipse on 0
inx = inx-el(1)-el(3)/2;
iny = iny-el(2)-el(4)/2;

%ellipse axes
ax1 = [el(3)/2; 0];
ax2 = [0; el(4)/2];
W = [ax1(:) ax2(:)];

out = reshape(sum(([inx(:) iny(:)]/W.').^2,2)<1, size(inx));