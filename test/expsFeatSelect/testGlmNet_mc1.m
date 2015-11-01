function testGlmNet_mc1()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};

if exist( 'glmnet_mc1_test.mat', 'file' )
    load( 'glmnet_mc1_test.mat' );
end

for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
    
fprintf( '.\n' );

if exist( ['glmnet_mc1_' classes{cc} '.mat'], 'file' )
    load( ['glmnet_mc1_' classes{cc} '.mat'] );
else
    continue;
end

if exist( 'modelpathes','var' )  &&  ...
        size(modelpathes,1) >= fc  &&  isempty( modelpathes{fc} )
    continue;
end
if exist( 'modelpathes','var' )  &&  size(modelpathes,1) < fc
    continue;
end
if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= fc  &&  size(modelpathes_test,2) >= cc ...
        &&  ~isempty( modelpathes_test{fc,cc} )
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

pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes_test{fc,cc} = pipe.pipeline.run( classes(cc), 0 );

testmodel = load( [modelpathes_test{fc,cc} filesep classes{cc} '.model.mat'] );

test_performances{fc,cc} = [testmodel.testPerfresults.performance];
cv_performances{fc,cc} = testmodel.model.lPerfsMean;
cv_std{fc,cc} = testmodel.model.lPerfsStd;
[coefIdxs_b{fc,cc},...
 impacts_b{fc,cc},...
 perf_b{fc,cc},...
 lambda_b{fc,cc},...
 nCoefs_b{fc,cc}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{fc,cc},...
 impacts_bms{fc,cc},...
 perf_bms{fc,cc},...
 lambda_bms{fc,cc},...
 nCoefs_bms{fc,cc}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{fc,cc},...
 impacts_hws{fc,cc},...
 perf_hws{fc,cc},...
 lambda_hws{fc,cc},...
 nCoefs_hws{fc,cc}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.lambda == lambda_b{fc,cc} );
lhwsIdx = find( testmodel.model.lambda == lambda_hws{fc,cc} );
test_performances_b{ii,cc,fc,aa,aatest} = test_performances{fc,cc}(lbIdx);
test_performances_hws{ii,cc,fc,aa,aatest} = test_performances{fc,cc}(lhwsIdx);

save( 'glmnet_mc1_test.mat', 'classes', 'featureCreators', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws'  );

end
end

