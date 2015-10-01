function genGO2_set1()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

genGenOvrl2( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

genGenOvrl2( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

genGenOvrl2( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

genGenOvrl2( featureCreator, dataset );

end

