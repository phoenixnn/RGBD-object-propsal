function [ bbox, segMasks ] = BBfromPRs (segMasks,sz, inliers)
%  propose bounding box on planar regions
%
% Inputs:
%   segMasks: L x 1 cell segment masks from segmentation
%   inliers: N x 1 cell plane points
% 
% Outputs:
%   bbox: bounding boxes on planes
debug = false;

h = sz(1);
w = sz(2);
num_seg = numel(segMasks);
N = numel(inliers);

if N == 0
   bbox = [];
   segMasks = [];
   return;
end

% reform planes map
planesMap = zeros(h, w);
SE = strel('square', 5);
id = 1;
NPX = [];
for i = 1 : N
    PR = zeros(h, w);
    PR(inliers{i}) = 1;
    % morphological process
    PR = imdilate(PR, SE);
    PR = imerode(PR, SE);
    % cc
    cc = bwconncomp(PR, 8);
    for j = 1 : cc.NumObjects
        planesMap(cc.PixelIdxList{j}) = id;
        id = id + 1;
        NPX = [NPX; numel(cc.PixelIdxList{j})];
    end
end
num_planar = numel(NPX);
if debug
fprintf('# masks on planes (before filter): %d\n', num_seg); 
end

% filter out segments 
survive = true(num_seg,1);
for i = 1 : num_seg
    mask = false(h, w);
    mask(segMasks{i}) = true;
    
    tmp = planesMap(mask);
    num_pixels = numel(tmp);
    tmp(tmp==0) = [];
    bins = histc(tmp, 1:num_planar);
    if numel(tmp) == 1
        bins = bins';
    end
    r = bins./NPX;
    maxr = max(r);
    r1 = sum(bins)/num_pixels;
    if maxr > 1.0 || r1 < 0.2
        survive(i) = false;
    end
end

segMasks = segMasks(survive);
if debug
fprintf('# masks on planes (after filter): %d\n', size(segMasks,3));
end

% change to bbox
bbox = Mask2Bbox(segMasks, [h, w], 1.0);

% remove duplicated boxes
area = bbox(:,3).* bbox(:,4);
[~, ind] = sort(area, 'descend');
bbox = bbox(ind,:);
segMasks = segMasks(ind);
[bbox, ids] = RemoveDupBbox(bbox, 0.98);
segMasks = segMasks(ids);
if debug
fprintf('# of masks on planes after remove duplicated criteria: %d\n', size(bbox,1));
end

% nms
[bbox, ids] = RemoveDupBbox(bbox, 0.8);
segMasks = segMasks(ids);
num_seg = numel(segMasks);
if debug
fprintf('# of masks after nms criteria: %d\n', num_seg);
end


% bad bounding box
% [bbox, ids] = m_removeBadBB_planar(bbox, planesMap, NPX, 0.9);
% segMasks = segMasks(:,:,ids);
% num_seg = size(segMasks,3);
% if debug
% fprintf('# of masks after remove bad bbs: %d\n', num_seg);
% end

% aspect ratio
aspect1 = bbox(:,3)./bbox(:,4);
aspect2 = bbox(:,4)./bbox(:,3);
aspect = min([aspect1 aspect2], [],2);
survive = aspect > 0.04;
bbox = bbox(survive,:);
segMasks = segMasks(survive);
num_seg = numel(segMasks);
if debug
fprintf('# of masks after remove aspect bb: %d\n', num_seg);
end


end

function [out, survive] = m_removeBadBB_planar(bbox, planesMap, NPX, th)
N = size(bbox,1);
survive = true(N,1);
num_planar = numel(NPX);
for i = 1 : N
    rBegin = bbox(i,2);
    rEnd = rBegin + bbox(i,4) -1;
    cBegin = bbox(i,1);
    cEnd = cBegin + bbox(i,3) -1;
    tmp = planesMap(rBegin:rEnd, cBegin:cEnd);
    tmp = tmp(:);
    tmp(tmp==0) = [];
    bins = histc(tmp, 1:num_planar);
    if numel(tmp) == 1
        bins = bins';
    end
    r = bins./NPX;
    maxr = max(r);
    if maxr > th
        survive(i) = false;
    end
end

out = bbox(survive,:);

end

