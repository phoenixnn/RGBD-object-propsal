function [bbox_dp, masksDP] = BBfromDPs(inliers, sz)
% bounding boxes directly converted from detected planes 

N = numel(inliers);
if N == 0
   bbox_dp = [];
   masksDP = [];
   return;
end

% cc for each plane region
% SE = strel('square', 5);
regions = [];
for i = 1 : N
   PR = zeros(sz);
   PR(inliers{i}) = 1;
   % morphological process
%    PR = imdilate(PR, SE);
%    PR = imerode(PR, SE);
   % cc
   cc = bwconncomp(PR, 8);
   masks = zeros(sz(1), sz(2), cc.NumObjects);
   for j = 1 : cc.NumObjects
      tmp = zeros(sz);
      tmp(cc.PixelIdxList{j}) = 1;
      masks(:,:,j) = tmp; 
   end
   regions = cat(3, regions, masks);
   if cc.NumObjects > 1
       regions = cat(3, regions, PR);
   end
end

% 
bbox_dp = m_mask2bbox(regions, 1.0);
masksDP = regions;

end

