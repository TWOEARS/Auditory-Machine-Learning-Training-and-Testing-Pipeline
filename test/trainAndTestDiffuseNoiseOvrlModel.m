function trainAndTestDiffuseNoiseOvrlModel( classname )

if nargin < 1, classname = 'footsteps'; end;

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startIdentificationTraining();


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

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS_mini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.addSource( SceneConfig.DiffuseSource( ...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'loop', 'randomSeq',...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'snrRef', 1 );
sc.setLengthRef( 'source', 1, 'min', 10 );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', classname, 'modelPath', 'test_diffuseWhtNoiseOvrl' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );


