% propose object segments for each RGB-D image in SUN RGB-D dataset.
% zhuo deng
% 09/02/2015

addpath('ext/toolbox_nyu_depth_v2');
addpath('src/planeDet');
addpath('ext/m_Grabcut');
addpath('ext/m_Grabcut_3D');
addpath('ext/YAEL');
addpath('src/segmentations');

% load split data
var = load('data/nyuv2/nyusplits.mat');
set_type = 'test';
if strcmp(set_type, 'test')
    imlist = var.tst - 5000;
else
    imlist = var.trainval - 5000;
end

% result path
res_path ='result/nyuv2/Seg';
if ~exist(res_path, 'dir')
   mkdir(res_path);
end
data_path = 'data/nyuv2';
bb_path = 'result/nyuv2/BB';
if ~exist(bb_path, 'dir')
   mkdir(bb_path);
end

Kmat = GetCameraMatrix();
for i = 1 % numel(imlist)
   
    if exist(fullfile(res_path, [num2str(imlist(i)), '.mat']), 'file')
       fprintf('file exists, skip ...\n');
       continue; 
    end
    
    % load proposed bbox
    var = load(fullfile('result/nyuv2/BB_init', [num2str(imlist(i)), '.mat']));
    BB = var.BB;
    
    % load rgb and  rawDepth (meters)
    I = imread(fullfile(data_path, 'color_crop', [num2str(imlist(i)), '.jpg']));
    var = load(fullfile(data_path, 'rawDepth_crop', [num2str(imlist(i)), '.mat']));
    rawDepth = var.rawDepth;
    [h, w] = size(rawDepth);
    
    % fill holes based on color  
    rD = rawDepth;
    rD(isnan(rawDepth)) = 0;
    depth_fill = fill_depth_colorization(I, double(rD));
    
    pcd = Depth2PCD(depth_fill) * 100;
    
    % GC2D
    disp('Run GrabCut (RGB) ...');
    seg_GC2D = m_mask5GC_cell(I, BB, true);
    
    % GC3D
    disp('Run GrabCut (RGB-D) ...');
    seg_GC3D = m_mask5GC3D_cell(I, pcd,  BB, true);
 
    % load Watershed masks
    var = load(fullfile('cache/sp', num2str(imlist(i)), 'WSMasks_c.mat'));
    seg_WS = var.masksWS_cell;
    
    % MS
    K = [300, 500];  MIN = 200;  sigma = 0.5;
    seg_MS = GraphBasedSegmentation( I, pcd, K, MIN, sigma);
    
    % DP
    var = load(fullfile('cache/sp', num2str(imlist(i)), 'DPMasks_c.mat'));
    seg_DP = var.masksDP_cell;
    
    % remove duplicated
    seg = RemoveDupGCxD(seg_GC2D, seg_GC3D, [h, w]);
    clear seg_GC2D seg_GC3D; 
    segCells = cat(1, seg, seg_DP, seg_WS, seg_MS);
    clear seg_DP seg_WS seg_MS seg;
    fprintf('number of segs (before): %d\n', numel(segCells));
    seg_Full = RemoveDupSeg(segCells, [h, w]); 
    fprintf('number of segs (after): %d\n', numel(seg_Full));
    save(fullfile(res_path, [num2str(imlist(i)), '.mat']), 'seg_Full', '-v7.3');
    
    %
    N = numel(segCells);
    BB_Full_seg = zeros(N,4);
    for j = 1 : N
       tmp = zeros(h, w); 
       tmp(segCells{j}) = 1;
       BB_Full_seg(j,:) = m_mask2bbox(tmp);
    end 
    save(fullfile(bb_path, [num2str(imlist(i)), '.mat']), 'BB_Full_seg', '-v7.3');
      
end

