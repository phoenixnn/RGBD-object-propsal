function [bbox, survive] = RemoveBadBbox(bbox, non_planar, th)

%  remove bounding box that have small overlap with non-planar area
N = size(bbox,1);
survive = true(N,1);
area = bbox(:,3).*bbox(:,4);
for i = 1 : N
    rBegin = bbox(i,2);
    rEnd = rBegin + bbox(i,4) -1;
    cBegin = bbox(i,1);
    cEnd = cBegin + bbox(i,3) -1;
    region = non_planar(rBegin:rEnd, cBegin:cEnd);
    ratio = sum(region(:))/area(i);
    if ratio < th
        survive(i) = false;
    end
end

bbox = bbox(survive,:);

end

