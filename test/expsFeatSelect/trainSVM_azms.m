function trainSVM_azms( classname )
    
classes = {'alarm','baby','femaleSpeech','fire'};
cc = 1 : numel( classes );
cc(~strcmp(classname,classes)) = [];

addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};
lambdas = {'0','b','hws'};

if exist( 'glmnet_azms.mat', 'file' )
    gmat = load( 'glmnet_azms.mat' );
    modelpathes = gmat.modelpathes;
else
    return;
end
if exist( ['glmnet_azms_' classname '_svm.mat'], 'file' )
    gmatt = load( ['glmnet_azms_' classname '_svm.mat'] );
    modelpathes_svm = gmatt.modelpathes_test;
end

for ii = 1 : 4
for aa = 1 : numel( azimuths )
for ll = 1 : numel( lambdas )
for fc = 1 : numel( featureCreators )
for aatest = 1 : numel( azimuths )
    
fprintf( '.\n' );

if exist( 'modelpathes','var' )  &&  ...
        size(modelpathes,1) >= ii  &&  size(modelpathes,2) >= cc  &&  ...
        size(modelpathes,3) >= fc  &&  size(modelpathes,4) >= aa  ...
        &&  isempty( modelpathes{ii,cc,fc,aa} )
    continue;
end
if exist( 'modelpathes','var' )  &&  (...
        size(modelpathes,1) < ii  ||  size(modelpathes,2) < cc  ||  ...
        size(modelpathes,3) < fc  ||  size(modelpathes,4) < aa )
    continue;
end
if exist( 'modelpathes_svm','var' )  &&  ...
        size(modelpathes_svm,1) >= ii  &&  size(modelpathes_svm,2) >= ll  &&  ...
        size(modelpathes_svm,3) >= fc  &&  size(modelpathes_svm,4) >= aa  &&  ...
        size(modelpathes_svm,5) >= aatest  ...
        &&  ~isempty( modelpathes_svm{ii,ll,fc,aa,aatest} )
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
sc.addSource( sceneConfig.PointSource('azimuth',...
                                      sceneConfig.ValGen('manual',azimuths{aatest})) );

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = modelTrainers.SVMmodelSelectTrainer( ...
    'performanceMeasure', @performanceMeasures.BAC2, ...
    'hpsEpsilons', [0.1], ... % define hps set (not a range)
    'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
    'hpsCrange', [-7 0], ...    % define hps C range -- logspaced between 10^a and 10^b
    'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
                              ... % 10^b. Ignored for kernel other than rbf
    'hpsMaxDataSize', 6000, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 0, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', 8, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 4 )           % number of hps cv folds of training set
modelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [setsBasePath 'NIGENS_75pTrain_TrainSet_' num2str(ii) '.flist'];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
pipe.setupData();

pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes_svm{ii,ll,fc,aa,aatest} = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpathes_svm{ii,ll,fc,aa,aatest} filesep classname '.model.mat'] );

test_performances{ii,ll,fc,aa,aatest} = [testmodel.testPerfresults.performance];

save( ['glmnet_azms_' classname '_svm.mat'], 'lambdas', 'featureCreators', 'azimuths', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws' );

end
end
end
end
end

