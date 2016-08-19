function buildMultiPointSrcsAzmDistrData()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmAmsBlockmean();
azmLabeler = LabelCreators.IdAzmDistributionLabeler( 'angularResolution', 5, ...
    'types', {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'}, {{'femaleScream'}, {'maleScream'}}});
pipe.labelCreator = azmLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 90 ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', -90 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelPath', 'test_buildMultiPointSrcsAzmDistrData', 'runOption', 'dataStoreUni' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

