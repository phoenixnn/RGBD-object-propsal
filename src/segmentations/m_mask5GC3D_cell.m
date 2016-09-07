function segCells = m_mask5GC3D_cell(I, points, BB, isRescale)
% get segments from bounding box by using grabcut rgbd
%
% Inputs:
%      I: color image
% points: 3d points 
%     BB: bounding boxes. N x 4
% Outputs:
%  segCells: Nx1
if nargin < 4
    isRescale = false;
end
[org_h, org_w, ~] = size(I);
if isRescale
    I = imresize(I, 0.5);
    points = imresize(points, 0.5);
end

[h, w, ~] = size(I);
im = double(I);
mask_fixed_fg = false(h, w);
mask_fixed_bg = false(h, w);


% run RGBD grab cut
N = size(BB, 1);
segCells = cell(N, 1);
parfor i = 1 : N
    tmp = m_BB2mask(BB(i,:), [org_h, org_w]);
    if isRescale
        tmp = tmp(1:2:end, 1:2:end);
    end
    segMask = m_Grabcut_3D( im, points, tmp, mask_fixed_fg, mask_fixed_bg);
    if isRescale
        segMask = imresize(segMask, [org_h, org_w], 'nearest');
    end
    segCells{i} = find(segMask);
end

end

