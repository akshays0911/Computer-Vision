clear all, close all
I2 = imread('facebook.jpg');
I1 = imread('US_Cellular.jpg');
% Find 4 corners of picture.
if ~exist('points.mat', 'file')
% Start the GUI to select corresponding points
[Pts1,Pts2] = cpselect(I1,I2, 'Wait', true);
save('points.mat', 'Pts1', 'Pts2');
else
load('points.mat');
end

% Display for verification
imshow(I1, []);
for i=1:size(Pts1,1)
rectangle('Position', [Pts1(i,1)-4 Pts1(i,2)-4 8 8], 'EdgeColor', 'r');
text(Pts1(i,1), Pts1(i,2), sprintf('%d', i));
end
figure, imshow(I2, []);
for i=1:size(Pts2,1)
rectangle('Position', [Pts2(i,1)-4 Pts2(i,2)-4 8 8], 'EdgeColor', 'r');
text(Pts2(i,1), Pts2(i,2), sprintf('%d', i));
end

% Transform image 2 to image 1. Now the new picture is in
% the right place to replace the old picture.
T21 = fitgeotrans(Pts2, Pts1, 'projective');
I2warp = imwarp(I2, T21, 'OutputView', ...
imref2d(size(I1), [1 size(I1,2)], [1 size(I1,1)]), ...
'Interp', 'cubic');
figure, imshow(I2warp, []);

% We need to create a polygon mask for the area of the photo.
Iphoto = poly2mask(Pts1(:,1), Pts1(:,2), size(I1,1), size(I1,2));
Ibackground = ~Iphoto; % Also for the background
figure, imshow(Iphoto), title('Mask for photo');
figure, imshow(Ibackground), title('Mask for background');

% The masks should be the same type as the input image.
Iphoto = uint8(Iphoto);
Ibackground = uint8(Ibackground);
% Combine pictures
if size(I1,3) == 1
% Grayscale image
Icombined = I1 .* Ibackground + I2warp .* Iphoto;
elseif size(I1,3) == 3
% RGB image
Icombined(:,:,1) = I1(:,:,1) .* Ibackground + I2warp(:,:,1) .* Iphoto;
Icombined(:,:,2) = I1(:,:,2) .* Ibackground + I2warp(:,:,2) .* Iphoto;
Icombined(:,:,3) = I1(:,:,3) .* Ibackground + I2warp(:,:,3) .* Iphoto;
else
fprintf('Unknown color model\n');
end
figure, imshow(Icombined, []);