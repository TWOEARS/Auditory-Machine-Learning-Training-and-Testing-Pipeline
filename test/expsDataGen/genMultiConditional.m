function genMultiConditional( fc, fl )

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

%% GO

sc(2) = sceneConfig.SceneConfiguration();
sc(2).addSource( sceneConfig.PointSource() );
sc(2).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));
pipe.setSceneConfig( sc ); 

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-45) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',45), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));
pipe.setSceneConfig( sc ); 

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-90) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));
pipe.setSceneConfig( sc ); 


%% Azm

sc(6) = sceneConfig.SceneConfiguration();
sc(6).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

sc(10) = sceneConfig.SceneConfiguration();
sc(10).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',135)) );

%% DWN

sc(12) = sceneConfig.SceneConfiguration();
sc(12).addSource( sceneConfig.PointSource() );
sc(12).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -10 ));

sc(13) = sceneConfig.SceneConfiguration();
sc(13).addSource( sceneConfig.PointSource() );
sc(13).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(15) = sceneConfig.SceneConfiguration();
sc(15).addSource( sceneConfig.PointSource() );
sc(15).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 10 ));


%% run

pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


end
