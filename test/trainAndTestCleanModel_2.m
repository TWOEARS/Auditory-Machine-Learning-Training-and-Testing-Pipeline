function trainAndTestCleanModel_2( classname, fmask )

if nargin < 1, classname = 'speech'; end;
if nargin < 2, fmask = []; end;

addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
ModelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TestSet.flist';

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( classname );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

