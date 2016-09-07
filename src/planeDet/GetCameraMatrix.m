function K = GetCameraMatrix()
camera_params;
K = [fx_rgb, 0, cx_rgb-40;
     0, fy_rgb, cy_rgb-45;
     0, 0, 1];
end

