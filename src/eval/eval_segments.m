
% load split data
var = load('data/nyuv2/nyusplits.mat');
set_type = 'test';
if strcmp(set_type, 'test')
    imlist = var.tst - 5000;
else
    imlist = var.trainval - 5000;
end

% result path
res_path ='result/nyuv2/Eval/Seg';
if ~exist(res_path, 'dir')
   mkdir(res_path);
end
data_path = 'data/nyuv2';

% compute Jmat for each image
seg_path = 'result/nyuv2/Seg';
parfor i = 1 : numel(imlist)
    pid = imlist(i);
    fprintf('**************processing image %d ***************\n', pid);
    if exist(fullfile(res_path, [num2str(pid) '.mat']), 'file')
        fprintf('skip %d\n', pid);
        continue;
    end
    var = load(fullfile(seg_path, [num2str(pid) '.mat']));
    segMasks = var.segCells;
    [GtMasks, ~] = GetMasksGT(data_path, pid);
    Jmat = m_SEG_VS_GT(segMasks, GtMasks);
    ParSave(fullfile(res_path, [num2str(pid) '.mat']), Jmat);
end

%% extract stat info from Jmats
ncandSet =  [10:5:100,125:25:1000,1500:500:6000,10000]; % use the first ncand proposals
num_ncand = numel(ncandSet);

% get the total number of objects in tst dataset
num_objects = 0;
for i = 1 : numel(imlist)
    pid = imlist(i);
    var = load(fullfile(res_path, [num2str(pid) '.mat']));
    Jmat = var.Jmat;
    num_objects = num_objects + size(Jmat,1);
end

% compute best Jaccard for each objects
Jmax = zeros(num_objects, num_ncand);
n_mask_sel = zeros(num_images, num_ncand);
for i = 1 : num_ncand
    ncand = ncandSet(i);
    k = 1;
    for j = 1 : numel(imlist)
        pid = imlist(j);
        var = load(fullfile(res_path, [num2str(pid) '.mat']));
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
save(fullfile(res_path, 'res.mat'), 'Jmax','n_mask_sel');

%% JI
figure;
grid on;
grid minor;
xlabel('Number of candidates');
ylabel('Jaccard');
title('Segment proposals on NYUV2 dataset');
Methods = {'ours'};
for k = 1 : 1
    hold on;
    Ji = sum(Jmax, 1);
    plot(avg_n_mask_sel, Ji/num_objects, 'r-'); 
    legend(Methods{k});
end
