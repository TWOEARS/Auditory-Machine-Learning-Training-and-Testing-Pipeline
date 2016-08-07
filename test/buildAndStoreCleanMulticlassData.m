function buildAndStoreCleanMulticlassData( )

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmBlockmean();
% alarm will be 1, baby 2, female 3, fire 4, rest -1
typeMulticlassLabeler = LabelCreators.MultiEventTypeLabeler( ...
                                'types', {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'}} );
pipe.labelCreator = typeMulticlassLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models\IdentityKS\trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'runOption', 'dataStoreUni', 'modelPath', 'cleanMulticlassData' );

fprintf( ' -- run log is saved at %s -- \n\n', modelPath );
