function genAzm_dog_engine_female()

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

featureCreator = featureCreators.FeatureSet1VarBlocks();
dataset = 'sound_databases/generalSoundsNI/dog.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/engine.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/female.flist';

genAzms( featureCreator, dataset );

featureCreator = featureCreators.FeatureSet1Blockmean2Ch();
dataset = 'sound_databases/generalSoundsNI/dog.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/engine.flist';

genAzms( featureCreator, dataset );

dataset = 'sound_databases/generalSoundsNI/female.flist';

genAzms( featureCreator, dataset );


end

