function [ masks_cell ] = GraphBasedSegmentation( I, points, K, MIN, sigma)
%  generate segment masks from multiscale, multi-channel graph
%  based segmentation
debug = false;
% grayscale depth image
rawDepth = points(:,:,3);
maxi = max(rawDepth(:));
mini = min(rawDepth(:));
grayIm = uint8(255 * (rawDepth - mini)/(maxi-mini));
grayIm(isnan(rawDepth)) = 0;
grayIm = cat(3, grayIm, grayIm, grayIm);

% normalized x y z (uint8)
x = points(:,:,1);
y = points(:,:,2);
z = points(:,:,3);
x = uint8(255*(x - min(x(:))) / (max(x(:)) - min(x(:))));
y = uint8(255*(y - min(y(:))) / (max(y(:)) - min(y(:))));
z = uint8(255*(z - min(z(:))) / (max(z(:)) - min(z(:))));
pts = cat(3, x,y,z);
pts = double(pts);

masks_cell = [];
for i = 1 : numel(K)
  % color image
  [mapColor, ~] = m_segmentWrapper(I, nan(size(I)), K(i), MIN, sigma);
  tmp = Label2Mask(mapColor);
  masks_cell = cat(1, masks_cell, tmp);

  % depth image (grayscale)
  [mapDepth, ~] = m_segmentWrapper(grayIm, nan(size(I)), K(i), MIN, sigma);
  tmp = Label2Mask(mapDepth);
  masks_cell = cat(1, masks_cell, tmp);

  % color + depth
  [map, ~] = m_segmentWrapper(I, pts, K(i), MIN, sigma);
  tmp = Label2Mask(map);
  masks_cell = cat(1, masks_cell, tmp);
  
  % visualization
  if (debug)
      imc = ColorizeLabelImage(int32(mapColor));
      imd = ColorizeLabelImage(int32(mapDepth));
      imcd = ColorizeLabelImage(int32(map));

      im1 = cat(2, I, imc);
      im2 = cat(2, imd, imcd);
      figure;
      im = cat(1, im1, im2);
      imshow(im);
  end
end

end

