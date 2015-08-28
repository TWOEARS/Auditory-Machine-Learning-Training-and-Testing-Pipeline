function modelPath = idtrainCleanAzmMC( classname, trainFlist, featureCreator, modelTrainer )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc1 = sceneConfig.SceneConfiguration();
sc1.angleSignal = sceneConfig.ValGen('manual', 0);
sc2 = sceneConfig.SceneConfiguration();
sc2.angleSignal = sceneConfig.ValGen('manual', 45);
sc3 = sceneConfig.SceneConfiguration();
sc3.angleSignal = sceneConfig.ValGen('manual', 90);
sc4 = sceneConfig.SceneConfiguration();
sc4.angleSignal = sceneConfig.ValGen('manual', 135);
sc5 = sceneConfig.SceneConfiguration();
sc5.angleSignal = sceneConfig.ValGen('manual', 180);
trainpipe.setSceneConfig( [sc1,sc2,sc3,sc4,sc5] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

