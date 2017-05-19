function SelfTaughtLearning_Lucas()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();

m = load('.\SparseCodingTest_Lucas\SparseCodingTest_Lucas.model.mat');

% -- feature creator
wrappedFeatureCreator = FeatureCreators.FeatureSet5Blockmean(); 
%pipe.featureCreator = FeatureCreators.FeatureSetDecoratorSparseCoding(wrappedFeatureCreator, m.model, 0.6); 
pipe.featureCreator = wrappedFeatureCreator;

% -- label creator
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 
pipe.labelCreator = babyFemaleVsRestLabeler; 

% -- model creator
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ... 
    'performanceMeasure', @PerformanceMeasures.BAC, ... 
    'cvFolds', 4, ...
    'alpha', 0.99 );

pipe.modelCreator.verbose( 'on' );

% -- prepare data
pipe.trainset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist';

pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);
modelPath = pipe.pipeline.run( 'modelName', 'SelftTaughtTest_Lucas', 'modelPath', 'SelftTaughtTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

