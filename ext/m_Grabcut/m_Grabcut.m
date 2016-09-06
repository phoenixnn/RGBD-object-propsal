function [ seg ] = m_Grabcut( I, mask_u, mask_fixed_fg, mask_fixed_bg)
% *************************************************************************
% INPUTS: 
% I: input color image
% mask_u: interactive mask for unknown label region which contains 
%         foreground (logical matrix). It indicates that its complement 
%         mask (~mask_u) is a hard pixel assignment for background
%           
% mask_fixed_fg: hard pixel assignment mask for forground.
% mask_fixed_bg: hard pixel assignment mask for background.
%                (typically, for pixels inside mask_u)

% OUTPUTS:
% segment: the binary segmentation result.

% Author: Zhuo Deng, Temple University. Mar, 2015.

% This is implementation of image segmentation algorithm GrabCut described in
% "GrabCut — Interactive Foreground Extraction using Iterated Graph Cuts".
% Carsten Rother, Vladimir Kolmogorov, Andrew Blake. SIGGRAPH, 2004.
% *************************************************************************


% parameters setting
  K = 5; % clusters
  %gamma = 50; % for original image
  gamma = 25; % for resized image 
  lambda = 9 * gamma;
  

% initialize fg and bg GMMs models by k-means
  I = double(I);
  [h, w, ~] = size(I);
  
  %tmp
  BB = m_mask2bbox(mask_u); %[c, r, w, h]
  bbox = [BB(2), BB(2)+BB(4)-1, BB(1), BB(1)+BB(3)-1]; % [rmin, rmax, cmin, cmax]
  bbox_ext = [max(1, bbox(1)-round(1)), min(h, bbox(2)+ round(1)), ...
              max(1, bbox(3)-round(1)), min(w, bbox(4)+ round(1))];  
  
  % assume that fixed fg and bg are within unknown area
  mask_fixed_bg  = mask_fixed_bg & mask_u;
  mask_fixed_fg  = mask_fixed_fg & mask_u;
  
  fgIds = find(mask_u & (~mask_fixed_bg));
  bgIds = find(~mask_u | mask_fixed_bg);
  assert( (numel(fgIds) + numel(bgIds)) == (h*w) );
  
  examples = reshape(I, [], 3);
  fgExamples = examples(fgIds, :);
  bgExamples = examples(bgIds, :); 
  
  %tic;
  [fgGMMs, bgGMMs, flag_ini] = m_init_GMMs(fgExamples, bgExamples, K);
  %fprintf('m_init_GMMs: %d\n', toc);
  if flag_ini
     seg = mask_u;
     return;
  end
  
  % 
  ini_labels = mask_u & (~mask_fixed_bg);
  label_cost = [0 gamma; gamma 0];
  
  %save('ini_labels.mat', 'ini_labels');
  
  % compute N edge weights:
  %tic;
  [v_edge_wt, h_edge_wt] = m_calcNwt(I);
  %fprintf('m_calcNwt: %d %d %d\n', toc, size(v_edge_wt,1), size(v_edge_wt,2));
  %save('vCue.mat', 'v_edge_wt');
  %save('hCue.mat', 'h_edge_wt');

%% iterative minimization
% t_assign = 0;
% t_learn = 0;
% t_unary = 0;
% t_graph = 0;


% add for loop here
max_iter = 10;
last_seg = mask_u;
dupCount = 0;
for i = 1 : max_iter
% assign GMM components to pixels
% kn = argmin Dn(alpha_n, kn, theta, zn);
  %t = tic;
  [fgkids, bgkids]= m_assignGMM2pixels(examples, fgGMMs, bgGMMs, fgIds, bgIds);
  %t_assign = t_assign + toc(t);
  %fprintf('m_assignGMM2pixels: %d\n', toc);
  
% learn GMM parameters
% theta = argmin U(alpha, k, theta, z);
  %t = tic;
  [fgGMMs, bgGMMs , flag] = m_learnGMMs(examples,fgIds, bgIds, fgkids, bgkids, K);
  %t_learn  = t_learn + toc(t);
  %fprintf('m_learnGMMs: %d\n', toc);
  if flag
     seg = mask_u;
     return; 
  end
%   fprintf('fgGMMs.cov\n');
%   fgGMMs.cov{:}
%   fprintf('fgGMMs.wt\n');
%   fgGMMs.wt
%   fprintf('bgGMMs.cov\n');
%   bgGMMs.cov{:}
%   fprintf('bgGMMs.wt\n');
%   bgGMMs.wt
% update unary energy
  %t = tic;
  [fgLogPL, bgLogPL] = m_Unary_LogPL(examples, fgGMMs, bgGMMs, ... 
                                     mask_u, mask_fixed_fg, mask_fixed_bg, lambda);
  %t_unary = t_unary + toc(t);
%   if ( i == max_iter)
%      save('fgLogPL.mat', 'fgLogPL');
%      save('bgLogPL.mat', 'bgLogPL');
%   end
                                
  %fprintf('m_Unary_LogPL: %d\n', toc);
% estimate segmentation
% alpha = argmin E(alpha, k, theta, z);
  %t = tic;
  %[seg, energy] = m_GraphCut(fgLogPL, bgLogPL, label_cost, v_edge_wt, h_edge_wt, ini_labels);
  [seg, energy] = m_GraphCut(fgLogPL(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                             bgLogPL(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                             label_cost, ...
                             v_edge_wt(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                             h_edge_wt(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                             ini_labels(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)));
  %t_graph = t_graph + toc(t);
  %fprintf('m_GraphCut: %d\n', toc);
  %tmp
  tmp = false(h, w);
  tmp(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)) = seg;
  seg = tmp;
  
  % compare
%   cmp = seg & (~last_seg);
%   if (nnz(cmp) == 0)
%   if isequal(seg, last_seg)
%       dupCount = dupCount + 1;
%   else
%       dupCount = 0;
%   end
%   
%   if dupCount >= 2
%       break;
%   else
%       last_seg = seg;
%   end

    if isequal(seg, last_seg)
        break;
    else
        last_seg = seg; 
    end
  
  
  fgIds = find(seg == 1);
  bgIds = find(seg == 0);
  
end

%fprintf('iterations: %d\n', i);
% fprintf('m_assignGMM2pixels: %d\n', t_assign);
% fprintf('m_learnGMMs: %d\n', t_learn);
% fprintf('m_Unary_LogPL: %d\n', t_unary);
% fprintf('m_GraphCut: %d\n', t_graph);


end

