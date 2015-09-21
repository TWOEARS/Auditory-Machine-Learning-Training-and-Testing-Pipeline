addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'sound_databases/generalSoundsNI/all.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

md{1} = saveModelData( dataset, sc, featureCreator );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'sound_databases/generalSoundsNI/all.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

md{2} = saveModelData( dataset, sc, featureCreator );

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/all.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

md{3} = saveModelData( dataset, sc, featureCreator );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'sound_databases/generalSoundsNI/all.flist';

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

md{4} = saveModelData( dataset, sc, featureCreator );

for ii = 1 : 4
    disp( md{ii} );
end
