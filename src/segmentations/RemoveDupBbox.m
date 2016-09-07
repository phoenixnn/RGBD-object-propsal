function [ out, survive ] = RemoveDupBbox( bbox, th )
%   remove duplicated bounding boxes

% Inputs:
% bbox : m x 4; [Cmin, Rmin, width, height]
% th: threshold for overlap
% outputs: 
% out : n x 4

N = size(bbox, 1);
coor = bbox;
coor(:,3) = coor(:,1) + coor(:,3) -1;
coor(:,4) = coor(:,2) + coor(:,4) -1;

survive = true(N, 1);
for i = 1 : (N-1)
    
    if ~survive(i)
        continue;
    end
    
    minr1 = coor(i,2);
    maxr1 = coor(i,4);
    minc1 = coor(i,1);
    maxc1 = coor(i,3);
    a1 = bbox(i,3) * bbox(i,4);
    
    for j = (i+1) : N
        minr2 = coor(j, 2);
        maxr2 = coor(j, 4);
        minc2 = coor(j, 1);
        maxc2 = coor(j, 3);
        a2 = bbox(j,3) * bbox(j,4);
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
        
        % determine
        ratio = IA/UA;
        if ratio > th
            survive(j) = false;
        end 
    end
end

out = bbox(survive, :);

end

