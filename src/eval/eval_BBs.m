% evaluate the quality of proposed bounding boxes

% addpath('./m_common/');
% addpath('./Evaluation/');

close all;

% load split data
var = load('data/nyuv2/nyusplits.mat');
set_type = 'test';
if strcmp(set_type, 'test')
    imlist = var.tst - 5000;
else
    imlist = var.trainval - 5000;
end

% result path
res_path ='result/nyuv2/Eval/BB';
if ~exist(res_path, 'dir')
   mkdir(res_path);
end
data_path = 'data/nyuv2';


% compute Jmat for each image
BB_path = 'result/nyuv2/BB';
parfor i = 1 : numel(imlist)
pid = imlist(i);
fprintf('**************processing  %d ***************\n', pid);
if exist(fullfile(res_path, [num2str(pid), '.mat']), 'file')
    fprintf('skip %d\n', pid);
    continue;
end

var = load(fullfile(BB_path, [num2str(pid), '.mat']));
BB = var.BB;
[GtMasks, ~] = GetMasksGT(data_path, pid);
GtBB = m_mask2bbox(GtMasks);
Jmat = m_BB_VS_GT(BB, GtBB);
ParSave(fullfile(res_path, [num2str(pid), '.mat']), Jmat);
end

%% extract stat info from Jmats
ncandSet =  [10:5:100,125:25:1000,1500:500:6000,10000]; % use the first ncand proposals
num_ncand = numel(ncandSet);

% get the total number of objects in tst dataset
num_objects = 0;
num_images = numel(imlist);
for i = 1 : numel(imlist)
    var = load(fullfile(res_path, [num2str(imlist(i)), '.mat']));
    Jmat = var.Jmat;
    num_objects = num_objects + size(Jmat,1);
end

% compute best Jaccard for each objects
Jmax = zeros(num_objects, num_ncand);
n_mask_sel = zeros(num_images, num_ncand);
for i = 1 : num_ncand
    ncand = ncandSet(i);
    k = 1;
    for j = 1 : num_images
        pid = imlist(j);
        var = load(fullfile(res_path, [num2str(pid), '.mat']));
        Jmat = var.Jmat;
        [nobjs, nprops] = size(Jmat);
        nsel = min(nprops, ncand);
        % choose first nsel proposals
        Jmat = Jmat(:, 1:nsel);
        Jmax_1 = max(Jmat, [], 2);
        % save to Jmax
        Jmax(k:(k+nobjs-1),i) = Jmax_1;
        % update k
        k = k + nobjs;
        % save nsel
        n_mask_sel(j,i) = nsel;
    end
end


avg_n_mask_sel = mean(n_mask_sel);
save(fullfile(res_path, 'res_s.mat'), 'Jmax','n_mask_sel');

%% multi-level recall score (Rs)
lineColors = {'k-', 'r-', 'c-', 'b+', 'gs', 'bo', 'r^', 'm*', 'b>', 'ks', 'r+', 'g^','k--', 'b-'};
overlap_levels = 0.5;
figure;
grid on;
grid minor;
xlabel('Number of candidates');
ylabel('Recall');
title('bounding box proposals on NYUV2 dataset', 'Interpreter','none');
Methods = {'ours'};
for k = 1 : numel(Methods)
    hold on;
    num_recalls = sum(Jmax > overlap_levels, 1);
    plot(avg_n_mask_sel, num_recalls/num_objects, lineColors{k}); 
    legend(Methods{k});
end