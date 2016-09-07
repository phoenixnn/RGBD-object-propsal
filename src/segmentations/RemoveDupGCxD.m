function seg = RemoveDupGCxD(seg_GC2D, seg_GC3D, sz)
% remove duplicated segments between GC2D and GC3D

% seg_GC2D -- cell
% seg_GC3D -- cell
% sz - size of image

% seg -- combined unique segments cell

N = numel(seg_GC2D);
survive = true(N,1);

parfor i = 1 : N
    J = false;
    if numel(seg_GC2D{i}) == numel(seg_GC3D{i})
       avg2D = mean(seg_GC2D{i});
       avg3D = mean(seg_GC3D{i});
       
       if (avg2D == avg3D)
           mask1 = zeros(sz);
           mask1(seg_GC2D{i}) = 1;
           mask2 = zeros(sz);
           mask2(seg_GC3D{i}) = 1;
           J = isequal(mask1, mask2);
       end
    end
    
    if J
        survive(i) = false;
    end
end
segGC = seg_GC2D(survive);
seg = cat(1, segGC, seg_GC3D);

end

