function trainAndTest_featMask_svm()

startTwoEars('tt_general.config.xml');

%% training feature selecting model
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 0.5 );
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 'preFolded', ...  % most reasonable if supplying prefolded dataset definitions
    'alpha', 0.75 );  % mix of L1 and L2 regularization
pipe.modelCreator.verbose( 'on' );
ModelTrainers.CVtrainer.useParallelComputing( true );

% data setup
pipe.setTrainset( {'DCASE13_mini_TrainSet_f1.flist',...
                   'DCASE13_mini_TrainSet_f2.flist',...
                   'DCASE13_mini_TrainSet_f3.flist',...
                   'DCASE13_mini_TrainSet_f4.flist'} );
pipe.setupData();

% scene setup
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',-60), ...
                     'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',-30), ...
                     'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
                 'snr', SceneConfig.ValGen( 'manual', 0 ),...
                 'loop', 'randomSeq' );
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',0), ...
                     'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
                 'snr', SceneConfig.ValGen( 'manual', 0 ),...
                 'loop', 'randomSeq' );
sc.setLengthRef( 'source', 1, 'min', 30 );
sc.setSceneNormalization( true, 1 )
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model] = pipe.pipeline.run( 'modelName', 'featSelectModel', 'modelPath', 'test_featMask' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis of GLMNET model
cmpCvAndTestPerf( modelPath, true, '', 'featSelectModel' );
plotCVperfNCoefLambda( model );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );

%% training & testing feature-masked SVM model
% create mask based on selected features from GLMNET model
fmask = zeros( size( fImpacts ) );
[~,fisIdxs] = sort( fImpacts, 'descend' );
fmask(fisIdxs(1:100)) = 1;

% pipe setup
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 0.5 );
pipe.modelCreator = ModelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC, ...
    'hpsMethod', 'random', ...
    'hpsEpsilons', [0.1], ... % define hps set (not a range)
    'hpsKernels', [2], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-5 3], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
    'hpsRefineStages', 2, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', [30,20,10], ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 'preFolded' );           % number of hps cv folds of training set
ModelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );
ModelTrainers.CVtrainer.useParallelComputing( true );

% data setup
pipe.setTrainset( {'DCASE13_mini_TrainSet_f1.flist',...
                   'DCASE13_mini_TrainSet_f2.flist',...
                   'DCASE13_mini_TrainSet_f3.flist',...
                   'DCASE13_mini_TrainSet_f4.flist'} );
pipe.setTestset( {'DCASE13_mini_TestSet.flist'} );
pipe.setupData();

% scene setup
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',-60), ...
                     'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',-30), ...
                     'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
                 'snr', SceneConfig.ValGen( 'manual', 0 ),...
                 'loop', 'randomSeq' );
sc.addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',0), ...
                     'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
                 'snr', SceneConfig.ValGen( 'manual', 0 ),...
                 'loop', 'randomSeq' );
sc.setLengthRef( 'source', 1, 'min', 30 );
sc.setSceneNormalization( true, 1 )
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'featMaskedModel', 'modelPath', 'test_featMask' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis of SVM model
fprintf( 'Sensitivity: %.2f\n', testPerf.sensitivity );
fprintf( 'Specificity: %.2f\n', testPerf.specificity );

svmHpsPlot( [model.hpsSet.params.c], [model.hpsSet.params.gamma], model.hpsSet.perfs );



