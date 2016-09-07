function [bbox, segMasks] = HierClustering(points, clusterTolerance, inliers, isV, isH, isB, pid)
%  spatial pcd partition by euclidean clustering
%  note plane points are removed
%
% Inputs:
%    points: mxnx3 pcd
%    clusterTolerance: Lx1 (cm)
%    inliers: NX1 cell for plane inliers
%    isV, isH, isB: plane types
% 
% Outputs:
%   bbox: bounding boxes
%   segMasks: corresponding masks

%% remove plane points from pcd
[h,w,~] = size(points);
pts = reshape(points, [], 3);
N = size(pts, 1);
ind = (1 : N)';
planeIdx = [];
%planeId = find(isV | isH | isB);

new_isH = m_filter_HVP(inliers, isH, [h, w], 6000);
%planeId = find(isV | new_isH | isB);

new_isV = m_filter_HVP(inliers, isV, [h, w], 25000);
planeId = find(new_isH | isB |new_isV);
for i = 1 : numel(planeId)
    planeIdx = cat(1, planeIdx, inliers{planeId(i)}');
end

% get remaining point index
isMissing = isnan(pts(:,3));
ind = ind(~isMissing);
ind = setdiff(ind, planeIdx);
% get remaining points
pcd = pts(ind, :);
pcd = pcd/100; % convert to meters
pcdFile = fullfile('src/segmentations', [num2str(pid) '.pcd']);
mat2PCDfile(pcdFile,double(pcd));



%% clustering
segMasks = [];
clusterTolerance = clusterTolerance/100; % use meters
for i = 1 : numel(clusterTolerance)
    % euclidean clustering
    system(sprintf('src/segmentations/m_pcd_clustering.out %s %d %d', ...
                   pcdFile, clusterTolerance(i), pid));
    % read in result from text file
    txtFile = ['clusters_', num2str(pid), '.txt'];
    clusters = load(fullfile('./', txtFile));
    % save mask
    nC = max(clusters);
    for j = 1 : nC
        tmp = zeros(h, w);
        idx = ind(clusters == j);
        tmp(idx) = 1;
        mask = cell(1,1);
        mask{1,1} = find(tmp);
        segMasks = cat(1, segMasks, mask);
    end
    system(['rm ./', txtFile]);
end


%% convert to bounding box
bbox = Mask2Bbox(segMasks,[h, w], 1.0);
area = bbox(:,3).* bbox(:,4);
[~,idx] = sort(area, 'descend');
bbox = bbox(idx,:);
segMasks = segMasks(idx);
[bbox, ind] = RemoveDupBbox(bbox, 0.8);
segMasks = segMasks(ind);

system(['rm ' pcdFile]);
end

% function m_vis_clustering(pcd, clusters)
% c = m_label2rgb(clusters);
% c = uint8(255 * reshape(c,[],3));
% pointRGB = cat(2, pcd, single(c));
% mat2PCDfile('./visualization/vis_clustering.pcd',double(pointRGB));
% system('./visualization/m_pclViewer.out  ./visualization/vis_clustering.pcd');
% end

function  new_isH = m_filter_HVP(inliers, isH, sz, th)
N = numel(isH);

for i = 1 : N
   if ~isH(i)
       continue;
   end
   
   PR = zeros(sz);
   PR(inliers{i}) = 1;
   % cc
   cc = bwconncomp(PR, 8);
   count = zeros(cc.NumObjects,1);
   for j = 1 : cc.NumObjects
      count(j) = numel(cc.PixelIdxList{j}); 
   end
   % 
   ind = find(count > th);
   if isempty(ind)
       isH(i) = false;
   end
end
new_isH = isH;
end