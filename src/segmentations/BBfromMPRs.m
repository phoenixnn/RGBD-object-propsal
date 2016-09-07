function [ bbox, Masks ] = BBfromMPRs( inliers, points )
%  propose object bounding box by merging plane regions
% 
% Inputs:
%  inliers: N x 1 cell
%  points: n x m x 3 pcd
% 
% Outputs:
% bbox: bounding boxes
% Masks: corresponding regions for bbox

[h, w, ~] = size(points);
N = numel(inliers);

% cc for each plane region
% SE = strel('square', 5);
regions = [];
for i = 1 : N
   PR = zeros(h,w);
   PR(inliers{i}) = 1;
   % morphological process
%    PR = imdilate(PR, SE);
%    PR = imerode(PR, SE);
   % cc
   cc = bwconncomp(PR, 8);
   masks = zeros(h, w, cc.NumObjects);
   for j = 1 : cc.NumObjects
      tmp = zeros(h, w);
      tmp(cc.PixelIdxList{j}) = 1;
      masks(:,:,j) = tmp; 
   end
   regions = cat(3, regions, masks);
end

% find borders for each region
NR = size(regions,3);
borders = cell(NR, 1);
for i = 1 : NR
   borders{i} = find( FindBorderPixels(regions(:,:,i))); 
end

% create min dist matrix
pts = reshape(points, [], 3);
distMat = zeros(NR, NR);
for i = 1 : (NR-1)
    pcd1 = pts(borders{i},:); 
    for j = (i+1) : NR
        pcd2 = pts(borders{j},:);
        dist = pdist2(pcd1, pcd2);
        distMat(i,j) = min(dist(:));
    end
end
distMat = distMat + distMat';

% merge PRs
th = 10; % cm
CC = m_graphCC(NR, distMat, th);

% convert to bounding box
Masks = [];
bbox = [];
for i = 1 : numel(CC)
    if numel(CC{i}) > 1
        PR = regions(:,:,CC{i});
        PR = sum(PR, 3);
        Masks = cat(3, Masks, PR);
        bb = m_mask2bbox(PR, 1.0);
        bbox = cat(1,bbox, bb);
    end
end

end

function cc = m_graphCC(N_node, distMat, th)

edges = (distMat < th);
edges(logical(eye(N_node, N_node))) = false;
cc = {};
isExplored = false(N_node,1);

for i = 1 : N_node
   if ~isExplored(i)
       Q = i;
       ids = i;
       isExplored(i) = true;
       while ~isempty(Q)
           v = Q(1);
           Q(1) = [];
           % find neighbors
           Ne = find(edges(v,:)' & ~isExplored);
           % update
           ids = [ids; Ne];
           Q = [Q; Ne];
           isExplored(Ne) = true;
       end
       cc = cat(1, cc, ids);
   end
end

end

