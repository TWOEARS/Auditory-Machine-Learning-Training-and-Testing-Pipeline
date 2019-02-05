function trainAndTestOverlappedMultiClass()

startTwoEars('tt_general.config.xml');

%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.blockCreator = BlockCreators.DistractedBlockCreator( 1.0, 0.4, ...
                                                          'distractorSources', 2,...
                                                          'rejectEnergyThreshold', -30 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
% clearthroat will be 1, knock 2, keys 3, speech 4, rest -1. Order decides in case of overlap 
%  (e.g. knock over keys or speech) 
typeMulticlassLabeler = LabelCreators.MultiEventTypeLabeler( ...
                                       'types', {{'clearthroat'},{'knock'},{'keys'},{'speech'}}, ...
                                       'srcPrioMethod', 'order' );
pipe.labelCreator = typeMulticlassLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomial', ...
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
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                  'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc.addSource( SceneConfig.PointSource( ...
                  'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
              'loop', 'randomSeq',...
              'snr', SceneConfig.ValGen( 'manual', 0 ),...
              'snrRef', 1 );
sc.setLengthRef( 'source', 1, 'min', 30 );
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'multiclass', 'modelPath', 'test_multiclass_training' );
fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

% short analysis
fprintf( 'Confusion matrix (rows ~ true type, columns ~ predicted type):\nLabels:' );
disp( testPerf.cmLabels' );
disp( testPerf.confusionMatrix );
fprintf( '\n' );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


