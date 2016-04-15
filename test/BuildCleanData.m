function loadedData = BuildCleanData( )

addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );

pipe.init( sc );

modelPath = pipe.pipeline.run( 'onlyGenCache' ); 

fprintf( ' -- Log is saved at %s -- \n', modelPath );

% access to data:
loadedData = pipe.pipeline.data;

