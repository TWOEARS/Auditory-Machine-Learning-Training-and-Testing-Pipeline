function trainAndTestCleanMultilabelModel()

startTwoEars('tt_general.config.xml');

%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
% knock or switch will be 1, rest -1
clicksVsRestLabeler =  LabelCreators.MultiEventTypeLabeler( 'types', {{'knock', 'switch'}}, ...
                                                            'negOut', 'rest' );
% knock will be 1, rest -1
knockLabeler = LabelCreators.MultiEventTypeLabeler( 'types', {{'knock'}}, ...
                                                    'negOut', 'rest' );
% switch will be 1, rest -1
switchLabeler = LabelCreators.MultiEventTypeLabeler( 'types', {{'switch'}}, ...
                                                    'negOut', 'rest' );
% multivariate labels
pipe.labelCreator = LabelCreators.MultiLabeler( {clicksVsRestLabeler,knockLabeler,switchLabeler} );
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'family', 'multinomialGrouped', ...
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
                  'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc.addSource( SceneConfig.PointSource( ...
                  'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
              'loop', 'randomSeq',...
              'snr', SceneConfig.ValGen( 'manual', 0 ),...
              'snrRef', 1 );
sc.setLengthRef( 'source', 1, 'min', 30 );
pipe.init( sc, 'fs', 16000 );

% pipeline run
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'multilabel', 'modelPath', 'test_multilabel_training' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis
fprintf( 'Sensitivity: %.2f\n', testPerf.sensitivity );
fprintf( 'Specificity: %.2f\n', testPerf.specificity );

cmpCvAndTestPerf( modelPath, true );
plotCVperfNCoefLambda( model );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


