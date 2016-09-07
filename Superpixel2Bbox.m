% bounding boxes proposal from superpixels
% zhuo deng
% 08/31/2015

close all;

addpath('src/segmentations');
addpath('ext/EGBS3D');

% load split data
var = load('data/nyuv2/nyusplits.mat');
set_type = 'test';
if strcmp(set_type, 'test')
    imlist = var.tst - 5000;
else
    imlist = var.trainval - 5000;
end

% result path
res_path ='result/nyuv2/BB_init';
if ~exist(res_path, 'dir')
   mkdir(res_path);
end
data_path = 'data/nyuv2';

sp_path = 'cache/sp';
if ~exist(sp_path, 'dir')
   mkdir(sp_path);
end

% load intrinsic matrix 
Kmat = GetCameraMatrix();

parfor i = 1 : 1 %1 : numel(imlist)
   fprintf('processing image %d\n', i); 
   
   if exist(fullfile(res_path, [num2str(imlist(i)), '.mat']), 'file')
      fprintf('file exists, skip ...\n');
      continue; 
   end
   
   if ~exist(fullfile(sp_path, num2str(imlist(i))), 'dir')
      mkdir(fullfile(sp_path, num2str(imlist(i))));
   end
   
   % load color image, aligned points
   I = imread(fullfile(data_path, 'color_crop', [num2str(imlist(i)), '.jpg']));
   [h, w, d] = size(I); 
   
   % raw depth
   var = load(fullfile(data_path, 'rawDepth_crop', [num2str(imlist(i)), '.mat']));
   rawDepth = var.rawDepth;
   
   % gravity aligned pcd 
   var = load(fullfile(data_path, 'pcd_align_crop', [num2str(imlist(i)), '.mat']));
   pcd = var.points;
   
   %% multi-scale graph based segmentations
   % parameters
   K = [100, 300, 500]; MIN = 200; sigma = 0.5;
   
   % collect masks
   masks_cell = GraphBasedSegmentation( I, pcd, K, MIN, sigma);
   
   % load plane detections
   var = load (fullfile('result/nyuv2/planes', [num2str(imlist(i)), '.mat']));
   Pinfo = var.Pinfo;   
   planesMap = Pinfo.planesMap;
   planes = Pinfo.planes;
   inliers = Pinfo.inliers;
   
   % watershed
   rD = rawDepth;
   rD(isnan(rawDepth)) = 0;
   depth_fill = fill_depth_colorization(I, double(rD));
   masksWS_cell = WatershedSegmentation(I, rawDepth, depth_fill);
   
   % bounding boxes from non-planar regions
   [bbox_np, ~] = BBfromNPRs(masks_cell, masksWS_cell, planesMap);  
   BB1 = m_rescale_bbox(bbox_np, [h,w], 1.3);
   bbox_np = cat(1, bbox_np, BB1);
   ParSave(fullfile(sp_path, num2str(imlist(i)),'WSMasks_c.mat'), masksWS_cell);
   
   % big region proposals from planes
   [isV, isH, isB] = m_classify_planes(planes, pcd);
   bbox_b = BBfromMPRs(inliers(~isB), pcd);
   
   % object on vertical and horizontal plane proposals
   tmp = [];
   for j = 1:numel(K)
       [mapColor, ~] = m_segmentWrapper(I, nan(size(I)), K(j), MIN, sigma);
       tmp = cat(1, tmp, Label2Mask(mapColor));
   end
   [mapColor, ~] = m_segmentWrapper(I, nan(size(I)), 300, 200, 0.2);
   tmp = cat(1, tmp, Label2Mask(mapColor), masksWS_cell);
   [bbox_p, ~ ] = BBfromPRs (tmp, [h, w], inliers);

   
   % hierarchical clustering
   clusterTolerance = [2, 5, 10];
   [bbox_hc, masksHC_cell] = HierClustering(pcd, clusterTolerance, inliers, isV, isH, isB, i);
   BB1 = m_rescale_bbox(bbox_hc, [h,w], 1.3);
   bbox_hc = cat(1, bbox_hc, BB1);
   
   % detected plane proposals
   [bbox_dp, masksDP] = BBfromDPs(inliers, [h, w]);
   masksDP_cell = Mask2Cell(masksDP);
   ParSave(fullfile(sp_path, num2str(imlist(i)),'DPMasks_c.mat'), masksDP_cell);
   masksNPR_cell = [];
   

   % all bbox
   BB = cat(1, bbox_np, bbox_b, bbox_p, bbox_hc, bbox_dp);
   validBB = (BB(:,3) > 1) & (BB(:,4) >1); 
   BB = BB(validBB, :);
   area = BB(:,3).*BB(:,4);
   [~, ind] = sort(area, 'descend');
   BB = BB(ind, :);
   [BB, ~] = RemoveDupBbox(BB, 0.98);
   
   % save
   ParSave(fullfile(res_path, [num2str(imlist(i)), '.mat']), BB);
end
