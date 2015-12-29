function gen_PDs( azmCfgIdxs )
    
addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1Blockmean2Ch};
azimuths = {{0,0},...
            {0,45},{45,0},{22.5,-22.5},{67.5,112.5},{-157.5,157.5},...
            {0,90},{22.5,112.5},{45,135},{90,180},{22.5,-67.5},{45,-45},{90,0},{-157.5,112.5},...
            {0,180},{22.5,-157.5},{45,-135},{67.5,-112.5},{90,-90}}; % 19 cfgs
snrs = {0,-10,10,-20};
datasets = {'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist'...
...%            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_3.flist',...
...%            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_3.flist',...
...%            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_4.flist',...
...%            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_4.flist'
            };

doneCfgs = {};
if exist( ['pdCfgsDone_' strrep(num2str(azmCfgIdxs),' ','_') '.mat'], 'file' )
    load( ['pdCfgsDone_' strrep(num2str(azmCfgIdxs),' ','_')], 'doneCfgs' );
end

for dd = 1 : numel( datasets )
for ss = 1 : numel( snrs )
for ff = 1 : numel( featureCreators )
for aa = azmCfgIdxs

fprintf( '\n\n==============\nStarting; dd = %d, ff = %d, ss = %d, aa = %d.==============\n\n', dd, ff, ss, aa );
if any( cellfun( @(x)(all(x==[dd ss ff aa])), doneCfgs ) )
    continue;
end

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{ff}.Name );
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = datasets{dd};
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( ...
        'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{1}) ) );
sc.addSource( sceneConfig.PointSource( ...
        'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{2}), ...
        'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')),...
        'offset', sceneConfig.ValGen('manual',0.0) ),...
    sceneConfig.ValGen( 'manual', snrs{ss} ),...
    true ); % loop
pipe.setSceneConfig( [sc] ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );

doneCfgs{end+1} = [dd ss ff aa];

save( ['pdCfgsDone_' strrep(num2str(azmCfgIdxs),' ','_')], 'doneCfgs' );

end
end
end
end
