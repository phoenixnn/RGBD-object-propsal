function segCells = m_mask5GC_cell(I, BB, isRescale)
% get segments from bounding box by using grabcut
%
% Inputs:
%      I: color image
%     BB: bounding boxes. N x 4
% Outputs:
%  segCells: Nx1
if nargin < 3
    isRescale = false;
end

[org_h, org_w, ~] = size(I);
if isRescale
    I = imresize(I, 0.5);
end

im = double(I);
[h, w, ~] = size(I);
N = size(BB, 1);

% hard constraints 
mask_fixed_fg = false(h, w);
mask_fixed_bg = false(h, w);

%
segCells = cell(N, 1);
parfor i = 1 : N
    tmp = m_BB2mask(BB(i,:), [org_h, org_w]);
    if isRescale
        tmp = tmp(1:2:end, 1:2:end);
    end
     
    segMask = m_Grabcut(im, tmp, mask_fixed_fg, mask_fixed_bg);
    if isRescale
        segMask = imresize(segMask, [org_h, org_w], 'nearest');
    end
    
    segCells{i} = find(segMask);
end

end

