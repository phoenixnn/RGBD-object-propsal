function masksWS_cell = WatershedSegmentation(I, rawDepth, D)
% generate segments based on watershed from different signal channels
% 
th_L = 0.1;
th_rD = 0.3;
th_d = 0.2;
th_N = 0.1;

G1 = fspecial('gaussian',[9 9],1);
%% process RGB info (intensity)
[L,~,~] = Rgb2Lab(I);
L = imfilter(L,G1,'same','replicate');
gradient_L = imgradient(L);
gradient_L = m_Normalize(gradient_L);
gradient_L = (gradient_L > th_L).*gradient_L;
segMap = Watershed_region(gradient_L,false);
masksL = m_segMap2masks(segMap, 85); % 85
%% process rawDepth info (holes)
isvalid = (rawDepth ~= 0);
SE = strel('square',3);
isvalid = imerode(isvalid,SE);
rawDepth(~isvalid) = 0;
rD = m_any2gray(rawDepth);
rD = imfilter(rD, G1,'same','replicate');
gradient_rD = imgradient(rD);
gradient_rD = m_Normalize(gradient_rD);
gradient_rD = (gradient_rD > th_rD).*gradient_rD;
segMap = Watershed_region(gradient_rD,false);
masksRD = m_segMap2masks(segMap, 20);

%% process depth info (depth gradient)
d = m_any2gray(D);
d = imfilter(d,G1,'same','replicate');
gradient_d = imgradient(d);
gradient_d = m_Normalize(gradient_d);
gradient_d = (gradient_d > th_d).*gradient_d;
segMap = Watershed_region(gradient_d,false);
masksD = m_segMap2masks(segMap, 20);

%% normals
points = Depth2PCD(D);
normals= CalcNormals( points);
gradient_n = NormalVectorGradient(normals(:,:,1:3));
gradient_n = m_Normalize(gradient_n);
gradient_n = medfilt2(gradient_n, [5,5], 'symmetric');
gradient_n = (gradient_n > th_N) .* gradient_n;
segMap = Watershed_region(gradient_n,false);
masksN = m_segMap2masks(segMap, 85); %85

masksWS_cell = cat(1,masksL, masksRD, masksD, masksN);
end

function masks_cell = m_segMap2masks(segMap, th)
% Note segMap starts from 0 here
segMap = segMap + 1;
N = max(segMap(:));
count = 1;
[h, w] = size(segMap);
max_pixels = round(h*w/4);
masks_cell = [];

for i = 1 : N
    tmp = (segMap == i);
    num_pixels = sum(tmp(:));
    if (num_pixels > th) && (num_pixels < max_pixels)
        tmp1 = cell(1,1);
        tmp1{1,1} = find(tmp);
        masks_cell = cat(1, masks_cell, tmp1);    
       count = count + 1;
    end  
end

end


