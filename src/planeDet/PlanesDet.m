function Pinfo = PlanesDet( points, rawDepth)   
% fitting multiple planes to point clouds
% 
% Inputs: 
% points: organized 3d points m x n x 3 (unit cm)
% rawDepth: original depth m x n (unit meter) 
%
% Outputs:
% planesMap: m x n, 0 means uncertain area
% planes: N x 4, plane parameters.

%% initialize planes
[h, w, ~] = size(points);
Z = points(:, :, 3);
non_missing = ~isnan(Z);
pts = reshape(points,[],3);
pts_homo = [pts ones(h*w, 1)];
rawDepth (rawDepth == 0) = NaN;
rawDepth = rawDepth * 100;
tolerance_d = 1 * 2.85e-5 * rawDepth(:).^2;
tolerance_n = 0.8;
min_pts_plane = 2000;

% compute normals
normals = CalcNormals(points);
normals = reshape(normals, [], 4);
 
% sample grid seeds on image
interval = 20;
ri = round(interval/4 + 1) : interval : round(h-interval/4);
ci = round(interval/4 + 1) : interval : round(w-interval/4);
[c, r] = meshgrid(ci, ri);

% choose triple point set
scale = [0.5 1];
triple_ids = [];
for i = 1 : numel(scale)
    pid_1 = r(:) + (c(:)-1) * h;
    pid_2 = pid_1 +(scale(i)*interval -(scale(i)*2*interval)*(c(:) > w/2)) * h;
    pid_3 = pid_1 +(scale(i)*interval -(scale(i)*2*interval)*(r(:) > h/2));
    tmp = [pid_1 pid_2 pid_3];
    triple_ids = cat(1, triple_ids, tmp);
end
%triple_ids = [pid_1 pid_2 pid_3];
fprintf('# triple sets (before): %d\n', size(triple_ids,1));
idx = all(non_missing(triple_ids), 2);
triple_ids = triple_ids(idx, :);
fprintf('# triple sets: %d\n', size(triple_ids,1));

% fitting planes
N = size(triple_ids, 1);
inlier_ids = cell(N, 1);
params = zeros(N, 4);
survive = true(N, 1);
count = zeros(N, 1);

for i = 1 : N
    A = pts_homo(triple_ids(i,:), :);
    [v, ~] = eig(A'*A);
    p = v(:,1);
    p = p/norm(p(1:3));
    params(i, :) = p';
    % find inliers
    dist2plane = abs(pts_homo * p);
    distN = abs(normals(:,1:3) * p(1:3));
    inlier_ids{i} = find(non_missing(:) & (dist2plane < tolerance_d) ...
                         & (distN > tolerance_n));
    count(i) = numel(inlier_ids{i});

end
fprintf('initialized # planes: %d\n', sum(survive(:)));

%% filter out planes by size threshold
for i = 1 : N
    if (count(i) < min_pts_plane)
        survive(i) = false;
        count(i) = 0;
        inlier_ids{i} = [];
        params(i,:) = 0;
    end
end
fprintf('after filtering by size # planes: %d\n', sum(survive(:)));

%% filter out planes with heavy overlapping areas
overlap = 0.5;
occupied = false(h, w);
[~, ind] = sort(count, 'descend');
for i = ind'
   if survive(i)
      num_not_used = sum(~occupied(inlier_ids{i}));
      if (num_not_used > (overlap * count(i))) && (num_not_used > min_pts_plane)
          occupied(inlier_ids{i}) = true;
          distD = abs(pts_homo * params(i,:)');
          tmpidx = non_missing(:) & (distD < (0.5*tolerance_d));
          A = pts_homo(tmpidx, :);        
          [v, l] = eig(A'*A);
          p = v(:,1);
          params(i,:) = p/norm(p(1:3))';
      else
          survive(i) = false;
          count(i) = 0;
          params(i,:) = 0;
          inlier_ids{i} = []; 
      end
   end
end
fprintf('after filtering by overlap # planes: %d\n', sum(survive(:)));

%% merge similar planes
planes = params(survive, :);
inliers = inlier_ids(survive);
count = count(survive);
[count, ind] = sort(count, 'descend');
planes = planes(ind,:);
inliers = inliers(ind);
N = size(planes,1);
survive = true(N,1);

for i = 1 : N-1
    if ~survive(i)
        continue;
    end
    
    p1 = planes(i,:);
    inlier_ids1 = inliers{i};
    collect = inlier_ids1;
    pts1 = pts_homo(inlier_ids1,:);
    for j = (i+1) : N
        if survive(j)
            pts2 = pts_homo(inliers{j},:);
            p2 = planes(j, :);
            dist21 = abs(pts2 * p1') < 2 * tolerance_d(inliers{j});
            dist12 = abs(pts1 * p2') < 2 * tolerance_d(inlier_ids1);
            if (mean(dist21) > 0.5) || (mean(dist12) > 0.5)
               collect = cat(1, collect, inliers{j});
               survive(j) = false;
            end
        end
    end
    inliers{i} = collect;
end
fprintf('after merging # planes: %d\n', sum(survive(:)));

%% remove multiple labeled points
% update plane info
planes = planes(survive, :);
inliers = inliers(survive);
N = size(planes, 1);

labeled = zeros(h, w);
for i = 1 : N
  tmp = zeros(h,w);
  tmp(inliers{i}) = 1; 
  labeled = labeled + tmp;
end
multi_ids = find(labeled>1);
fprintf('multiple labeled points: %d\n', numel(multi_ids));

survive = true(N ,1);
if ~isempty(multi_ids)
    for i = 1 : N
        inliers{i} = setdiff(inliers{i}, multi_ids);
        if numel(inliers{i}) < min_pts_plane
            survive(i) = false;
        end
    end
end
% update plane info
planes = planes(survive, :);
inliers = inliers (survive);
N = size(planes,1);
fprintf('# planes after removing multi-labeled points:  %d\n', N);

%% filter out fake planes
survive = true(N,1);
new_planes = [];
new_inliers = [];

min_pts_cc = 100;

for i = 1 : N
% find connected components
  cc = m_connectedComponent2d(inliers{i}, h, w);
  P = planes(i,:);
% fitting components by strict ransac
  for j = 1 : cc.NumObjects  
      if numel(cc.PixelIdxList{j}) < min_pts_cc
          inliers{i} = setdiff(inliers{i}, cc.PixelIdxList{j});
          continue;
      end
      % ransac
      A = pts_homo(cc.PixelIdxList{j}, :);
      td = tolerance_d(cc.PixelIdxList{j});
      n = normals(cc.PixelIdxList{j}, 1:3);
      p = m_ransac(A, td, n, 0.9, 100);
      % compare parent and child plane
      flag = false;
      if isempty(p)
          flag = true;
      else
          if (abs(P(1:3)*p(1:3)) < 0.9848) % to be determined!!!
              flag = true;
          end
      end
      if flag
          if numel(cc.PixelIdxList{j}) > min_pts_plane
              % create new plane
              new_planes = cat(1, new_planes, p');
              new_inliers = cat(1,new_inliers,cc.PixelIdxList(j));
          end
          % remove pixels from original plane
          inliers{i} = setdiff(inliers{i}, cc.PixelIdxList{j});        
      end
      

  end
  % filter out plane by size
  if numel(inliers{i}) < min_pts_plane
     survive(i) = false; 
  end 
end

% update planes info
old_planes = planes(survive,:);
old_inliers = inliers(survive);
planes = cat(1, old_planes, new_planes);
inliers = cat(1, old_inliers, new_inliers);
N = size(planes,1);
count = zeros(N,1);
for i = 1 : N
    count(i) = numel(inliers{i});
end
[~, ind] = sort(count, 'descend');
planes = planes(ind,:);
inliers = inliers(ind);
fprintf('# planes after CC: %d\n', N);

%% re-estimate planes
% strict ransac
for i = 1 : N
    idx = inliers{i};
    A = pts_homo(idx, :);
    td = tolerance_d(idx);
    n = normals(idx, 1:3);
    p = m_ransac(A, td, n, 0.95, 100);
    planes(i,:) = p';
end
% loose assignment
pset = 1 : h*w;
pset = pset(non_missing(:));
for i = 1 : N
    A = pts_homo(pset, :);
    n = normals(pset,1:3);
    distD = abs(A * planes(i,:)');
    distN = abs(n * planes(i,1:3)');
    mask = (distD < 3*tolerance_d(pset)) & (distN > 0.75);
    inliers{i} = pset(mask);
    pset = pset(~mask);
end

%% postprocessing
% cc
for i = 1 :N
   cc = m_connectedComponent2d(inliers{i}, h, w);
   idc = [];
   ct = [];
   msed = [];
   msea = [];
   for j = 1 : cc.NumObjects
       ccpx = cc.PixelIdxList{j};
       npc = numel(ccpx);
       if npc < 400
           inliers{i} = setdiff(inliers{i}, ccpx);
       else
           idc = [idc, j];
           ct = [ct, npc];
           distD = abs(pts_homo(ccpx,:) * planes(i,:)');
           distN = abs(normals(ccpx,1:3) * planes(i,1:3)');
           msed = [msed, sum(distD)/npc];
           msea = [msea, sum(acos(distN)*180/pi)/npc];
           %
           Tmse = sum(tolerance_d(ccpx))/npc;
           if (msed(end) > Tmse) && (msea(end) > 20)
              inliers{i} = setdiff(inliers{i}, ccpx);
           end
           
       end
   end

end

% update
survive = true(N,1);
for i = 1 : N
    if numel(inliers{i}) < min_pts_plane
        survive(i) = false;
    end
end
planes = planes(survive,:);
inliers = inliers(survive);
N = sum(survive);
fprintf('# planes Final: %d\n', N);
%% assign pixels to planes
disp('done\n');

planesMap = zeros(h, w);
for i = 1 : N
   planesMap(inliers{i}) = i; 
end


Pinfo.planesMap = planesMap;
Pinfo.planes = planes;
Pinfo.inliers = inliers;
Pinfo.normals = normals;

end


function cc = m_connectedComponent2d(inliers, h, w)
    bw = zeros(h, w);
    bw(inliers) = 1;
    cc = bwconncomp(bw, 8);
end

function p = m_ransac(A, td, n, th_n, iter)
N = size(A, 1);
assert(N >= 3);
inliers = [];

for i = 1 : iter
    % fit plane
    ind = randperm(N,3);
    X = A(ind, :);   
    [vv,~] = eig(X'*X);
    p = vv(:,1);
    p = p/norm(p(1:3));
    
    % calc inliers
    distD = abs(A * p);
    distN = abs(n * p(1:3));
    inliers_ids = find ((distD < td) & (distN > th_n));
    tmp = A(inliers_ids, :);
    if numel(inliers_ids) == N
        inliers = tmp;
        break;
    end

    if numel(inliers_ids) > size(inliers, 1)
        inliers = tmp;
    end
 
end
% re-estimate plane
if ~isempty(inliers)
    [vv, ~] = eig(inliers'*inliers);
    p = vv(:,1);
    p = p/norm(p(1:3));
else
    p = [];
end

end