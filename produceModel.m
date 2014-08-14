function produceModel( soundsDir, className, esetup )

%% start debug output

modelSavePreStr = [soundsDir '/' className '/' className '_' getModelHash(esetup)];
delete( [modelSavePreStr '.log'] );
diary( [modelSavePreStr '.log'] );
disp('--------------------------------------------------------');
disp('--------------------------------------------------------');
flatPrintStruct( esetup )
disp('--------------------------------------------------------');

%% data pipeline: load sounds - wp2 process - extract blocks - create labels & features

wp2processSounds( soundsDir, className, esetup );
blockifyData( soundsDir, className, esetup );
[y, identities] = makeLabels( soundsDir, className, esetup );
x = makeFeatures( soundsDir, className, esetup );

%%  split data for outer CV
[yfolds, xfolds, idsfolds] = splitDataPermutation( y, x, identities, esetup.generalizationEstimation.folds );
save( [soundsDir '/' className '/' className '_' getSplitDataHash(esetup) '.splitdata.mat'], 'yfolds', 'xfolds', 'idsfolds', 'esetup' );

%% outer CV for estimating generalization performance

for i = 1:esetup.generalizationEstimation.folds
    
    foldsIdx = 1:esetup.generalizationEstimation.folds;
    foldsIdx(i) = [];
    
    fprintf( '\n%i. run of generalization assessment CV -- training\n\n', i );
    [model, translators, factors, predGenVals(i), hps{i}, cvtrVals(i)] = trainSvm( foldsIdx, yfolds, xfolds, idsfolds, esetup, 0 );
    
    fprintf( '\n%i. run of generalization assessment CV -- testing\n', i );
    [~, genVals(i), ~] = libsvmPredictExt( yfolds{i}, xfolds{i}, model, translators, factors, 0 );
    fprintf( '===============================================================\n' );

end

%% get perfomance numbers

cvtrVal = mean( cvtrVals );
cvtrValStd = std( cvtrVals );
genVal = mean( genVals );
genValStd = std( genVals );
predGenVal = mean( predGenVals );
predGenValStd = std( predGenVals );
fprintf( '\n=============================================\n' );
fprintf( '====================================================================================\n' );
fprintf( '\nTraining perfomance as evaluated by %i-fold CV is %g +-%g\n', esetup.generalizationEstimation.folds, cvtrVal, cvtrValStd );
fprintf( '\nGeneralization perfomance as evaluated by %i-fold CV is %g +-%g\n', esetup.generalizationEstimation.folds, genVal, genValStd );
fprintf( 'Prediction of CV was %g +-%g\n\n', predGenVal, predGenValStd );
fprintf( '====================================================================================\n' );
fprintf( '=============================================\n' );

%% final production of a model, using the whole dataset

disp( 'training model on whole dataset' );
[model, translators, factors, trPredGenVal, trHps, trVal] = trainSvm( 1:esetup.generalizationEstimation.folds, yfolds, xfolds, idsfolds, esetup, 1 );

%% saving model and perfomance numbers, end debug output

modelhashes = {['wp2hash: ' getWp2dataHash( esetup )]; ['blockdatahash: ' getBlockDataHash( esetup )]; ['labelhash: ' getLabelsHash( esetup )]; ['featureshash: ' getFeaturesHash( esetup )]; ['splitdatahash: ' getSplitDataHash( esetup )]; ['modelhash: ' getModelHash( esetup )]}
save( [modelSavePreStr '_model.mat'], 'model', 'genVal', 'genValStd', 'genVals', 'cvtrVal', 'cvtrValStd', 'cvtrVals', 'predGenVal', 'predGenValStd', 'predGenVals', 'trPredGenVal', 'trVal', 'hps', 'trHps', 'modelhashes', 'esetup' );
save( [modelSavePreStr '_scale.mat'], 'translators', 'factors', 'esetup' );
dynSaveMFun( @scaleData, [], [modelSavePreStr '_scaleFunction'] );
dynSaveMFun( esetup.featureCreation.function, esetup.featureCreation.functionParam, [modelSavePreStr '_featureFunction.mat'] );

diary off;

