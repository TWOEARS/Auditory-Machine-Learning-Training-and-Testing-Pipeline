function BuildAndStoreCleanData( )

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource() );

pipe.init( sc );

%modelPath = pipe.pipeline.run( 'dataStore', 0 ); % native pipeline format
modelPath = pipe.pipeline.run( 'dataStoreUni', 0 ); % universal format (x,y)

fprintf( ' -- Data is saved at %s -- \n', modelPath );

