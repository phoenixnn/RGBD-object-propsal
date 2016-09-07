function [objMasks, objLabels] = GetMasksGT(m_dataDir,  img_id)
% get ground truth object masks and corresponding labels

load (fullfile(m_dataDir, 'label_crop', [num2str(img_id) '.mat']));
load (fullfile(m_dataDir, 'instances_crop', [num2str(img_id) '.mat']));
[objMasks, objLabels] = get_instance_masks(label, instance);


end

