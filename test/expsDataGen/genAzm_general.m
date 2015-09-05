function genAzm_general()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/general.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();

genAzms( featureCreator, dataset );

end

