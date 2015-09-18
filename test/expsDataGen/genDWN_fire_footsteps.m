function genDWN_fire_footsteps()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/fire.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/footsteps.flist';

genDiffWhtNoise( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'sound_databases/generalSoundsNI/fire.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/footsteps.flist';

genDiffWhtNoise( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes();
dataset = 'sound_databases/generalSoundsNI/fire.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/footsteps.flist';

genDiffWhtNoise( featureCreator, dataset );

end

