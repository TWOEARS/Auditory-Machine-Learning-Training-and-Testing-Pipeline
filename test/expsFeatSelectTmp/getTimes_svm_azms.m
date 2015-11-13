function getTimes_svm_azms()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};
lambdas = {'0','b','hws'};
azmIdxs = [reshape(repmat(1:numel(azimuths),numel(azimuths),1),1,[]);repmat(1:numel(azimuths),1,numel(azimuths))];
azmIdxs = [azmIdxs(:,azmIdxs(1,:) == azmIdxs(2,:)),azmIdxs(:,azmIdxs(1,:) ~= azmIdxs(2,:))];


for ii = 1 : 2
for aai = 1 : 4

for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes_svm;
if exist( ['glmnet_azms_' classname '_svm.mat'], 'file' )
    load( ['glmnet_azms_' classname '_svm.mat'] );
else
    continue;
end

for fc = 1 : numel( featureCreators )
for ll = 1 : numel( lambdas )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
    
fprintf( '.\n' );

if exist( 'modelpathes_svm','var' )  &&  ...
       (size(modelpathes_svm,1) < ii  ||  size(modelpathes_svm,2) < ll  ||  ...
        size(modelpathes_svm,3) < fc  ||  size(modelpathes_svm,4) < aa  ||  ...
        size(modelpathes_svm,5) < aatest  ...
        ||  isempty( modelpathes_svm{ii,ll,fc,aa,aatest} ))
    % no value in modelpathes_svm{ii,ll,fc,aa,aatest} yet
    if size(modelpathes_svm,1) >= ii  &&  size(modelpathes_svm,2) >= ll  &&  ...
            size(modelpathes_svm,3) >= fc  &&  size(modelpathes_svm,4) >= aa  &&  ...
            ~isempty( [modelpathes_svm{ii,ll,fc,aa,:}] )
        % but there is a value in modelpathes_svm{ii,ll,fc,aa,:}
        mptmp = squeeze( modelpathes_svm(ii,ll,fc,aa,:) );
        mptmp = mptmp(~cellfun(@isempty,mptmp));
        modelpathes_svm{ii,ll,fc,aa,aatest} = mptmp{1};
    else
        continue; % we cannot test
    end    
end

testmodel = load( [modelpathes_svm{ii,ll,fc,aa,aatest} filesep classname '.model.mat'] );
trainTime{ii,cc,ll,fc,aa} = testmodel.trainTime;

if ii > 1, continue; end

m = load( [modelpathes_svm{ii,ll,fc,aa,aatest} filesep classname '.model.mat'] );
fmask = m.model.featureMask;

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',...
                                      sceneConfig.ValGen('manual',azimuths{aatest})) );

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes_svm{ii,ll,fc,aa,aatest}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2 );
modelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
pipe.setupData();

pipe.setSceneConfig( sc ); 

pipe.init();
modelpath_test = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpath_test filesep classname '.model.mat'] );
testTime{ii,cc,ll,fc,aa} = testmodel.testTime;

rmdir( modelpath_test, 's' );

save( ['svm_azms_times.mat'], 'classes', 'lambdas', 'featureCreators', 'azimuths', ...
                              'trainTime', 'testTime' );
end
end
save( ['svm_azms_times.mat'], 'classes', 'lambdas', 'featureCreators', 'azimuths', ...
                              'trainTime', 'testTime' );
end
end
end
