function trainAndTestAlphaSelectGroupedMultiClass()

startTwoEars('tt_general.config.xml');

%% training & testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
typeMulticlassLabeler = LabelCreators.MultiEventTypeLabeler( ...
                              'types', {{'knock'},{'switch'},{'keys'}}, ...
                              'srcPrioMethod', 'energy' );
pipe.labelCreator = typeMulticlassLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomialGrouped', ... % optimize betas for all classes jointly
    'maxDataSize', 1000, ...
    'alphas', [0, 0.5, 0.99], ... % define hps alpha range
    'cvFolds', 'preFolded' ...
 );
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
[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'alphaGroupedMulticlassModel', 'modelPath', 'alphaGroupedMulticlass' );
fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

% short analysis
fprintf( 'Confusion matrix (rows ~ true type, columns ~ predicted type):\n\n' );
disp( testPerf.confusionMatrix );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );


