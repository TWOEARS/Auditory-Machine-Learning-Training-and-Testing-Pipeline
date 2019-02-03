function trainMcAndTestSc()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% training
if ~exist( fullfile( 'test_mc_training', 'speech.model.mat' ), 'file' )
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 1./3 );
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
pipe.setupData();

% scenes setup
sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',-45), ...
                     'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc(1).addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',+45), ...
                     'data', SceneConfig.MultiFileListValGen( pipe.srcDataSpec ) ),...
                 'snr', SceneConfig.ValGen( 'manual', 0 ),...
                 'loop', 'randomSeq' );
sc(1).setLengthRef( 'source', 1, 'min', 30 );
sc(1).setSceneNormalization( true, 1 )
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
                     'azimuth',SceneConfig.ValGen('manual',0), ...
                     'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc(2).addSource( SceneConfig.DiffuseSource( 'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
                 'loop', 'randomSeq',...
                 'snr', SceneConfig.ValGen( 'manual', 0 ) );
sc(2).setLengthRef( 'source', 1, 'min', 10 );
sc(2).setSceneNormalization( true, 1 );
pipe.init( sc, 'fs', 16000 );

% pipeline run
modelPath = pipe.pipeline.run( 'modelName', 'speech', 'modelPath', 'test_mc_training' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

else
disp( 'Already trained; only testing' );
modelPath = fullfile( pwd, 'test_mc_training' );
end
%% testing
% pipeline creation
pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 1./3 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, 'negOut', 'rest', ...
                                                         'labelBlockSize_s', 0.5 );
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( ...
        fullfile( modelPath, ['speech' '.model.mat'] ), ...
        'performanceMeasure', @PerformanceMeasures.BAC,...
        'maxDataSize', inf ...
        );
pipe.modelCreator.verbose( 'on' );

%data setup
pipe.setTestset( {'DCASE13_mini_TestSet.flist'} );
pipe.setupData();

% scene setup
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                  'azimuth',SceneConfig.ValGen('manual',0), ...
                  'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.setLengthRef( 'source', 1, 'min', 30 );
pipe.init( sc, 'fs', 16000 );

[modelPath,model,testPerf] = pipe.pipeline.run( 'modelName', 'speech', 'modelPath', 'test_mc_training' );
fprintf( ' -- Model is saved at %s -- \n', modelPath );

% short analysis
fprintf( 'Sensitivity: %.2f\n', testPerf.sensitivity );
fprintf( 'Specificity: %.2f\n', testPerf.specificity );

cmpCvAndTestPerf( modelPath, true );
plotCVperfNCoefLambda( model );

fDescription = pipe.featureCreator.description;
[~,fImpacts] = model.getBestLambdaCVresults();
plotDetailFsProfile( fDescription, fImpacts, '', false );

