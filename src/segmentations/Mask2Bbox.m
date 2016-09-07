function bbox = Mask2Bbox(masks, sz, scale)
%   covert masks into bounding boxes
% Inputs:
%  masks: d x 1 cell object masks
%  sz: [h, w]
%  scale: scale ratio for the bounding box
% 
% outputs:
%  bbox: d x 4 [col, row, width, height]
if nargin < 2
    scale = 1.0;
end

h = sz(1);
w = sz(2);
d = numel(masks);
bbox = zeros(d, 4);

for i = 1 : d
    mask = false(h, w);
    mask(masks{i}) = true;
    bbox(i,:) = m_helper(mask, scale); 
end


end

function bbox = m_helper(mask, scale)
[h, w] = size(mask);

% calc borders
[c, r] = meshgrid(1:w,1:h);

R = r(mask);
C = c(mask);
maxr = max(R);
minr = min(R);
maxc = max(C);
minc = min(C);
width = maxc -minc + 1;
height = maxr- minr + 1;
center_r = floor((minr+maxr)/2);
center_c = floor((minc+maxc)/2); 

% scale 
new_width = width * scale;
new_height = height * scale;

% update borders
Rmin = 0; 
Cmin = 0;
if mod(minr+maxr,2) == 0
   Rmin = center_r - floor(new_height/2);
   Cmin = center_c - floor(new_width/2);
else
   Rmin = center_r - floor(new_height/2) + 1;
   Cmin = center_c - floor(new_width/2) + 1;
end 

if Rmin <= 0
    Rmin = 1;
end

if Rmin > h
    Rmin = h;
end

Rmax = center_r + floor(new_height/2);
if Rmax > h
    Rmax = h;
end

if Rmax <=0
    Rmax = 1;
end

if Cmin <= 0 
    Cmin = 1;
end

if Cmin > w
    Cmin = w;
end

Cmax = center_c + floor(new_width/2);
if Cmax > w
    Cmax = w;
end

if Cmax <=0
    Cmax = 1;
end

if Cmax < Cmin
    Cmax = Cmin;
end

if Rmax < Rmin
    Rmax = Rmin;
end

bbox = [Cmin, Rmin, (Cmax-Cmin+1), (Rmax-Rmin+1)]; 

end

