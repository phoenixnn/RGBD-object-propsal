function [v_edge_wt, h_edge_wt ] = m_calcNwt_3D(I)
% compute neighborhood edge weights
% exp{-beta*L2(z1, z2)}

gradH = I(:, 2:end, :) - I(:, 1:end-1, :);
gradV = I(2:end, :, :) - I(1:end-1, :, :);

gradH = sum(gradH.^2, 3);
gradV = sum(gradV.^2, 3);

% tmp code
% gradH_c = gradH(:,:,1:3); gradH_c = sum(gradH_c.^2, 3); 
% gradH_d = gradH(:,:,4:6); gradH_d = sum(gradH_d.^2, 3);
% gradV_c = gradV(:,:,1:3); gradV_c = sum(gradV_c.^2, 3);
% gradV_d = gradV(:,:,4:6); gradV_d = sum(gradV_d.^2, 3);
% 
% gradH_c = gradH_c/max(gradH_c(:));
% gradH_d = gradH_d/max(gradH_d(:));
% gradV_c = gradV_c/max(gradV_c(:));
% gradV_d = gradV_d/max(gradV_d(:));
% 
% mask_H = gradH_c > gradH_d;
% gradH = mask_H.* gradH_c + (~mask_H).*gradH_d;
% mask_V = gradV_c > gradV_d;
% gradV = mask_V.* gradV_c + (~mask_V).*gradV_d;



% Calculate beta - parameter of GrabCut algorithm.
% beta = 1/(2*avg(sqr(||color[i] - color[j]||)))
% 4 connection average
[h, w, d] = size(I);
num_C = 2*h*w - (h + w);
beta = 1 / ( 2 * (sum(gradH(:)) + sum(gradV(:))) /num_C );

% hC = exp(-beta.*gradH./mean(gradH(:)));
% vC = exp(-beta.*gradV./mean(gradV(:)));

hC = exp(-beta * gradH);
vC = exp(-beta * gradV);

h_edge_wt = [hC zeros(size(hC,1),1)];
v_edge_wt = [vC ;zeros(1, size(vC,2))];

end

