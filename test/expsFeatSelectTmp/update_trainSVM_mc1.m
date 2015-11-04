function update_trainSVM_mc1()

addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};
lambdas = {'0','b','hws'};


for cc = 1 : numel( classes )
classname = classes{cc};
clear modelpathes_svm;
clear test_performances;
if exist( ['glmnet_mc1_' classname '_svm.mat'], 'file' )
    load( ['glmnet_mc1_' classname '_svm.mat'] );
else continue;
end
if exist( ['glmnet_mc1_' classname '_svm1.mat'], 'file' )
    altmat = load( ['glmnet_mc1_' classname '_svm1.mat'] );
end
for fc = 1 : numel( featureCreators )
for ll = 1 : numel( lambdas )
    
fprintf( '.\n' );

if exist( 'modelpathes_svm','var' )  &&  ...
        size(modelpathes_svm,1) >= fc  &&  size(modelpathes_svm,2) >= ll  ...
        &&  isempty( modelpathes_svm{fc,ll} )
    if exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_svm' )  &&  ...
            size(altmat.modelpathes_svm,1) >= fc  &&  size(altmat.modelpathes_svm,2) >= ll  ...
            &&  ~isempty( altmat.modelpathes_svm{fc,ll} )
        modelpathes_svm{fc,ll} = altmat.modelpathes_svm{fc,ll};
        if isfield( altmat, 'test_performances' )  &&  ...
                size(altmat.test_performances,1) >= fc  &&  size(altmat.test_performances,2) >= ll  ...
                &&  ~isempty( altmat.test_performances{fc,ll} )
            test_performances{fc,ll} = altmat.test_performances{fc,ll};
        end
    else
        continue;
    end
end
if exist( 'modelpathes_svm','var' )  &&  ...
        (size(modelpathes_svm,1) < fc  ||  size(modelpathes_svm,2) < ll)
    if exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_svm' )  &&  ...
            size(altmat.modelpathes_svm,1) >= fc  &&  size(altmat.modelpathes_svm,2) >= ll  ...
            &&  ~isempty( altmat.modelpathes_svm{fc,ll} )
        modelpathes_svm{fc,ll} = altmat.modelpathes_svm{fc,ll};
        if isfield( altmat, 'test_performances' )  &&  ...
                size(altmat.test_performances,1) >= fc  &&  size(altmat.test_performances,2) >= ll  ...
                &&  ~isempty( altmat.test_performances{fc,ll} )
            test_performances{fc,ll} = altmat.test_performances{fc,ll};
        end
    else
        continue;
    end
end
if exist( 'test_performances','var' )  &&  ...
        size(test_performances,1) >= fc  &&  size(test_performances,2) >= ll  ...
        &&  ~isempty( test_performances{fc,ll} )
    continue;
end
    
m = load( [modelpathes_svm{fc,ll} filesep classname '.model.mat'] );
fmask = m.model.featureMask;

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes_svm{fc,ll}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2,...
        'maxDataSize', (36000*3)/(fc+1) );
modelTrainers.Base.featureMask( true, fmask );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
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
pipe.pipeline.gatherFeaturesProc.setConfDataUseRatio( 0.5, classname );
modelpath_test = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpath_test filesep classname '.model.mat'] );

test_performances{fc,ll} = [testmodel.testPerfresults.performance];

save( ['glmnet_mc1_' classname '_svm.mat'], 'lambdas', 'featureCreators', ...
    'modelpathes_svm', 'test_performances' );

end
end
save( ['glmnet_mc1_' classname '_svm.mat'], 'lambdas', 'featureCreators', ...
    'modelpathes_svm', 'test_performances' );
end

