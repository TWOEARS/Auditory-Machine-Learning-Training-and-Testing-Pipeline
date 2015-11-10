function testGlmNet_mc1_sc()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};

if exist( 'glmnet_mc1_test_sc.mat', 'file' )
    load( 'glmnet_mc1_test_sc.mat' );
end

for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
    
fprintf( '.\n' );

clear modelpathes;

if exist( ['glmnet_mc1_' classes{cc} '.mat'], 'file' )
    load( ['glmnet_mc1_' classes{cc} '.mat'] );
else
    continue;
end

if exist( 'modelpathes','var' )  &&  ...
        size(modelpathes,2) >= fc  &&  isempty( modelpathes{fc} )
    continue;
end
if exist( 'modelpathes','var' )  &&  size(modelpathes,2) < fc
    continue;
end

for scii = 1 : 18
    
if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= fc  &&  size(modelpathes_test,2) >= cc ...
        &&  size(modelpathes_test,3) >= scii ...
        &&  ~isempty( modelpathes_test{fc,cc,scii} )
    continue;
end
    
pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{fc}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', []) );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_1.flist'];
pipe.setupData();

sc(1) = sceneConfig.SceneConfiguration();
sc(1).addSource( sceneConfig.PointSource() );
sc(1).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(2) = sceneConfig.SceneConfiguration();
sc(2).addSource( sceneConfig.PointSource() );
sc(2).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(3) = sceneConfig.SceneConfiguration();
sc(3).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-45) ) );
sc(3).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',45), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(4) = sceneConfig.SceneConfiguration();
sc(4).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-90) ) );
sc(4).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(5) = sceneConfig.SceneConfiguration();
sc(5).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',0)) );

sc(6) = sceneConfig.SceneConfiguration();
sc(6).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',135)) );

sc(7) = sceneConfig.SceneConfiguration();
sc(7).addSource( sceneConfig.PointSource() );
sc(7).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -10 ));

sc(8) = sceneConfig.SceneConfiguration();
sc(8).addSource( sceneConfig.PointSource() );
sc(8).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 0 ));

sc(9) = sceneConfig.SceneConfiguration();
sc(9).addSource( sceneConfig.PointSource() );
sc(9).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 10 ));

sc(10) = sceneConfig.SceneConfiguration();
sc(10).addSource( sceneConfig.PointSource() );
sc(10).addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', -10 ));

sc(11) = sceneConfig.SceneConfiguration();
sc(11).addSource( sceneConfig.PointSource() );
sc(11).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 10 ));

sc(12) = sceneConfig.SceneConfiguration();
sc(12).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-45) ) );
sc(12).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',45), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 20 ));

sc(13) = sceneConfig.SceneConfiguration();
sc(13).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',-90) ) );
sc(13).addSource( sceneConfig.PointSource( 'azimuth',sceneConfig.ValGen('manual',90), ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', -10 ));

sc(14) = sceneConfig.SceneConfiguration();
sc(14).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',90)) );

sc(15) = sceneConfig.SceneConfiguration();
sc(15).addSource( sceneConfig.PointSource('azimuth',sceneConfig.ValGen('manual',180)) );

sc(16) = sceneConfig.SceneConfiguration();
sc(16).addSource( sceneConfig.PointSource() );
sc(16).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 20 ));

sc(17) = sceneConfig.SceneConfiguration();
sc(17).addSource( sceneConfig.PointSource() );
sc(17).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', -20 ));

sc(18) = sceneConfig.SceneConfiguration();
sc(18).addSource( sceneConfig.PointSource() );
sc(18).addSource( sceneConfig.DiffuseSource( ...
    'data',sceneConfig.NoiseValGen(struct( 'len', sceneConfig.ValGen('manual',4410000) )) ),...
    sceneConfig.ValGen( 'manual', 5 ));

pipe.setSceneConfig( sc(scii) ); 

pipe.init();
pipe.pipeline.gatherFeaturesProc.setConfDataUseRatio( 0.4, classes{cc} );
modelpathes_test{fc,cc,scii} = pipe.pipeline.run( classes(cc), 0 );

testmodel = load( [modelpathes_test{fc,cc,scii} filesep classes{cc} '.model.mat'] );

test_performances{fc,cc,scii} = [testmodel.testPerfresults.performance];
cv_performances{fc,cc,scii} = testmodel.model.lPerfsMean;
cv_std{fc,cc,scii} = testmodel.model.lPerfsStd;
[coefIdxs_b{fc,cc,scii},...
 impacts_b{fc,cc,scii},...
 perf_b{fc,cc,scii},...
 lambda_b{fc,cc,scii},...
 nCoefs_b{fc,cc,scii}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{fc,cc,scii},...
 impacts_bms{fc,cc,scii},...
 perf_bms{fc,cc,scii},...
 lambda_bms{fc,cc,scii},...
 nCoefs_bms{fc,cc,scii}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{fc,cc,scii},...
 impacts_hws{fc,cc,scii},...
 perf_hws{fc,cc,scii},...
 lambda_hws{fc,cc,scii},...
 nCoefs_hws{fc,cc,scii}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.model.lambda == lambda_b{fc,cc,scii} );
lhwsIdx = find( testmodel.model.model.lambda == lambda_hws{fc,cc,scii} );
test_performances_b{fc,cc,scii} = test_performances{fc,cc,scii}(lbIdx);
test_performances_hws{fc,cc,scii} = test_performances{fc,cc,scii}(lhwsIdx);
[lambdas{fc,cc,scii},...
 nCoefs{fc,cc,scii}] = testmodel.model.getLambdasAndNCoefs();
trainTime{fc,cc,scii} = testmodel.trainTime;

save( 'glmnet_mc1_test_sc.mat', 'classes', 'featureCreators', 'sc', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws', 'lambdas', 'nCoefs', 'trainTime'  );

end
end
end

