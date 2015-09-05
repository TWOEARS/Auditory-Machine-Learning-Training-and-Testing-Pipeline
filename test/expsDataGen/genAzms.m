function genAzms( fc, fl )

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',135)) );

createModelData( fl, sc, fc );


sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',180)) );

createModelData( fl, sc, fc );

end
