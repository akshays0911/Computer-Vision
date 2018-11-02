function lineSegs = fitLineSegments(E, DTHRESH, MINLENGTH)
% Fit line segments to the edge points in the image E.
% Parameters:
%   DTHRESH:  maximum distance between the original curve and its
%       approximation (in pixels)
%   MINLENGTH: minimum length of a line segment (in pixels)
% Output line segments is an array of size Nx4 array, where each row is a
% segment, and is composed of   p1x,p1y, p2x,p2y.

lineSegs = [];

while true
    % Find the first edge point.
    ind = find(E(:),1,'first');
    [r,c] = ind2sub(size(E), ind);
    if isempty(r)   break;  end
    p = [r(1), c(1)];
    
    % Trace the boundary, starting from that point.  Use 'W' as initial step
    % direction.  Get the list of points as an Nx2 array.
    pts = bwtraceboundary(E, [p(1),p(2)], 'W', 8, Inf, 'clockwise');
    
    N = size(pts,1);         % Number of points along contour
    if N < MINLENGTH
        % Delete those edge points from the edge image.
        ind = sub2ind(size(E), pts(:,1), pts(:,2));
        E(ind) = false;
        continue;         % Skip very short contours
    end
    
    % Find the point furthest from centroid
    pCenter = mean(pts);      % Get centroid
    dp = pts - repmat(pCenter,N,1);
    d = dp(:,1).^2 + dp(:,2).^2;
    [~,i1] = max(d);
    
    % Shift the points so that p1 is the first one.
    pts = [pts(i1(1):N,:); pts(1:i1(1)-1, :)];
    
    % Ok, go along the contour until all points are processed, and extract
    % contour segments.  Each contour segment goes from index i1 to i2.  As
    % we visit points, we delete them from the edge image.
    i1 = [];
    for iPt=1:N
        if isempty(i1)
            % Start a new segment.
            i1 = iPt;
        end
        p = pts(iPt,:);
        
        % Sometimes a point is duplicated.  If so, ignore it.
        if iPt>1 && pts(iPt,1)==pts(iPt-1,1) && pts(iPt,2)==pts(iPt-1,2)
            E(p(1),p(2)) = false;        % delete point
            continue;
        end
        
        % Check for the end of this contour segment.
        i2 = [];
        if ~E(p(1),p(2))
            i2 = iPt-1;
        elseif iPt == N
            i2 = N;
        end
        
        if ~isempty(i2)
            ptsOut = pts(i1:i2,:);
            if size(ptsOut,1) > MINLENGTH
                % Ok, we have a complete contour.  Approximate it with line
                % segments.
                lineSegs = [lineSegs; fitLineSegs(ptsOut, [], DTHRESH, MINLENGTH)];
            end
            
            % Start a new contour segment.
            i1 = [];
        end
        
        E(p(1),p(2)) = false;   % delete point
    end
    
end

return


function lineSegs = fitLineSegs(pts, lineSegs, DTHRESH, MINLENGTH)
% A function that recursively splits a sequence of points into line
% segments.
% Parameters:
%   pts:  A sequence of points (Nx2)
%   DTHRESH:  maximum distance between the original curve and its
%       approximation (in pixels)
%   MINLENGTH: minimum length of a line segment (in pixels)
% Output line segments is an array of size Nx4 array, where each row is a
% segment, and is composed of   p1x,p1y, p2x,p2y.

N = size(pts,1);    % Number of points along contour
if N < MINLENGTH
    return;
end

p1 = pts(1,:);  % First point on contour
p3 = pts(end,:); % Last point on contour


% Find the point p2 that is the furthest from the line from p1 to p3.
v = [p3(2)-p1(2); -(p3(1)-p1(1))];  % A vector perpendicular to that line
v = v/norm(v);

% Get vectors from the first endpoint to all other points.
r = pts - repmat(p1,N,1);

% The distance from each point to the line is just abs(dot(v,r))
d = abs( v(1)*r(:,1) + v(2)*r(:,2) );
[dmax,i2] = max(d);        % Point p2 is the furthest from the line

% If dmax is less than the threshold, then we are done.
if dmax < DTHRESH
    lineSegs = [lineSegs; p1(2) p1(1) p3(2) p3(1)];
else
    % Recursively fit line segments to each piece.
    lineSegs = [lineSegs;
        fitLineSegs(pts(1:i2,:), [], DTHRESH, MINLENGTH);
        fitLineSegs(pts(i2:end,:), [], DTHRESH, MINLENGTH)];
end

return


