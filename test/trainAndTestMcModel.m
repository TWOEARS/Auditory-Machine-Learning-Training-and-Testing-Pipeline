function trainAndTestMcModel( classname )

if nargin < 1, classname = 'baby'; end;

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/trainSet_miniMini1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource() );
sc(1).addSource( SceneConfig.PointSource( ...
    'data',SceneConfig.FileListValGen(pipe.pipeline.trainSet('general',:,'wavFileName')),...
    'offset', SceneConfig.ValGen('manual',0.0) ),...
    SceneConfig.ValGen( 'manual', 10 ),...
    true );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( classname );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

pipe.modelCreator = ...
    ModelTrainers.LoadModelNoopTrainer( ...
        fullfile( modelPath, [classname '.model.mat'] ), ...
        'performanceMeasure', @PerformanceMeasures.BAC2,...
        'maxDataSize', inf ...
        );

pipe.trainset = [];
pipe.testset = 'learned_models/IdentityKS/trainTestSets/testSet_miniMini1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource() );
sc(1).addSource( SceneConfig.PointSource( ...
    'data',SceneConfig.FileListValGen(pipe.pipeline.testSet('general',:,'wavFileName')),...
    'offset', SceneConfig.ValGen('manual',0.0) ),...
    SceneConfig.ValGen( 'manual', 10 ),...
    true );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( classname );
