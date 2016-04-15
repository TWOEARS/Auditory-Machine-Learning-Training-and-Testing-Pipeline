function trainAndTestDiffuseNoiseOvrlModel( classname )

if nargin < 1, classname = 'speech'; end;

addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TestSet_1.flist';

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource() );
sc.addSource( SceneConfig.DiffuseSource( ...
    'data',SceneConfig.NoiseValGen(struct( 'len', SceneConfig.ValGen('manual',44100) )) ),...
    SceneConfig.ValGen( 'manual', 10 ),...
    true );

pipe.init( sc );
modelPath = pipe.pipeline.run( classname );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

