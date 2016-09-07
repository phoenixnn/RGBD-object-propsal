function [isV, isH, isB] = m_classify_planes(planes, points)
%  classify planes into horizontal,  vertical, boundary

% Inputs: 
%  planes: N x 4  parametric matrix
%  points: m x n x 3 3d coordinates
%
% Outputs: indicators for type
%  isV: 
%  isH:
%  isB:

num_planes = size(planes,1);
%  angles with ny:  cos(alpha) = ny
angles = acos(abs(planes(:,2))) * 180 /pi;
th = 10;
% vertical 
isV = angles > (90-th);
% horizontal
isH = angles < th;

% make planes normal point to viewer
direction = planes(:,4) < 0 ;
sign = ones(num_planes, 1);
sign(direction) = -1;
sign = repmat(sign, 1,4);
planes = planes .* sign;

% compute distance to planes
[h, w, ~] = size(points);
rawDepth = points(:,:,3);
tolerance_d = 1 * 2.85e-5 * rawDepth(:).^2;
pts = reshape(points, [], 3);
pts_homo = [pts ones(h*w, 1)];

dist = planes * pts_homo';
offset = repmat(3 * tolerance_d', num_planes, 1); 
dist = dist + offset;
outbound = dist < 0;
non_missing = ~isnan(rawDepth);
outbound = outbound(:, non_missing);
N_out = size(outbound,2);
num_outbound = sum(outbound, 2);
ratio = num_outbound / N_out;

isB = ratio < 0.01;

end

