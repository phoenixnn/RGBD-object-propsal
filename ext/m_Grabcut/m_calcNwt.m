function [v_edge_wt, h_edge_wt ] = m_calcNwt(I)
% compute neighborhood edge weights
% exp{-beta*L2(z1, z2)}

gradH = I(:, 2:end, :) - I(:, 1:end-1, :);
gradV = I(2:end, :, :) - I(1:end-1, :, :);

gradH = sum(gradH.^2, 3);
gradV = sum(gradV.^2, 3);

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

