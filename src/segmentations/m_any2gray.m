function [ grayIm ] = m_any2gray( data )
% convert matrix to uint8 format for visualization purpose

mask = isnan(data);
data(mask) = 0;

maxi = max(data(:));
mini = min(data(:));
grayIm = uint8(255 * (data - mini)/(maxi-mini));

end

