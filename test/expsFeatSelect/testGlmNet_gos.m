function testGlmNet_gos( classname )
    
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
    load( ['glmnet_gos_' classname '.mat'] );
else
    return;
end
if exist( ['glmnet_gos_' classname '_test.mat'], 'file' )
    load( ['glmnet_gos_' classname '_test.mat'] );
end

for fc = 1 : numel( featureCreators )
for ssi = 1 : size( snrIdxs, 2 )
for aai = 1 : size( azmIdxs, 2 )
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
if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= ss  &&  size(modelpathes_test,2) >= fc  &&  ...
        size(modelpathes_test,3) >= aa  &&  size(modelpathes_test,4) >= aatest  &&  ...
        size(modelpathes_test,5) >= sstest  ...
        &&  ~isempty( modelpathes_test{ss,fc,aa,aatest,sstest} )
    continue;
end
    
pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{ss,fc,aa}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', []) );
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
modelpathes_test{ss,fc,aa,aatest,sstest} = pipe.pipeline.run( {classname}, 0 );

testmodel = load( [modelpathes_test{ss,fc,aa,aatest,sstest} filesep classname '.model.mat'] );

test_performances{ss,fc,aa,aatest,sstest} = [testmodel.testPerfresults.performance];
cv_performances{ss,fc,aa,aatest,sstest} = testmodel.model.lPerfsMean;
cv_std{ss,fc,aa,aatest,sstest} = testmodel.model.lPerfsStd;
[coefIdxs_b{ss,fc,aa,aatest,sstest},...
 impacts_b{ss,fc,aa,aatest,sstest},...
 perf_b{ss,fc,aa,aatest,sstest},...
 lambda_b{ss,fc,aa,aatest,sstest},...
 nCoefs_b{ss,fc,aa,aatest,sstest}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{ss,fc,aa,aatest,sstest},...
 impacts_bms{ss,fc,aa,aatest,sstest},...
 perf_bms{ss,fc,aa,aatest,sstest},...
 lambda_bms{ss,fc,aa,aatest,sstest},...
 nCoefs_bms{ss,fc,aa,aatest,sstest}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{ss,fc,aa,aatest,sstest},...
 impacts_hws{ss,fc,aa,aatest,sstest},...
 perf_hws{ss,fc,aa,aatest,sstest},...
 lambda_hws{ss,fc,aa,aatest,sstest},...
 nCoefs_hws{ss,fc,aa,aatest,sstest}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.model.lambda == lambda_b{ss,fc,aa,aatest,sstest} );
lhwsIdx = find( testmodel.model.model.lambda == lambda_hws{ss,fc,aa,aatest,sstest} );
test_performances_b{ii,cc,fc,aa,aatest} = test_performances{ss,fc,aa,aatest,sstest}(lbIdx);
test_performances_hws{ii,cc,fc,aa,aatest} = test_performances{ss,fc,aa,aatest,sstest}(lhwsIdx);

save( ['glmnet_gos_' classname '_test.mat'], 'featureCreators', 'azimuths', 'snrs', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws'  );

end
end
end

