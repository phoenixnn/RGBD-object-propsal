% Gets a mask for the projected images that is most conservative with
% respect to the regions that maintain the kinect depth signal following
% projection.
%
% Returns: 
%   mask - HxW binary image where the projection falls.
%   sz - the size of the valid region.
function [mask sz] = get_projection_mask()
  mask = false(480, 640);
  % original mask
%   mask(45:471, 41:601) = 1; 
%   sz = [427 561];
  
  % Gupta CVPR2013 mask
  mask(46:470, 41:600) = 1; 
  sz = [425 560];
end
