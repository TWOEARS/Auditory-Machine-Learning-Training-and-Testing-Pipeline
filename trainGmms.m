function [model1, model0] = trainGmms( y, x, esetup )
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

x0 = real((x(y~=1,:,:))');
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end
options = statset('MaxIter',1000);

try
    model1 =  gmdistribution.fit(x1',esetup.nComp,'Options',options);
catch err
    if (strcmp(err.identifier,'stats:gmdistribution:IllCondCovIter'))
        display('ill-conditioned covariance matrix was catched, training using a single Gaussian component...')
    model1 =  gmdistribution.fit(x1',1,'Options',options);
    end
end

try
    model0 =  gmdistribution.fit(x0',esetup.nComp,'Options',options);
catch err
    if (strcmp(err.identifier,'stats:gmdistribution:IllCondCovIter'))
        display('ill-conditioned covariance matrix was catched, training using a single Gaussian component...')
    model0 =  gmdistribution.fit(x0',1,'Options',options);
    end
end
