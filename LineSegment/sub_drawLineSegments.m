function sub_drawLineSegments(lineSeg)
% Draw line segments onto the currently displayed image.
% Line segments are represented by a Nx4 array, where each row is a
% segment, and is composed of
%  p1x,p1y, p2x,p2y

for i=1:size(lineSeg,1)
    p1x = lineSeg(i,1);
    p1y = lineSeg(i,2);
    p2x = lineSeg(i,3);
    p2y = lineSeg(i,4);
    line([p1x,p2x], [p1y,p2y], 'Color', 'r', 'LineWidth', 2.0);
end

end

