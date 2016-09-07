function [ normals ] = CalcNormals( points )
% compute normals for each pixel
% 
% Inputs:
%  points: mxnx3 cm
%  rawDepth: mxn cm 
%
% Output:
% normals: mxnx4
rawDepth = points(:,:,3); % delete later!!!
[h, w] = size(rawDepth);
pts = reshape(points, [], 3);
pts_homo = [pts ones(h*w, 1)];

bw = [-9:2:-1 0 1 : 2 : 9];
[bc, br] = meshgrid(bw, bw);

non_missing = ~isnan(rawDepth(:));
normals = NaN(h*w, 4);
[ci, ri] = meshgrid(1 : w, 1 : h);

parfor k = 1 : (h*w)
    
    if non_missing(k) == false
        continue;
    end
    
    u = ri(k);
    v = ci(k);
    ROI_r = u + br;
    ROI_c = v + bc;
    % ensure that ROI is within image.
    valid = (ROI_r >= 1) & (ROI_c >= 1) & (ROI_r <= h) & (ROI_c <= w);
    u1 = ROI_r(valid);
    v1 = ROI_c(valid);
    ind = u1 + (v1-1)*h;
    % ensure that neighbor pixels have similar depth value (not good!)
    valid = abs(rawDepth(ind) - rawDepth(k)) ...
             < (rawDepth(k) * 0.05);
    ind = ind(valid);
    % ensure that NaN depth is removed
    valid = non_missing(ind);
    ind = ind(valid);
    
    % calculate normal by fitting plane to points with RANSAC
%     pts_candidates = pts_homo(ind, :);
%     p = m_normal_ransac(pts_candidates, pts_homo(k,:));
%     if ~isempty(p)
%         normals(k, :) = p';
%     end
    if numel(ind) >= 3
        A = pts_homo(ind, :);
        [v, l] = eig(A'*A);
        p = v(:,1);
        p = p/norm(p(1:3));
        normals(k,:) = p';
    end
end

normals = reshape(normals, [h,w,4]);
end

