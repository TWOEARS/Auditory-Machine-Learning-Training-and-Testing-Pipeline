function loadedData = BuildCleanData( )

addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource() );

pipe.init( sc );

modelPath = pipe.pipeline.run( 'onlyGenCache' ); 

fprintf( ' -- Log is saved at %s -- \n', modelPath );

% access to data:
loadedData = pipe.pipeline.data;

