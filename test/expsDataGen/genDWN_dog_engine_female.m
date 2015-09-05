function genDWN_dog_engine_female()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/dog.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/engine.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/female.flist';

genDiffWhtNoise( featureCreator, dataset );

end

