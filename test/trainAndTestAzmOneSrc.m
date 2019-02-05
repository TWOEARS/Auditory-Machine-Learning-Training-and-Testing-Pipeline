function trainAndTestAzmOneSrc()

startTwoEars('tt_general.config.xml');

%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
% FeatureSet5Blockmean is _not_ a very suitable feature set for
% sound source localization.
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
% label will be azm of source 1
pipe.labelCreator = LabelCreators.AzmLabeler( 'sourceId', 1 );
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.NSE, ... % negative squared error
    'family', 'gaussian',... % train as regression task
    'maxDataSize', 5000, ...
    'hpsMaxDataSize', 4000, ...
    'cvFolds', 'preFolded', ...  % most reasonable if supplying prefolded dataset definitions
    'alpha', 0.99 );  % prevents numeric instabilities (compared to 1)
pipe.modelCreator.verbose( 'on' );
ModelTrainers.CVtrainer.useParallelComputing( false );

% data setup
pipe.setTrainset( {'DCASE13_mini_TrainSet_f1.flist',...
                   'DCASE13_mini_TrainSet_f2.flist',...
                   'DCASE13_mini_TrainSet_f3.flist',...
                   'DCASE13_mini_TrainSet_f4.flist'} );
pipe.setTestset( {'DCASE13_mini_TestSet.flist'} );
pipe.setupData();

% scene setup
sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc(1).setLengthRef( 'source', 1, 'min', 30 );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', -45 ) ) );
sc(2).setLengthRef( 'source', 1, 'min', 30 );
sc(3) = SceneConfig.SceneConfiguration();
sc(3).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', -90 ) ) );
sc(3).setLengthRef( 'source', 1, 'min', 30 );
sc(4) = SceneConfig.SceneConfiguration();
sc(4).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 180 ) ) );
sc(4).setLengthRef( 'source', 1, 'min', 30 );
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'azm', 'modelPath', 'test_azm_training' );
fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

% short analysis
fprintf( 'Mean average error: %.1f°\n\n', testPerf.mae );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


