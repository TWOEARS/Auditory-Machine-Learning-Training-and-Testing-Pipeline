function buildOnlyCache( )

startTwoEars('tt_general.config.xml');

% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 0.5 );
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );

% data setup
pipe.setData( {'DCASE13_mini_TrainSet_f1.flist',...
               'DCASE13_mini_TrainSet_f2.flist',...
               'DCASE13_mini_TrainSet_f3.flist',...
               'DCASE13_mini_TrainSet_f4.flist',...
               'DCASE13_mini_TestSet.flist'} );
pipe.trainsetShare = 1;
pipe.setupData();

% scene setup
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( 'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc.addSource( SceneConfig.DiffuseSource( 'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
              'loop', 'randomSeq',...
              'snr', SceneConfig.ValGen( 'manual', 10 ),...
              'snrRef', 1 );
sc.addSource( SceneConfig.PointSource( 'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
              'loop', 'randomSeq',...
              'snr', SceneConfig.ValGen( 'manual', 0 ),...
              'snrRef', 1 );
sc.setLengthRef( 'source', 1, 'min', 30 );
pipe.init( sc, 'fs', 16000, 'stopAfterProc', inf );

% pipeline run
modelPath = pipe.pipeline.run( 'runOption', 'onlyGenCache' );
fprintf( ' -- run log is saved at %s -- \n\n', modelPath );
