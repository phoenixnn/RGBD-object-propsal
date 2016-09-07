function mat2PCDfile(fileName, points, mode)

% zhuo deng 
% temple university
% 20140918

% convert the 3d points represented by matlab matrix into .pcd file

% PCD v.7 file format
% =========================
% VERSION .7
% FIELDS x y z rgb
% SIZE 4 4 4 4
% TYPE F F F F
% COUNT 1 1 1 1
% WIDTH 213
% HEIGHT 1
% VIEWPOINT 0 0 0 1 0 0 0
% POINTS 213
% DATA ascii
% 0.93773 0.33763 0 4.2108e+06
% 0.90805 0.35641 0 4.2108e+06
% 0.81915 0.32 0 4.2108e+06
% ...
% ==========================

% inputs: 
%    fileName: filePath + fileName (e.g. /usr/local/MATLAB/points.pcd)
%    points: 3D points data in matlab matrix mxnxd or mxd
%    mode: string 'binary' or 'ascii'

if nargin < 3
    
    mode = 'ascii';
end

assert( strcmp(mode, 'ascii') || strcmp(mode, 'binary'), ... 
        'invalid mode');

if strcmp(mode, 'ascii')
    
    fid = fopen(fileName,'w');
    save_PCD(fid, points, 'ascii');
    fclose(fid);
    
else
   
    fprintf('binary mode is under construction ... \n');    
end



end

function save_PCD(fileID, points, mode)

fprintf(fileID, 'VERSION .7\n');

if ndims(points) == 2 
    % unorganized points
    
    % write attributes
    num_attributes = size(points,2);   
    print_helper(fileID, num_attributes);    
    fprintf(fileID, 'WIDTH %d\n', size(points,1));
    fprintf(fileID, 'HEIGHT 1\n');  
    fprintf(fileID, 'VIEWPOINT 0 0 0 1 0 0 0 \n');
    fprintf(fileID, 'POINTS %d\n', size(points,1));
    fprintf(fileID, 'DATA %s\n',mode);
    
    % write data
    print_helper_1(fileID, points');
     
else
    % organized points
    
    % write attributes
    num_attributes = size(points,3);
    print_helper(fileID, num_attributes);
    fprintf(fileID, 'WIDTH %d\n', size(points,2));
    fprintf(fileID, 'HEIGHT %d\n', size(points,1));  
    fprintf(fileID, 'VIEWPOINT 0 0 0 1 0 0 0 \n');
    fprintf(fileID, 'POINTS %d\n', size(points,2) * size(points,1));
    fprintf(fileID, 'DATA %s\n',mode);
    
    % write data
    points_t = reshape(points, [], size(points,3));
    print_helper_1(fileID, points_t');
    
    
end



end

function print_helper(fileID, num_attributes)
% print 'fields', 'size', 'type', 'count'

switch num_attributes
    case 3
        % x y z
        fprintf(fileID, 'FIELDS x y z\n');
        fprintf(fileID, 'SIZE 4 4 4\n');
        fprintf(fileID, 'TYPE F F F\n');
        fprintf(fileID, 'COUNT 1 1 1\n');
        
    case 6
        % x y z r g b
        fprintf(fileID, 'FIELDS x y z rgb\n');
        fprintf(fileID, 'SIZE 4 4 4 4\n');
        fprintf(fileID, 'TYPE F F F F\n');
        fprintf(fileID, 'COUNT 1 1 1 1\n');
        
    otherwise 
        disp('other attribute format is under construction ...\n');
        
end



end

function print_helper_1 (fileID, points)
% print data : each column represents one point
num_dim = size(points,1);

switch num_dim
    case 3
        fprintf(fileID,'%.10f %.10f %.10f\n', points);
        
    case 6
        % encode r g b into rgb
        color = encodeRGB(points(4:6,:));
        fprintf(fileID, '%.10f %.10f %.10f %d\n',[points(1:3,:); color]);
        
        
    otherwise
        disp('other attribute format is under construction ...\n');
end

end

function color = encodeRGB(rgb)
% rgb is a 3xN matrix (r, g, b)
color = bitor( bitshift(rgb(1,:), 16), bitshift(rgb(2,:),8));
color = bitor (color, rgb(3,:));

end





