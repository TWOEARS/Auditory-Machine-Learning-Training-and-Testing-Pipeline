function trainAndTestCleanMultiSpeechModel()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% male or female speech will be 1, rest -1
speechVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'maleSpeech', 'femaleSpeech'}}, ...
                                          'negOut', 'rest' );
% male will be 1, female speech 2, rest -1
maleVsFemaleLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'maleSpeech'},{'femaleSpeech'}}, ...
                                          'negOut', 'rest' );
% multivariate labels
multiLabeler = LabelCreators.MultiLabeler( {speechVsRestLabeler, maleVsFemaleLabeler} );
pipe.labelCreator = multiLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
sc.setLengthRef( 'time', 15 );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'multiSpeech', 'modelPath', 'test_cleanMultispeech' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

