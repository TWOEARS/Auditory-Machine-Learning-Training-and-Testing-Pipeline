function trainAndTestCleanBabyFemale_Lucas()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe(); %todo: anschauen; erzeugt wrapper
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean(); % feature creator (package) (welche features werden erzeugt)
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); % Ziel des Trainings (type (x), location, number of sources)
% binäre classification (hit or not) -> hier zB speech
pipe.labelCreator = babyFemaleVsRestLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ... %was ist Trainingsalgo
    'performanceMeasure', @PerformanceMeasures.BAC, ... %todo anschauen
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' ); %Ausführung wird kommentiert (-verbose)

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  ); %anechoic (HRIR) per default
pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', 'babyFemale_Lucas', 'modelPath', 'test_cleanBabyFemale_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

