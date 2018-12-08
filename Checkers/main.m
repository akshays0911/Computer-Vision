clear all
close all
countWhite = zeros(8,8);
countBlack = zeros(8,8);
movieObj = VideoReader('checkers.mp4');
nFrames = movieObj.NumberOfFrames;

for iFrame=1:10:nFrames
    I = read(movieObj,iFrame);
    fprintf('Frame %d\n', iFrame);
    if size(I,2)>640
        I = imresize(I, 640/size(I,2));
    end
    figure(1), imshow(I), title(sprintf('Frame %d', iFrame));
    % A checkerboard is found in every 10th frame and four corners of the checkerboard are returned in the form of 4X2 array
    [corners, nMatches, avgErr] = findCheckerBoard(I);
    figure(1)
    if nMatches < 64
        text(40,40, 'No board found', 'Color', 'k', 'BackgroundColor', 'w');
        pause(0.2);
        continue;
    end
    line([corners(1,1) corners(2,1)], [corners(1,2) corners(2,2)], 'Color', 'g', 'LineWidth', 3);
    line([corners(2,1) corners(3,1)], [corners(2,2) corners(3,2)], 'Color', 'g', 'LineWidth', 3);
    line([corners(3,1) corners(4,1)], [corners(3,2) corners(4,2)], 'Color', 'g', 'LineWidth', 3);
    line([corners(4,1) corners(1,1)], [corners(4,2) corners(1,2)], 'Color', 'g', 'LineWidth', 3);
    L = 400;
    cornersRef = [ 1,1; L,1; L,L; 1,L ];
    T = fitgeotrans(corners, cornersRef, 'projective');
    Oboard = imwarp(I, T, 'OutputView', imref2d([L L], [1 L], [1 L])); %orthoboard
    figure(2), imshow(Oboard, []), title(sprintf('Frame %d', iFrame));
    [detectedBlack, detectedWhite] = findCheckerPieces(Oboard);
    R0 = 0.3*L/8;       
    [rows,cols] = find(detectedBlack);
    for i=1:length(rows)
        x0 = (cols(i)-0.5)*(L/8);
        y0 = (rows(i)-0.5)*(L/8);
        rectangle('Position', [x0-R0 y0-R0 2*R0+1 2*R0+1], 'EdgeColor', 'b', 'Curvature', [1 1], 'LineWidth', 3);
    end
    [rows,cols] = find(detectedWhite);
    for i=1:length(rows)
        x0 = (cols(i)-0.5)*(L/8);
        y0 = (rows(i)-0.5)*(L/8);
        rectangle('Position', [x0-R0 y0-R0 2*R0+1 2*R0+1], 'EdgeColor', 'w', 'Curvature', [1 1], 'LineWidth', 3);
    end
    countWhite = countWhite + detectedWhite;
    countBlack = countBlack + detectedBlack;
    pause(0.5);
end
MINCOUNT = 5;
finalWhite = countWhite >= MINCOUNT;
finalBlack = countBlack >= MINCOUNT;
figure(3), imshow(Oboard, []), title('Final');
R0 = 0.3*L/8;       
[rows,cols] = find(finalBlack);
for i=1:length(rows)
    x0 = (cols(i)-0.5)*(L/8);
    y0 = (rows(i)-0.5)*(L/8);
    rectangle('Position', [x0-R0 y0-R0 2*R0+1 2*R0+1], 'EdgeColor', 'b', 'Curvature', [1 1], 'LineWidth', 3);
end
[rows,cols] = find(finalWhite);
for i=1:length(rows)
    x0 = (cols(i)-0.5)*(L/8);
    y0 = (rows(i)-0.5)*(L/8);
    rectangle('Position', [x0-R0 y0-R0 2*R0+1 2*R0+1], 'EdgeColor', 'w', 'Curvature', [1 1], 'LineWidth', 3);
end
disp(countWhite)
disp(countBlack)