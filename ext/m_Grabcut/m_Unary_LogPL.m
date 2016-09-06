function [fgLogPL, bgLogPL] = m_Unary_LogPL(examples, fgGMMs, bgGMMs, ...
                              mask_u, mask_fixed_fg, mask_fixed_bg, lambda)
% compute date terms for graph cut    
% Inputs:
% examples: N x 3 color image (double)
% fgGMMs, bgGMMs : GMMs model for fg/bg
% mask_u: initial unknown region
% mask_fixed_fg: fixed fg pixels within unknown region
% mask_fixed_bg: fixed bg pxiels within unknown region
% lambda: penalty for fixed labels

% Outputs:
% fgLogPL, bgLogPL: negative log likelihoods for each pixel. NxM

[h, w] = size(mask_u);
% determine unknown region, fixed fg/bg region
mask_U = mask_u & (~mask_fixed_fg) & (~mask_fixed_bg);
mask_BG = (~mask_u) | mask_fixed_bg;
mask_FG = mask_fixed_fg;

% compute negative log likelihoods
fgLogPL = zeros(h, w); 
bgLogPL = zeros(h, w);

fgLogPL(mask_FG) = lambda;
bgLogPL(mask_BG) = lambda;

U_ids = find(mask_U);
uExamples = examples(U_ids, :);
fgLogPL_U = m_unary_helper(uExamples, fgGMMs, h, w, U_ids);
bgLogPL_U = m_unary_helper(uExamples, bgGMMs, h, w, U_ids);

fgLogPL = fgLogPL + bgLogPL_U;
bgLogPL = bgLogPL + fgLogPL_U;

end

function [LogPL] = m_unary_helper(examples, GMMs, h, w, ids)
K = size(GMMs.mu, 2);
N = size(examples, 1);
PL = zeros(N, K);
for i = 1 : K
   if GMMs.wt(i) ~= 0 
      PL(:, i) = exp( -m_GM_logPL(examples, GMMs.mu(:,i), GMMs.detcov(i), GMMs.icov(:,:,i)) );
   end
end

PL = PL * GMMs.wt;

LogPL = zeros(h * w, 1);
LogPL(ids) = -log(PL);
LogPL = reshape(LogPL, h, w);

end

