function [seg, E] = m_GraphCut(fgLogPL, bgLogPL, sc, v_edge_wt, h_edge_wt, ini_Labelset)
% construct the ST graph and solve it by graph cut
% 
% Inputs:
% fgLogPL, bgLogPL: unary potentials for fg/bg 
% sc: label smooth cost matrix e.g., V(L1, L2) = gamma and V(L1,L1) = 0
% v_edge_wt: exp{-beta*L2(z1, z2)} for vertial edges
% h_edge_wt: for horizontal edges
% ini_Labelset: intialize labels before inference

% Outputs:
% seg: binary segmentation 
% E : energy

dc = cat(3, fgLogPL, bgLogPL);
graphHandle = GraphCut('open', dc , sc, v_edge_wt, h_edge_wt);
graphHandle = GraphCut('set', graphHandle, int32(ini_Labelset));
[graphHandle, seg] = GraphCut('expand', graphHandle);
[graphHandle, E] = GraphCut('energy', graphHandle);
GraphCut('close', graphHandle);

end

