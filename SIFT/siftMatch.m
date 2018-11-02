% Try SIFT matching
%
clear all
close all

% First make sure the vl_sift code is in the path
if exist('vl_sift', 'file')==0
    run('C:\Users\William\Documents\Research\vlfeat-0.9.20\toolbox\vl_setup');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First image
I1 = imread('floor1.jpg');
if size(I1,3)>1     I1 = rgb2gray(I1);  end
I1 = single(I1);  % Convert to single precision floating point
imshow(I1,[]);

% These parameters limit the number of features detected
peak_thresh = 0;    % increase to limit; default is 0
edge_thresh = 10;   % decrease to limit; default is 10
[f1,d1] = vl_sift(I1, ...
    'PeakThresh', peak_thresh, ...
    'edgethresh', edge_thresh );
fprintf('Number of frames (features) detected: %d\n', size(f1,2));

% Show all SIFT features detected
h = vl_plotframe(f1) ;
set(h,'color','y','linewidth',2) ;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Second image
I2 = imread('floor2.jpg');
if size(I2,3)>1     I2 = rgb2gray(I2);  end
I2 = single(I2);  % Convert to single precision floating point
figure, imshow(I2,[]);

% These parameters limit the number of features detected
peak_thresh = 0;    % increase to limit; default is 0
edge_thresh = 10;   % decrease to limit; default is 10

[f2,d2] = vl_sift(I2, ...
    'PeakThresh', peak_thresh, ...
    'edgethresh', edge_thresh );
fprintf('Number of frames (features) detected: %d\n', size(f2,2));

% Show all SIFT features detected
h   = vl_plotframe(f2) ;
set(h,'color','y','linewidth',2) ;

pause;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Match features
% The index of the original match and the closest descriptor is stored in
% each column of matches and the distance between the pair is stored in
% scores.

% Threshold for matching
% Descriptor D1 is matched to a descriptor D2 only if the distance d(D1,D2)
% multiplied by THRESH is not greater than the distance of D1 to all other
% descriptors
thresh = 2.0;   % default = 1.5; increase to limit matches
[matches, scores] = vl_ubcmatch(d1, d2, thresh);
fprintf('Number of matching frames (features): %d\n', size(matches,2));

indices1 = matches(1,:);        % Get matching features
f1match = f1(:,indices1);       
d1match = d1(:,indices1);

indices2 = matches(2,:);
f2match = f2(:,indices2);
d2match = d2(:,indices2);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show matches
figure, imshow([I1,I2],[]);
o = size(I1,2) ;
line([f1match(1,:);f2match(1,:)+o], ...
    [f1match(2,:);f2match(2,:)]) ;

for i=1:size(f1match,2)
    x = f1match(1,i);
    y = f1match(2,i);
    text(x,y,sprintf('%d',i), 'Color', 'r');
end

for i=1:size(f2match,2)
    x = f2match(1,i);
    y = f2match(2,i);
    text(x+o,y,sprintf('%d',i), 'Color', 'r');
end
pause

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Between all pairs of matching features, compute 
% orientation difference, scale ratio, and center offset
allScales = zeros(1,size(matches,2));   % Store computed values
allAngs = zeros(1,size(matches,2));
allX = zeros(1,size(matches,2));
allY = zeros(1,size(matches,2));
 
for i=1:size(matches, 2)    
    fprintf('Match %d: image 1 (scale,orient = %f,%f) matches', ...
        i, f1match(3,i), f1match(4,i));
    fprintf(' image 2 (scale,orient = %f,%f)\n', ...
        f2match(3,i), f2match(4,i));
    scaleRatio = f1match(3,i)/f2match(3,i);
    dTheta = f1match(4,i) - f2match(4,i);
    
    % Force dTheta to be between -pi and +pi
    while dTheta > pi   dTheta = dTheta - 2*pi;     end
    while dTheta < -pi   dTheta = dTheta + 2*pi;     end
    
    allScales(i) = scaleRatio;
    allAngs(i) = dTheta;
    
    x1 = f1match(1,i);      % the feature in image 1
    y1 = f1match(2,i);
    x2 = f2match(1,i);      % the feature in image 2
    y2 = f2match(2,i);
    
    % The "center" of the object in image 1 is located at an offset of 
    % (-x1,-y1) relative to the detected feature.  We need to scale and rotate 
    % this offset and apply it to the image 2 location.
    offset = [-x1; -y1];
    offset = offset / scaleRatio;   % Scale to match image 2 scale
    offset = [cos(dTheta) +sin(dTheta); -sin(dTheta) cos(dTheta)]*offset;    
 
    allX(i) = x2 + offset(1);
    allY(i) = y2 + offset(2);
end
 
figure, plot(allScales, allAngs, '.'), xlabel('scale'), ylabel('angle');
figure, plot(allX, allY, '.'), xlabel('x'), ylabel('y');
pause

% Use a coarse Hough space.
% Dimensions are [angle, scale, x, y]
% Define bin centers
aBin = -pi:(pi/4):pi;
sBin = 0.5:(2):10;
xBin = 1:(size(I2,2)/5):size(I2,2);
yBin = 1:(size(I2,1)/5):size(I2,1);
 
H = zeros(length(aBin), length(sBin), length(xBin), length(yBin));
for i=1:size(matches, 2)    
    a = allAngs(i);
    s = allScales(i);
    x = allX(i);
    y = allY(i);
 
    % Find bin that is closest to a,s,x,y
    [~, ia] = min(abs(a-aBin));
    [~, is] = min(abs(s-sBin));
    [~, ix] = min(abs(x-xBin));
    [~, iy] = min(abs(y-yBin));
 
    H(ia,is,ix,iy) = H(ia,is,ix,iy) + 1;   % Inc accumulator array
end
 
% Find all bins with 3 or more features
[ap,sp,xp,yp] = ind2sub(size(H), find(H>=3));
 
fprintf('Peaks in the Hough array:\n');
for i=1:length(ap)
    fprintf('%d:  %d points, (a,s,x,y) = %f,%f,%f,%f\n', ...
        i, H(ap(i), sp(i), xp(i), yp(i)), ...
        aBin(ap(i)), sBin(sp(i)), xBin(xp(i)), yBin(yp(i)) );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the features corresponding to the largest bin
nFeatures = max(H(:));      % Number of features in largest bin
fprintf('Largest bin contains %d features\n', nFeatures);
[ap,sp,xp,yp] = ind2sub(size(H), find(H == nFeatures));
indices = [];   % Make a list of indices
for i=1:size(matches, 2)    
    a = allAngs(i);
    s = allScales(i);
    x = allX(i);
    y = allY(i);
 
    % Find bin that is closest to a,s,x,y
    [~, ia] = min(abs(a-aBin));
    [~, is] = min(abs(s-sBin));
    [~, ix] = min(abs(x-xBin));
    [~, iy] = min(abs(y-yBin));
 
    if ia==ap(1) && is==sp(1) && ix==xp(1) && iy==yp(1)
        indices = [indices i];
    end
end
fprintf('Features belonging to highest peak:\n');
disp(indices);


% Show matches to features in largest bin as line segments
figure, imshow([I1,I2],[]);
o = size(I1,2) ;
line([f1match(1,indices);f2match(1,indices)+o], ...
    [f1match(2,indices);f2match(2,indices)]) ;
for i=1:length(indices)
    x = f1match(1,indices(i));
    y = f1match(2,indices(i));
    text(x,y,sprintf('%d',indices(i)), 'Color', 'r');
end
for i=1:length(indices)
    x = f2match(1,indices(i));
    y = f2match(2,indices(i));
    text(x+o,y,sprintf('%d',indices(i)), 'Color', 'r');
end
pause


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fit an affine transformation to those features.
% We use affine transformation because the image of a planar surface 
% undergoing a small out-of-plane rotation can be approximated by an
% affine transformation.

% Create lists of corresponding points pA and pB.
pA = [f1match(1,indices); f1match(2,indices)];
pB = [f2match(1,indices); f2match(2,indices)];
N = size(pA,2);
 
% Calculate the transformation T from I1 to I2; ie p2 = T p1.
A = zeros(2*N,6);
for i=1:N
    A( 2*(i-1)+1, :) = [ pA(1,i)  pA(2,i)  0       0       1  0];
    A( 2*(i-1)+2, :) = [ 0        0        pA(1,i) pA(2,i) 0  1];
end
b = reshape(pB, [], 1);
x = A\b;
 
T = [ x(1)  x(2)    x(5);
      x(3)  x(4)    x(6);
      0     0       1];
fprintf('Derived affine transformation:\n');
disp(T);
 
r = A*x-b;          % Residual error
ssr = sum(r.^2);    % Sum of squared residuals
 
% Estimate the error for each image point measurement.
% For N image points, we get two measurements from each, so there are 2N
% quantities in the sum.  However, we have 6 degrees of freedom in the result.
sigmaImg = sqrt(ssr/(2*N-6));       % Estimated image std deviation
fprintf('#pts = %d, estimated image error = %f pixels\n', N, sigmaImg);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ok, apply the transformation to image 1 to align it to image 2.
% We'll use Matlab's imtransform function.
tform = maketform('affine', T');
I3 = imtransform(I1,tform, ...
    'XData', [1 size(I1,2)], 'YData', [1 size(I1,1)] );
figure, imshow(I3, []);
pause
 
% Overlay the images
RGB(:,:,1) = (I2+I3)/2;
RGB(:,:,2) = (I2+I3)/2;
RGB(:,:,3) = I2/2;
 
RGB = uint8(RGB);
figure, imshow(RGB);
