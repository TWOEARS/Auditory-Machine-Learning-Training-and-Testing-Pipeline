function update_trainSVM_azms()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};
lambdas = {'0','b','hws'};
azmIdxs = [reshape(repmat(1:numel(azimuths),numel(azimuths),1),1,[]);repmat(1:numel(azimuths),1,numel(azimuths))];
azmIdxs = [azmIdxs(:,azmIdxs(1,:) == azmIdxs(2,:)),azmIdxs(:,azmIdxs(1,:) ~= azmIdxs(2,:))];


for ii = 1 : 4
for aai = 1 : size( azmIdxs, 2 )

for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes_svm;
clear test_performances;
if exist( ['glmnet_azms_' classname '_svm.mat'], 'file' )
    load( ['glmnet_azms_' classname '_svm.mat'] );
else
    continue;
end
clear altmat;
if exist( ['glmnet_azms_' classname '_svm1.mat'], 'file' )
    altmat = load( ['glmnet_azms_' classname '_svm1.mat'] );
end

for fc = 1 : numel( featureCreators )
for ll = 1 : numel( lambdas )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
    
if aai > 4  &&  ll ~= 2, continue; end; 

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
    elseif exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_svm' )  &&  ...
            size(altmat.modelpathes_svm,1) >= ii  &&  size(altmat.modelpathes_svm,2) >= ll  &&  ...
            size(altmat.modelpathes_svm,3) >= fc  &&  size(altmat.modelpathes_svm,4) >= aa  ...
            &&  ~isempty( [altmat.modelpathes_svm{ii,ll,fc,aa,:}] )
        % or in altmat.modelpathes_svm{ii,ll,fc,aa,:}
        mptmp = squeeze( altmat.modelpathes_svm(ii,ll,fc,aa,:) );
        mptmp = mptmp(~cellfun(@isempty,mptmp));
        modelpathes_svm{ii,ll,fc,aa,aatest} = mptmp{1};
        if isfield( altmat, 'test_performances' )  &&  ...
                size(altmat.test_performances,1) >= ii  &&  size(altmat.test_performances,2) >= ll  &&  ...
                size(altmat.test_performances,3) >= fc  &&  size(altmat.test_performances,4) >= aa  &&  ...
                size(altmat.test_performances,5) >= aatest  ...
                &&  ~isempty( altmat.test_performances{ii,ll,fc,aa,aatest} )
            test_performances{ii,ll,fc,aa,aatest} = altmat.test_performances{ii,ll,fc,aa,aatest};
        end
    else
        continue; % we cannot test
    end    
end

if exist( 'test_performances','var' )  &&  ...
        size(test_performances,1) >= ii  &&  size(test_performances,2) >= ll  &&  ...
        size(test_performances,3) >= fc  &&  size(test_performances,4) >= aa  &&  ...
        size(test_performances,5) >= aatest  ...
        &&  ~isempty( test_performances{ii,ll,fc,aa,aatest} )
    continue; % we don't need to test
end


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
pipe.pipeline.gatherFeaturesProc.setConfDataUseRatio( 0.5, classname );
modelpath_test = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpath_test filesep classname '.model.mat'] );

test_performances{ii,ll,fc,aa,aatest} = [testmodel.testPerfresults.performance];

save( ['glmnet_azms_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );
end
save( ['glmnet_azms_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );
end
end
end
save( ['glmnet_azms_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );
end
