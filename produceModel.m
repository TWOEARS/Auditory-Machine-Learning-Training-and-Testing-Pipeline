function produceModel( soundsDir, className, niState )

%% start debug output

modelSavePreStr = [soundsDir '/' className '/' className '_' getModelHash(niState)];
delete( [modelSavePreStr '.log'] );
diary( [modelSavePreStr '.log'] );
disp('--------------------------------------------------------');
disp('--------------------------------------------------------');
flatPrintStruct( niState )
disp('--------------------------------------------------------');

%% data pipeline: load sounds - wp2 process - extract blocks - create labels & features

wp2processSounds( soundsDir, className, niState );
blockifyData( soundsDir, className, niState );
[y, identities] = makeLabels( soundsDir, className, niState );
x = makeFeatures( soundsDir, className, niState );

%%  split data for outer CV
[yfolds, xfolds, idsfolds] = splitDataPermutation( y, x, identities, niState.generalizationEstimation.folds );
save( [soundsDir '/' className '/' className '_' getSplitDataHash(niState) '.splitdata.mat'], 'yfolds', 'xfolds', 'idsfolds', 'niState' );

%% outer CV for estimating generalization performance

for i = 1:niState.generalizationEstimation.folds
    
    foldsIdx = 1:niState.generalizationEstimation.folds;
    foldsIdx(i) = [];
    
    fprintf( '\n%i. run of generalization assessment CV -- training\n\n', i );
    [model, translators, factors, predGenVals(i), hps{i}, cvtrVals(i)] = trainSvm( foldsIdx, yfolds, xfolds, idsfolds, niState );
    
    fprintf( '\n%i. run of generalization assessment CV -- testing\n', i );
    [~, genVals(i), ~] = libsvmPredictExt( yfolds{i}, xfolds{i}, model, translators, factors );
    
end

%% get perfomance numbers

cvtrVal = mean( cvtrVals );
cvtrValStd = std( cvtrVals );
genVal = mean( genVals );
genValStd = std( genVals );
predGenVal = mean( predGenVals );
predGenValStd = std( predGenVals );
fprintf( '\nTraining perfomance as evaluated by %i-fold CV is %g +-%g\n', niState.generalizationEstimation.folds, cvtrVal, cvtrValStd );
fprintf( '\nGeneralization perfomance as evaluated by %i-fold CV is %g +-%g\n', niState.generalizationEstimation.folds, genVal, genValStd );
fprintf( 'Prediction of CV was %g +-%g\n\n', predGenVal, predGenValStd );

%% final production of a model, using the whole dataset

disp( 'training model on whole dataset' );
[model, translators, factors, trPredGenVal, trHps, trVal] = trainSvm( 1:niState.generalizationEstimation.folds, yfolds, xfolds, idsfolds, niState );

%% saving model and perfomance numbers, end debug output

modelhashes = {['wp2hash: ' getWp2dataHash( niState )]; ['blockdatahash: ' getBlockDataHash( niState )]; ['labelhash: ' getLabelsHash( niState )]; ['featureshash: ' getFeaturesHash( niState )]; ['splitdatahash: ' getSplitDataHash( niState )]; ['modelhash: ' getModelHash( niState )]}
save( [modelSavePreStr '_model.mat'], 'model', 'genVal', 'genValStd', 'genVals', 'cvtrVal', 'cvtrValStd', 'cvtrVals', 'predGenVal', 'predGenValStd', 'predGenVals', 'trPredGenVal', 'trVal', 'hps', 'trHps', 'modelhashes', 'niState' );
save( [modelSavePreStr '_scale.mat'], 'translators', 'factors', 'niState' );
dynSaveMFun( @scaleData, [], [modelSavePreStr '_scaleFunction'] );
dynSaveMFun( niState.featureCreation.function, niState.featureCreation.functionParam, [modelSavePreStr '_featureFunction.mat'] );

diary off;

