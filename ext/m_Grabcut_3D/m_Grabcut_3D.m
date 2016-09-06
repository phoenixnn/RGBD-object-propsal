function [ seg ] = m_Grabcut_3D( I, pts, mask_u, mask_fixed_fg, mask_fixed_bg)
% *************************************************************************
% INPUTS: 
% I: input color image
% pts: 3d aligned points mxnx3 unit(meter) 
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
  %gamma = 500; % original image
  gamma = 250; % resized image
  lambda = 9 * gamma;
  

% initialize fg and bg GMMs models by k-means
  I = double(I);
  [h, w, ~] = size(I);
  %I = I./255;
  points = reshape(pts, [], 3);
  
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
  examples = [examples points];
  fgExamples = examples(fgIds, :);
  bgExamples = examples(bgIds, :); 
  
  %tic;
  [fgGMMs, bgGMMs, flag_ini] = m_init_GMMs_3D(fgExamples, bgExamples, K);
  %fprintf('init_GMMs_3D: %d\n', toc);
  
  if flag_ini 
     seg = mask_u;
     return;
  end
  
  % 
  ini_labels = mask_u & (~mask_fixed_bg);
  label_cost = [0 gamma; gamma 0];
  
  % compute N edge weights:
  rgbd = cat(3, I, pts);
  %tic;
  [v_edge_wt, h_edge_wt] = m_calcNwt_3D(rgbd);
  %fprintf('m_calcNwt_3D: %d\n', toc);

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
  %tic;
  [fgkids, bgkids]= m_assignGMM2pixels_3D(examples, fgGMMs, bgGMMs, fgIds, bgIds);
  %t_assign = t_assign + toc;
  
  
% learn GMM parameters
% theta = argmin U(alpha, k, theta, z);
  %tic;
  [fgGMMs, bgGMMs, flag] = m_learnGMMs_3D(examples,fgIds, bgIds, fgkids, bgkids, K);
  %t_learn = t_learn + toc;
  
  if flag
      seg = mask_u;
      return;
  end
  
% update unary energy
  %tic;
  [fgLogPL, bgLogPL] = m_Unary_LogPL_3D(examples, fgGMMs, bgGMMs, ... 
                                     mask_u, mask_fixed_fg, mask_fixed_bg, lambda);
  %t_unary = t_unary + toc;
% estimate segmentation
% alpha = argmin E(alpha, k, theta, z);
  %[seg, energy] = m_GraphCut_3D(fgLogPL, bgLogPL, label_cost, v_edge_wt, h_edge_wt, ini_labels);
  %tic;
  [seg, energy] = m_GraphCut_3D(fgLogPL(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                         bgLogPL(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                         label_cost, ...
                         v_edge_wt(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                         h_edge_wt(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)), ...
                         ini_labels(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)));
  %t_graph = t_graph + toc;
  % tmp                   
  tmp = false(h, w);
  tmp(bbox_ext(1):bbox_ext(2), bbox_ext(3):bbox_ext(4)) = seg;
  seg = tmp;
  
  % compare
%   cmp = seg & (~last_seg);
%   if (nnz(cmp) == 0)
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
% fprintf('the data term energy: %d\n', energy.data);
% fprintf('the smooth term energy: %d\n', energy.smooth);
% fprintf('assign pixels 3D: %d\n', t_assign);
% fprintf('learnGMM3D: %d\n', t_learn);
% fprintf('unaryLog3D: %d\n', t_unary);
% fprintf('graphcut: %d \n', t_graph);
end

