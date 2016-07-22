function trainAndTestCleanBabyFemaleSVMmodel()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmAmsBlockmean();
% baby+female will be 1, rest -1
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'baby', 'femaleSpeech'}}, ...
                                          'negOut', 'all', 'negOutType', 'rest' );
pipe.labelCreator = babyFemaleVsRestLabeler;
pipe.modelCreator = ModelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'hpsEpsilons', [0.001], ... % define hps set (not a range)
    'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-6 2], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
    'hpsMaxDataSize', 1000, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 1, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 7, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4,...         % number of hps cv folds of training set
    'finalMaxDataSize',10000);           
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS_mini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.setLengthRef( 'time', 15 );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'babyFemale', 'modelPath', 'test_cleanBabyFemale_svm' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

