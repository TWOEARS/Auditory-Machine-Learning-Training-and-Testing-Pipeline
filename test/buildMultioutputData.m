function buildMultioutputData()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmAmsBlockmean();
% alarm will be 1, baby 2, female 3, fire 4, rest -1
typeMulticlassLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', ...
                                       {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'}} );
% label will be azm of source 1
azmLabeler = LabelCreators.AzmLabeler( 'sourceId', 1 );
% multivariate labels: (typeId,azmSrc1)
multiLabeler = LabelCreators.MultiLabeler( {typeMulticlassLabeler, azmLabeler} );
pipe.labelCreator = multiLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 90 ) ) );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', -90 ) ) );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelPath', 'test_multivarData', 'runOption', 'dataStoreUni' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

