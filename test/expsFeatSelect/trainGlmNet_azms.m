function trainGlmNet_azms()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};

if exist( 'glmnet_azms.mat', 'file' )
    gmat = load( 'glmnet_azms.mat' );
    modelpathes = gmat.modelpathes;
end

for ii = 1 : 4
for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
for aa = 1 : numel( azimuths )

if exist( 'modelpathes','var' )  &&  ...
   size(modelpathes,1) >= ii  &&  size(modelpathes,2) >= cc  &&  ...
   size(modelpathes,3) >= fc  &&  size(modelpathes,4) >= aa  ...
   &&  ~isempty( modelpathes{ii,cc,fc,aa} )
continue;
end
    
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',...
                                      sceneConfig.ValGen('manual',azimuths{aa})) );

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 7, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [setsBasePath 'NIGENS_75pTrain_TrainSet_' num2str(ii) '.flist'];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
pipe.setupData();

pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes{ii,cc,fc,aa} = pipe.pipeline.run( {classes{cc}}, 0 );

save( 'glmnet_azms.mat', 'classes', 'featureCreators', 'azimuths', 'modelpathes' );

end
end
end
end

