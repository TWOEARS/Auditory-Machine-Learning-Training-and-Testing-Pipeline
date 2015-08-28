function modelPath = idtrainVarSNR( classname, trainFlist, featureCreator, modelTrainer, SNR )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc = sceneConfig.SceneConfiguration();
sc.angleSignal = sceneConfig.ValGen('manual', [0]);
sc.distSignal = sceneConfig.ValGen('manual', [3]);
sc.addOverlay( ...
    sceneConfig.ValGen('random', [0,359.9]), ...
    sceneConfig.ValGen('manual', 3),...
    sceneConfig.ValGen('manual', [SNR]), 'diffuse',...
    sceneConfig.ValGen('set', {'trainingScripts/noise/whtnoise.wav'}), ...
    sceneConfig.ValGen('manual', 0) );
trainpipe.setSceneConfig( [sc] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

