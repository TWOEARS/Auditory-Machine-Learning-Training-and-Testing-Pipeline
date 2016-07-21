function buildOnlyCache( )

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
babyLabeler = LabelCreators.MultiEventTypeLabeler( ...
                             'types', {{'baby'}}, 'negOut', 'all', 'negOutType', 'rest' );
pipe.labelCreator = babyLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );

pipe.data = 'learned_models\IdentityKS\trainTestSets/NIGENS_mini_TrainSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
                  pipe.pipeline.data('fileLabel',{{'type',{'fire'}}},'fileName') ) ),...
    'loop', 'randomSeq',...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'snrRef', 1 );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'runOption', 'onlyGenCache' );

fprintf( ' -- run log is saved at %s -- \n\n', modelPath );
