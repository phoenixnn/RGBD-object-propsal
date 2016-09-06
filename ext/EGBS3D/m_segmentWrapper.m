function [map, N] = m_segmentWrapper( I, pts, K, MIN, SIGMA)
%M_SEGMENTWRAPPER Summary of this function goes here
% remove the relabel section of Peter Corke's function igraphseg.m
% add corresponding part here

[L, N] = igraphseg(I, pts, K, MIN, SIGMA);
Ids = unique(L(:));
A = zeros(max(Ids),1);
A(Ids) = 1:numel(Ids);
map = A(L);

end

