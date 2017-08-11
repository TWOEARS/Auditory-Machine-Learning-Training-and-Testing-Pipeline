function STLGlmNet

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

trainSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_1.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_2.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_3.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_4.flist'};
        
testSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_1.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_2.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_3.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_4.flist'};

label = {'alarm', 'baby', 'femaleSpeech', 'fire'};


for labelIndex=1:length(label)    
    for cvIndex=1:length(trainSet) 

        pipe = TwoEarsIdTrainPipe();
        pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
        pipe.labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {{ label{labelIndex} }}, ...
                                              'negOut', 'rest' );

        pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
            'performanceMeasure', @PerformanceMeasures.BAC2, ...
            'cvFolds', 4, ...
            'alpha', 0.99 );

        pipe.trainset = trainSet{cvIndex};
        pipe.testset = testSet{cvIndex};
        pipe.setupData();

        sc = SceneConfig.SceneConfiguration();
        sc.addSource( SceneConfig.PointSource( ...
                'data', SceneConfig.FileListValGen( 'pipeInput' )));
        
        pipe.init( sc, 'fs', 16000);

        modelName = sprintf('STLGlmNet_%s_%s', label{labelIndex} ,datestr(now, 30));
        modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', 'STLTest', 'debug', true);

        fprintf( ' -- Model is saved at %s -- \n', modelPath ); 
    end
end
