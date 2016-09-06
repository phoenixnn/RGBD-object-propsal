function [fgGMMs, bgGMMs, flag] = m_init_GMMs_3D(fgExamples, bgExamples, K)
% INPUTS:
% fgExamples: Nx6
% bgExamples: Mx6
% K: number of clusters

% OUTPUTS:
% fgGMMs: foreground GMM models (means, icovs, detcovs and weights)  struct
% bgGMMs: background GMM models (means, icovs, detcovs and weights)  struct

flag = false;
[num_fg, d] = size(fgExamples);
num_bg = size(bgExamples, 1); 

% initialize models
fgGMMs.mu = zeros(d, K);
fgGMMs.icov = zeros(d, d, K);
fgGMMs.detcov = zeros(K, 1);
fgGMMs.wt = zeros(K, 1);

bgGMMs.mu = zeros(d, K);
bgGMMs.icov = zeros(d, d, K);
bgGMMs.detcov = zeros(K, 1);
bgGMMs.wt = zeros(K, 1);

% K-means
opts = statset('kmeans');
%opts.MaxIter = 30;

%  assert(num_fg ~= 0);
%  assert(num_bg ~= 0);

if (num_fg < K) || (num_bg < K)
   flag = true; 
   return;
end
 
% [fgClusterIds, fgCenters] = kmeans(fgExamples, K, 'emptyaction','singleton' ,'Options',opts);
% [bgClusterIds, bgCenters] = kmeans(bgExamples, K, 'emptyaction','singleton' ,'Options',opts);

%tic;
[~,fgClusterIds] = yael_kmeans(single(fgExamples'),K,'redo',1,'niter',20,'init',0,'verbose',0); 
[~,bgClusterIds] = yael_kmeans(single(bgExamples'),K,'redo',1,'niter',20,'init',0,'verbose',0); 
%fprintf('yael_3D: %d\n', toc);

% compute sample mean and covariance for GMMs
for i = 1 : K
    fg_egs = fgExamples(fgClusterIds == i, :);
    if ~isempty(fg_egs)
        fgGMMs.mu(:, i) = mean(fg_egs, 1)';
        fg_covar = cov(fg_egs);
        fgGMMs.icov(:,:,i) = pinv(fg_covar);
        fgGMMs.detcov(i) = det(fg_covar);
        fgGMMs.wt(i) = size(fg_egs, 1)/num_fg;
    end 
    
    bg_egs = bgExamples(bgClusterIds == i, :);
    if ~isempty(bg_egs)
        bgGMMs.mu(:, i) = mean(bg_egs, 1)';
        bg_covar = cov(bg_egs);
        bgGMMs.icov(:,:,i) = pinv(bg_covar);
        bgGMMs.detcov(i) = det(bg_covar);
        bgGMMs.wt(i) = size(bg_egs, 1)/num_bg;
    end
end

assert(abs(sum(fgGMMs.wt) - 1) < 1e-6 && abs(sum(bgGMMs.wt) - 1)  < 1e-6 );

end

