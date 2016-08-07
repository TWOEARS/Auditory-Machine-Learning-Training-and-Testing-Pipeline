function trainAndTest_featSelect( classname )

if nargin < 1, classname = 'baby'; end;

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', classname, 'modelPath', 'test_featSelect' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

m = load( [modelPath filesep classname '.model.mat'] );
fmask = zeros( size( m.featureCreator.description ) );
fmask(m.model.getBestLambdaCVresults()) = 1;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ModelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'hpsEpsilons', [0.1], ... % define hps set (not a range)
    'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-8 0], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
...%     'hpsMaxDataSize', 1000, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 0, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 9, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4 );           % number of hps cv folds of training set
ModelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', [classname '.featSelect'], 'modelPath', 'test_featSelect' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );
