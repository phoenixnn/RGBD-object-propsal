function [masks_cell, N] = Label2Mask( map )
% convert label map into region masks
%
% inputs:
%    map: mxn (start from 1)
% outputs:
%  masks_cell: N x 1
%  N: number of masks

N = max(map(:));
masks_cell = cell(N, 1);
for i = 1 : N
   masks_cell{i} = find(map == i); 
end

end

