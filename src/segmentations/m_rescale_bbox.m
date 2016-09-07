function  BB = m_rescale_bbox(bbox, sz, scale)
N = size(bbox,1);
BB = zeros(N, 4);
h = sz(1);
w = sz(2);
for i = 1 : N
    bb = bbox(i,:);
    
    width = bb(3);
    height = bb(4);
    minr = bb(2);
    minc = bb(1);
    
    maxc = minc + width -1;
    maxr = minr + height -1;
    
    center_r = floor((minr+maxr)/2);
    center_c = floor((minc+maxc)/2); 
    
    % scale 
    new_width = width * scale;
    new_height = height * scale;

    % update borders
    Rmin = 0; 
    Cmin = 0;
    if mod(minr+maxr,2) == 0
       Rmin = center_r - floor(new_height/2);
       Cmin = center_c - floor(new_width/2);
    else
       Rmin = center_r - floor(new_height/2) + 1;
       Cmin = center_c - floor(new_width/2) + 1;
    end 

    if Rmin <= 0
        Rmin = 1;
    end

    if Rmin > h
        Rmin = h;
    end

    Rmax = center_r + floor(new_height/2);
    if Rmax > h
        Rmax = h;
    end

    if Rmax <=0
        Rmax = 1;
    end

    if Cmin <= 0 
        Cmin = 1;
    end

    if Cmin > w
        Cmin = w;
    end

    Cmax = center_c + floor(new_width/2);
    if Cmax > w
        Cmax = w;
    end

    if Cmax <=0
        Cmax = 1;
    end

    if Cmax < Cmin
        Cmax = Cmin;
    end

    if Rmax < Rmin
        Rmax = Rmin;
    end

    BB(i,:) = [Cmin, Rmin, (Cmax-Cmin+1), (Rmax-Rmin+1)];
    
end






end