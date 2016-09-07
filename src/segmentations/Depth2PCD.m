function [ points] = Depth2PCD(D)
% this function is dedicated to the KINECT used by NYUV2
% and the image itself is cropped to size [425 560].
% You can modify the camera parameters accordingly
% 
% Inputs:
%      D: inpainted depth matrix mxn
% 
% Outputs:
% points: 3d point clouds mxnx3

Kd = GetCameraMatrix();

[h, w] = size(D);
[xx,yy] = meshgrid(1:w, 1:h);

X = (xx - Kd(1,3)) .* D / Kd(1,1);
Y = (yy - Kd(2,3)) .* D / Kd(2,2);
Z = D;

points = cat(3, X, Y, Z);

end

