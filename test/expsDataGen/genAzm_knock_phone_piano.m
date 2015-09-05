function genAzm_knock_phone_piano()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/knock.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/phone.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/piano.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'sound_databases/generalSoundsNI/knock.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/phone.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/piano.flist';

genAzms( featureCreator, dataset );


end

