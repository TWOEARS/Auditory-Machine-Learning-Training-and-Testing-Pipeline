function trainGlmNet_GOs( classname )
    
addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};
azimuths = {{0,0},{-45,45},{-90,90}};
snrs = {20,10,0,-10};

if exist( ['glmnet_gos_' classname '.mat'], 'file' )
    load( ['glmnet_gos_' classname '.mat'] );
end

for fc = 1 : numel( featureCreators )
for ss = 1 : numel( snrs )
for aa = 1 : numel( azimuths )
 
if exist( 'modelpathes','var' )  && ...
   size(modelpathes,1) >= ss  &&  size(modelpathes,2) >= fc  &&  ...
   size(modelpathes,3) >= aa ...
   &&  ~isempty( modelpathes{ss,fc,aa} )
continue;
end

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'cvFolds', 7, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [setsBasePath 'NIGENS_75pTrain_TrainSet_1.flist'];
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{1}) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{2}), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', snrs{ss} ));
pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes{ss,fc,aa} = pipe.pipeline.run( {classname}, 0 );

save( ['glmnet_gos_' classname '.mat'], 'snrs', 'featureCreators', 'azimuths', 'modelpathes' );

end
end
end

