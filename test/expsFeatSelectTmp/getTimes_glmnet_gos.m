function getTimes_glmnet_gos
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};
azimuths = {{0,0},{-45,45},{-90,90}};
snrs = {20,10,0,-10};
azmIdxs = [reshape(repmat(1:numel(azimuths),numel(azimuths),1),1,[]);repmat(1:numel(azimuths),1,numel(azimuths))];
azmIdxs = [azmIdxs(:,azmIdxs(1,:) == azmIdxs(2,:)),azmIdxs(:,azmIdxs(1,:) ~= azmIdxs(2,:))];
snrIdxs = [reshape(repmat(1:numel(snrs),numel(snrs),1),1,[]);repmat(1:numel(snrs),1,numel(snrs))];
snrIdxs = [snrIdxs(:,snrIdxs(1,:) == snrIdxs(2,:)),snrIdxs(:,snrIdxs(1,:) ~= snrIdxs(2,:))];

for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes;

if exist( ['glmnet_gos_' classname '.mat'], 'file' )
    load( ['glmnet_gos_' classname '.mat'] );
else
    continue;
end

for fc = 1 : 2 % numel( featureCreators )
for ssi = 1 : 4 % size( snrIdxs, 2 )
for aai = 1 : 3 % size( azmIdxs, 2 )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
ss = snrIdxs(1,ssi);
sstest = snrIdxs(2,ssi);
    
fprintf( '.\n' );

if exist( 'modelpathes','var' )  &&  ...
        size(modelpathes,1) >= ss  &&  size(modelpathes,2) >= fc  &&  ...
        size(modelpathes,3) >= aa  ...
        &&  isempty( modelpathes{ss,fc,aa} )
    continue;
end
if exist( 'modelpathes','var' )  &&  (...
        size(modelpathes,1) < ss  ||  size(modelpathes,2) < fc  ||  ...
        size(modelpathes,3) < aa )
    continue;
end
    
testmodel = load( [modelpathes{ss,fc,aa} filesep classname '.model.mat'] );
trainTime{cc,fc,ss,aa} = testmodel.trainTime;

if aai > 2, continue; end
if ssi < 2 || ssi > 3, continue; end

[~,~,~,fs1lambda] = testmodel.model.getBestLambdaCVresults();
[~,~,~,fs3lambda] = testmodel.model.getHighestLambdaWithinStdCVresults();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{ss,fc,aa}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', fs1lambda) );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_1.flist'];
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{1}) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{2}), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', snrs{sstest} ));
pipe.setSceneConfig( sc ); 

pipe.init();
modelpath_test = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpath_test filesep classes{cc} '.model.mat'] );
testTime{1,cc,fc,ss,aa} = testmodel.testTime;

rmdir( modelpath_test, 's' );

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{ss,fc,aa}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', fs3lambda) );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_1.flist'];
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{1}) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{2}), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', snrs{sstest} ));
pipe.setSceneConfig( sc ); 

pipe.init();
modelpath_test = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpath_test filesep classes{cc} '.model.mat'] );
testTime{2,cc,fc,ss,aa} = testmodel.testTime;

rmdir( modelpath_test, 's' );

end
save( ['glmnet_gos_times.mat'], 'classes', 'featureCreators', 'azimuths', 'snrs', ...
                                'trainTime', 'testTime'  );
end
end
end

