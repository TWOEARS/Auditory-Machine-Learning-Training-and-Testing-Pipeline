function genDWN_alarm_baby_crash()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/alarm.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/baby.flist';

genDiffWhtNoise( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/crash.flist';

genDiffWhtNoise( featureCreator, dataset );

end

