function getTimes_svm_gos

classes = {'alarm','baby','femaleSpeech','fire'};

addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};
azimuths = {{0,0},{-45,45},{-90,90}};
lambdas = {'0','b','hws'};
snrs = {20,10,0,-10};
azmIdxs = [reshape(repmat(1:numel(azimuths),numel(azimuths),1),1,[]);repmat(1:numel(azimuths),1,numel(azimuths))];
azmIdxs = [azmIdxs(:,azmIdxs(1,:) == azmIdxs(2,:)),azmIdxs(:,azmIdxs(1,:) ~= azmIdxs(2,:))];
snrIdxs = [reshape(repmat(1:numel(snrs),numel(snrs),1),1,[]);repmat(1:numel(snrs),1,numel(snrs))];
snrIdxs = [snrIdxs(:,snrIdxs(1,:) == snrIdxs(2,:)),snrIdxs(:,snrIdxs(1,:) ~= snrIdxs(2,:))];

testTime = {};

for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes_svm;
if exist( ['glmnet_gos_' classname '_svm.mat'], 'file' )
    load( ['glmnet_gos_' classname '_svm.mat'] );
else continue;
end
for ssi = 1 : 4 % size( snrIdxs, 2 )
for aai = 1 : 3 % size( azmIdxs, 2 )
for fc = 1 : 2 % numel( featureCreators )
for ll = 1 : numel( lambdas )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
ss = snrIdxs(1,ssi);
sstest = snrIdxs(2,ssi);
    
fprintf( '.\n' );

if exist( 'modelpathes_svm','var' )  &&  ...
       (size(modelpathes_svm,1) < ss  ||  size(modelpathes_svm,2) < ll  ||  ...
        size(modelpathes_svm,3) < fc  ||  size(modelpathes_svm,4) < aa  ||  ...
        size(modelpathes_svm,5) < aatest  || size(modelpathes_svm,6) < sstest ...
        ||  isempty( modelpathes_svm{ss,ll,fc,aa,aatest,sstest} ))
    % no value in modelpathes_svm{ss,ll,fc,aa,aatest,sstest} yet
    if size(modelpathes_svm,1) >= ss  &&  size(modelpathes_svm,2) >= ll  &&  ...
            size(modelpathes_svm,3) >= fc  &&  size(modelpathes_svm,4) >= aa  &&  ...
            ~isempty( [modelpathes_svm{ss,ll,fc,aa,:,:}] )
        % but there is a value in modelpathes_svm{ss,ll,fc,aa,:,:}
        mptmp = squeeze( modelpathes_svm(ss,ll,fc,aa,:,:) );
        mptmp = mptmp(~cellfun(@isempty,mptmp));
        modelpathes_svm{ss,ll,fc,aa,aatest,sstest} = mptmp{1};
    else
        continue; % we cannot test
    end    
end

testmodel = load( [modelpathes_svm{ss,ll,fc,aa,aatest,sstest} filesep classname '.model.mat'] );
trainTime{cc,ll,fc,ss,aa} = testmodel.trainTime;

if aai > 2, continue; end
if ssi < 2 || ssi > 3, continue; end

m = load( [modelpathes_svm{ss,ll,fc,aa,aatest,sstest} filesep classname '.model.mat'] );
fmask = m.model.featureMask;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes_svm{ss,ll,fc,aa,aatest,sstest}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2 );
modelTrainers.Base.featureMask( true, fmask );
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
testTime{cc,ll,fc,ss,aa} = testmodel.testTime;

rmdir( modelpath_test, 's' );

save( ['svm_gos_times.mat'], 'classes','lambdas', 'featureCreators', 'azimuths', ...
                             'trainTime', 'testTime' );

end
end
save( ['svm_gos_times.mat'], 'classes','lambdas', 'featureCreators', 'azimuths', ...
                             'trainTime', 'testTime' );
end
end
end

