function [model1, model0] = trainBGMMs( y, x, esetup )
% y: labels of x
% x: matrix of data points (+1 and -1!)
% esetup: training parameters
%
% model: trained gmm
% trVal: performance of trained model on training data
x1 = (x(y==1,:,:))';
[~, model1, L1] = vbgm(x1, esetup.initComps); %

x0 = (x(y~=1,:,:))';
[~, model0, L0] = vbgm(x0, esetup.initComps); %


