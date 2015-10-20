function pths = saveGenOvrl( fc, fl, tazm, dazm, snr )

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',tazm) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',dazm), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', snr ));
pipe.setSceneConfig( sc ); 

pipe.init();
pths{end+1} = pipe.pipeline.run( {'dataStoreUni'}, 0 );

end
