function Jmat = m_SEG_VS_GT( segCell, GtMasks)
% compare segments with ground truth

% segCell -- segments stored in cell
% GtMasks -- ground truth masks

% Jmat 

   nobjs = numel(segCell);
   [h, w, nGt] = size(GtMasks);
   % Jmat
   Jmat = zeros(nGt, nobjs);
   % care
   instancesMap = zeros(h, w);
   for i = 1 : nGt
       instancesMap(logical(GtMasks(:,:,i))) = i;
   end
   care = (instancesMap ~= 0);
   
   %
   parfor i = 1 : nobjs 
       mask = zeros(h, w);
       mask(segCell{i}) = 1;
       %
       Jmat(:,i) = m_overlap(mask, GtMasks, care);
   end

end

function  J = m_overlap(mask, GtMasks, care)
    S = size(GtMasks,3);
    J = zeros(S,1);
    for i = 1 : S
        tmp = logical(GtMasks(:,:,i));
        if isempty(tmp)
            J(i) = 0;
        else
            J(i) = overlap_care(logical(mask), tmp , care);
        end
    end
end


