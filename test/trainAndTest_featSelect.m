function trainAndTest_featSelect( classname )

if nargin < 1, classname = 'speech'; end;

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

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TestSet.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( {classname}, 0 );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

m = load( [modelPath filesep classname '.model.mat'] );
fmask = zeros( size( m.featureCreator.description ) );
fmask(m.model.getBestLambdaCVresults()) = 1;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'hpsEpsilons', [0.1], ... % define hps set (not a range)
    'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-8 0], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
...%     'hpsMaxDataSize', 50, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 0, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 9, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4 );           % number of hps cv folds of training set
modelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TrainSet.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_mini_TestSet.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );

pipe.init( sc );
modelPath = pipe.pipeline.run( {classname}, 0 );

fprintf( ' -- Model is saved at %s -- \n', modelPath );
