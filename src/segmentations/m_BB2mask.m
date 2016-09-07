function [ masks ] = m_BB2mask( BB, sz )
% convert bounding box to mask
% 
% Inputs:
%    BB: N x 4. [Cmin, Rmin, Width, Height]
%    sz: mask size
% Outputs:
%   masks: m x n x N

N = size(BB, 1);
masks = zeros(sz(1), sz(2), N);

for i = 1 : N
   rBegin = BB(i,2);
   rEnd = BB(i,2) + BB(i,4) -1;
   cBegin = BB(i,1);
   cEnd = BB(i,1) + BB(i,3) -1;
   masks(rBegin:rEnd, cBegin:cEnd,i) =  1;
end


end

