function testSvm_mc1_sc()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};
lambdas = {'0','b','hws'};

if exist( 'glmnet_svm_mc1_test_sc.mat', 'file' )
    load( 'glmnet_svm_mc1_test_sc.mat' );
end

for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
for ll = 2 %1 : numel( lambdas )
    
fprintf( '.\n' );

clear modelpathes_svm;

if exist( ['glmnet_mc1_' classes{cc} '_svm.mat'], 'file' )
    load( ['glmnet_mc1_' classes{cc} '_svm.mat'] );
else
    continue;
end

if exist( 'modelpathes_svm','var' )  &&  ...
        (size(modelpathes_svm,1) < fc  ||  size(modelpathes_svm,2) < ll ...
        ||  isempty( modelpathes_svm{fc,ll} ) )
    continue;
end

for scii = 1 : 18
    
if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= fc  &&  size(modelpathes_test,2) >= cc ...
        &&  size(modelpathes_test,3) >= scii  &&  size(modelpathes_test,4) >= ll ...
        &&  ~isempty( modelpathes_test{fc,cc,scii,ll} )
    continue;
end
    
m = load( [modelpathes_svm{fc,ll} filesep classes{cc} '.model.mat'] );
fmask = m.model.featureMask;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes_svm{fc,ll}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2 );
modelTrainers.Base.featureMask( true, fmask );
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
modelpathes_test{fc,cc,scii,ll} = pipe.pipeline.run( classes(cc), 0 );

testmodel = load( [modelpathes_test{fc,cc,scii,ll} filesep classes{cc} '.model.mat'] );

test_performances{fc,cc,scii,ll} = [testmodel.testPerfresults.performance];

save( 'glmnet_svm_mc1_test_sc.mat', 'classes', 'featureCreators', 'sc', ...
    'modelpathes_test', 'test_performances' );

end
end
end
end

