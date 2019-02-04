function trainAndTestDiffuseNoiseOvrlModel()

startTwoEars('tt_general.config.xml');

%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 0.5 );
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC, ...
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
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.addSource( SceneConfig.DiffuseSource( ...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'loop', 'randomSeq',...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'snrRef', 1 );
sc.setLengthRef( 'source', 1, 'min', 20 );
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'noisy', 'modelPath', 'test_noisy_training' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis
fprintf( 'Sensitivity: %.2f\n', testPerf.sensitivity );
fprintf( 'Specificity: %.2f\n', testPerf.specificity );

cmpCvAndTestPerf( modelPath, true );
plotCVperfNCoefLambda( model );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


