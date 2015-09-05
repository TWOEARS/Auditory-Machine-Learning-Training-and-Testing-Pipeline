function genDWN_knock_phone_piano()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/knock.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/phone.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/piano.flist';

genDiffWhtNoise( featureCreator, dataset );

end

