clear all
close all

I = imread("/home/tom/org-classes/Classes/taught/F17/CSCI507/CSCI507/lectures/30-LineSegmentFitting/demo/cameraman.tif");
E = edge(I, 'canny');

imshow(E, 'InitialMagnification', 300);
hold on         % Turn hold on so we can "plot" on top of image

% Click on the first point along the contour.
fprintf('Pick first point on a contour\n');
while true
    p1 = round(ginput(1));  % Get x,y coords
    if ~E(p1(2),p1(1))
        fprintf('Try again\n');
    else
        break;
    end
end
plot(p1(1),p1(2), 'g*');

% Trace the boundary, starting from that point.  Use 'W' as initial step
% direction. Matlab's "bwtrackboundary" seems to have problems occasionally
% when the neighbor to the west is occupied.  So if it is, let's move p1 to
% that point.
while E(p1(2),p1(1)-1)     % Check if neighbor to the left is occupied
    p1(1) = p1(1)-1;
end

pts = bwtraceboundary(E, [p1(2),p1(1)], 'W', 8, Inf, 'clockwise');
N = size(pts, 1);       % Number of points

% Click on the 2nd point along the contour.
fprintf('Pick 2nd point on the contour\n');
while true
    p2 = round(ginput(1));  % Get x,y coords
    if ~E(p2(2),p2(1))
        fprintf('Try again\n');
    else
        break;
    end
end
plot(p2(1),p2(2), 'g*');

% Get the indices of the 1st point in our list.
indices1 = find( (pts(:,1)==p1(2)) & (pts(:,2)==p1(1)) );

% Get the indices of the 2nd point in our list.
indices2 = find( (pts(:,1)==p2(2)) & (pts(:,2)==p2(1)) );
assert(~isempty(indices2), 'Can''t find point2 along the contour');

% Find the pair of indices that are closest to each other.
for i=1:length(indices1)
    for j=1:length(indices2)
        d(i,j) = abs(indices2(j) - indices1(i));
    end
end
[i,j] = find(d == min(d(:)));
if indices1(i)<indices2(j)
    i1 = indices1(i);
    i2 = indices2(j);
else
    i1 = indices2(j);
    i2 = indices1(i);
end
    
% Get points from p1 to p2.
pts = pts(i1:i2, :);
plot(pts(:,2), pts(:,1), 'g*');

% Fit line segments to the points in the contour.  Each row of
% "lineSegs" consists of
%   [x0, y0, x1, y1]
lineSegs = demoFitLineSegments(pts, [], 2.0);

% Draw final line segments
figure, imshow(I, 'InitialMagnification', 300);
for iSeg=1:size(lineSegs,1)
    p0 = lineSegs(iSeg,1:2);
    p1 = lineSegs(iSeg,3:4);
    line([p0(1) p1(1)], [p0(2) p1(2)], 'Color', 'r', 'LineWidth', 3.0);
end


