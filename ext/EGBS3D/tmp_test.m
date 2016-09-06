% parameters
K = 100;
MIN = 200;
sigma = 0.5;
pid = 34;

% color image
Img = imread(fullfile('./data/NYUV2/nyu_color_crop/',[num2str(pid) '.jpg']));
pts = nan(size(Img));
[mapColor, ~] = m_segmentWrapper(Img, pts, K, MIN, sigma);

% depth image (grayscale)
load (fullfile('./data/NYUV2/m_pcdAlign/',[num2str(pid) '.mat']));
rawDepth = points(:,:,3);
maxi = max(rawDepth(:));
mini = min(rawDepth(:));
grayIm = uint8(255 * (rawDepth - mini)/(maxi-mini));
grayIm(isnan(rawDepth)) = 0;
grayIm = cat(3, grayIm, grayIm, grayIm);
[mapDepth, ~] = m_segmentWrapper(grayIm, pts, K, MIN, sigma);

% color + depth;
t = tic; 
% normalize
x = points(:,:,1);
y = points(:,:,2);
z = points(:,:,3);
x = uint8(255*(x - min(x(:))) / (max(x(:)) - min(x(:))));
y = uint8(255*(y - min(y(:))) / (max(y(:)) - min(y(:))));
z = uint8(255*(z - min(z(:))) / (max(z(:)) - min(z(:))));
pts = cat(3, x,y,z);
pts = double(pts);
[map, N] = m_segmentWrapper(Img, pts, K, MIN, sigma); 
toc(t)

% visualization
imc = ColorizeLabelImage(int32(mapColor));
imd = ColorizeLabelImage(int32(mapDepth));
imcd = ColorizeLabelImage(int32(map));

im1 = cat(2, Img, imc);
im2 = cat(2, imd, imcd);
im = cat(1, im1, im2);
figure;
imshow(im);



