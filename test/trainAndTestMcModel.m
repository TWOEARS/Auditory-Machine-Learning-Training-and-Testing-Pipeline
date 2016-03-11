function trainAndTestMcModel( classname )

if nargin < 1, classname = 'baby'; end;

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/trainSet_miniMini1.flist';
pipe.setupData();

sc(1) = sceneConfig.SceneConfiguration();
sc(1).addSource( sceneConfig.PointSource() );
sc(1).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.trainSet('general',:,'wavFileName')),...
    'offset', sceneConfig.ValGen('manual',0.0) ),...
    sceneConfig.ValGen( 'manual', 10 ),...
    true );
sc(2) = sceneConfig.SceneConfiguration();
sc(2).addSource( sceneConfig.PointSource() );
pipe.setSceneConfig( sc ); 

pipe.init();
modelPath = pipe.pipeline.run( {classname}, 0 );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2,...
        'maxDataSize', inf ...
        );

pipe.trainset = [];
pipe.testset = 'learned_models/IdentityKS/trainTestSets/testSet_miniMini1.flist';
pipe.setupData();

sc(1) = sceneConfig.SceneConfiguration();
sc(1).addSource( sceneConfig.PointSource() );
sc(1).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.testSet('general',:,'wavFileName')),...
    'offset', sceneConfig.ValGen('manual',0.0) ),...
    sceneConfig.ValGen( 'manual', 10 ),...
    true );
sc(2) = sceneConfig.SceneConfiguration();
sc(2).addSource( sceneConfig.PointSource() );
pipe.setSceneConfig( sc ); 

pipe.init();
modelPath = pipe.pipeline.run( {classname}, 0 );
