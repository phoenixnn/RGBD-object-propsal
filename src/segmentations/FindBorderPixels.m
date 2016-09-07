function [ borderMask ] = FindBorderPixels( spMask )

%   find boundary pixels given one superpixel
% Input:
% spMask: superpixel mask
% Output:
% borderMask: boundary pixels mask

B = bwboundaries(spMask, 'noholes');
sz = size(spMask);
borderMask = zeros(sz);
for i = 1 : numel(B)
   b = B{i};
   b = b(1:end-1, :);
   ind = sub2ind(sz, b(:,1), b(:,2));
   borderMask(ind) = 1;
end

end

