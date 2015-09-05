function genDiffWhtNoise( fc, fl )

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -20 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -10 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 0 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 5 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 10 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 20 ));

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 30 ));

createModelData( fl, sc, fc );

end
