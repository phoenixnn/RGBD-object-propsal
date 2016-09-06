function m_GrabCut_GUI
close all
%  Create and hide the UI as it is being constructed.
f = figure('Visible','on','Position',[360,500,1320,350]);

% Construct the components
h_load    = uicontrol('Style','pushbutton',...
             'String','Image','Position',[410,250,70,25], ...
             'Callback', @loadImage_Callback);
h_poly    = uicontrol('Style','pushbutton',...
             'String','Polygon','Position',[410,180,70,25], ...
             'Callback', @MarkPolygon_Callback);
h_run = uicontrol('Style','pushbutton',...
             'String','Run','Position',[410,110,70,25], ...
             'Callback', @Run_Callback);
         
align([h_load, h_poly, h_run],'Center','None');

handles = guihandles(f);

handles.h_display_1 = axes('Units','Pixels','Position',[10,30,400,300]); 
handles.h_display_2 = axes('Units','Pixels','Position',[485,30,400,300]);
handles.h_display_3 = axes('Units','Pixels','Position',[900,30,400,300]);

guidata(f, handles);

end

function loadImage_Callback(source, eventdata)
FilterSpec = ['*'];
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec);
fullFileName = strcat(PathName, FileName);
global I;
I = imread(fullFileName);
handles = guidata(source,);
imshow(I, 'Parent', handles.h_display_1);
end


function MarkPolygon_Callback(hObject, eventdata)
global fixedBG;
global I; 

handles = guidata(gcbo);
disp('select ROI ...');

fixedBG = ~roipoly(I);


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
imshow(im, 'Parent', handles.h_display_1);
end

function Run_Callback(hObject, eventdata)

global fixedBG;
global I;
disp('Run GrabCut ...');
im = double(I);
[h, w, d] = size(I);
mask_fixed_fg = false(h, w);
mask_fixed_bg = false(h, w);
seg = m_Grabcut( im, ~fixedBG, mask_fixed_fg, mask_fixed_bg);
result = I.* repmat(uint8(seg), [1 1 3]);
handles = guidata(gcbo);
imshow(result, 'Parent', handles.h_display_2);
imshow(logical(seg), 'Parent', handles.h_display_3);


end