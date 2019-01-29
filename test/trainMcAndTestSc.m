function trainMcAndTestSc( classname )

if nargin < 1, classname = 'alarm'; end;

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmAmsBlockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'loop', 'randomSeq' );
sc(1).setLengthRef( 'source', 1, 'min', 30 );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc(2).addSource( SceneConfig.DiffuseSource( ...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'loop', 'randomSeq',...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'snrRef', 1 );
sc(2).setLengthRef( 'source', 1, 'min', 10 );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', classname, 'modelPath', 'test_mc_1vsAll_training' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );


pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetRmAmsBlockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ...
    ModelTrainers.LoadModelNoopTrainer( ...
        fullfile( modelPath, [classname '.model.mat'] ), ...
        'performanceMeasure', @PerformanceMeasures.BAC,...
        'maxDataSize', inf ...
        );

pipe.trainset = [];
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', classname, 'modelPath', 'test_mc_1vsAll_testing' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );


