function trainAndTest_BRIR()

startTwoEars('tt_general.config.xml');

brirs = { ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
    };
    
%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 1.0/3 );
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 1.0 );
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
sc.addSource( SceneConfig.BRIRsource( brirs{3}, 'speakerId', 1, ...
                                      'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc.addSource( SceneConfig.BRIRsource( brirs{3}, 'speakerId', 2, ...
                                      'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ),...
                                      'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
              'snr', SceneConfig.ValGen( 'manual', 0 ),...
              'loop', 'randomSeq' );
sc.setBRIRheadOrientation( 0.4 ); % relative to recorded azm range (0..1)
sc.setLengthRef( 'source', 1, 'min', 30 );
sc.setSceneNormalization( true, 1 )
pipe.init( sc, 'hrir', [], 'fs', 16000 ); % empty hrir to avoid usage of default HRIR

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'brirSpeech', 'modelPath', 'test_brir_training' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis
fprintf( 'Sensitivity: %.2f\n', testPerf.sensitivity );
fprintf( 'Specificity: %.2f\n', testPerf.specificity );

cmpCvAndTestPerf( modelPath, true );
plotCVperfNCoefLambda( model );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


