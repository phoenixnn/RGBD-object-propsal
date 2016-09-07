function segCell = Mask2Cell( segMasks )
% convert segment mask to cell structure

N = size(segMasks,3);
segCell = cell(N, 1);
for i = 1 : N
    segCell{i} = find(segMasks(:,:,i));
end

end

