function update_trainSVM_gos()

addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
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


for ssi = 1 : size( snrIdxs, 2 )
for aai = 1 : size( azmIdxs, 2 )
for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes_svm;
clear test_performances;
if exist( ['glmnet_gos_' classname '_svm.mat'], 'file' )
    load( ['glmnet_gos_' classname '_svm.mat'] );
else continue;
end
clear altmat;
if exist( ['glmnet_gos_' classname '_svm1.mat'], 'file' )
    altmat = load( ['glmnet_gos_' classname '_svm1.mat'] );
end
for fc = 1 : numel( featureCreators )
for ll = 1 : numel( lambdas )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
ss = snrIdxs(1,ssi);
sstest = snrIdxs(2,ssi);
    
if aai > 3  &&  fc > 2, continue; end; % uncomment to do cross-tests
if ssi > 4  &&  fc > 2, continue; end; % uncomment to do cross-tests
if aai > 3  &&  ll ~= 2, continue; end; % uncomment to do cross-tests
if ssi > 4  &&  ll ~= 2, continue; end; % uncomment to do cross-tests
if ssi > 4 && (ss == 2  ||  sstest == 2), continue; end;

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
    elseif exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_svm' )  &&  ...
            size(altmat.modelpathes_svm,1) >= ss  &&  size(altmat.modelpathes_svm,2) >= ll  &&  ...
            size(altmat.modelpathes_svm,3) >= fc  &&  size(altmat.modelpathes_svm,4) >= aa  ...
            &&  ~isempty( [altmat.modelpathes_svm{ss,ll,fc,aa,:,:}] )
        % or in altmat.modelpathes_svm{ss,ll,fc,aa,:,:}
        mptmp = squeeze( altmat.modelpathes_svm(ss,ll,fc,aa,:,:) );
        mptmp = mptmp(~cellfun(@isempty,mptmp));
        modelpathes_svm{ss,ll,fc,aa,aatest,sstest} = mptmp{1};
        if isfield( altmat, 'test_performances' )  &&  ...
                size(altmat.test_performances,1) >= ss  &&  size(altmat.test_performances,2) >= ll  &&  ...
                size(altmat.test_performances,3) >= fc  &&  size(altmat.test_performances,4) >= aa  &&  ...
                size(altmat.test_performances,5) >= aatest  && size(altmat.test_performances,6) >= sstest  ...
                &&  ~isempty( altmat.test_performances{ss,ll,fc,aa,aatest,sstest} )
            test_performances{ss,ll,fc,aa,aatest,sstest} = altmat.test_performances{ss,ll,fc,aa,aatest,sstest};
        end
    else
        continue; % we cannot test
    end    
end

if exist( 'test_performances','var' )  &&  ...
        size(test_performances,1) >= ss  &&  size(test_performances,2) >= ll  &&  ...
        size(test_performances,3) >= fc  &&  size(test_performances,4) >= aa  &&  ...
        size(test_performances,5) >= aatest  && size(test_performances,6) >= sstest  ...
        &&  ~isempty( test_performances{ss,ll,fc,aa,aatest,sstest} )
    continue; % we don't need to test
end
    
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
%pipe.trainset = [setsBasePath 'NIGENS_75pTrain_TrainSet_1.flist'];
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

testmodel = load( [modelpath_test filesep classname '.model.mat'] );

test_performances{ss,ll,fc,aa,aatest,sstest} = [testmodel.testPerfresults.performance];

save( ['glmnet_gos_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );

end
save( ['glmnet_gos_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );
end
end
end
save( ['glmnet_gos_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );
end

