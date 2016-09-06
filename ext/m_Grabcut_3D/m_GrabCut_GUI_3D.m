function m_GrabCut_GUI_3D
close all
m_create_components();
end

function m_create_components()
%  Create and hide the UI as it is being constructed.
f = figure('Visible','on','Position',[360,500,1320,750]);

% Construct the pushbuttons
h_load = uicontrol('Style','pushbutton','String','Color','Position', ...
                   [200,20,70,25], 'Callback', @loadImage_Callback);
         
% h_load_d = uicontrol('Style','pushbutton','String','Depth','Position', ...
%                      [600,20,70,25]);%, 'Callback', @loadDepth_Callback);
         
h_poly = uicontrol('Style','pushbutton','String','Polygon','Position', ...
                   [800,20,70,25],'Callback', @MarkPolygon_Callback);
               
h_rect = uicontrol('Style','pushbutton','String','Rect','Position', ...
                   [1000,20,70,25],'Callback', @MarkRect_Callback);
               
h_run_rgb = uicontrol('Style','pushbutton','String','Run(RGB)','Position', ...
                  [1200,20,70,25], 'Callback', @Run_Callback);
              
h_run_rgbd = uicontrol('Style','pushbutton','String','Run(RGB-D)','Position', ...
                  [1200,20,80,25], 'Callback', @Run_Callback_rgbd);
              
h_vis_3d = uicontrol('Style','pushbutton','String','3D scene','Position', ...
                  [1200,20,80,25], 'Callback', @vis3d_Callback);

h_vis_3d_org = uicontrol('Style','pushbutton','String','3D scene(org)','Position', ...
                  [1200,20,100,25], 'Callback', @vis3d_org_Callback);  
              
h_kde_depth = uicontrol('Style','pushbutton','String','Depth_KDE','Position', ...
                  [1200,20,100,25], 'Callback', @kde_d_Callback);  
              
h_floor = uicontrol('Style','pushbutton','String','Floor','Position', ...
  [1200,20,100,25], 'Callback', @floor_Callback);
         
align([h_load, h_poly, h_rect, h_run_rgb, h_run_rgbd, h_vis_3d, ...
       h_vis_3d_org, h_kde_depth, h_floor], 'Fixed', 30,'bottom');

% create axes and texts
handles = guihandles(f);

handles.h_display_1 = axes('Units','Pixels','Position',[10,420,400,300]);
uicontrol('Style','text','Position',[100,725,200,20],'String', ...
          'Original Color Image', 'FontSize',12, 'FontWeight', 'bold');

handles.h_display_2 = axes('Units','Pixels','Position',[455,420,400,300]);
uicontrol('Style','text','Position',[520,725,250,20],'String', ...
          'GrabCut(RGB) Segment', 'FontSize',12, 'FontWeight', 'bold');
      
handles.h_display_3 = axes('Units','Pixels','Position',[900,420,400,300]);
uicontrol('Style','text','Position',[1000,725,200,20],'String', ...
          'GrabCut(RGB) Mask', 'FontSize',12, 'FontWeight', 'bold');

handles.h_display_4 = axes('Units','Pixels','Position',[10,70,400,300]);
uicontrol('Style','text','Position',[100,380,200,20],'String', ...
          'ROI Polygon', 'FontSize',12, 'FontWeight', 'bold');
      
handles.h_display_5 = axes('Units','Pixels','Position',[455,70,400,300]);
uicontrol('Style','text','Position',[520,380,250,20],'String', ...
          'GrabCut(RGB-D) Segment', 'FontSize',12, 'FontWeight', 'bold');
      
handles.h_display_6 = axes('Units','Pixels','Position',[900,70,400,300]);
uicontrol('Style','text','Position',[1000,380,200,20],'String', ...
          'GrabCut(RGB-D) Mask', 'FontSize',12, 'FontWeight', 'bold');
guidata(f, handles);


end

function loadImage_Callback(source, eventdata)
FilterSpec = ['*'];
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec);
fullFileName = strcat(PathName, FileName);
global I;
I = imread(fullFileName);
%I = imresize(I, 0.5);
handles = guidata(gcbo);
imshow(I, 'Parent', handles.h_display_1);

[~,name,ext] = fileparts(fullFileName);

% load in-painted depth
global D;
D = double(imread(fullfile('./data/NYUV2/nyu_depth_crop', [name, '.png'])));
D = D/100; % centimeters
fprintf('load depth image\n');

% fx_d = 5.8262448167737955e+02;
% fy_d = 5.8269103270988637e+02;
% cx_d = 3.1304475870804731e+02;
% cy_d = 2.3844389626620386e+02;
% 
% Kd = [fx_d 0 (cx_d-40);
%       0 fy_d (cy_d-45);
%       0 0 1];

fx_rgb = 5.1885790117450188e+02;
fy_rgb = 5.1946961112127485e+02;
cx_rgb = 3.2558244941119034e+02;
cy_rgb = 2.5373616633400465e+02;

% intrinsic matrix
Kd = [fx_rgb 0 (cx_rgb-40);
      0 fy_rgb (cy_rgb-45);
      0 0 1];
  
[h, w, ~] = size(I);
[xx,yy] = meshgrid(1:w, 1:h);

X = (xx - Kd(1,3)) .* D / Kd(1,1);
Y = (yy - Kd(2,3)) .* D / Kd(2,2);
Z = D;
global points;
points = cat(3, X, Y, Z);

% load original depth
global pts_org;
tmp = load(fullfile('./data/NYUV2/m_pcdAlign', [name, '.mat']));
pts_org = tmp.points;

% load detected planes
tmp = load(fullfile('./data/cache/m_planes', [name, '.mat']));
global planes;
planes = tmp.planeStruct;
planeid = planes.planeInfo.isBoundary & planes.planeInfo.isHorizontal;
id = find(planeid>0);
global floor;
floor = (planes.planemap == id);

end

% function loadDepth_Callback(source, eventdata)
% FilterSpec = ['*'];
% [FileName,PathName,FilterIndex] = uigetfile(FilterSpec);
% fullFileName = strcat(PathName, FileName);
% global D;
% D = double(imread(fullFileName));
% D = D/100; % centimeters
% end


function MarkPolygon_Callback(hObject, eventdata)
global fixedBG;
global I; 

handles = guidata(gcbo);
disp('select Polygon ROI ...');
axes(handles.h_display_4);
fixedBG = ~roipoly(I);
tmp = ~fixedBG;
fprintf('number of pixels in mask : %d\n', sum(tmp(:)));
%%% show red bounds:
% imBounds = I;
% bounds = double(abs(edge(fixedBG)));
% se = strel('square',3);
% bounds = 1 - imdilate(bounds,se);
% imBounds(:,:,2) = imBounds(:,:,2).*uint8(bounds);
% imBounds(:,:,3) = imBounds(:,:,3).*uint8(bounds);
% imshow(imBounds, 'Parent', handles.h_display_1);

% show seg
im = I.* repmat(uint8(~fixedBG) , [1 1 3]);
imshow(im, 'Parent', handles.h_display_4);
end

function MarkRect_Callback(hObject, eventdata)
global fixedBG;
global I; 

handles = guidata(gcbo);
disp('select Rect ROI ...');
axes(handles.h_display_4);
imshow(I, 'Parent', handles.h_display_4);
h = imrect;
wait(h);
fixedBG = ~createMask(h);

% show seg
im = I.* repmat(uint8(~fixedBG) , [1 1 3]);
imshow(im, 'Parent', handles.h_display_4);
end


function Run_Callback(hObject, eventdata)
global fixedBG;
global I;
[h, w, ~] = size(I);
% run RGB grab cut
disp('Run GrabCut (RGB) ...');
% im = double(I);
% mask_fixed_fg = false(h, w);
% mask_fixed_bg = false(h, w);
handles = guidata(gcbo);
% t = tic;
% seg_rgb = m_Grabcut(im, ~fixedBG, mask_fixed_fg, mask_fixed_bg);
% toc(t)

BB = m_mask2bbox(~fixedBG);
%save('./m_FGsegment/tst_BB.mat','BB');
t= tic;
segMasks = m_mask5GC(I, BB, true);
toc(t)
result_rgb = I.* repmat(uint8(segMasks), [1 1 3]);


% result_rgb = I.* repmat(uint8(seg_rgb), [1 1 3]);
imshow(result_rgb, 'Parent', handles.h_display_2);
%imshow(logical(seg_rgb), 'Parent', handles.h_display_3);
 imshow(logical(segMasks), 'Parent', handles.h_display_3);
end

function Run_Callback_rgbd(hObject, eventdata)

global fixedBG;
global I;
global points;
disp('Run GrabCut (RGB-D) ...');
handles = guidata(gcbo);

% [h, w, ~] = size(I);
% im = double(I);
% mask_fixed_fg = false(h, w);
% mask_fixed_bg = false(h, w);

% run RGBD grab cut
% t = tic;
% seg = m_Grabcut_3D( im,points, ~fixedBG, mask_fixed_fg, mask_fixed_bg);
% toc(t)
% result = I.* repmat(uint8(seg), [1 1 3]);

% imshow(result, 'Parent', handles.h_display_5);
% imshow(logical(seg), 'Parent', handles.h_display_6);

BB = m_mask2bbox(~fixedBG);
t= tic;
segMasks = m_mask5GC3D(I, points, BB, true);
%save('./m_FGsegment/tst_BB.mat','BB');
toc(t)
result = I.* repmat(uint8(segMasks), [1 1 3]);
imshow(result, 'Parent', handles.h_display_5);
imshow(logical(segMasks), 'Parent', handles.h_display_6);

end

function vis3d_Callback(hObject, eventdata)
global I;
global points;
global fixedBG;
[h,w,~] = size(I);
pointRGB = cat(3, points./100, single(I));
pointRGB = reshape(pointRGB, [], 6);
pointRGB(fixedBG(:), :) = 0;

pointRGB = reshape(pointRGB, [h,w,6]);
mat2PCDfile('./visualization/test.pcd',double(pointRGB));
system('./visualization/m_pclViewer ./visualization/test.pcd');
end

function vis3d_org_Callback(hObject, eventdata)
global I;
global pts_org;
global fixedBG;
% centimeter to meter
points = pts_org/100;
points(isnan(points)) = 0;

[h,w,~] = size(I);
pointRGB = cat(3, points, single(I));
pointRGB = reshape(pointRGB, [], 6);
pointRGB(fixedBG(:), :) = 0;

pointRGB = reshape(pointRGB, [h,w,6]);
mat2PCDfile('./visualization/test.pcd',double(pointRGB));
system('./visualization/m_pclViewer ./visualization/test.pcd');

end


function kde_d_Callback(hObject, eventdata)
global points;
global fixedBG;

% fitting KDE
d = points(:,:,3);
x = d(~fixedBG);
h = std(x) * 1.06 * numel(x)^(-0.2);
[f,xi, bw] = ksdensity(x, 'bandwidth',h);

% find peaks and valleys
figure;
plot(xi, f);
thresh_wp = 10;
thresh_wv = 10;
[pks, loc_p, width_p, ~ ] = findpeaks(f,xi)
[valleys, loc_v, width_v, ~ ] = findpeaks(-f,xi)

sel_p = width_p > thresh_wp;
pks = pks(sel_p);
loc_p = loc_p(sel_p)
width_p = width_p(sel_p)
hold on;
plot(loc_p, pks + 1e-6, 'v','MarkerFaceColor','r');

sel_v = width_v > thresh_wv;
valleys = valleys(sel_v);
loc_v = loc_v(sel_v)
width_v = width_v(sel_v)

hold on;
plot(loc_v, -valleys - 1e-6, '^','MarkerFaceColor','b');
legend('KDE curve', 'peaks', 'valleys');


% d1 = d;
% d1(fixedBG) = 0;
% mask = ~(d1 > 329) & ~fixedBG;
% figure;
% imshow(mask);

% 
[~, id] = max(pks);
fg_loc = loc_p(id);
bg_loc_far = loc_v(loc_v > fg_loc);
bg_prob_far = valleys(loc_v > fg_loc);
bg_loc_near = loc_v(loc_v < fg_loc);
bg_prob_near = valleys(loc_v < fg_loc);

mask_vis = true(size(d));
flag_1 = false;
if ~isempty(bg_loc_far)
    d1 = d;
    d1(fixedBG) = 0;
    [~, id1] = min(bg_prob_far); 
    mask = ~(d1 > bg_loc_far(id1)) & ~fixedBG; 
    mask_vis = mask_vis & mask;
    flag_1 = true;
end

flag_2 = false;
if ~isempty(bg_loc_near)
    d1 = d;
    d1(fixedBG) = 0;
    [~, id2] = min(bg_prob_near);
    mask = ~(d1 < bg_loc_near(id2)) & ~fixedBG;
    mask_vis = mask_vis & mask;
    flag_2 = true;
end
if flag_1 | flag_2
fixedBG = fixedBG | ~mask_vis;
figure;
imshow(mask_vis);
end

end

function floor_Callback(hObject, eventdata)
global floor;
global fixedBG;
fixedBG = fixedBG | floor;
figure; imshow(floor);
end
