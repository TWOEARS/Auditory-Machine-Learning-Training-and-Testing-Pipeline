function modelPath = idtrainSimReverb( classname, trainFlist, featureCreator, modelTrainer )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc = sceneConfig.SceneConfiguration();
sc.angleSignal = sceneConfig.ValGen('manual', [0]);
sc.distSignal = sceneConfig.ValGen('manual', [2]);
room.lengthX = sceneConfig.ValGen('manual', [6]);
room.lengthY = sceneConfig.ValGen('manual', [6]);
room.height = sceneConfig.ValGen('manual', [2.5]);
room.rt60 = sceneConfig.ValGen('manual', [1]);
sc.addRoom( sceneConfig.RoomValGen(room) );
trainpipe.setSceneConfig( [sc] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

