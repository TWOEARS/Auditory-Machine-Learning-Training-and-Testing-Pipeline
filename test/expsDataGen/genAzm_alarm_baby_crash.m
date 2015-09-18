function genAzm_alarm_baby_crash()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/alarm.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/baby.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/crash.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'sound_databases/generalSoundsNI/alarm.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/baby.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/crash.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean();
dataset = 'sound_databases/generalSoundsNI/alarm.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/baby.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/crash.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes();
dataset = 'sound_databases/generalSoundsNI/alarm.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/baby.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/crash.flist';

genAzms( featureCreator, dataset );


end

