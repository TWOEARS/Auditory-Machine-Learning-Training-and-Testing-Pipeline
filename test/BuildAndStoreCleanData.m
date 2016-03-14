function BuildAndStoreCleanData( )

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe( );
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
pipe.setSceneConfig( [sc] ); 

pipe.init();
%modelPath = pipe.pipeline.run( {'dataStore'}, 0 ); % native pipeline format
modelPath = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

fprintf( ' -- Data is saved at %s -- \n', modelPath );

