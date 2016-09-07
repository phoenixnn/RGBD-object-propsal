% 20130604  Zhuo Deng Temple University
% Convert a rgb image into Lab space


function [L,A,B,lab] = Rgb2Lab(img)

cform = makecform('srgb2lab');
lab = applycform(img,cform);
L=lab(:,:,1);
A=lab(:,:,2);
B=lab(:,:,3);

end