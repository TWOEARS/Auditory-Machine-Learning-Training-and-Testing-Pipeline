function [model1, model0] = trainMbfs( y, x, esetup )
% y: labels of x
% x: matrix of data points (+1 and -1!)
% esetup: training parameters
%
% model: trained gmm
% trVal: performance of trained model on training data

x1 = (x(y==1,:,:))';
if sum(sum(isnan(x1)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x1(isnan(x1))=0;
end
x0 = real((x(y~=1,:,:))');
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end
factorDim = 1;
mySetup.nIter = 10;
mySetup.minLLstep = 1E-3;
mySetup.TOLERANCE = 1E-1;
% x1 = preprocess(x1);
pDprior1 = init(MixtureFactorAnalysers(esetup.nComp),x1 ,factorDim);
[model1,LL1,r1] = adapt(pDprior1, x1 ,mySetup);
% x0 = preprocess(x0);
pDprior0 = init(MixtureFactorAnalysers(esetup.nComp),x0 ,factorDim);
[model0,LL0,r0] = adapt(pDprior0, x0 ,mySetup);
