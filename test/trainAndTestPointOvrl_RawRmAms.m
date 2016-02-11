function trainAndTestPointOvrl_RawRmAms( classname )

if nargin < 1, classname = 'baby'; end;

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSetRawRmAms();
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/trainSet_miniMini1.flist';
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.trainSet('general',:,'wavFileName')),...
    'offset', sceneConfig.ValGen('manual',0.0) ),...
    sceneConfig.ValGen( 'manual', -9 ),...
    true );
pipe.setSceneConfig( [sc] ); 

pipe.init();
modelPath = pipe.pipeline.run( {classname}, 0 );
%modelPath = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSetRawRmAms();
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2,...
        'maxDataSize', inf ...
        );

pipe.trainset = [];
pipe.testset = 'learned_models/IdentityKS/trainTestSets/testSet_miniMini1.flist';
pipe.setupData();

sc = sceneConfig.SceneConfiguration(); % clean
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.testSet('general',:,'wavFileName')),...
    'offset', sceneConfig.ValGen('manual',0.0) ),...
    sceneConfig.ValGen( 'manual', -9 ),...
    true );
pipe.setSceneConfig( [sc] ); 

pipe.init();
modelPath1 = pipe.pipeline.run( {classname}, 0 );
%modelPath1 = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

fprintf( ' -- Training: Saved at %s -- \n\n', modelPath );
fprintf( ' -- Testing: Saved at %s -- \n\n', modelPath1 );
