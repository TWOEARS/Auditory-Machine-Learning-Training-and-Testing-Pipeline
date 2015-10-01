function genGO2_set2()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist';

genGenOvrl2( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist';

genGenOvrl2( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist';

genGenOvrl2( featureCreator, dataset );

end

