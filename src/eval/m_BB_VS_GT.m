function Jmat = m_BB_VS_GT(BB, GtBB)
% compute Jaccard matrix between proposed bounding boxes and ground
% truth objects
% 
% Inputs:
% BB: proposals N x 4;
% GtBB: M x 4;
%
% Outputs:
% Jmat: M x N

N = size(BB, 1);
M = size(GtBB, 1);
Jmat = zeros(M, N);

for i = 1 : M
    gt = GtBB(i,:);
    for j = 1 : N
        Jmat(i,j) = m_Jaccard_bbox(gt, BB(j,:));   
    end
end

end

