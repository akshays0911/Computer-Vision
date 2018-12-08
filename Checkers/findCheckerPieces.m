function [detectedBlack, detectedWhite] = findCheckerPieces(Iboard)
if size(Iboard,3)>1
    Iboard = rgb2gray(Iboard);
end
[centers, radii] = imfindcircles(Iboard, ...
    [10, 20], ...       
    'ObjectPolarity', 'bright', ...   
    'EdgeThreshold', 0.2*graythresh(Iboard), ...
    'Sensitivity', 0.9);   
figure(20), imshow(Iboard, []), impixelinfo
for j=1:size(centers,1)
    r = radii(j);
    x = centers(j,1);
    y = centers(j,2);
    rectangle('Position', [x-r y-r 2*r 2*r], 'EdgeColor', 'r', ...
        'Curvature', [1 1], 'LineWidth', 2);
end
diffs = zeros(1, size(centers,1));
for i=1:size(centers,1)
    x0 = round(centers(i,1));
    y0 = round(centers(i,2));
    R0 = round(radii(i));
    diffs(i) = getIntensityDifference(Iboard, x0, y0, R0);
end
thresh = 256*graythresh(uint8(diffs));
detectedWhite = false(8,8);
detectedBlack = false(8,8);
for i=1:size(centers,1)
    r = radii(i);
    x = centers(i,1);
    y = centers(i,2);
    ix = round( 8*(x/size(Iboard,2)) + 0.5);
    iy = round( 8*(y/size(Iboard,1)) + 0.5);
    if diffs(i)>thresh
        detectedWhite(iy,ix) = true;
    else
        detectedBlack(iy,ix) = true;
    end
end
end
function diff = getIntensityDifference(I, x0, y0, R0)
dR = 4;
xMin = max(x0-R0-dR, 1);
xMax = min(x0+R0+dR, size(I,2));
yMin = max(y0-R0-dR, 1);
yMax = min(y0+R0+dR, size(I,1));
[X,Y] = meshgrid(xMin:xMax, yMin:yMax);
R = ((X-x0).^2 + (Y-y0).^2) .^ 0.5;
Rinside = (R < (R0-dR)) & (R > (R0-2*dR));
Xinside = X(Rinside);
Yinside = Y(Rinside);
indices = sub2ind(size(I), Yinside, Xinside);
intensityInside = mean(I(indices));
Routside = (R > (R0+dR)) & (R < (R0+2*dR));
Xoutside = X(Routside);
Youtside = Y(Routside);
indices = sub2ind(size(I), Youtside, Xoutside);
intensityOutside = median(I(indices));
diff = intensityInside - intensityOutside;
end
