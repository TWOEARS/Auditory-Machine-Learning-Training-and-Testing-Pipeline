function glmnet_PDs_mc( dd,ff )

if nargin < 2, ff = 1; end

addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1Blockmean2Ch};
azimuths = {{0,0},...
    {0,45},{45,0},{22.5,-22.5},{67.5,112.5},{-157.5,157.5},...
    {0,90},{22.5,112.5},{45,135},{90,180},{22.5,-67.5},{45,-45},{90,0},{-157.5,112.5},...
    {0,180},{22.5,-157.5},{45,-135},{67.5,-112.5},{90,-90}}; % 19 cfgs
snrs = {0,-10,10,-20};
datasets = {'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_3.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_3.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_4.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_4.flist'
            };
classes = {'alarm','baby','femaleSpeech','fire','crash','dog','engine','footsteps',...
           'knock','phone','piano'};

doneCfgs = {};
modelpathes = {};
if exist( ['pds_mc_' strrep(num2str([dd,ff]),' ','_') '_glmnet.mat'], 'file' )
    load( ['pds_mc_' strrep(num2str([dd,ff]),' ','_') '_glmnet'] );
else
    warning( 'mat file not found' );
    pause;
end

for cc = 1 : 11
    fprintf( '\n\n==============\nTraining; cc = %d, dd = %d, ff = %d, MC.==============\n\n', ...
        cc, dd, ff );
    if any( cellfun( @(x)(all(x==[cc dd ff])), doneCfgs ) )
        continue;
    end
    
    pipe = TwoEarsIdTrainPipe();
    pipe.featureCreator = feval( featureCreators{ff}.Name );
    pipe.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'cvFolds', 7, ...
        'alpha', 0.99, ...
        'maxDataSize', 100000 );
    modelTrainers.Base.balMaxData( true, true );
    pipe.modelCreator.verbose( 'on' );
    
    pipe.trainset = datasets{dd};
    pipe.setupData();
    
    clear mcsc;
    for aa = [1,4,12,19,14,6,7,9,10,13]
        for ss = 1:4
            sc = sceneConfig.SceneConfiguration();
            sc.addSource( sceneConfig.PointSource( ...
                'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{1}) ) );
            sc.addSource( sceneConfig.PointSource( ...
                'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{2}), ...
                'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')),...
                'offset', sceneConfig.ValGen('manual',0.0) ),...
                sceneConfig.ValGen( 'manual', snrs{ss} ),...
                true ); % loop
            mcsc(end+1) = sc;
        end
    end
    pipe.setSceneConfig( mcsc );
    
    pipe.init();
    pipe.pipeline.gatherFeaturesProc.setConfDataUseRatio( 0.1 );
    modelpathes{cc,dd,ff} = pipe.pipeline.run( classes(cc), 0 );
    doneCfgs{end+1} = [cc dd ff];
    
    save( ['pds_mc_' strrep(num2str([dd,ff]),' ','_') '_glmnet'], ...
        'doneCfgs', 'modelpathes' );
end


end
