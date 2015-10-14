function pths = saveGO_set1()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

pths = {};

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset );

dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';

pths{end+1} = saveGenOvrl( featureCreator, dataset );

% featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
% dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';
% 
% pths{end+1} = saveGenOvrl2( featureCreator, dataset );
% 
% dataset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';
% 
% pths{end+1} = saveGenOvrl2( featureCreator, dataset );


end

