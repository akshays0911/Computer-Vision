function [corners, nMatches, avgErr] = findCheckerBoard(I)
if size(I,3)>1
    I = rgb2gray(I);
end
[~,thresh] = edge(I, 'canny');      
E = edge(I, 'canny', 5*thresh);     
%figure(10), imshow(E), title('Edges');
[H,thetaValues,rhoValues] = hough(E);
myThresh = ceil(0.05*max(H(:)));
NHoodSize = ceil([size(H,1)/50, size(H,2)/50]);
if mod(NHoodSize(1),2)==0  NHoodSize(1) = NHoodSize(1)+1;  end
if mod(NHoodSize(2),2)==0  NHoodSize(2) = NHoodSize(2)+1;  end
peaks = houghpeaks(H, ...
    30, ...             
    'Threshold', myThresh, ...      
    'NHoodSize', NHoodSize);    
%figure(11), imshow(H, []), title('Hough'), impixelinfo;
for i=1:size(peaks,1)
    rectangle('Position', ...
        [peaks(i,2)-NHoodSize(2)/2, peaks(i,1)-NHoodSize(1)/2, ...
        NHoodSize(2), NHoodSize(1)], 'EdgeColor', 'r');
end
[lines1, lines2] = findOrthogonalLines( ...
    rhoValues(peaks(:,1)), ...      
    thetaValues(peaks(:,2)));       
lines1 = sortLines(lines1, size(E));
lines2 = sortLines(lines2, size(E));
[xIntersections, yIntersections] = findIntersections(lines1, lines2);
IMG_SIZE_REF = 100;      
[xIntersectionsRef, yIntersectionsRef] = createReference(IMG_SIZE_REF);
[corners, nMatches, avgErr] = findCorrespondence( ...
    xIntersections, yIntersections, ...         
    xIntersectionsRef, yIntersectionsRef, ...   
    size(E));
end
function [lines1, lines2] = findOrthogonalLines( ...
    rhoValues, ...      
    thetaValues)        
bins = -90:10:90;       
[counts, bins] = histcounts(thetaValues, bins);    
[~,indices] = sort(counts, 'descend');
a1 = (bins(indices(1)) + bins(indices(1)+1))/2;     
for i=2:length(indices)
    if (abs(indices(1)-indices(i)) <= 2) || ...
            (abs(indices(1)-indices(i)+length(indices)) <= 2) || ...
            (abs(indices(1)-indices(i)-length(indices)) <= 2)
        continue;
    else
        a2 = (bins(indices(i)) + bins(indices(i)+1))/2;
        break;
    end
end
%fprintf('Most common angles: %f and %f\n', a1, a2);
lines1 = [];
lines2 = [];
for i=1:length(rhoValues)
    r = rhoValues(i);
    t = thetaValues(i);
    D = 25;     
    if abs(t-a1) < D || abs(t-180-a1) < D || abs(t+180-a1) < D
        lines1 = [lines1 [t;r]];
    elseif abs(t-a2) < D || abs(t-180-a2) < D || abs(t+180-a2) < D
        lines2 = [lines2 [t;r]];
    end
end
end
function lines = sortLines(lines, sizeImg)
xc = sizeImg(2)/2;  
yc = sizeImg(1)/2;
t = lines(1,:);     
r = lines(2,:);     
nLines = size(lines,2);
nVertical = sum(abs(t)<45);
if nVertical/nLines > 0.5
    dist = (-sind(t)*yc + r)./cosd(t) - xc;  
else
    dist = (-cosd(t)*xc + r)./sind(t) - yc;  
end
[~,indices] = sort(dist, 'ascend');
lines = lines(:,indices);
end
function [xIntersections, yIntersections] = findIntersections(lines1, lines2)
N1 = size(lines1,2);
N2 = size(lines2,2);
xIntersections = zeros(N1,N2);
yIntersections = zeros(N1,N2);
for i1=1:N1
    r1 = lines1(2,i1);
    t1 = lines1(1,i1);
    l1 = [cosd(t1); sind(t1); -r1];
    for i2=1:N2
        r2 = lines2(2,i2);
        t2 = lines2(1,i2);
        l2 = [cosd(t2); sind(t2); -r2];
        p = cross(l1,l2);
        p = p/p(3);
        xIntersections(i1,i2) = p(1);
        yIntersections(i1,i2) = p(2);
    end
end
end
function [xIntersectionsRef, yIntersectionsRef] = createReference(sizeRef)
sizeSquare = sizeRef/8;     
[xIntersectionsRef, yIntersectionsRef] = meshgrid(1:9, 1:9);
xIntersectionsRef = (xIntersectionsRef-1)*sizeSquare + 1;
yIntersectionsRef = (yIntersectionsRef-1)*sizeSquare + 1;
end
function [corners, nMatchesBest, avgErrBest] = findCorrespondence( ...
    xIntersections, yIntersections, ...         
    xIntersectionsRef, yIntersectionsRef, ...   
    sizeImg)
pCornersRef = [ ...
    xIntersectionsRef(1,1), yIntersectionsRef(1,1);
    xIntersectionsRef(1,end), yIntersectionsRef(1,end);
    xIntersectionsRef(end,end), yIntersectionsRef(end,end);
    xIntersectionsRef(end,1), yIntersectionsRef(end,1) ];
M = 4;      
DMIN = 4;   
nMatchesBest = 0;   
avgErrBest = 1e9;   
N1 = size(xIntersections,1);
N2 = size(xIntersections,2);
for i1a=1:min(M,N1)
    for i1b=N1:-1:max(N1-M,i1a+1)
        for i2a=1:min(M,N2)
            for i2b=N2:-1:max(N2-M,i2a+1)
                pCornersImg = zeros(4,2);
                pCornersImg(1,:) = [xIntersections(i1a,i2a) yIntersections(i1a,i2a)];
                pCornersImg(2,:) = [xIntersections(i1a,i2b) yIntersections(i1a,i2b)];
                pCornersImg(3,:) = [xIntersections(i1b,i2b) yIntersections(i1b,i2b)];
                pCornersImg(4,:) = [xIntersections(i1b,i2a) yIntersections(i1b,i2a)];
                v12 = pCornersImg(2,:) - pCornersImg(1,:);
                v13 = pCornersImg(3,:) - pCornersImg(1,:);
                if v12(1)*v13(2) - v12(2)*v13(1) < 0
                    temp = pCornersImg(2,:);
                    pCornersImg(2,:) = pCornersImg(4,:);
                    pCornersImg(4,:) = temp;
                end
                T = fitgeotrans(pCornersRef, pCornersImg, 'projective');
                pIntersectionsRefWarp = transformPointsForward(T, ...
                    [xIntersectionsRef(:) yIntersectionsRef(:)]);
                dPts = 1e6 * ones(size(pIntersectionsRefWarp,1),1);
                for i=1:size(pIntersectionsRefWarp,1)
                    x = pIntersectionsRefWarp(i,1);
                    y = pIntersectionsRefWarp(i,2);
                    d = ((x-xIntersections(:)).^2 + (y-yIntersections(:)).^2).^0.5;
                    dmin = min(d);
                    dPts(i) = dmin;
                end
                nMatches = sum(dPts < DMIN);
                avgErr = mean(dPts(dPts < DMIN));
                if nMatches < nMatchesBest
                    continue;
                end
                if (nMatches == nMatchesBest) && (avgErr > avgErrBest)
                    continue;
                end
                avgErrBest = avgErr;
                nMatchesBest = nMatches;
                corners = pCornersImg;
            end
        end
    end
end

end


function drawLines(rhos, thetas, imageSize, color)
for i=1:length(thetas)
    if abs(thetas(i)) > 45
        
        
        x0 = 1;
        y0 = (-cosd(thetas(i))*x0+rhos(i))/sind(thetas(i));
        x1 = imageSize(2);
        y1 = (-cosd(thetas(i))*x1+rhos(i))/sind(thetas(i));
    else
        
        
        y0 = 1;
        x0 = (-sind(thetas(i))*y0+rhos(i))/cosd(thetas(i));
        y1 = imageSize(1);
        x1 = (-sind(thetas(i))*y1+rhos(i))/cosd(thetas(i));
    end
    
    line([x0 x1], [y0 y1], 'Color', color);
    text(x0,y0,sprintf('%d', i), 'Color', color);
end

end
