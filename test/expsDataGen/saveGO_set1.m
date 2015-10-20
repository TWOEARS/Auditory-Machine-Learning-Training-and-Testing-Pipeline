function pths = saveGO_set1()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

pths = {};

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 20 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 20 );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 20 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 20 );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 20 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 20 );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 0 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, 0, 0, 20 );
pths{end+1} = saveGenOvrl( featureCreator, dataset, -45, 45, 20 );


end

