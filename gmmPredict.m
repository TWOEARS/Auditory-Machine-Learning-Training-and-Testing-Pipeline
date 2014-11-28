function [pred, val, llh1,llh0,P1,P0] = gmmPredict( y, x, model1, model0 )
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0

% ML-EM approach
xc = x';
[P1, llh1] = likelihood(xc, model1);
[P0, llh0] = likelihood(xc, model0);
pred = repmat(-1,size(y,1),1);
pred(llh1'>llh0')=1;
val = validation_function(pred, y);


