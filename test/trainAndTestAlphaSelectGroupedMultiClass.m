function trainAndTestAlphaSelectGroupedMultiClass()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% male scream will be 1, baby crying 2, female scream 3, rest -1. Energy decides 
%   in case of overlap 
typeMulticlassLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( ...
                              'types', {{'maleScream'},{'baby'},{'femaleScream'}}, ...
                              'srcPrioMethod', 'energy' );
pipe.labelCreator = typeMulticlassLabeler;
pipe.modelCreator = ModelTrainers.GlmNetModelSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomialGrouped', ... % throw out the same betas for all classes
    'hpsAlphaRange', [0 1], ... % define hps alpha range
    'hpsSearchBudget', 5, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 3,...         % number of hps cv folds of training set
    'cvFolds', 2 ... %????
 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'alphaGroupedMulticlassModel', 'modelPath', 'alphaGroupedMulticlass' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );
