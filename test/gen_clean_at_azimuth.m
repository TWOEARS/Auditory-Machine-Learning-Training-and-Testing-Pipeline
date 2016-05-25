function [trainPath, testPath] = gen_clean_at_azimuth(azimuth_target, featCreator)
% generates features at with specific target angle, for simultaneous
% classification and localization

addpath( '..' );
startIdentificationTraining();

azimuths = {{azimuth_target, 0}}; % {{target_loc, distractor_loc}}
aa = 1;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featCreator;

%Generate Training Data
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );
%pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist';
pipe.trainset = 'learned_models/IdentityKS/trainTestSets/trainSet_miniMini2.flist';
pipe.setupData();

sc=sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( ...
    'azimuth', sceneConfig.ValGen('manual', azimuths{aa}{1})));
pipe.init([sc]);
modelPath = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

%Generate Test Data
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2,...
        'maxDataSize', inf ...
        );
pipe.trainset = [];
pipe.testset =  'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist';
pipe.setupData();

sc=sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( ...
    'azimuth', sceneConfig.ValGen('manual', azimuths{aa}{1})));
pipe.init([sc]);
modelPath1 = pipe.pipeline.run( {'dataStoreUni'}, 0 ); % universal format (x,y)

fprintf( ' -- Training: Saved at %s -- \n\n', modelPath );
fprintf( ' -- Testing: Saved at %s -- \n\n', modelPath1 );
trainPath = modelPath;
testPath = modelPath1;

