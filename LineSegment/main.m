clear all
close all

%I = imread('circuit.tif');
%I = imread('lighthouse.png');
I = imread('checkerboard.jpg');
%I = imread('tape.png');
%I = imread('gantrycrane.png');

if size(I,3) > 1
    I = rgb2gray(I);
end
[height,width] = size(I);

% Extract edge points.
sigma = 0.005*width;    % Sigma will be a fraction of image width
E = edge(I, 'canny', ...
    [], ...     % threshold, use [] to pick automatically
    'both', ... % direction (not used with canny operator)
    sigma);   % sigma
figure, imshow(E,[]);


% Find line segments in the image. Line segments are represented by a Nx4
% array, where each row is a segment, and is composed of
%  p1x,p1y, p2x,p2y

DTHRESH = 2.0;  % Max distance between original curve and its approximation (pixels)
MINLENGTH = round(0.025*width);     % Minimum length of a line segment (in pixels)

lineSegs = fitLineSegments(E, DTHRESH, MINLENGTH);
figure, imshow(I,[]);
sub_drawLineSegments(lineSegs);

