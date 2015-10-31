function trainSVM_gos( classname )
    
classes = {'alarm','baby','femaleSpeech','fire'};
cc = 1 : numel( classes );
cc(~strcmp(classname,classes)) = [];

addpath( '../..' );
startIdentificationTraining();

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

if exist( ['glmnet_gos_' classname '.mat'], 'file' )
    gmat = load( ['glmnet_gos_' classname '.mat'] );
    modelpathes = gmat.modelpathes;
else
    return;
end
if exist( ['glmnet_gos_' classname '_svm.mat'], 'file' )
    gmatt = load( ['glmnet_gos_' classname '_svm.mat'] );
    modelpathes_svm = gmatt.modelpathes_svm;
end

for fc = 1 : numel( featureCreators )
for ssi = 1 : size( snrIdxs, 2 )
for aai = 1 : size( azmIdxs, 2 )
for ll = 1 : numel( lambdas )
aa = azmIdxs(1,aai);
aatest = azmIdxs(2,aai);
ss = snrIdxs(1,ssi);
sstest = snrIdxs(2,ssi);
    
if aai > 3, continue; end; % uncomment to do cross-tests
if ssi > 4, continue; end; % uncomment to do cross-tests

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
if exist( 'modelpathes_svm','var' )  &&  ...
        size(modelpathes_svm,1) >= ss  &&  size(modelpathes_svm,2) >= ll  &&  ...
        size(modelpathes_svm,3) >= fc  &&  size(modelpathes_svm,4) >= aa  &&  ...
        size(modelpathes_svm,5) >= aatest  && size(modelpathes_svm,6) >= sstest  ...
        &&  ~isempty( modelpathes_svm{ss,ll,fc,aa,aatest,sstest} )
    continue;
end
    
m = load( [modelpathes{ii,cc,fc,aa} filesep classname '.model.mat'] );
fmask = zeros( size( m.featureCreator.description ) );
switch lambdas{ll}
    case '0'
        fmask(1:end) = 1;
    case 'b'
        fmask(m.model.getBestLambdaCVresults()) = 1;
    case 'hws'
        fmask(m.model.getHighestLambdaWithinStdCVresults()) = 1;
end

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{1}) ) );
sc.addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',azimuths{aatest}{2}), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', snrs{sstest} ));
pipe.setSceneConfig( sc ); 

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = modelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'hpsEpsilons', [0.1], ... % define hps set (not a range)
    'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-7 -1], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
    'hpsMaxDataSize', 5000, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 0, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 7, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4 );           % number of hps cv folds of training set
modelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [setsBasePath 'NIGENS_75pTrain_TrainSet_' num2str(ii) '.flist'];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
pipe.setupData();

pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes_svm{ss,ll,fc,aa,aatest,sstest} = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpathes_svm{ss,ll,fc,aa,aatest,sstest} filesep classname '.model.mat'] );

test_performances{ss,ll,fc,aa,aatest,sstest} = [testmodel.testPerfresults.performance];

save( ['glmnet_gos_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_svm', 'test_performances' );

end
end
end
end

