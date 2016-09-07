% Zhuo Deng
% 08/27/2015
% script for plane segmentation

close all;
addpath('ext/toolbox_nyu_depth_v2');
addpath('src/planeDet');
addpath('src/util');
addpath('src/vis');


% load split data
var = load('data/nyuv2/nyusplits.mat');
set_type = 'test';
if strcmp(set_type, 'test')
    imlist = var.tst - 5000;
else
    imlist = var.trainval - 5000;
end

% create result path
res_path = 'result/nyuv2/planes';
if ~exist(res_path, 'dir')
   mkdir(res_path);
end
data_path = 'data/nyuv2';

% load intrinsic matrix 
K = GetCameraMatrix();


parfor i = 1 : numel(imlist)
   fprintf('processing image %d\n', i); 
   
   if exist(fullfile(res_path, [num2str(imlist(i)), '.mat']), 'file')
      fprintf('file exists, skip ...\n');
      continue; 
   end
   
   % load color image
   I = imread(fullfile(data_path, 'color_crop', [num2str(imlist(i)), '.jpg']));
   %figure; imshow(I); title('color image');
   
   % raw depth
   var = load(fullfile(data_path, 'rawDepth_crop', [num2str(imlist(i)), '.mat']));
   rawDepth = var.rawDepth;
   
   % gravity aligned pcd 
   var = load(fullfile(data_path, 'pcd_align_crop', [num2str(imlist(i)), '.mat']));
   pcd = var.points;

   % plane detection
   % Note: pcd should have cm unit as input
   Pinfo = PlanesDet(pcd, rawDepth);
   
   % save data and visualization
   ParSave(fullfile(res_path, [num2str(imlist(i)), '.mat']), Pinfo);
   vis = Label2Rgb(Pinfo.planesMap);
   imwrite(vis,fullfile(res_path, [num2str(imlist(i)), '.png']));
end