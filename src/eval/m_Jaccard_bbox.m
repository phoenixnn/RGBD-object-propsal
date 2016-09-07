function [ J ] = m_Jaccard_bbox( gt, bbox )
% compute Jaccard index for overlapping between gt and bbox
% Inputs:
% gt: 1 x 4; [Cmin, Rmin, width, height]
% bbox : 1 x 4; [Cmin, Rmin, width, height]
% Outputs:
% J: Jaccard index

% convert to [Cmin, Rmin, Cmax, Rmax]
coor_gt = gt;
coor_gt(3) = gt(1) + gt(3) - 1;
coor_gt(4) = gt(2) + gt(4) - 1;

a1 = gt(3)*gt(4);

coor_bbox = bbox;
coor_bbox(3) = bbox(1) + bbox(3) - 1;
coor_bbox(4) = bbox(2) + bbox(4) - 1;

a2 = bbox(3) * bbox(4);

%
minr1 = coor_gt(2);
maxr1 = coor_gt(4);
minc1 = coor_gt(1);
maxc1 = coor_gt(3);
%
minr2 = coor_bbox(2);
maxr2 = coor_bbox(4);
minc2 = coor_bbox(1);
maxc2 = coor_bbox(3);
% intersection area
ri_1 = max(minr1, minr2);
ci_1 = max(minc1, minc2);
ri_2 = min(maxr1, maxr2);
ci_2 = min(maxc1, maxc2);

hi = ri_2 - ri_1 + 1;
wi = ci_2 - ci_1 + 1;
IA = 0;
if (hi > 0) && (wi > 0)
    IA = hi * wi;
end
% union area
UA = a1 + a2 - IA;
assert(UA > 0);
%
J = IA / UA;

end

