function hyperParameters = gridSvmTrain( foldsIdx, yfolds, xfolds, idfolds, niState )

%% get data used for hyperparameter search
% choose number of folds such that the specified data share for hyperparameter search is roughly met

fprintf( 'grid search for best hyperparameters\n\n' );
nDfolds = max( 1, round( niState.hyperParamSearch.dataShare * length( foldsIdx ) ) );
foldsIdxTmp = foldsIdx;
for i = 1:nDfolds
    j = randi( length(foldsIdxTmp) );
    hpsFolds(i) = foldsIdxTmp(j);
    foldsIdxTmp(j) = [];
end
x = vertcat( xfolds{hpsFolds} );
y = vertcat( yfolds{hpsFolds} );
ids = vertcat( idfolds{hpsFolds} );

%
%% determine hyperparameters to test

hyperParameters = [];
switch( lower( niState.hyperParamSearch.method ) )
    case 'grid'
        for k = niState.hyperParamSearch.kernels
        for e = niState.hyperParamSearch.epsilons
            if k == 0
                d = round( niState.hyperParamSearch.searchBudget / length( niState.hyperParamSearch.epsilons ) );
                for c = logspace( niState.hyperParamSearch.cRange(1), niState.hyperParamSearch.cRange(2), d );
                    hyperParameters = [hyperParameters; 0, e, c, 0];
                end
            end
            if k == 2
                d = round( ( niState.hyperParamSearch.searchBudget / length( niState.hyperParamSearch.epsilons ) ) ^ 0.5 );
                for c = logspace( niState.hyperParamSearch.cRange(1), niState.hyperParamSearch.cRange(2), d );
                for g = logspace( niState.hyperParamSearch.gammaRange(1), niState.hyperParamSearch.gammaRange(2), d );
                    hyperParameters = [hyperParameters; 2, e, c, g];
                end
                end
            end
        end
        end
    case 'random'
        for i = 1:niState.hyperParamSearch.searchBudget
            c = 10^( log10(niState.hyperParamSearch.cRange(1)) + ( log10(niState.hyperParamSearch.cRange(2)) - log10(niState.hyperParamSearch.cRange(1)) ) * rand( 'double' ) );
            g = 10^( log10(niState.hyperParamSearch.gammaRange(1)) + ( log10(niState.hyperParamSearch.gammaRange(2)) - log10(niState.hyperParamSearch.gammaRange(1)) ) * rand( 'double' ) );
        end
    case 'intelligrid'
end

%% try each hyperparameter combination with cross validation on the above determined data

bestVal = 0;
for i = 1:size(hyperParameters,1)
    svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 1 -q -e %e', hyperParameters(i,1), hyperParameters(i,4), hyperParameters(i,3), hyperParameters(i,2) );
    fprintf( '\nCV with %s...', svmParamString );
    val = libsvmCVext( y, x, ids, svmParamString, niState.hyperParamSearch.folds, bestVal );
    hyperParameters(i, 5) = val;
    bestVal = max( val, bestVal );
end

%% refine the search, if specified so

if niState.hyperParamSearch.refineStages > 0
    sHPs = sortrows( hyperParameters, 5 );
    bestHPsmean = mean( log10( sHPs(end-2:end,:) ), 1 );
    niStateRec = niState;
    niStateRec.hyperParamSearch.refineStages = niStateRec.hyperParamSearch.refineStages - 1;
    eSmallRange = getNewLogRange( log10(niStateRec.hyperParamSearch.epsilons), bestHPsmean(2) );
    niStateRec.hyperParamSearch.epsilons = unique( 10.^[eSmallRange, bestHPsmean(2)] );
    cSmallRange = getNewLogRange( niStateRec.hyperParamSearch.cRange, bestHPsmean(3) );
    niStateRec.hyperParamSearch.cRange = cSmallRange;
    gSmallRange = getNewLogRange( niStateRec.hyperParamSearch.gammaRange, bestHPsmean(4) );
    niStateRec.hyperParamSearch.gammaRange = gSmallRange;
    hyperParametersRf = gridSvmTrain( x, y, ids, niStateRec );
    hyperParameters = [hyperParameters; hyperParametersRf];
end

%% return hyperparameters/perfomance values

hyperParameters = sortrows( hyperParameters, 5 );

end