function trainAndTest_BRIR( classname )

if nargin < 1, classname = 'baby'; end;

%startTwoEars( '../IdentificationTraining.xml' );
addpath( '..' );
startIdentificationTraining();

brirs = { ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
    };


pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreators.FeatureSet1Blockmean();
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/trainSet_miniMini1.flist';
pipe.testset = 'learned_models/IdentityKS/trainTestSets/testSet_miniMini1.flist';
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
pipe.setSceneConfig( [sc] ); 

pipe.init();
%modelPath = pipe.pipeline.run( {classname}, 0 );
modelPath = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

fprintf( ' -- Saved at %s -- \n\n', modelPath );
