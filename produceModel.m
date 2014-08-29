function produceModel( soundsDir, className, esetup )

%% start debug output

modelSavePreStr = [soundsDir '/' className '/' className '_' getModelHash(esetup)];
delete( [modelSavePreStr '.log'] );
diary( [modelSavePreStr '.log'] );
disp('--------------------------------------------------------');
disp('--------------------------------------------------------');
flatPrintStruct( esetup )
disp('--------------------------------------------------------');

%% collect data files

dfiles = makeSoundLists( soundsDir, className );

%% data pipeline: load sounds - wp2 process - extract blocks - create labels & features

wp2processSounds( dfiles, esetup );
blockifyData( dfiles, esetup );
[y, identities] = makeLabels( dfiles, soundsDir, className, esetup );
x = makeFeatures( dfiles, soundsDir, esetup );

%% get training share of data

if esetup.data.trainSetShare(1) / esetup.data.trainSetShare(2) >= 0.99
    yTrain = y;
    yTest = [];
    xTrain = x;
    xTest = [];
    idsTrain = identities;
    idsTest = [];
else
    [yTrainTestFolds, xTrainTestFolds, idsTrainTestFolds] = splitDataPermutation( y, x, identities, esetup.data.trainSetShare(2) );
    yTrain = vertcat( yTrainTestFolds{1:esetup.data.trainSetShare(1)} );
    yTest = vertcat( yTrainTestFolds{esetup.data.trainSetShare(1)+1:end} );
    xTrain = vertcat( xTrainTestFolds{1:esetup.data.trainSetShare(1)} );
    xTest = vertcat( xTrainTestFolds{esetup.data.trainSetShare(1)+1:end} );
    idsTrain = vertcat( idsTrainTestFolds{1:esetup.data.trainSetShare(1)} );
    idsTest = vertcat( idsTrainTestFolds{esetup.data.trainSetShare(1)+1:end} );
end

trainFiles = {};
for k = 1:size(idsTrain,1)
    trainFiles{k} = sprintf( '%s\n', dfiles.soundFileNames{idsTrain(k,1)} );
end
trainFiles = unique( trainFiles );
trainFilesFid = fopen( [modelSavePreStr '_trainSet.txt'], 'w' );
for k = 1:length(trainFiles)
    fprintf( trainFilesFid, '%s', trainFiles{k} );
end
fclose( trainFilesFid );

testFiles = {};
for k = 1:size(idsTest,1)
    testFiles{k} = sprintf( '%s\n', dfiles.soundFileNames{idsTest(k,1)} );
end
testFiles = unique( testFiles );
testFilesFid = fopen( [modelSavePreStr '_testSet.txt'], 'w' );
for k = 1:length(testFiles)
    fprintf( testFilesFid, '%s', testFiles{k} );
end
fclose( testFilesFid );

%% split data for outer CV (generalization perfomance assessment)

[yfolds, xfolds, idsfolds] = splitDataPermutation( yTrain, xTrain, idsTrain, esetup.generalizationEstimation.folds );

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

%% get perfomance numbers of outer CV

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

%% final production of a model, using the whole training dataset

disp( 'training model on whole training dataset' );
[model, translators, factors, trPredGenVal, trHps, trVal] = trainSvm( 1:esetup.generalizationEstimation.folds, yfolds, xfolds, idsfolds, esetup, 1 );

%% test final model on test set, if split

if ~isempty( yTest )
    fprintf( '\n\nPerfomance of final model on test set:\n', i );
    [~, testVal, ~] = libsvmPredictExt( yTest, xTest, model, translators, factors, 1 );
    fprintf( '===============================================================\n' );
else
    testVal = [];
end

%% saving model and perfomance numbers, end debug output

modelhashes = {['wp2hash: ' getWp2dataHash( esetup )]; ['blockdatahash: ' getBlockDataHash( esetup )]; ['labelhash: ' getLabelsHash( esetup )]; ['featureshash: ' getFeaturesHash( esetup )]; ['modelhash: ' getModelHash( esetup )]}
save( [modelSavePreStr '_model.mat'], 'model', 'genVal', 'genValStd', 'genVals', 'cvtrVal', 'cvtrValStd', 'cvtrVals', 'predGenVal', 'predGenValStd', 'predGenVals', 'trPredGenVal', 'trVal', 'testVal', 'hps', 'trHps', 'modelhashes', 'esetup' );
save( [modelSavePreStr '_scale.mat'], 'translators', 'factors', 'esetup' );
dynSaveMFun( @scaleData, [], [modelSavePreStr '_scaleFunction'] );
dynSaveMFun( esetup.featureCreation.function, esetup.featureCreation.functionParam, [modelSavePreStr '_featureFunction.mat'] );

diary off;

