function [ bbox, segMasks] = BBfromNPRs( masks, masksWS, planesMap )
%   propose bounding box from Non-planar regions

% Inputs:
%  masks: Lx1 cell segment masks
%  masksWS: M x 1 cell
%  planesMap: mxn plane map from plane detection
%
% Outputs:
%  bbox:  bounding boxes
%  segMasks: corresponding segments Nx1 cell
debug = false;

% masks = logical(masks);
% [h, w, d] = size (masks);
[h, w] = size(planesMap);
d = numel(masks);
fprintf('# of masks from multi-scale segmentation: %d\n', d + numel(masksWS));

% morphological processing to fill small holes
planar = (planesMap ~= 0);
SE = strel('square', 3); 
planar = imdilate(planar, SE);
planar = imerode(planar, SE);
non_planar = ~planar;

% morphological processing to remove little wires
SE = strel('square', 5);
survive = true(d, 1);
for i = 1 : d
    mask = false(h, w);
    mask(masks{i}) = true;
    mask = imerode(mask, SE);
    mask = imdilate(mask, SE);
    masks{i} = find(mask);
    if numel(masks{i}) == 0
       survive(i) = false;
    end
end
masks = masks(survive);

% add wshed here
masks = cat(1, masks, masksWS);
d = numel(masks);
if debug
   fprintf('# of masks after little wires criteria: %d\n', d);
end

% consider use other strategy to filter out masks further 
% p/np ratio
survive = true(d,1);
for i = 1 : d
    mask = false(h, w);
    mask(masks{i}) = true;
    tmp = non_planar(mask);
    rt = sum(tmp(:))/sum(mask(:));
    if rt < 0.2
        survive(i) = false;
    end
end
d = sum(survive);
if debug
   fprintf('# of masks after p/np ratio criteria: %d\n', d);
end
masks = masks(survive);

% compute bounding box
scale = 1.0;
bbox = Mask2Bbox(masks, [h, w], scale);

% remove duplicated boxes
area = bbox(:,3).* bbox(:,4);
[~, ind] = sort(area, 'descend');
bbox = bbox(ind,:);
masks = masks(ind);
[bbox, ind] = RemoveDupBbox(bbox, 0.98);
masks = masks(ind);
if debug
   fprintf('# of masks after remove duplicated criteria: %d\n', size(bbox,1));
end

% filter out bbox which have small overlap with non-planar
[bbox, ind] = RemoveBadBbox(bbox, non_planar, 0.1);
masks = masks(ind);
if debug
   fprintf('# of masks after box overlap criteria: %d\n', size(bbox,1));
end

% nms
[bbox, ind] = RemoveDupBbox(bbox, 0.9);
segMasks = masks(ind);
if debug
   fprintf('# of masks after nms criteria: %d\n', size(bbox,1));
end


end

