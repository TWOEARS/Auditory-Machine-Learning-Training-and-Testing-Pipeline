function genMultiConditional( fc, fl )

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

%% GO

sc(1) = sceneConfig.SceneConfiguration();
sc(1).addSource( sceneConfig.PointSource() );
sc(1).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(2) = sceneConfig.SceneConfiguration();
sc(2).addSource( sceneConfig.PointSource() );
sc(2).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(3) = sceneConfig.SceneConfiguration();
sc(3).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-45) ) );
sc(3).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',45), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(4) = sceneConfig.SceneConfiguration();
sc(4).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-90) ) );
sc(4).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));


%% Azm

sc(5) = sceneConfig.SceneConfiguration();
sc(5).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

sc(6) = sceneConfig.SceneConfiguration();
sc(6).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',135)) );

%% DWN

sc(7) = sceneConfig.SceneConfiguration();
sc(7).addSource( sceneConfig.PointSource() );
sc(7).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -10 ));

sc(8) = sceneConfig.SceneConfiguration();
sc(8).addSource( sceneConfig.PointSource() );
sc(8).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(9) = sceneConfig.SceneConfiguration();
sc(9).addSource( sceneConfig.PointSource() );
sc(9).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 10 ));


%% run

pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


end
