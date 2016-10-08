function trainAndTestVWModel(classname)

if nargin < 1, classname = 'speech'; end;
addpath( '..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.VWmodelSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'passes', 5, ...
    'lossFunction', 'hinge', ...
    'hpsLearningRateRange', [0.1 20000], ...
    'learningRateDecay', 1, ...
    ... %'hpsLambda1', [0.1 10], ...
    'lambda1', 0, ...
    'lambda2', 0, ...
    ... %'hpsInitialTrange', [0 20000], ...
    'initialT', 0, ...
    'powerT', 0.5, ...
    'hpsMaxDataSize', 50, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 1, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 7, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4,...         % number of hps cv folds of training set
    'finalMaxDataSize',111);           
modelTrainers.Base.balMaxData( true, false );

pipe.modelCreator.verbose( 'on' );

%pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
%pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TestSet.flist';

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TestSet_1.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( {classname}, 0 );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

