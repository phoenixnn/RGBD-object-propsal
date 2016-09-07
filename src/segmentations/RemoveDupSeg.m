function out = RemoveDupSeg( segCells, sz )
% remove duplicated segments from multiple sources

N = numel(segCells);
th = 1;
care = true(sz);

% precompute area, centroid
Area = zeros(N, 1);
Centers = zeros(N, 1);
for i = 1 : N
    Area(i) = numel(segCells{i});
    Centers(i) = mean(segCells{i});
end

% 
cpmat = zeros(N,N);
parfor i = 1 : N
%     mask1 = zeros(sz);
%     mask1(segCells{i}) = 1;
%     np = numel(segCells{i});
%     cpmat(i,:) = m_helper_compare(logical(mask1), segCells, care, th, i, np);
    cpmat(i,:) = m_compare(segCells, i, sz, Area, Centers);
end

sel = triu(cpmat);
sel(logical(eye(N))) = 0;

sel = sum(sel, 1);
survive = (sel == 0);

Segs = segCells(survive);

% remove empty masks
N = numel(Segs);
survive = true(N, 1);
for i = 1 : N
    if (numel(Segs{i}) == 0)
        survive(i) = false;
    end
end
out = Segs(survive);

end

function out = m_compare(segCells, j, sz, Area, Centers)
N = numel(segCells);
out = zeros(1, N);
for i = 1 : N
    if i > j
        
        J = false;
        if Area(j) == Area(i)
       
           if (Centers(j) == Centers(i))
               mask1 = zeros(sz);
               mask1(segCells{i}) = 1;
               mask2 = zeros(sz);
               mask2(segCells{i}) = 1;
               J = isequal(mask1, mask2);
           end
           
        end
        
        if J
           out(i) = 1; 
        end
        
    end
end


end


function out = m_helper_compare(mask1, segCells, care, th, j, np1)
[h,w] = size(mask1);
N = numel(segCells);
out = zeros(1, N);

for i = 1 : N
    if j >= i
        continue;
    end

    mask2 = zeros(h,w);
    mask2(segCells{i}) = 1;
    
    np2 = numel(segCells{i});
    if (abs(np1 - np2)/(min(np1,np2) + eps)) > 0
        continue;
    end
     
    J = overlap_care(mask1, logical(mask2) , care);
    if J >= th
       out(i) = 1;
    end
end
end

