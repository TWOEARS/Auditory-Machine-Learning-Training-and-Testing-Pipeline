function pths = saveAzms_set1()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

pths = {};

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );



dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );



featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );


dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',45)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

pths{end+1} = saveModelData( dataset, sc, featureCreator );


end

