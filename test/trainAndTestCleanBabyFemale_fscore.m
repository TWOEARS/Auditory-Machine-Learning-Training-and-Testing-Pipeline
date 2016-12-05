function trainAndTestCleanBabyFemale_fscore()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'femaleSpeech','maleSpeech'}}, ...
                                          'negOut', 'rest' );
pipe.labelCreator = babyFemaleVsRestLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.Fscore, ...
    'labelWeights', [1.25 1], ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'babyFemale', 'modelPath', 'test_cleanBabyFemale_svm' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

