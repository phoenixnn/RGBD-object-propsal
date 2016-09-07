function rgb = Label2Rgb( labels )
% colorize labeled image
% assume that 0 for unlabeled pixels

L = max(labels(:));
if L <= 7
    cmap = lines(L);
else
    cmap = cat(1,lines(7), hsv(L-7));  
end

cmap = [0 0 0; cmap];
rgb = ind2rgb(labels+1, cmap);

end

