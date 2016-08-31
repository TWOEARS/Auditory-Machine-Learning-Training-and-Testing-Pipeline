function trainAndTestNSrc()

%% inits

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) );
startIdentificationTraining();

%% setup pipeline

pipe = TwoEarsIdTrainPipe();
% block creator
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
% feature creator
pipe.featureCreator = FeatureCreators.FeatureSetNSrc();
% label creator
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler();
% model creator
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );
% train and test set
pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
% setup data
pipe.setupData();

%% scene creation

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 0 ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', 45 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', -45 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
pipe.init( sc );

%% output parameters

modelPath = pipe.pipeline.run( ...
    'modelName', 'nSrc', ...
    'modelPath', 'test_buildMultiPointSrcsAzmDistrData', ...
    'runOption', 'dataStoreUni' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

%% EOF

