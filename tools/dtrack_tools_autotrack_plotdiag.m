function dtrack_tools_autotrack_plotdiag(im, diagims, cent, area, ah)

tx = size(im, 2)/2;
ty = 0;
to = {'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'color', 'r'};

for i = 1:4, cla(ah(i)); end
hold(ah, 'on');

image(ah(1), im);
plot(ah(1), cent(1), cent(2) , 'or', 'markersize', 20);
plot(ah(1), cent(1), cent(2) , '.r');
text(ah(1), tx, ty, sprintf('original frame (%d pixel object detected)', area), to{:});

imagesc(ah(2), diagims{1}/max(diagims{1}(:)));
text(ah(2), tx, ty, 'difference frame', to{:});
colormap(ah(2), "gray")

imagesc(ah(3), diagims{2}/max(diagims{2}(:)));
text(ah(3), tx, ty, 'thresholded difference frame', to{:});
colormap(ah(3), "gray")

imagesc(ah(4), diagims{4}/max(diagims{4}(:)));
text(ah(4), tx, ty, 'ROI and area threshold applied', to{:});
colormap(ah(4), "gray")

axis(ah, 'image', 'off', 'ij');
