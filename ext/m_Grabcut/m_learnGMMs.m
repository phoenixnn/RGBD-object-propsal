function [fgGMMs, bgGMMs, flag] = m_learnGMMs(examples,fgIds, bgIds, fgkids, bgkids, K)
% ***********************************************************
% estimate parameters of GMMs

% Inputs:
% examples: N x 3 color image
% fgIds : pixel ids for foreground 
% bgIds : pixel ids for background
% fgkids: GMMs component ids for foreground pixels
% bgkids: GMMs component ids for background pixels
% K: number of components

% Outputs:
% fgGMMs: GMMs model for foreground
% bgGMMs: GMMs model for background
% flag: if it is true, it means bad segment happened
%************************************************************
flag = false;
[~, d] = size(examples);

fgExamples = examples(fgIds, :);
bgExamples = examples(bgIds, :);

% initialize models
fgGMMs.mu = zeros(d, K);
fgGMMs.icov = zeros(d, d, K);
fgGMMs.detcov = zeros(K, 1);
fgGMMs.wt = zeros(K, 1);

bgGMMs.mu = zeros(d, K);
bgGMMs.icov = zeros(d, d, K);
bgGMMs.detcov = zeros(K, 1);
bgGMMs.wt = zeros(K, 1);

num_fg = numel(fgIds); 
num_bg = numel(bgIds);

% assert(num_fg ~= 0);
% assert(num_bg ~= 0);

if num_fg == 0 || num_bg == 0
    flag = true;
    return;
end


for i = 1 : K
   
    fg_egs = fgExamples(fgkids == i, :);
    if ~isempty(fg_egs)
        fgGMMs.mu(:, i) = mean(fg_egs, 1)';
        fg_covar = cov(fg_egs);
        fgGMMs.icov(:,:,i) = pinv(fg_covar);
        fgGMMs.detcov(i) = det(fg_covar);
        fgGMMs.wt(i) = size(fg_egs, 1)/num_fg;
    end
    
    bg_egs = bgExamples(bgkids == i, :);
    if ~isempty(bg_egs)
        bgGMMs.mu(:, i) = mean(bg_egs, 1)';
        bg_covar = cov(bg_egs);
        bgGMMs.icov(:,:,i) = pinv(bg_covar);
        bgGMMs.detcov(i) = det(bg_covar);
        bgGMMs.wt(i) = size(bg_egs, 1)/num_bg; 
    end
end



end

