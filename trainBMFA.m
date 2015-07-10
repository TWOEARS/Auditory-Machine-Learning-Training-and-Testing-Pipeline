function [model1, model0] = trainBMFA( y, x, esetup )
% y: labels of x
% x: matrix of data points (+1 and -1!)
% esetup: training parameters
%
% model: trained gmm


x1 = (x(y==1,:,:))';
if sum(sum(isnan(x1)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x1(isnan(x1))=0;
end
%  [x1,~] = preprocess(x1);
model1 = vbmfa(x1,esetup.mfaK);
x0 = (x(y==-1,:,:))';
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end
% [x0,~] = preprocess(x0);
model0 = vbmfa(x0,esetup.mfaK);

