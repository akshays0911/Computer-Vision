function lineSegs = demoFitLineSegments(pts, lineSegs, THRESH)
% Input array pts is size (N,2), where each row is the coordinates of a
% point on the contour, (r,c).

N = size(pts,1);                    % Number of points along contour

p1 = pts(1,:);  % First point on contour
p3 = pts(end,:); % Last point on contour

% Draw line from p1 to p3
line([p1(2) p3(2)], [p1(1) p3(1)], 'Color', 'r', 'LineWidth', 3.0);
pause
    
% Find the point p2 that is the furthest from the line from p1 to p3.
v = [p3(2)-p1(2); -(p3(1)-p1(1))];  % A vector perpendicular to that line
v = v/norm(v);

% Get vectors from the first endpoint to all other points.
r = pts - repmat(p1,N,1);

% The distance from each point to the line is just abs(dot(v,r))
d = abs( v(1)*r(:,1) + v(2)*r(:,2) );
[dmax,i2] = max(d);        % Point p2 is the furthest from the line

% If dmax is less than the threshold, then we are done.
if dmax < THRESH
    lineSegs = [lineSegs; p1(2) p1(1) p3(2) p3(1)];
else
    % Recursively fit line segments to each piece.
    lineSegs = [lineSegs;
        demoFitLineSegments(pts(1:i2,:), [], THRESH);
        demoFitLineSegments(pts(i2:end,:), [], THRESH)];
end
    
return
